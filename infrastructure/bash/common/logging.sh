#!/usr/bin/env bash
# SimpleProd — Common Logging Functions
# Colored output, language-aware (EN/ES), progress reporting
set -euo pipefail

# Language setting (overridden by config or CLI)
SP_LANG="${SP_LANG:-en}"

# ============================================================================
# Color Definitions
# ============================================================================

# Only use colors if stdout is a terminal
if [[ -t 1 ]]; then
    SP_RED='\033[0;31m'
    SP_GREEN='\033[0;32m'
    SP_YELLOW='\033[0;33m'
    SP_BLUE='\033[0;34m'
    SP_CYAN='\033[0;36m'
    SP_BOLD='\033[1m'
    SP_NC='\033[0m'    # No Color
else
    SP_RED=''
    SP_GREEN=''
    SP_YELLOW=''
    SP_BLUE=''
    SP_CYAN=''
    SP_BOLD=''
    SP_NC=''
fi

# ============================================================================
# Message Functions (language-aware)
# ============================================================================

# Resolve message directory from this file's location (common/)
# common/ -> bash/ -> infrastructure/ -> project root -> application/config/messages
_SP_COMMON_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
_SP_MSG_DIR_DEFAULT="${_SP_COMMON_DIR}/../../../application/config/messages"

# Get a message from the messages YAML file
# Usage: sp_msg "preflight.os_supported" "os=Ubuntu version=22.04"
sp_msg() {
    local key="${1}"
    shift
    local msg_file="${SP_MSG_DIR:-${_SP_MSG_DIR_DEFAULT}}/${SP_LANG}.yaml"

    # Simple YAML key lookup — search for the nested key
    # key format: "preflight.os_supported" -> search for "os_supported:"
    local leaf_key
    leaf_key="$(echo "${key}" | awk -F. '{print $NF}')"

    local msg=""
    if [[ -f "${msg_file}" ]]; then
        # Extract value from the SAME line (inline YAML values, not multiline block scalars)
        msg="$(grep "^  ${leaf_key}:" "${msg_file}" 2>/dev/null | head -1 | sed "s/^  ${leaf_key}: *//" | sed 's/^"//;s/"$//')"
    fi

    # Default to English if message not found
    if [[ -z "${msg}" && "${SP_LANG}" != "en" ]]; then
        local en_file="${_SP_MSG_DIR_DEFAULT}/en.yaml"
        if [[ -f "${en_file}" ]]; then
            msg="$(grep "^  ${leaf_key}:" "${en_file}" 2>/dev/null | head -1 | sed "s/^  ${leaf_key}: *//" | sed 's/^"//;s/"$//')"
        fi
    fi

    # Fall back to the key itself if still not found
    msg="${msg:-${key}}"

    # Substitute variables
    local var val
    for var in "$@"; do
        val="${var#*=}"
        var="${var%%=*}"
        msg="${msg//\{${var}\}/${val}}"
    done

    echo "${msg}"
}

# ============================================================================
# Logging Functions
# ============================================================================

# Info message (cyan)
sp_log_info() {
    local msg="${1}"
    echo -e "${SP_CYAN}ℹ ${msg}${SP_NC}"
}

# Success message (green)
sp_log_success() {
    local msg="${1}"
    echo -e "${SP_GREEN}✓ ${msg}${SP_NC}"
}

# Warning message (yellow)
sp_log_warning() {
    local msg="${1}"
    echo -e "${SP_YELLOW}⚠ ${msg}${SP_NC}" >&2
}

# Error message (red)
sp_log_error() {
    local msg="${1}"
    echo -e "${SP_RED}✗ ${msg}${SP_NC}" >&2
}

# Step header (bold blue)
sp_log_step() {
    local step_num="${1}"
    local step_name="${2}"
    echo ""
    echo -e "${SP_BOLD}${SP_BLUE}━━━ Step ${step_num}: ${step_name} ━━━${SP_NC}"
}

# Dry-run message (yellow, prefixed)
sp_log_dry_run() {
    local msg="${1}"
    echo -e "${SP_YELLOW}[DRY RUN] ${msg}${SP_NC}"
}

# Progress indicator
sp_log_progress() {
    local completed="${1}"
    local total="${2}"
    local step_name="${3:-}"
    local percent=$(( (completed * 100) / total ))
    echo -e "${SP_CYAN}  [${completed}/${total}] ${percent}% — ${step_name}${SP_NC}"
}

# ============================================================================
# Banner
# ============================================================================

sp_banner() {
    # Read version from VERSION file (common/ -> bash/ -> infrastructure/ -> project root)
    local version_file="${_SP_COMMON_DIR}/../../../VERSION"
    local sp_version="v0.1.0"
    if [[ -f "${version_file}" ]]; then
        sp_version="v$(cat "${version_file}")"
    fi

    local inner_width=40
    local title="SimpleProd ${sp_version}"
    local subtitle="VPS Production Setup Bundle"
    local title_pad=$(( (inner_width - ${#title}) / 2 ))
    local sub_pad=$(( (inner_width - ${#subtitle}) / 2 ))

    echo -e "${SP_BOLD}${SP_CYAN}"
    echo "  ╔$(printf '═%.0s' $(seq 1 "${inner_width}"))╗"
    echo "  ║$(printf '%*s' "${title_pad}")${title}$(printf '%*s' $(( inner_width - title_pad - ${#title} )))║"
    echo "  ║$(printf '%*s' "${sub_pad}")${subtitle}$(printf '%*s' $(( inner_width - sub_pad - ${#subtitle} )))║"
    echo "  ╚$(printf '═%.0s' $(seq 1 "${inner_width}"))╝"
    echo -e "${SP_NC}"
    sp_log_info "$(sp_msg "config.wizard_prompt")"
    echo ""
}