#!/bin/bash
# ============================================
# DR-PHARMA - Script de déploiement cPanel
# ============================================
# Upload direct dans public_html/
#
# STRUCTURE sur le serveur:
#   /home/username/public_html/
#   ├── .htaccess              ← Redirige vers public/
#   ├── app/
#   ├── bootstrap/
#   ├── config/
#   ├── database/
#   ├── lang/
#   ├── public/
#   │   ├── .htaccess          ← Rewriting Laravel
#   │   └── index.php
#   ├── resources/
#   ├── routes/
#   ├── storage/
#   ├── vendor/
#   ├── .env
#   ├── artisan
#   └── composer.json
#
# PRÉREQUIS:
# - PHP 8.2+ avec extensions: pdo_mysql, mbstring, openssl, tokenizer, xml, ctype, json, bcmath, gd
# - MySQL/MariaDB
# - Accès SSH

set -e

echo "=========================================="
echo "  DR-PHARMA - Déploiement Production"
echo "=========================================="

# ------------------------------------------------
# CONFIGURATION
# ------------------------------------------------
CPANEL_USER="kvyajoqt"
REMOTE_HOST="drlpharma.com"
DEPLOY_PATH="/home/${CPANEL_USER}/public_html"

# ------------------------------------------------
# ÉTAPE 1: Build local
# ------------------------------------------------
echo ""
echo "[1/6] Préparation du build local..."

cd "$(dirname "$0")/../api"

composer install --no-dev --optimize-autoloader --no-interaction

echo "✓ Dépendances installées"

# ------------------------------------------------
# ÉTAPE 2: Nettoyage des caches locaux
# ------------------------------------------------
echo ""
echo "[2/6] Nettoyage des caches locaux..."

# Ne PAS générer le cache localement (les chemins locaux macOS seraient embarqués)
# Le cache sera généré sur le serveur distant (étape 5)
php artisan config:clear
php artisan route:clear
php artisan view:clear
php artisan event:clear

echo "✓ Caches locaux nettoyés (sera regénéré sur le serveur)"

# ------------------------------------------------
# ÉTAPE 3: Créer l'archive
# ------------------------------------------------
echo ""
echo "[3/6] Création de l'archive..."

DEPLOY_DIR=$(mktemp -d)
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
ARCHIVE_NAME="drpharma_${TIMESTAMP}.tar.gz"

# Vérifier que le fichier credentials Firebase existe avant déploiement
if [ ! -f "storage/app/firebase-credentials.json" ]; then
    echo "⚠️  ATTENTION: storage/app/firebase-credentials.json introuvable!"
    echo "   Le Google Vision API (KYC selfie) ne fonctionnera pas sans ce fichier."
    echo "   Placez le fichier et relancez le déploiement, ou continuez sans (Vision désactivé)."
    read -p "   Continuer quand même ? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

tar czf "${DEPLOY_DIR}/${ARCHIVE_NAME}" \
    --exclude='.env' \
    --exclude='.env.local' \
    --exclude='.env.production' \
    --exclude='node_modules' \
    --exclude='.git' \
    --exclude='tests' \
    --exclude='storage/logs/*.log' \
    --exclude='storage/framework/cache/data/*' \
    --exclude='storage/framework/sessions/*' \
    --exclude='storage/framework/views/*' \
    --exclude='bootstrap/cache/config.php' \
    --exclude='bootstrap/cache/routes-v7.php' \
    --exclude='bootstrap/cache/events.php' \
    --exclude='database/database.sqlite' \
    --exclude='*.zip' \
    --exclude='phpunit.xml' \
    --exclude='vite.config.js' \
    --exclude='package.json' \
    .

echo "✓ Archive créée: ${ARCHIVE_NAME}"

# ------------------------------------------------
# ÉTAPE 4: Envoyer sur le serveur
# ------------------------------------------------
echo ""
echo "[4/6] Envoi sur le serveur..."

scp "${DEPLOY_DIR}/${ARCHIVE_NAME}" "${CPANEL_USER}@${REMOTE_HOST}:~/${ARCHIVE_NAME}"

echo "✓ Archive envoyée"

# ------------------------------------------------
# ÉTAPE 5: Déployer
# ------------------------------------------------
echo ""
echo "[5/6] Déploiement sur le serveur..."

# Créer un script de déploiement distant
REMOTE_SCRIPT_FILE="${DEPLOY_DIR}/deploy_remote.sh"
cat > "${REMOTE_SCRIPT_FILE}" << 'REMOTE_SCRIPT'
#!/bin/bash
set -e

DEPLOY_PATH="__DEPLOY_PATH__"
ARCHIVE="$HOME/__ARCHIVE_NAME__"

# Backup du .env
if [ -f "${DEPLOY_PATH}/.env" ]; then
    cp "${DEPLOY_PATH}/.env" "$HOME/.env.backup"
    echo "  → .env sauvegardé"
fi

# Extraire
echo "  → Extraction dans ${DEPLOY_PATH}..."
cd "${DEPLOY_PATH}"
tar xzf "${ARCHIVE}" --overwrite 2>/dev/null || tar xzf "${ARCHIVE}"

# Restaurer le .env
if [ -f "$HOME/.env.backup" ]; then
    cp "$HOME/.env.backup" "${DEPLOY_PATH}/.env"
    echo "  → .env restauré"
fi

# Configurer les variables Google Vision (KYC) dans le .env
# IMPORTANT: Forcer la valeur à true même si la clé existe déjà avec false
if grep -q "^GOOGLE_VISION_ENABLED=" "${DEPLOY_PATH}/.env" 2>/dev/null; then
    # La clé existe - forcer la valeur à true
    sed -i "s/^GOOGLE_VISION_ENABLED=.*/GOOGLE_VISION_ENABLED=true/" "${DEPLOY_PATH}/.env"
    echo "  → GOOGLE_VISION_ENABLED forcé à true"
else
    # La clé n'existe pas - l'ajouter
    echo "" >> "${DEPLOY_PATH}/.env"
    echo "# Google Vision API (KYC selfie verification)" >> "${DEPLOY_PATH}/.env"
    echo "GOOGLE_VISION_ENABLED=true" >> "${DEPLOY_PATH}/.env"
    echo "  → GOOGLE_VISION_ENABLED ajouté au .env"
fi

if grep -q "^GOOGLE_APPLICATION_CREDENTIALS=" "${DEPLOY_PATH}/.env" 2>/dev/null; then
    # Forcer le bon chemin
    sed -i "s|^GOOGLE_APPLICATION_CREDENTIALS=.*|GOOGLE_APPLICATION_CREDENTIALS=storage/app/firebase-credentials.json|" "${DEPLOY_PATH}/.env"
else
    echo "GOOGLE_APPLICATION_CREDENTIALS=storage/app/firebase-credentials.json" >> "${DEPLOY_PATH}/.env"
fi
echo "  → GOOGLE_APPLICATION_CREDENTIALS configuré"

# Vérifier que le fichier credentials existe sur le serveur
if [ ! -f "${DEPLOY_PATH}/storage/app/firebase-credentials.json" ]; then
    echo "  ⚠ ATTENTION: firebase-credentials.json absent du serveur!"
    echo "    Le KYC/liveness ne fonctionnera pas."
fi

# Permissions
echo "  → Permissions..."
mkdir -p storage/logs
mkdir -p storage/framework/{cache/data,sessions,views}
chmod -R 775 storage bootstrap/cache

# Nettoyer les anciens caches (IMPORTANT: éviter les chemins locaux résiduels)
echo "  → Nettoyage des anciens caches..."
php artisan config:clear 2>/dev/null || rm -f bootstrap/cache/config.php
php artisan route:clear 2>/dev/null || rm -f bootstrap/cache/routes-v7.php
php artisan view:clear 2>/dev/null || true
php artisan event:clear 2>/dev/null || rm -f bootstrap/cache/events.php

# Migrations
echo "  → Migrations..."
php artisan migrate --force

# Cache (généré sur le serveur avec les bons chemins)
echo "  → Regénération du cache..."
php artisan config:cache
php artisan route:cache
php artisan view:cache
php artisan event:cache
php artisan icons:cache 2>/dev/null || true

# Storage link
php artisan storage:link 2>/dev/null || true

# Queue restart
php artisan queue:restart 2>/dev/null || true

# Redémarrer le queue worker persistant
echo "  → Redémarrage du queue worker..."
pkill -f 'queue_worker.sh' 2>/dev/null || true
pkill -f 'queue:work' 2>/dev/null || true
sleep 1
if [ -f "$HOME/queue_worker.sh" ]; then
    nohup "$HOME/queue_worker.sh" > /dev/null 2>&1 &
    echo "  → Queue worker relancé (PID: $!)"
else
    echo "  ⚠ queue_worker.sh introuvable - queue worker non redémarré"
fi

# Vérifier que le cron est installé
if ! crontab -l 2>/dev/null | grep -q 'schedule:run'; then
    echo "  ⚠ Cron Laravel scheduler non installé - exécutez setup_cron_queue.sh"
fi

# Nettoyage
rm -f "${ARCHIVE}"
rm -f "$HOME/deploy_remote.sh"

echo "  ✓ Déploiement terminé"
REMOTE_SCRIPT

# Remplacer les placeholders
sed -i '' "s|__DEPLOY_PATH__|${DEPLOY_PATH}|g" "${REMOTE_SCRIPT_FILE}"
sed -i '' "s|__ARCHIVE_NAME__|${ARCHIVE_NAME}|g" "${REMOTE_SCRIPT_FILE}"

# Envoyer le script de déploiement
scp "${REMOTE_SCRIPT_FILE}" "${CPANEL_USER}@${REMOTE_HOST}:~/deploy_remote.sh"

# Exécuter le script à distance
ssh -t "${CPANEL_USER}@${REMOTE_HOST}" "bash ~/deploy_remote.sh"

echo "✓ Serveur mis à jour"

# ------------------------------------------------
# ÉTAPE 6: Nettoyage local
# ------------------------------------------------
echo ""
echo "[6/6] Nettoyage..."

rm -rf "${DEPLOY_DIR}"

echo "✓ Nettoyage terminé"

echo ""
echo "=========================================="
echo "  ✅ DÉPLOIEMENT TERMINÉ"
echo "=========================================="
echo ""
echo "  URL:   https://drlpharma.com"
echo "  Admin: https://drlpharma.com/admin"
echo ""
echo "  VÉRIFICATIONS:"
echo "  1. https://drlpharma.com"
echo "  2. https://drlpharma.com/api/webhooks/jeko/health"
echo "  3. Tester connexion depuis l'app mobile"
echo ""
