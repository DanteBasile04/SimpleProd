#!/usr/bin/env bash
# SimpleProd — Logrotate Setup (Domain 2)
# Configure logrotate for Nginx logs (/var/log/nginx/) and app logs
set -euo pipefail

# Source common functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../common/safety.sh"
source "${SCRIPT_DIR}/../common/backup.sh"
source "${SCRIPT_DIR}/../common/logging.sh"
source "${SCRIPT_DIR}/../common/secrets.sh"

# Config from environment (defaults from defaults.yaml)
SP_DRY_RUN="${SP_DRY_RUN:-false}"

# ============================================================================
# Logrotate Setup
# ============================================================================

main() {
    sp_log_step "2.15" "Logrotate Setup"

    # ── Dry-run mode ──
    if [[ "${SP_DRY_RUN}" == "true" ]]; then
        sp_log_dry_run "Would configure logrotate for Nginx and app logs"
        sp_log_dry_run "  - Create /etc/logrotate.d/simpleprod config file"
        sp_log_dry_run "  - Backup existing logrotate configs"
        return 0
    fi

    # ── Idempotency check ──
    if [[ -f "/etc/logrotate.d/simpleprod" ]]; then
        sp_log_success "Logrotate config already exists. Skipping."
        return 0
    fi

    # ── STEP 1: Backup existing logrotate configs ──
    sp_log_info "Backing up existing logrotate configs..."
    local backup_path
    backup_path="$(sp_backup_file "/etc/logrotate.conf")"
    sp_manifest_add "${backup_path}"

    # ── STEP 2: Create logrotate config ──
    sp_log_info "Creating logrotate config..."
    local logrotate_config="/etc/logrotate.d/simpleprod"
    cat > "${logrotate_config}" <<EOF
/var/log/nginx/*.log {
    daily
    missingok
    rotate 14
    compress
    delaycompress
    notifempty
    create 0640 www-data adm
    sharedscripts
    postrotate
        systemctl reload nginx >/dev/null 2>&1 || true
    endscript
}

/var/log/simpleprod/*.log {
    daily
    missingok
    rotate 14
    compress
    delaycompress
    notifempty
    create 0640 www-data adm
    sharedscripts
}
EOF

    sp_log_success "Logrotate setup complete"
}

main "$@"