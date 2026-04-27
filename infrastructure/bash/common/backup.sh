#!/usr/bin/env bash
# SimpleProd — Common Backup Functions (Domain 0)
# Pre-change backup with timestamped copies and rollback support
set -euo pipefail

# Default backup directory
SP_BACKUPS_DIR="${SP_BACKUPS_DIR:-/var/backups/simpleprod}"
SP_BACKUP_RETENTION_DAYS="${SP_BACKUP_RETENTION_DAYS:-30}"

# ============================================================================
# Backup Functions
# ============================================================================

# Create a timestamped backup of a file before modification
# Usage: sp_backup_file "/etc/ssh/sshd_config"
# Returns: path to the backup file
sp_backup_file() {
    local src="${1}"
    local timestamp dst_dir dst

    # Check source file exists
    if [[ ! -f "${src}" ]]; then
        sp_log_warning "File ${src} does not exist, skipping backup."
        return 0
    fi

    timestamp="$(date +%Y%m%d_%H%M%S)"
    # Build destination path mirroring the original structure
    dst_dir="${SP_BACKUPS_DIR}/$(dirname "${src}")"
    dst="${dst_dir}/$(basename "${src}").${timestamp}.bak"

    # Create backup directory
    mkdir -p "${dst_dir}"

    # Copy the file with permissions preserved
    cp -a "${src}" "${dst}"

    sp_log_success "Backup created: ${dst}"
    echo "${dst}"
}

# Restore a file from a backup
# Usage: sp_restore_file "/var/backups/simpleprod/etc/ssh/sshd_config.20240101_120000.bak"
sp_restore_file() {
    local backup="${1}"
    local original

    if [[ ! -f "${backup}" ]]; then
        sp_log_error "Backup file not found: ${backup}"
        return 1
    fi

    # Derive original path from backup path
    # /var/backups/simpleprod/etc/ssh/sshd_config.20240101_120000.bak
    # becomes /etc/ssh/sshd_config
    original="$(echo "${backup}" | sed "s|${SP_BACKUPS_DIR}/||" | sed 's/\.[0-9_]*\.bak$//')"

    cp -a "${backup}" "${original}"
    sp_log_success "Restored: ${original} from ${backup}"
}

# Restore all backups from the most recent run
# Usage: sp_restore_latest
# Finds the most recent .bak files and restores them
sp_restore_latest() {
    local backup_count=0

    sp_log_info "Looking for backups to restore..."

    while IFS= read -r -d '' backup; do
        sp_restore_file "${backup}" || true
        ((backup_count++))
    done < <(find "${SP_BACKUPS_DIR}" -name "*.bak" -type f -print0 2>/dev/null | sort -zr)

    if (( backup_count == 0 )); then
        sp_log_warning "No backups found to restore."
    else
        sp_log_success "Restored ${backup_count} file(s)."
    fi
}

# Rollback ALL changes made in this run
# Uses a manifest file to track which files were modified
# Usage: sp_rollback
sp_rollback() {
    local manifest="${SP_BACKUPS_DIR}/.manifest"

    if [[ ! -f "${manifest}" ]]; then
        sp_log_error "No manifest found. Cannot rollback."
        return 1
    fi

    sp_log_warning "Rolling back all changes..."

    local backup
    while IFS= read -r backup; do
        if [[ -f "${backup}" ]]; then
            sp_restore_file "${backup}"
        else
            sp_log_warning "Backup missing: ${backup}"
        fi
    done < "${manifest}"

    sp_log_success "Rollback complete."
}

# Add a file to the manifest for rollback tracking
# Usage: sp_manifest_add "/var/backups/simpleprod/etc/ssh/sshd_config.20240101_120000.bak"
sp_manifest_add() {
    local backup_path="${1}"
    local manifest="${SP_BACKUPS_DIR}/.manifest"

    mkdir -p "${SP_BACKUPS_DIR}"
    echo "${backup_path}" >> "${manifest}"
}

# Start a new manifest (call at the beginning of a provisioning run)
sp_manifest_start() {
    local manifest="${SP_BACKUPS_DIR}/.manifest"
    mkdir -p "${SP_BACKUPS_DIR}"
    : > "${manifest}"
    sp_log_info "Started new backup manifest."
}

# Clean up old backups (older than SP_BACKUP_RETENTION_DAYS)
# Usage: sp_backup_cleanup [days]
sp_backup_cleanup() {
    local days="${1:-${SP_BACKUP_RETENTION_DAYS}}"
    local count

    sp_log_info "Cleaning up backups older than ${days} days..."

    count="$(find "${SP_BACKUPS_DIR}" -name "*.bak" -type f -mtime "+${days}" -delete -print 2>/dev/null | wc -l)"

    sp_log_success "Cleaned up ${count} old backup(s)."
}