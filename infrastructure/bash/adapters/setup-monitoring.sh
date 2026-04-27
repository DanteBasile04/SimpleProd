#!/usr/bin/env bash
# SimpleProd — Monitoring Setup (Domain 2)
# Set up basic disk/CPU/memory monitoring
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
# Monitoring Setup
# ============================================================================

main() {
    sp_log_step "2.14" "Monitoring Setup"

    # ── Dry-run mode ──
    if [[ "${SP_DRY_RUN}" == "true" ]]; then
        sp_log_dry_run "Would set up basic monitoring"
        sp_log_dry_run "  - Create monitoring script"
        sp_log_dry_run "  - Set up cron job"
        return 0
    fi

    # ── Idempotency check ──
    if [[ -f "/var/simpleprod/scripts/monitor-system.sh" ]]; then
        sp_log_success "Monitoring script already exists. Skipping."
        return 0
    fi

    # ── STEP 1: Create monitoring script ──
    sp_log_info "Creating monitoring script..."
    local monitor_script="/var/simpleprod/scripts/monitor-system.sh"
    cat > "${monitor_script}" <<EOF
#!/usr/bin/env bash
# SimpleProd — System Monitoring Script
set -euo pipefail

# Source common functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../common/safety.sh"
source "${SCRIPT_DIR}/../common/backup.sh"
source "${SCRIPT_DIR}/../common/logging.sh"
source "${SCRIPT_DIR}/../common/secrets.sh"

# Config from environment (defaults from defaults.yaml)
SP_DRY_RUN="${SP_DRY_RUN:-false}"

# Monitoring thresholds
DISK_THRESHOLD=90
CPU_THRESHOLD=90
MEMORY_THRESHOLD=90

# Check disk usage
check_disk() {
    local disk_usage
    disk_usage="$(df -h / | awk 'NR==2 {print $5}' | tr -d '%')"

    if (( disk_usage >= DISK_THRESHOLD )); then
        sp_log_warning "Disk usage is at ${disk_usage}% (threshold: ${DISK_THRESHOLD}%)"
    else
        sp_log_info "Disk usage is at ${disk_usage}%"
    fi
}

# Check CPU usage
check_cpu() {
    local cpu_usage
    cpu_usage="$(top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{print 100 - $1}')"

    if (( $(echo "${cpu_usage} >= ${CPU_THRESHOLD}" | bc -l) )); then
        sp_log_warning "CPU usage is at ${cpu_usage}% (threshold: ${CPU_THRESHOLD}%)"
    else
        sp_log_info "CPU usage is at ${cpu_usage}%"
    fi
}

# Check memory usage
check_memory() {
    local memory_usage
    memory_usage="$(free | awk '/Mem/{printf("%.2f"), $3/$2*100}')"

    if (( $(echo "${memory_usage} >= ${MEMORY_THRESHOLD}" | bc -l) )); then
        sp_log_warning "Memory usage is at ${memory_usage}% (threshold: ${MEMORY_THRESHOLD}%)"
    else
        sp_log_info "Memory usage is at ${memory_usage}%"
    fi
}

# Main monitoring function
main() {
    sp_log_step "1" "System Monitoring"

    check_disk
    check_cpu
    check_memory

    sp_log_success "System monitoring complete"
}

main "$@"
EOF

    chmod +x "${monitor_script}"

    # ── STEP 2: Set up cron job ──
    sp_log_info "Setting up cron job for monitoring..."
    (crontab -l 2>/dev/null; echo "*/15 * * * * /var/simpleprod/scripts/monitor-system.sh") | crontab -

    sp_log_success "Monitoring setup complete"
}

main "$@"