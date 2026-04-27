#!/usr/bin/env bash
# SimpleProd — AI Tools Setup (Domain 2)
# Install Opencode CLI and GitHub CLI (gh)
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
# AI Tools Setup
# ============================================================================

main() {
    sp_log_step "2.10" "AI Tools Setup"

    # ── Dry-run mode ──
    if [[ "${SP_DRY_RUN}" == "true" ]]; then
        sp_log_dry_run "Would install AI tools"
        sp_log_dry_run "  - Install Opencode CLI"
        sp_log_dry_run "  - Install GitHub CLI (gh)"
        return 0
    fi

    # ── Idempotency check ──
    if command -v opencode &>/dev/null && command -v gh &>/dev/null; then
        sp_log_success "AI tools are already installed. Skipping."
        return 0
    fi

    # ── STEP 1: Install Opencode CLI ──
    sp_log_info "Installing Opencode CLI..."
    curl -sS https://opencode.ai/install.sh | sh

    # ── STEP 2: Install GitHub CLI (gh) ──
    sp_log_info "Installing GitHub CLI (gh)..."
    apt-get update
    apt-get install -y gh

    sp_log_success "AI tools setup complete"
}

main "$@"