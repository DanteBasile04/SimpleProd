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

# Main function
main() {
    sp_log_step "1" "Setup Base Tools"
    
    if [[ "${SP_DRY_RUN}" == "true" ]]; then
        sp_log_dry_run "Would install base tools: git, curl, wget, vim, htop"
        return 0
    fi
    
    # Check if already installed
    if sp_detect_existing "git" && sp_detect_existing "curl" && sp_detect_existing "wget" && sp_detect_existing "vim" && sp_detect_existing "htop"; then
        sp_log_success "Base tools already installed"
        return 0
    fi
    
    # Update package manager
    sp_log_info "Updating package manager..."
    apt-get update -qq
    
    # Install base tools
    sp_log_info "Installing base tools..."
    apt-get install -y git curl wget vim htop
    
    sp_log_success "Base tools installed successfully"
}

main "$@"