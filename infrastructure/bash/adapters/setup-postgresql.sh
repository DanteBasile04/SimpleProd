#!/usr/bin/env bash
# SimpleProd — PostgreSQL Setup (Domain 2)
# Install PostgreSQL, create database and user for each client
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
# PostgreSQL Setup
# ============================================================================

main() {
    sp_log_step "2.12" "PostgreSQL Setup"

    # ── Dry-run mode ──
    if [[ "${SP_DRY_RUN}" == "true" ]]; then
        sp_log_dry_run "Would install PostgreSQL and create databases for clients"
        sp_log_dry_run "  - Install PostgreSQL"
        sp_log_dry_run "  - Create database and user for each client"
        return 0
    fi

    # ── Idempotency check ──
    if sp_detect_existing "postgresql"; then
        sp_log_success "PostgreSQL is already installed. Configuring existing installation."
    fi

    # ── STEP 1: Install PostgreSQL ──
    sp_log_info "Installing PostgreSQL..."
    apt-get update
    apt-get install -y postgresql postgresql-contrib

    # ── STEP 2: Create database and user for each client ──
    sp_log_info "Creating databases and users for clients..."
    local clients
    clients="$(sp_secret_list_clients)"

    for client in ${clients}; do
        if ! sp_secret_exists "${client}"; then
            sp_secret_store_db_password "${client}"
        fi

        local db_user db_password db_name
        db_user="$(sp_secret_get "${client}" "DB_USER")"
        db_password="$(sp_secret_get "${client}" "DB_PASSWORD")"
        db_name="$(sp_secret_get "${client}" "DB_NAME")"

        # Check if database already exists
        if sudo -u postgres psql -lqt | cut -d \| -f 1 | grep -qw "${db_name}"; then
            sp_log_info "Database ${db_name} already exists. Skipping."
            continue
        fi

        # Create user
        sudo -u postgres psql -c "CREATE USER ${db_user} WITH PASSWORD '${db_password}'"

        # Create database
        sudo -u postgres psql -c "CREATE DATABASE ${db_name} OWNER ${db_user}"

        # Grant privileges
        sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE ${db_name} TO ${db_user}"

        sp_log_success "Created database ${db_name} for client ${client}"
    done

    sp_log_success "PostgreSQL setup complete"
}

main "$@"