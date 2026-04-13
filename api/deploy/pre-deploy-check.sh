#!/usr/bin/env bash
# ============================================================
# DR-PHARMA — Pre-deploy validation
# Vérifie que l'environnement est sain avant de déployer
# Usage: bash pre-deploy-check.sh
# ============================================================
set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

ERRORS=0
WARNINGS=0
APP_DIR="/var/www/drpharma/api"

check_pass() { echo -e "${GREEN}✓${NC} $1"; }
check_fail() { echo -e "${RED}✗${NC} $1"; ERRORS=$((ERRORS+1)); }
check_warn() { echo -e "${YELLOW}⚠${NC} $1"; WARNINGS=$((WARNINGS+1)); }

echo "============================================"
echo " DR-PHARMA Pre-Deploy Validation"
echo " $(date '+%Y-%m-%d %H:%M:%S')"
echo "============================================"
echo ""

# --- ENV ---
echo "── Environment ──"
if [ -f "$APP_DIR/.env" ]; then
    check_pass ".env file exists"
else
    check_fail ".env file MISSING"
    exit 1
fi

ENV_DEBUG=$(grep "^APP_DEBUG=" "$APP_DIR/.env" | cut -d= -f2)
if [ "$ENV_DEBUG" = "false" ]; then
    check_pass "APP_DEBUG=false"
else
    check_fail "APP_DEBUG is NOT false (value: $ENV_DEBUG)"
fi

ENV_ENV=$(grep "^APP_ENV=" "$APP_DIR/.env" | cut -d= -f2)
if [ "$ENV_ENV" = "production" ]; then
    check_pass "APP_ENV=production"
else
    check_fail "APP_ENV is NOT production (value: $ENV_ENV)"
fi

APP_KEY=$(grep "^APP_KEY=" "$APP_DIR/.env" | cut -d= -f2)
if [ -n "$APP_KEY" ] && [ "$APP_KEY" != "base64:" ]; then
    check_pass "APP_KEY is set"
else
    check_fail "APP_KEY is EMPTY"
fi

# --- Services ---
echo ""
echo "── Services ──"

if systemctl is-active --quiet nginx; then
    check_pass "Nginx running"
else
    check_fail "Nginx NOT running"
fi

if systemctl is-active --quiet mysql; then
    check_pass "MySQL running"
else
    check_fail "MySQL NOT running"
fi

if redis-cli ping &>/dev/null; then
    check_pass "Redis running"
else
    check_fail "Redis NOT running"
fi

if systemctl is-active --quiet php*-fpm; then
    check_pass "PHP-FPM running"
else
    check_fail "PHP-FPM NOT running"
fi

# --- Supervisor Workers ---
echo ""
echo "── Queue Workers ──"

WORKERS=$(supervisorctl status 2>/dev/null | grep "drpharma" || true)
if echo "$WORKERS" | grep -q "RUNNING"; then
    RUNNING_COUNT=$(echo "$WORKERS" | grep -c "RUNNING")
    check_pass "$RUNNING_COUNT queue workers running"
else
    check_fail "No queue workers running"
fi

if echo "$WORKERS" | grep -q "FATAL"; then
    FATAL_COUNT=$(echo "$WORKERS" | grep -c "FATAL")
    check_fail "$FATAL_COUNT workers in FATAL state"
fi

# --- Scheduler ---
echo ""
echo "── Scheduler ──"

if systemctl is-active --quiet drpharma-scheduler.timer; then
    check_pass "Scheduler timer active"
else
    check_fail "Scheduler timer NOT active"
fi

# --- SSL ---
echo ""
echo "── SSL Certificate ──"

EXPIRY=$(certbot certificates 2>/dev/null | grep "Expiry" | head -1 | awk '{print $3}')
if [ -n "$EXPIRY" ]; then
    DAYS_LEFT=$(( ($(date -d "$EXPIRY" +%s) - $(date +%s)) / 86400 ))
    if [ "$DAYS_LEFT" -gt 30 ]; then
        check_pass "SSL valid ($DAYS_LEFT days left)"
    elif [ "$DAYS_LEFT" -gt 7 ]; then
        check_warn "SSL expiring soon ($DAYS_LEFT days left)"
    else
        check_fail "SSL expiring in $DAYS_LEFT days!"
    fi
else
    check_warn "Could not check SSL expiry"
fi

# --- Disk Space ---
echo ""
echo "── Disk Space ──"

DISK_USAGE=$(df / | tail -1 | awk '{print $5}' | sed 's/%//')
if [ "$DISK_USAGE" -lt 80 ]; then
    check_pass "Disk usage: ${DISK_USAGE}%"
elif [ "$DISK_USAGE" -lt 90 ]; then
    check_warn "Disk usage high: ${DISK_USAGE}%"
else
    check_fail "Disk critically full: ${DISK_USAGE}%"
fi

# --- Backups ---
echo ""
echo "── Backups ──"

LATEST_BACKUP=$(ls -t /var/backups/drpharma/*.sql.gz 2>/dev/null | head -1)
if [ -n "$LATEST_BACKUP" ]; then
    BACKUP_AGE=$(( ($(date +%s) - $(stat -c %Y "$LATEST_BACKUP")) / 3600 ))
    if [ "$BACKUP_AGE" -lt 48 ]; then
        check_pass "Latest backup: ${BACKUP_AGE}h ago"
    else
        check_warn "Latest backup is ${BACKUP_AGE}h old (>48h)"
    fi
else
    check_fail "No backups found in /var/backups/drpharma/"
fi

# --- Permissions ---
echo ""
echo "── Permissions ──"

if [ -w "$APP_DIR/storage" ] || sudo -u drpharma test -w "$APP_DIR/storage"; then
    check_pass "storage/ writable"
else
    check_warn "storage/ may not be writable by drpharma"
fi

# --- Summary ---
echo ""
echo "============================================"
if [ "$ERRORS" -eq 0 ]; then
    echo -e "${GREEN}PASS${NC} — $WARNINGS warning(s), ready to deploy"
    exit 0
else
    echo -e "${RED}FAIL${NC} — $ERRORS error(s), $WARNINGS warning(s)"
    echo "Fix errors before deploying!"
    exit 1
fi
