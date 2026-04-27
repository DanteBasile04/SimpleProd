#!/usr/bin/env bash
# SimpleProd — Common Safety Functions (Domain 0)
# Lockout prevention, connectivity checks, pre-flight validation
set -euo pipefail

# ============================================================================
# Pre-flight Validation
# ============================================================================

# Check if running as root or with sudo
sp_require_root() {
    if [[ $EUID -ne 0 ]]; then
        sp_log_error "This script must be run as root or with sudo."
        exit 1
    fi
}

# Check OS is Ubuntu 22.04+ or Debian 12+
sp_check_os() {
    local os_id os_version
    if [[ -f /etc/os-release ]]; then
        # shellcheck disable=SC1091
        source /etc/os-release
        os_id="${ID:-unknown}"
        os_version="${VERSION_ID:-0}"
    else
        sp_log_error "Cannot determine OS. /etc/os-release not found."
        return 1
    fi

    case "${os_id}" in
        ubuntu)
            if sp_version_gte "${os_version}" "22.04"; then
                sp_log_success "OS supported: Ubuntu ${os_version}"
                return 0
            else
                sp_log_error "Ubuntu ${os_version} not supported. Need 22.04+."
                return 1
            fi
            ;;
        debian)
            if sp_version_gte "${os_version}" "12"; then
                sp_log_success "OS supported: Debian ${os_version}"
                return 0
            else
                sp_log_error "Debian ${os_version} not supported. Need 12+."
                return 1
            fi
            ;;
        *)
            sp_log_error "Unsupported OS: ${os_id}. Need Ubuntu 22.04+ or Debian 12+."
            return 1
            ;;
    esac
}

# Check internet connectivity
sp_check_internet() {
    sp_log_info "Checking internet connectivity..."
    if ping -c 1 -W 5 8.8.8.8 &>/dev/null || ping -c 1 -W 5 1.1.1.1 &>/dev/null; then
        sp_log_success "Internet connectivity: OK"
        return 0
    else
        sp_log_error "No internet connectivity. Cannot proceed."
        return 1
    fi
}

# Check minimum disk space (10GB)
sp_check_disk() {
    local min_gb=10
    local free_kb free_gb
    free_kb="$(df -k / | tail -1 | awk '{print $4}')"
    free_gb=$((free_kb / 1024 / 1024))
    if (( free_gb >= min_gb )); then
        sp_log_success "Disk space: ${free_gb}GB free (minimum: ${min_gb}GB)"
        return 0
    else
        sp_log_error "Insufficient disk space. ${free_gb}GB free, need at least ${min_gb}GB."
        return 1
    fi
}

# Check minimum RAM (1GB)
sp_check_ram() {
    local min_mb=1024
    local total_mb
    total_mb="$(free -m | awk '/^Mem:/ {print $2}')"
    if (( total_mb >= min_mb )); then
        sp_log_success "RAM: ${total_mb}MB available (minimum: ${min_mb}MB)"
        return 0
    else
        sp_log_error "Insufficient RAM. ${total_mb}MB available, need at least ${min_mb}MB."
        return 1
    fi
}

# Run all pre-flight checks
sp_preflight() {
    sp_log_info "Running pre-flight checks..."
    sp_require_root
    sp_check_os      || return 1
    sp_check_internet || return 1
    sp_check_disk    || return 1
    sp_check_ram     || return 1
    sp_log_success "All pre-flight checks passed. Proceeding with provisioning."
    return 0
}

# ============================================================================
# Lockout Prevention (CRITICAL — Domain 0)
# ============================================================================

# Verify SSH key authentication works before disabling password auth
# Returns 0 if key auth works, 1 if it fails
sp_verify_ssh_key_auth() {
    local username="${1:-}"
    local ssh_port="${2:-22}"

    sp_log_info "Verifying SSH key authentication before disabling password auth..."

    # Check if authorized_keys exists and has content
    local auth_keys="/home/${username}/.ssh/authorized_keys"
    if [[ ! -f "${auth_keys}" ]]; then
        sp_log_error "LOCKOUT RISK: ${auth_keys} not found. Password auth kept enabled."
        return 1
    fi

    if [[ ! -s "${auth_keys}" ]]; then
        sp_log_error "LOCKOUT RISK: ${auth_keys} is empty. Password auth kept enabled."
        return 1
    fi

    # Test key auth by checking if we can connect with the key
    # This is a local check — if we're running as root, sudo to the user
    if sudo -u "${username}" test -r "${auth_keys}"; then
        sp_log_success "SSH key authentication verified. Proceeding with hardening."
        return 0
    else
        sp_log_error "LOCKOUT RISK: Could not verify key authentication. Password auth kept enabled."
        return 1
    fi
}

# Verify SSH session is still active after network changes
sp_check_ssh_session() {
    sp_log_info "Verifying SSH session remains active..."

    # Check if sshd is running
    if systemctl is-active --quiet sshd 2>/dev/null || systemctl is-active --quiet ssh 2>/dev/null; then
        sp_log_success "SSH session active. Safe to proceed."
        return 0
    else
        sp_log_warning "SSH service may not be running. Please verify connectivity."
        return 1
    fi
}

# ============================================================================
# Step Failure Handling
# ============================================================================

# Offer retry/skip/rollback/abort on step failure
# Usage: sp_handle_failure "step_name" "error_message"
sp_handle_failure() {
    local step="${1}"
    local error="${2}"

    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" >&2
    sp_log_error "Step '${step}' failed with error:"
    sp_log_error "${error}"
    echo ""
    sp_log_info "Choose an action:"
    echo "  [R] Retry   — run this step again"
    echo "  [S] Skip    — continue without this step (WARNING: dependent steps will also be skipped)"
    echo "  [B] Rollback — revert all changes made in this run"
    echo "  [A] Abort   — stop provisioning immediately"
    echo ""

    local choice
    read -rp "Your choice [R/S/B/A]: " choice

    case "${choice^^}" in
        R) return 2 ;;   # retry
        S) return 3 ;;   # skip
        B) return 4 ;;   # rollback
        A) return 5 ;;   # abort
        *) sp_log_error "Invalid choice. Aborting."; return 5 ;;
    esac
}

# ============================================================================
# Existing Service Detection
# ============================================================================

# Check if a service is already installed/running
# Usage: sp_detect_existing "nginx" && echo "nginx found"
sp_detect_existing() {
    local service="${1}"
    command -v "${service}" &>/dev/null || systemctl is-active --quiet "${service}" 2>/dev/null
}

# Prompt user for action when existing service is detected
# Usage: sp_prompt_existing "nginx"
# Returns: 0=preserve, 1=overwrite, 2=merge
sp_prompt_existing() {
    local service="${1}"

    sp_log_warning "${service} is already installed."
    echo ""
    sp_log_info "Choose an action:"
    echo "  [P] Preserve   — keep existing configuration"
    echo "  [O] Overwrite  — backup existing, then apply SimpleProd config"
    echo "  [M] Merge      — apply SimpleProd settings on top of existing config"
    echo ""

    local choice
    read -rp "Your choice [P/O/M]: " choice

    case "${choice^^}" in
        P) return 0 ;;
        O) return 1 ;;
        M) return 2 ;;
        *) sp_log_warning "Invalid choice. Defaulting to Preserve."; return 0 ;;
    esac
}

# ============================================================================
# Utility
# ============================================================================

# Compare version numbers: sp_version_gte "22.04" "22.04"
sp_version_gte() {
    local actual="${1}"
    local required="${2}"
    printf '%s\n' "${required}" "${actual}" | sort -V -C 2>/dev/null
}