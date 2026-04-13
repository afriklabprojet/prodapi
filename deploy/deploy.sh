#!/usr/bin/env bash
#############################################################
# DR-PHARMA — deploy.sh
# Script de déploiement à exécuter sur le VPS Hetzner
#
# Usage :
#   ssh root@204.168.193.244 'bash /var/www/drpharma/api/deploy/deploy.sh'
#
# Rollback :
#   ssh root@204.168.193.244 'bash /var/www/drpharma/api/deploy/deploy.sh --rollback'
#############################################################
set -euo pipefail

REPO_DIR="/var/www/drpharma"
APP_DIR="/var/www/drpharma/api"
PHP="php"
COMPOSER="/usr/local/bin/composer"
BRANCH="${DEPLOY_BRANCH:-main}"
ROLLBACK_FILE="$APP_DIR/storage/.last_deploy_sha"

############## Couleurs ##############
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'
log()  { echo -e "${GREEN}[$(date +%H:%M:%S)] ✔ $*${NC}"; }
warn() { echo -e "${YELLOW}[$(date +%H:%M:%S)] ⚠ $*${NC}"; }
fail() { echo -e "${RED}[$(date +%H:%M:%S)] ✗ $*${NC}"; exit 1; }

# --- Rollback mode ---
if [ "${1:-}" = "--rollback" ]; then
    if [ ! -f "$ROLLBACK_FILE" ]; then
        fail "Aucun point de restauration trouvé"
    fi
    PREV_SHA=$(cat "$ROLLBACK_FILE")
    log "=== ROLLBACK vers $PREV_SHA ==="
    cd "$REPO_DIR"
    git checkout "$PREV_SHA"
    cd "$APP_DIR"
    $COMPOSER install --no-dev --no-interaction --prefer-dist --optimize-autoloader --no-scripts
    $PHP artisan migrate --force
    $PHP artisan config:cache && $PHP artisan route:cache && $PHP artisan view:cache && $PHP artisan event:cache
    supervisorctl restart drpharma-workers:* || true
    systemctl reload php8.3-fpm || true
    $PHP artisan up 2>/dev/null || true
    log "=== Rollback terminé vers $PREV_SHA ==="
    exit 0
fi

# --- Pre-deploy checks ---
log "=== Vérifications pré-déploiement ==="
cd "$APP_DIR"

ENV_DEBUG=$(grep "^APP_DEBUG=" .env | cut -d= -f2)
[ "$ENV_DEBUG" = "false" ] || fail "APP_DEBUG n'est pas false!"

ENV_ENV=$(grep "^APP_ENV=" .env | cut -d= -f2)
[ "$ENV_ENV" = "production" ] || fail "APP_ENV n'est pas production!"

# Save current SHA for rollback
CURRENT_SHA=$(cd "$REPO_DIR" && git rev-parse HEAD)
echo "$CURRENT_SHA" > "$ROLLBACK_FILE"
log "Point de restauration: $CURRENT_SHA"

log "=== Déploiement DR-PHARMA (branche: $BRANCH) ==="

# 1. Mode maintenance ON
log "Activation du mode maintenance..."
$PHP artisan down --refresh=15 --retry=10 || warn "Mode maintenance déjà actif"

# 2. Pull Git
log "Mise à jour du code (git pull)..."
cd "$REPO_DIR"
git fetch origin
git checkout "$BRANCH"
git pull origin "$BRANCH"
NEW_SHA=$(git rev-parse --short HEAD)
log "Code mis à jour: $NEW_SHA"

# 3. Dépendances Composer (prod, sans dev)
cd "$APP_DIR"
log "Installation des dépendances Composer..."
$COMPOSER install \
    --no-dev \
    --no-interaction \
    --prefer-dist \
    --optimize-autoloader \
    --no-scripts

# 4. Migrations
log "Exécution des migrations..."
$PHP artisan migrate --force

# 5. Caches de production
log "Reconstruction des caches..."
$PHP artisan config:cache
$PHP artisan route:cache
$PHP artisan view:cache
$PHP artisan event:cache
$PHP artisan icons:cache 2>/dev/null || true

# 6. Storage link
log "Vérification du lien storage..."
$PHP artisan storage:link --force 2>/dev/null || true

# 7. Permissions
log "Correction des permissions..."
chown -R drpharma:www-data storage bootstrap/cache
chmod -R 775             storage bootstrap/cache
find storage -type f -exec chmod 664 {} \;

# 8. Redémarrage des queues (supervisor)
log "Redémarrage des queue workers..."
supervisorctl restart drpharma-workers:* || warn "Supervisor non disponible"

# 9. Rechargement PHP-FPM (vide l'OPcache)
log "Rechargement PHP-FPM..."
systemctl reload php8.3-fpm || systemctl reload php8.2-fpm || warn "Impossible de recharger PHP-FPM"

# 10. Mode maintenance OFF
log "Désactivation du mode maintenance..."
$PHP artisan up

# 11. Smoke test
log "Smoke test..."
HTTP_CODE=$(curl -s -o /dev/null -w '%{http_code}' https://drlpharma.pro/api/health 2>/dev/null || echo "000")
if [ "$HTTP_CODE" = "200" ]; then
    log "Health check OK (HTTP $HTTP_CODE)"
else
    warn "Health check retourna HTTP $HTTP_CODE — vérifier manuellement"
fi

log "=== Déploiement terminé ($NEW_SHA) ==="
echo ""
echo "  → https://drlpharma.pro"
echo "  → https://drlpharma.pro/api/health"
echo "  → Rollback: bash $APP_DIR/deploy/deploy.sh --rollback"
