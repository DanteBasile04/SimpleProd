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
    sp_log_step "5" "Setup Fail2Ban"
    
    if [[ "${SP_DRY_RUN}" == "true" ]]; then
        sp_log_dry_run "Would install and configure Fail2Ban"
        return 0
    fi
    
    # Check if Fail2Ban is already installed
    if command -v fail2ban-client &>/dev/null; then
        sp_log_success "Fail2Ban already installed"
        return 0
    fi
    
    # Install Fail2Ban
    sp_log_info "Installing Fail2Ban..."
    apt-get install -y fail2ban
    
    # Configure Fail2Ban
    sp_log_info "Configuring Fail2Ban..."
    {
        echo "[sshd]"
        echo "enabled = true"
        echo "port = ${SP_SSH_PORT}"
        echo "filter = sshd"
        echo "logpath = /var/log/auth.log"
        echo "maxretry = 3"
        echo "bantime = 1h"
    } > "/etc/fail2ban/jail.local"
    
    # Restart Fail2Ban service
    systemctl restart fail2ban
    
    sp_log_success "Fail2Ban configured successfully"
}

main "$@"