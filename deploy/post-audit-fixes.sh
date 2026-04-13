#!/bin/bash
# =============================================================
# DR-PHARMA Post-Audit Fixes — Senior DevOps Go-Live
# Execute: ssh root@204.168.193.244 'bash -s' < post-audit-fixes.sh
# =============================================================
set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log() { echo -e "${GREEN}[FIX]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }

echo "============================================"
echo "DR-PHARMA Post-Audit Remediation"
echo "============================================"

# ─────────────────────────────────────────────
# 1. CRITIQUE: Install fail2ban
# ─────────────────────────────────────────────
log "Installing fail2ban..."
apt-get update -qq
apt-get install -y fail2ban

cat > /etc/fail2ban/jail.local << 'EOF'
[DEFAULT]
bantime  = 3600
findtime = 600
maxretry = 5
backend  = systemd

[sshd]
enabled  = true
port     = ssh
filter   = sshd
maxretry = 3
bantime  = 86400
EOF

systemctl enable fail2ban
systemctl restart fail2ban
log "fail2ban installed and configured (SSH: 3 retries, 24h ban)"

# ─────────────────────────────────────────────
# 2. HIGH: Fix .env permissions
# ─────────────────────────────────────────────
log "Fixing .env permissions..."
chmod 640 /var/www/drpharma/api/.env
chown drpharma:www-data /var/www/drpharma/api/.env
log ".env permissions: 640 (owner+group read)"

# ─────────────────────────────────────────────
# 3. HIGH: Disable server_tokens in Nginx
# ─────────────────────────────────────────────
log "Disabling Nginx server_tokens..."
sed -i 's/# server_tokens off;/server_tokens off;/' /etc/nginx/nginx.conf
sed -i 's/#\s*server_tokens off;/server_tokens off;/' /etc/nginx/nginx.conf
nginx -t && systemctl reload nginx
log "Nginx server_tokens disabled"

# ─────────────────────────────────────────────
# 4. MEDIUM: Stop php8.2-fpm
# ─────────────────────────────────────────────
log "Stopping php8.2-fpm..."
systemctl stop php8.2-fpm 2>/dev/null || true
systemctl disable php8.2-fpm 2>/dev/null || true
log "php8.2-fpm stopped and disabled"

# ─────────────────────────────────────────────
# 5. Backup retention (keep 30 days)
# ─────────────────────────────────────────────
log "Adding backup retention policy..."
cat > /etc/cron.d/drpharma-backup-cleanup << 'EOF'
# Cleanup backups older than 30 days
0 4 * * 0 root find /var/backups/drpharma -name "*.sql.gz" -mtime +30 -delete 2>&1 | logger -t drpharma-backup-cleanup
EOF
log "Backup retention: 30 days (weekly cleanup)"

# ─────────────────────────────────────────────
# 6. PHP OPcache production tuning
# ─────────────────────────────────────────────
log "Tuning OPcache for production..."
cat > /etc/php/8.3/fpm/conf.d/99-drpharma-opcache.ini << 'EOF'
; Production OPcache — no revalidation
opcache.validate_timestamps=0
opcache.revalidate_freq=0
opcache.max_accelerated_files=20000
opcache.memory_consumption=256
opcache.interned_strings_buffer=32
EOF
log "OPcache tuned (validate_timestamps=0 for production)"

# ─────────────────────────────────────────────
# Verification
# ─────────────────────────────────────────────
echo ""
echo "============================================"
echo "Verification"
echo "============================================"
echo ""

echo -n "fail2ban: "
systemctl is-active fail2ban

echo -n ".env perms: "
stat -c "%a %U:%G" /var/www/drpharma/api/.env

echo -n "server_tokens: "
grep 'server_tokens off' /etc/nginx/nginx.conf | head -1 | xargs

echo -n "php8.2-fpm: "
systemctl is-active php8.2-fpm 2>/dev/null || echo "inactive (good)"

echo -n "php8.3-fpm: "
systemctl is-active php8.3-fpm

echo ""
log "All fixes applied. Restart php8.3-fpm to load OPcache changes:"
echo "  systemctl restart php8.3-fpm"
echo ""
warn "IMPORTANT: Server needs a REBOOT for pending kernel updates."
warn "Schedule: systemctl reboot"
echo ""
echo "============================================"
echo "Remediation complete"
echo "============================================"
