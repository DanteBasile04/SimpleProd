#!/usr/bin/env bash
# SimpleProd — Common Secrets Functions (Domain 0)
# Secure storage of passwords, keys, and other secrets
# Mode 600, owned by root, never logged
set -euo pipefail

# Default secrets directory
SP_SECRETS_DIR="${SP_SECRETS_DIR:-/var/simpleprod/secrets}"

# ============================================================================
# Secret Management Functions
# ============================================================================

# Initialize the secrets directory with correct permissions
# Usage: sp_secrets_init
sp_secrets_init() {
    mkdir -p "${SP_SECRETS_DIR}"
    chmod 700 "${SP_SECRETS_DIR}"
    chown root:root "${SP_SECRETS_DIR}"
    sp_log_info "Secrets directory initialized: ${SP_SECRETS_DIR}"
}

# Store a secret value in a file
# Usage: sp_secret_store "client_name" "DB_PASSWORD" "super_secret_value"
# Creates /var/simpleprod/secrets/client_name.env with KEY=VALUE
sp_secret_store() {
    local client="${1}"
    local key="${2}"
    local value="${3}"
    local secrets_file="${SP_SECRETS_DIR}/${client}.env"

    # Ensure secrets directory exists
    mkdir -p "${SP_SECRETS_DIR}"
    chmod 700 "${SP_SECRETS_DIR}"

    # Create or update the secrets file
    if [[ -f "${secrets_file}" ]]; then
        # Update existing key or append
        if grep -q "^${key}=" "${secrets_file}" 2>/dev/null; then
            # Replace existing value — use temp file for safety
            local temp_file
            temp_file="$(mktemp)"
            sed "s|^${key}=.*|${key}=${value}|" "${secrets_file}" > "${temp_file}"
            mv "${temp_file}" "${secrets_file}"
        else
            echo "${key}=${value}" >> "${secrets_file}"
        fi
    else
        echo "${key}=${value}" > "${secrets_file}"
    fi

    # Set secure permissions: mode 600, owned by root
    chmod 600 "${secrets_file}"
    chown root:root "${secrets_file}"

    # Log ONLY the file path, NEVER the value
    sp_log_success "$(sp_msg "secrets.stored" "path=${secrets_file}")"
}

# Retrieve a secret value from a file
# Usage: sp_secret_get "client_name" "DB_PASSWORD"
# Returns the value to stdout
sp_secret_get() {
    local client="${1}"
    local key="${2}"
    local secrets_file="${SP_SECRETS_DIR}/${client}.env"

    if [[ ! -f "${secrets_file}" ]]; then
        sp_log_error "Secrets file not found: ${secrets_file}"
        return 1
    fi

    local value
    value="$(grep "^${key}=" "${secrets_file}" | cut -d'=' -f2-)"

    if [[ -z "${value}" ]]; then
        sp_log_error "Key '${key}' not found in ${secrets_file}"
        return 1
    fi

    echo "${value}"
}

# Generate a random password
# Usage: sp_secret_generate_password [length]
# Default length: 32
sp_secret_generate_password() {
    local length="${1:-32}"
    # Generate using /dev/urandom: alphanumeric + special chars
    tr -dc 'A-Za-z0-9!@#$%^&*()_+' < /dev/urandom | head -c "${length}"
}

# Store a generated password for a client's database
# Usage: sp_secret_store_db_password "client_name"
# Generates a random password and stores it as DB_PASSWORD
sp_secret_store_db_password() {
    local client="${1}"
    local password
    password="$(sp_secret_generate_password 32)"
    sp_secret_store "${client}" "DB_PASSWORD" "${password}"
    sp_secret_store "${client}" "DB_USER" "${client}"
    sp_secret_store "${client}" "DB_NAME" "client_${client}"
}

# Check if a secrets file exists for a client
# Usage: sp_secret_exists "client_name"
sp_secret_exists() {
    local client="${1}"
    [[ -f "${SP_SECRETS_DIR}/${client}.env" ]]
}

# List all clients that have secrets stored
# Usage: sp_secret_list_clients
sp_secret_list_clients() {
    if [[ -d "${SP_SECRETS_DIR}" ]]; then
        find "${SP_SECRETS_DIR}" -name "*.env" -type f -exec basename {} .env \;
    fi
}