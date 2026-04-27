#!/usr/bin/env bash
# SimpleProd — Nginx SSL Setup (Domain 2)
# Install Nginx + certbot, configure reverse proxy, provision Let's Encrypt SSL
set -euo pipefail

# Source common functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../common/safety.sh"
source "${SCRIPT_DIR}/../common/backup.sh"
source "${SCRIPT_DIR}/../common/logging.sh"
source "${SCRIPT_DIR}/../common/secrets.sh"

# Config from environment (defaults from defaults.yaml)
SP_DRY_RUN="${SP_DRY_RUN:-false}"
SP_DOMAIN="${SP_DOMAIN:-example.com}"

# ============================================================================
# Nginx SSL Setup
# ============================================================================

main() {
    sp_log_step "2.6" "Nginx SSL Setup"

    # ── Dry-run mode ──
    if [[ "${SP_DRY_RUN}" == "true" ]]; then
        sp_log_dry_run "Would install Nginx and configure SSL for domain: ${SP_DOMAIN}"
        sp_log_dry_run "  - Install Nginx"
        sp_log_dry_run "  - Install certbot"
        sp_log_dry_run "  - Configure reverse proxy"
        sp_log_dry_run "  - Provision Let's Encrypt SSL"
        return 0
    fi

    # ── Idempotency check ──
    if sp_detect_existing "nginx"; then
        sp_log_success "Nginx is already installed. Configuring existing installation."
    fi

    # ── STEP 1: Backup existing config ──
    sp_log_info "Backing up existing Nginx config..."
    local backup_path
    backup_path="$(sp_backup_file "/etc/nginx/nginx.conf")"
    sp_manifest_add "${backup_path}"

    # ── STEP 2: Install Nginx ──
    sp_log_info "Installing Nginx..."
    apt-get update
    apt-get install -y nginx

    # ── STEP 3: Install certbot ──
    sp_log_info "Installing certbot..."
    apt-get install -y certbot python3-certbot-nginx

    # ── STEP 4: Configure reverse proxy ──
    sp_log_info "Configuring reverse proxy for ${SP_DOMAIN}..."
    local nginx_config="/etc/nginx/sites-available/${SP_DOMAIN}"
    cat > "${nginx_config}" <<EOF
server {
    listen 80;
    server_name ${SP_DOMAIN};
    
    location / {
        proxy_pass http://localhost:3000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
EOF

    # Enable the site
    ln -s "${nginx_config}" "/etc/nginx/sites-enabled/"

    # ── STEP 5: Provision Let's Encrypt SSL ──
    sp_log_info "Provisioning Let's Encrypt SSL certificate for ${SP_DOMAIN}..."
    certbot --nginx -d "${SP_DOMAIN}" --non-interactive --agree-tos --email "admin@${SP_DOMAIN}"

    # ── STEP 6: Restart Nginx ──
    sp_log_info "Restarting Nginx..."
    systemctl restart nginx

    sp_log_success "Nginx SSL setup complete for ${SP_DOMAIN}"
}

main "$@"