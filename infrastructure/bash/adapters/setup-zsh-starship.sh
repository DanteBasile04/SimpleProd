#!/usr/bin/env bash
# SimpleProd — Zsh Starship Setup (Domain 2)
# Install zsh, set as default shell for SP_USERNAME, install Starship prompt, create .zshrc config
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
# Zsh Starship Setup
# ============================================================================

main() {
    sp_log_step "2.9" "Zsh Starship Setup"

    # ── Dry-run mode ──
    if [[ "${SP_DRY_RUN}" == "true" ]]; then
        sp_log_dry_run "Would install Zsh and Starship for user ${SP_USERNAME}"
        sp_log_dry_run "  - Install zsh"
        sp_log_dry_run "  - Set as default shell"
        sp_log_dry_run "  - Install Starship"
        sp_log_dry_run "  - Create .zshrc config"
        return 0
    fi

    # ── Idempotency check ──
    if command -v zsh &>/dev/null && [[ "$(grep "${SP_USERNAME}" /etc/passwd | cut -d: -f7)" == "/usr/bin/zsh" ]]; then
        sp_log_success "Zsh is already installed and set as default. Skipping."
        return 0
    fi

    # ── STEP 1: Install zsh ──
    sp_log_info "Installing zsh..."
    apt-get update
    apt-get install -y zsh

    # ── STEP 2: Set as default shell ──
    sp_log_info "Setting zsh as default shell for user ${SP_USERNAME}..."
    chsh -s "$(which zsh)" "${SP_USERNAME}"

    # ── STEP 3: Install Starship ──
    sp_log_info "Installing Starship..."
    curl -sS https://starship.rs/install.sh | sh

    # ── STEP 4: Create .zshrc config ──
    sp_log_info "Creating .zshrc config..."
    local zshrc="/home/${SP_USERNAME}/.zshrc"
    cat > "${zshrc}" <<EOF
# Load Starship prompt
if [ -f ~/.config/starship.toml ]; then
    eval "$(starship init zsh)"
fi

# Aliases
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'

# History settings
HISTSIZE=10000
HISTFILESIZE=20000

# Enable completion
autoload -Uz compinit
compinit
EOF

    sp_log_success "Zsh Starship setup complete for user ${SP_USERNAME}"
}

main "$@"