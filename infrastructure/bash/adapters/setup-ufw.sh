#!/usr/bin/env bash
set -euo pipefail

# Source common functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../common/safety.sh"
source "${SCRIPT_DIR}/../common/backup.sh"
source "${SCRIPT_DIR}/../common/logging.sh"
source "${SCRIPT_DIR}/../common/secrets.sh"

# Config from environment (defaults from defaults.yaml)
SP_DRY_RUN="${SP_DRY_RUN:-false}"
SP_SSH_PORT="${SP_SSH_PORT:-22}"

# Main function
main() {
    sp_log_step "4" "Setup UFW"
    
    if [[ "${SP_DRY_RUN}" == "true" ]]; then
        sp_log_dry_run "Would configure UFW firewall"
        return 0
    fi
    
    # ── Idempotency check ──
    if ufw status | grep -q "Status: active"; then
        # Verify required rules exist even if UFW is already active
        if ufw status | grep -q "${SP_SSH_PORT}/tcp" && \
           ufw status | grep -q "80/tcp" && \
           ufw status | grep -q "443/tcp"; then
            sp_log_success "UFW firewall already configured correctly."
            return 0
        fi
        sp_log_info "UFW is active but rules are incomplete. Adding missing rules..."
    fi

    # ── CRITICAL: Allow SSH port BEFORE enabling deny-all ──
    # This is Domain 0 safety — if we don't allow SSH first, we lock ourselves out.
    sp_log_info "Allowing SSH port ${SP_SSH_PORT}/tcp BEFORE enabling deny-all..."
    ufw allow "${SP_SSH_PORT}/tcp"
    sp_log_success "SSH rule added to UFW."

    # ── Allow HTTP and HTTPS ──
    sp_log_info "Allowing HTTP (80) and HTTPS (443)..."
    ufw allow 80/tcp
    ufw allow 443/tcp

    # ── Enable UFW with default deny incoming ──
    sp_log_info "Enabling default deny incoming policy..."
    ufw default deny incoming
    ufw default allow outgoing

    # ── Backup UFW rules before enabling ──
    # (UFW already backs up its own configs, but we log this for the manifest)
    sp_log_info "Enabling UFW firewall..."
    ufw --force enable

    # ── Verify SSH session is STILL ACTIVE ──
    # Domain 0 safety — if UFW broke SSH, we need to know immediately
    if ! sp_check_ssh_session; then
        sp_log_error "SSH session may have dropped after UFW changes! Rolling back."
        ufw disable
        return 1
    fi

    # ── Verify UFW status ──
    sp_log_info "UFW status:"
    ufw status verbose

    sp_log_success "UFW firewall configured: SSH ${SP_SSH_PORT}/tcp, HTTP 80, HTTPS 443 allowed"
}

main "$@"