#!/usr/bin/env bash
# SimpleProd — Backups Setup (Domain 2)
# Create backup scripts in /var/simpleprod/scripts/, set up cron jobs
set -euo pipefail

# Source common functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../common/safety.sh"
source "${SCRIPT_DIR}/../common/backup.sh"
source "${SCRIPT_DIR}/../common/logging.sh"
source "${SCRIPT_DIR}/../common/secrets.sh"

# Config from environment (defaults from defaults.yaml)
SP_DRY_RUN="${SP_DRY_RUN:-false}"
SP_BACKUP_RETENTION_DAYS="${SP_BACKUP_RETENTION_DAYS:-30}"

# ============================================================================
# Backups Setup
# ============================================================================

main() {
    sp_log_step "2.13" "Backups Setup"

    # ── Dry-run mode ──
    if [[ "${SP_DRY_RUN}" == "true" ]]; then
        sp_log_dry_run "Would create backup scripts and set up cron jobs"
        sp_log_dry_run "  - Create backup scripts in /var/simpleprod/scripts/"
        sp_log_dry_run "  - Set up cron jobs with retention of ${SP_BACKUP_RETENTION_DAYS} days"
        return 0
    fi

    # ── Idempotency check ──
    if [[ -d "/var/simpleprod/scripts" ]]; then
        sp_log_success "Backup scripts directory already exists. Skipping."
        return 0
    fi

    # ── STEP 1: Create backup scripts directory ──
    sp_log_info "Creating backup scripts directory..."
    mkdir -p "/var/simpleprod/scripts"

    # ── STEP 2: Create backup script for PostgreSQL ──
    sp_log_info "Creating PostgreSQL backup script..."
    local pg_backup_script="/var/simpleprod/scripts/backup-postgresql.sh"
    cat > "${pg_backup_script}" <<EOF
#!/usr/bin/env bash
# SimpleProd — PostgreSQL Backup Script
set -euo pipefail

# Source common functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../common/safety.sh"
source "${SCRIPT_DIR}/../common/backup.sh"
source "${SCRIPT_DIR}/../common/logging.sh"
source "${SCRIPT_DIR}/../common/secrets.sh"

# Config from environment (defaults from defaults.yaml)
SP_BACKUP_RETENTION_DAYS="${SP_BACKUP_RETENTION_DAYS:-30}"

# Backup PostgreSQL databases
main() {
    sp_log_step "1" "PostgreSQL Backup"

    local clients
    clients="$(sp_secret_list_clients)"

    for client in ${clients}; do
        local db_user db_password db_name
        db_user="$(sp_secret_get "${client}" "DB_USER")"
        db_password="$(sp_secret_get "${client}" "DB_PASSWORD")"
        db_name="$(sp_secret_get "${client}" "DB_NAME")"

        local backup_dir="/var/backups/simpleprod/postgresql/${client}"
        mkdir -p "${backup_dir}"

        local timestamp
        timestamp="$(date +%Y%m%d_%H%M%S)"

        sp_log_info "Backing up database ${db_name} for client ${client}..."
        pg_dump -U "${db_user}" -h localhost "${db_name}" > "${backup_dir}/${db_name}_${timestamp}.sql"

        # Clean up old backups
        find "${backup_dir}" -name "${db_name}_*.sql" -type f -mtime +${SP_BACKUP_RETENTION_DAYS} -delete
    done

    sp_log_success "PostgreSQL backup complete"
}

main "$@"
EOF

    chmod +x "${pg_backup_script}"

    # ── STEP 3: Set up cron job ──
    sp_log_info "Setting up cron job for PostgreSQL backups..."
    (crontab -l 2>/dev/null; echo "0 2 * * * /var/simpleprod/scripts/backup-postgresql.sh") | crontab -

    sp_log_success "Backups setup complete"
}

main "$@"