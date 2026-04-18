#!/usr/bin/env bash
#############################################################
# DR-PHARMA — deploy.sh
# Script de déploiement à exécuter sur le VPS Hetzner
#
# Usage depuis votre machine locale :
#   ssh drpharma@<VPS_IP> 'bash /var/www/drpharma/deploy/deploy.sh'
#
# Ou depuis le VPS directement :
#   cd /var/www/drpharma && bash deploy/deploy.sh
#############################################################
set -euo pipefail

APP_DIR="/var/www/drpharma"
PHP="php8.3"
COMPOSER="/usr/local/bin/composer"
BRANCH="${DEPLOY_BRANCH:-main}"

############## Couleurs ##############
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'
log()  { echo -e "${GREEN}[$(date +%H:%M:%S)] ✔ $*${NC}"; }
warn() { echo -e "${YELLOW}[$(date +%H:%M:%S)] ⚠ $*${NC}"; }
fail() { echo -e "${RED}[$(date +%H:%M:%S)] ✗ $*${NC}"; exit 1; }

cd "$APP_DIR" || fail "Répertoire $APP_DIR introuvable"

log "=== Déploiement DR-PHARMA (branche: $BRANCH) ==="

# 1. Mode maintenance ON
log "Activation du mode maintenance..."
$PHP artisan down --refresh=15 --retry=10 || warn "Mode maintenance déjà actif"

# 2. Pull Git
log "Mise à jour du code (git pull)..."
git fetch origin
git checkout "$BRANCH"
git pull origin "$BRANCH"

# 3. Dépendances Composer (prod, sans dev)
log "Installation des dépendances Composer..."
$COMPOSER install \
    --no-dev \
    --no-interaction \
    --prefer-dist \
    --optimize-autoloader \
    --no-scripts

# 3.1 Régénérer le cache des packages (nécessaire après --no-scripts)
log "Régénération du cache des packages..."
rm -f bootstrap/cache/packages.php bootstrap/cache/services.php
$PHP artisan package:discover --ansi 2>/dev/null || warn "package:discover partiel (normal en --no-dev)"

# 4. Migrations
log "Exécution des migrations..."
$PHP artisan migrate --force

# 5. Caches de production
log "Reconstruction des caches..."
$PHP artisan config:cache
$PHP artisan route:cache
$PHP artisan view:cache
$PHP artisan event:cache
$PHP artisan icons:cache 2>/dev/null || true   # Filament icons

# 6. Storage link
log "Vérification du lien storage..."
$PHP artisan storage:link --force 2>/dev/null || true

# 6.1 Nettoyage des fichiers de développement
log "Suppression des fichiers de développement..."
rm -rf tests phpunit.xml .phpunit.cache 2>/dev/null || true
rm -rf .github .editorconfig .gitattributes 2>/dev/null || true

# 7. Permissions
log "Correction des permissions..."
chown -R drpharma:www-data storage bootstrap/cache
chmod -R 775             storage bootstrap/cache
find storage -type f -exec chmod 664 {} \;

# 8. Redémarrage des queues (supervisor)
log "Redémarrage des queue workers..."
supervisorctl restart drpharma-workers:* || warn "Supervisor non disponible — relancer manuellement"

# 9. Rechargement PHP-FPM (vide l'OPcache)
log "Rechargement PHP-FPM..."
systemctl reload php8.2-fpm || warn "Impossible de recharger PHP-FPM"

# 10. Mode maintenance OFF
log "Désactivation du mode maintenance..."
$PHP artisan up

log "=== Déploiement terminé ! ==="
echo ""
echo "  → https://drlpharma.pro"
echo "  → https://drlpharma.pro/api/health"
