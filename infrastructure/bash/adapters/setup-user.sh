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
SP_USERNAME="${SP_USERNAME:-deploy}"

# Main function
main() {
    sp_log_step "2" "Setup User"
    
    if [[ "${SP_DRY_RUN}" == "true" ]]; then
        sp_log_dry_run "Would create user ${SP_USERNAME} with sudo privileges"
        return 0
    fi
    
    # Check if user already exists
    if id "${SP_USERNAME}" &>/dev/null; then
        sp_log_success "User ${SP_USERNAME} already exists"
        return 0
    fi
    
    # Create user
    sp_log_info "Creating user ${SP_USERNAME}..."
    adduser --disabled-password --gecos "" "${SP_USERNAME}"
    
    # Add to sudo group
    usermod -aG sudo "${SP_USERNAME}"
    
    # Set up SSH directory
    mkdir -p "/home/${SP_USERNAME}/.ssh"
    chown "${SP_USERNAME}:${SP_USERNAME}" "/home/${SP_USERNAME}/.ssh"
    chmod 700 "/home/${SP_USERNAME}/.ssh"

    # Copy SSH key from current user (Domain 0 — prevents lockout)
    # Checks: authorized_keys of current user → SP_SSH_KEY env var → none
    local current_user
    current_user="$(whoami)"
    local source_key=""

    if [[ -n "${SP_SSH_KEY:-}" && -f "${SP_SSH_KEY}" ]]; then
        source_key="${SP_SSH_KEY}"
    elif [[ -f "/root/.ssh/authorized_keys" ]]; then
        source_key="/root/.ssh/authorized_keys"
    elif [[ -f "/home/${current_user}/.ssh/authorized_keys" ]]; then
        source_key="/home/${current_user}/.ssh/authorized_keys"
    fi

    if [[ -n "${source_key}" && -s "${source_key}" ]]; then
        cp "${source_key}" "/home/${SP_USERNAME}/.ssh/authorized_keys"
        chown "${SP_USERNAME}:${SP_USERNAME}" "/home/${SP_USERNAME}/.ssh/authorized_keys"
        chmod 600 "/home/${SP_USERNAME}/.ssh/authorized_keys"
        sp_log_success "SSH key copied to ${SP_USERNAME} from ${source_key}"
    else
        sp_log_warning "No SSH key found to copy. You MUST add your key manually before SSH hardening:"
        sp_log_warning "  Run: ssh-copy-id -i ~/.ssh/id_rsa.pub ${SP_USERNAME}@<host>"
    fi
    
    sp_log_success "User ${SP_USERNAME} created with sudo privileges"
}

main "$@"