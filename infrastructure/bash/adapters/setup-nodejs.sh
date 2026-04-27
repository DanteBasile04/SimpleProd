#!/usr/bin/env bash
# SimpleProd — Node.js Setup (Domain 2)
# Install nvm, Node.js LTS, and PM2
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

# ============================================================================
# Node.js Setup
# ============================================================================

main() {
    sp_log_step "2.7" "Node.js Setup"

    # ── Dry-run mode ──
    if [[ "${SP_DRY_RUN}" == "true" ]]; then
        sp_log_dry_run "Would install Node.js and PM2"
        sp_log_dry_run "  - Install nvm"
        sp_log_dry_run "  - Install Node.js LTS"
        sp_log_dry_run "  - Install PM2"
        return 0
    fi

    # ── Idempotency check ──
    if command -v node &>/dev/null && command -v npm &>/dev/null; then
        sp_log_success "Node.js is already installed. Skipping."
        return 0
    fi

    # ── STEP 1: Install nvm ──
    sp_log_info "Installing nvm..."
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash

    # ── STEP 2: Install Node.js LTS ──
    sp_log_info "Installing Node.js LTS..."
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \
        . "$NVM_DIR/nvm.sh"
    nvm install --lts

    # ── STEP 3: Install PM2 ──
    sp_log_info "Installing PM2..."
    npm install -g pm2

    sp_log_success "Node.js setup complete"
}

main "$@"