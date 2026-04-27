#!/usr/bin/env bash
# SimpleProd — Homebrew Setup (Domain 2)
# Install Linuxbrew in user's home directory
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
# Homebrew Setup
# ============================================================================

main() {
    sp_log_step "2.8" "Homebrew Setup"

    # ── Dry-run mode ──
    if [[ "${SP_DRY_RUN}" == "true" ]]; then
        sp_log_dry_run "Would install Homebrew for user ${SP_USERNAME}"
        sp_log_dry_run "  - Install Linuxbrew"
        sp_log_dry_run "  - Add to PATH in .bashrc and .zshrc"
        return 0
    fi

    # ── Idempotency check ──
    if [[ -d "/home/${SP_USERNAME}/.linuxbrew" ]]; then
        sp_log_success "Homebrew is already installed. Skipping."
        return 0
    fi

    # ── STEP 1: Install Homebrew ──
    sp_log_info "Installing Homebrew for user ${SP_USERNAME}..."
    sudo -u "${SP_USERNAME}" bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

    # ── STEP 2: Add to PATH ──
    sp_log_info "Adding Homebrew to PATH in .bashrc and .zshrc..."
    local bashrc="/home/${SP_USERNAME}/.bashrc"
    local zshrc="/home/${SP_USERNAME}/.zshrc"

    if [[ -f "${bashrc}" ]]; then
        if ! grep -q "eval \"$(/home/${SP_USERNAME}/.linuxbrew/bin/brew shellenv)\"" "${bashrc}"; then
            echo "eval \"$(/home/${SP_USERNAME}/.linuxbrew/bin/brew shellenv)\"" >> "${bashrc}"
        fi
    fi

    if [[ -f "${zshrc}" ]]; then
        if ! grep -q "eval \"$(/home/${SP_USERNAME}/.linuxbrew/bin/brew shellenv)\"" "${zshrc}"; then
            echo "eval \"$(/home/${SP_USERNAME}/.linuxbrew/bin/brew shellenv)\"" >> "${zshrc}"
        fi
    fi

    sp_log_success "Homebrew setup complete for user ${SP_USERNAME}"
}

main "$@"