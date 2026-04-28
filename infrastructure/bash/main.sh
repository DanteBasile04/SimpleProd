#!/usr/bin/env bash
set -euo pipefail

# Source common functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMMON_DIR="${SCRIPT_DIR}/common"
source "${COMMON_DIR}/safety.sh"
source "${COMMON_DIR}/backup.sh"
source "${COMMON_DIR}/logging.sh"
source "${COMMON_DIR}/secrets.sh"

# Config from environment (defaults from defaults.yaml)
SP_DRY_RUN="${SP_DRY_RUN:-false}"
SP_LANG="${SP_LANG:-en}"
SP_USERNAME="${SP_USERNAME:-deploy}"
SP_SSH_PORT="${SP_SSH_PORT:-22}"

# Main function
main() {
    # Show banner
    sp_banner
    
    # Run pre-flight checks
    sp_preflight
    
    # Start backup manifest
    sp_manifest_start
    
    # Execute each setup script in dependency order
    local total_steps=5
    local current_step=0

    for script in \
        setup-base-tools.sh \
        setup-user.sh \
        setup-ssh.sh \
        setup-ufw.sh \
        setup-fail2ban.sh; do
        
        current_step=$((current_step + 1))
        sp_log_info "Running ${script}..."
        "${SCRIPT_DIR}/adapters/${script}"
        
        sp_log_progress "${current_step}" "${total_steps}" "${script}"
    done
    
    sp_log_success "All setup scripts executed successfully"
}

# Handle dry-run flag
if [[ "${1:-}" == "--dry-run" ]]; then
    export SP_DRY_RUN="true"
    shift
fi

main "$@"