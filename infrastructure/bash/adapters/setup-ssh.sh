#!/usr/bin/env bash
# SimpleProd — SSH Hardening (CRITICAL — Domain 0)
# Lockout prevention: verifies key auth BEFORE disabling password auth
# Connection safety: verifies SSH session stays active after changes
set -euo pipefail

# Source common functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../common/safety.sh"
source "${SCRIPT_DIR}/../common/backup.sh"
source "${SCRIPT_DIR}/../common/logging.sh"
source "${SCRIPT_DIR}/../common/secrets.sh"

# Config from environment (defaults from defaults.yaml)
SP_DRY_RUN="${SP_DRY_RUN:-false}"
SP_USERNAME="${SP_USERNAME:-deploy}"
SP_SSH_PORT="${SP_SSH_PORT:-22}"

# ============================================================================
# SSH Hardening — CRITICAL SECURITY STEP
# ============================================================================

main() {
    sp_log_step "3" "SSH Hardening"

    # ── Dry-run mode ──
    if [[ "${SP_DRY_RUN}" == "true" ]]; then
        sp_log_dry_run "Would harden SSH configuration:"
        sp_log_dry_run "  - Disable password authentication"
        sp_log_dry_run "  - Disable root login"
        sp_log_dry_run "  - Set SSH port to ${SP_SSH_PORT}"
        sp_log_dry_run "  - Set key-only authentication"
        sp_log_dry_run ""
        sp_log_dry_run "⚠ WARNING: This will change SSH settings. Ensure your key is configured before proceeding."
        return 0
    fi

    # ── Idempotency check ──
    if grep -q "^PasswordAuthentication no" /etc/ssh/sshd_config 2>/dev/null && \
       grep -q "^PermitRootLogin no" /etc/ssh/sshd_config 2>/dev/null; then
        sp_log_success "SSH is already hardened. No changes needed."
        return 0
    fi

    # ── STEP 1: Backup sshd_config ──
    sp_log_info "Backing up /etc/ssh/sshd_config..."
    local backup_path
    backup_path="$(sp_backup_file "/etc/ssh/sshd_config")"
    sp_manifest_add "${backup_path}"

    # ── STEP 2: Verify key authentication BEFORE disabling password ──
    # THIS IS THE MOST CRITICAL STEP IN THE ENTIRE BUNDLE.
    # If we disable password auth and the key doesn't work, the user is LOCKED OUT.
    if ! sp_verify_ssh_key_auth "${SP_USERNAME}" "${SP_SSH_PORT}"; then
        sp_log_error "LOCKOUT RISK: Could not verify key authentication. Password auth kept enabled."
        sp_log_error "Ensure ${SP_USERNAME}'s SSH public key is in /home/${SP_USERNAME}/.ssh/authorized_keys"
        return 1
    fi
    sp_log_success "SSH key authentication verified. Safe to proceed."

    # ── STEP 3: Detect existing service ──
    if sp_detect_existing "sshd"; then
        sp_log_info "SSH server is already installed. Configuring existing installation."
    fi

    # ── STEP 4: Apply hardening ──
    sp_log_info "Hardening SSH configuration..."

    # Use sed for in-place modification to preserve existing config structure
    local sshd_config="/etc/ssh/sshd_config"

    # Disable password authentication
    if grep -q "^#PasswordAuthentication" "${sshd_config}" 2>/dev/null; then
        sed -i "s/^#PasswordAuthentication.*/PasswordAuthentication no/" "${sshd_config}"
    elif grep -q "^PasswordAuthentication" "${sshd_config}" 2>/dev/null; then
        sed -i "s/^PasswordAuthentication.*/PasswordAuthentication no/" "${sshd_config}"
    else
        echo "PasswordAuthentication no" >> "${sshd_config}"
    fi

    # Disable root login
    if grep -q "^#PermitRootLogin" "${sshd_config}" 2>/dev/null; then
        sed -i "s/^#PermitRootLogin.*/PermitRootLogin no/" "${sshd_config}"
    elif grep -q "^PermitRootLogin" "${sshd_config}" 2>/dev/null; then
        sed -i "s/^PermitRootLogin.*/PermitRootLogin no/" "${sshd_config}"
    else
        echo "PermitRootLogin no" >> "${sshd_config}"
    fi

    # Set SSH port (if non-default)
    if [[ "${SP_SSH_PORT}" != "22" ]]; then
        sp_log_info "Changing SSH port to ${SP_SSH_PORT}..."
        # First update UFW to allow the new port BEFORE changing it
        if command -v ufw &>/dev/null; then
            ufw allow "${SP_SSH_PORT}"/tcp
            sp_log_success "UFW rule added for port ${SP_SSH_PORT}/tcp"
        fi
        if grep -q "^#Port" "${sshd_config}" 2>/dev/null; then
            sed -i "s/^#Port.*/Port ${SP_SSH_PORT}/" "${sshd_config}"
        elif grep -q "^Port" "${sshd_config}" 2>/dev/null; then
            sed -i "s/^Port.*/Port ${SP_SSH_PORT}/" "${sshd_config}"
        else
            echo "Port ${SP_SSH_PORT}" >> "${sshd_config}"
        fi
    fi

    # Additional hardening
    grep -q "^ChallengeResponseAuthentication" "${sshd_config}" 2>/dev/null || echo "ChallengeResponseAuthentication no" >> "${sshd_config}"
    grep -q "^X11Forwarding" "${sshd_config}" 2>/dev/null || echo "X11Forwarding no" >> "${sshd_config}"
    grep -q "^MaxAuthTries" "${sshd_config}" 2>/dev/null || echo "MaxAuthTries 3" >> "${sshd_config}"
    grep -q "^MaxSessions" "${sshd_config}" 2>/dev/null || echo "MaxSessions 2" >> "${sshd_config}"
    grep -q "^ClientAliveInterval" "${sshd_config}" 2>/dev/null || echo "ClientAliveInterval 300" >> "${sshd_config}"
    grep -q "^ClientAliveCountMax" "${sshd_config}" 2>/dev/null || echo "ClientAliveCountMax 2" >> "${sshd_config}"

    # ── STEP 5: Validate config before restarting ──
    if ! sshd -t 2>/dev/null; then
        sp_log_error "SSH config validation failed! Rolling back."
        sp_restore_file "${backup_path}"
        return 1
    fi
    sp_log_success "SSH config validation passed."

    # ── STEP 6: Restart SSH ──
    sp_log_info "Restarting SSH service..."
    if systemctl is-active --quiet sshd 2>/dev/null; then
        systemctl restart sshd
    elif systemctl is-active --quiet ssh 2>/dev/null; then
        systemctl restart ssh
    else
        systemctl restart sshd
    fi

    # ── STEP 7: Verify SSH session is STILL ACTIVE ──
    # Wait a moment for SSH to come back up
    sleep 2
    if ! sp_check_ssh_session; then
        sp_log_error "SSH session may have dropped! Rolling back changes."
        sp_restore_file "${backup_path}"
        if systemctl is-active --quiet sshd 2>/dev/null; then
            systemctl restart sshd
        elif systemctl is-active --quiet ssh 2>/dev/null; then
            systemctl restart ssh
        fi
        sp_log_error "Rolled back SSH configuration. Please verify your access."
        return 1
    fi

    sp_log_success "SSH hardened: password auth disabled, root login disabled, port ${SP_SSH_PORT}"
}

main "$@"