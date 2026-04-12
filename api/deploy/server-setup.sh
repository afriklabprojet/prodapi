#!/usr/bin/env bash
#############################################################
# DR-PHARMA — server-setup.sh
# À exécuter UNE SEULE FOIS sur un VPS Hetzner vierge
# (Ubuntu 22.04 LTS recommandé)
#
# Usage (en root) :
#   bash server-setup.sh
#############################################################
set -euo pipefail

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'
log()  { echo -e "${GREEN}[$(date +%H:%M:%S)] ✔ $*${NC}"; }
warn() { echo -e "${YELLOW}[$(date +%H:%M:%S)] ⚠ $*${NC}"; }

[[ $EUID -ne 0 ]] && { echo "Lancer en root : sudo bash $0"; exit 1; }

#############################################################
# Variables — adapter selon le VPS
#############################################################
VPS_USER="drpharma"
APP_DIR="/var/www/drpharma"
REPO_URL="https://github.com/afriklabprojet/prodapi.git"
DOMAIN="drlpharma.pro"
MYSQL_ROOT_PASS=""          # ← définir ou laisser vide (sera demandé)
MYSQL_DB="dr_pharma"
MYSQL_USER="drpharma"
MYSQL_PASS=""               # ← définir ou laisser vide (sera demandé)
PHP_VER="8.2"
#############################################################

log "=== Configuration du VPS Hetzner pour DR-PHARMA ==="

# 1. Mise à jour système
log "Mise à jour du système..."
apt update -qq && apt upgrade -y -qq

# 2. Paquets de base
log "Installation des paquets de base..."
apt install -y -qq \
    git curl wget unzip zip \
    nginx certbot python3-certbot-nginx \
    supervisor \
    mysql-server \
    software-properties-common ca-certificates apt-transport-https

# 3. PHP 8.2 + extensions Laravel
log "Installation de PHP $PHP_VER..."
add-apt-repository -y ppa:ondrej/php
apt update -qq
apt install -y -qq \
    php${PHP_VER}-fpm php${PHP_VER}-cli \
    php${PHP_VER}-mysql php${PHP_VER}-mbstring \
    php${PHP_VER}-xml php${PHP_VER}-curl php${PHP_VER}-zip \
    php${PHP_VER}-bcmath php${PHP_VER}-intl php${PHP_VER}-gd \
    php${PHP_VER}-pcov php${PHP_VER}-redis \
    php${PHP_VER}-opcache php${PHP_VER}-tokenizer \
    php${PHP_VER}-fileinfo php${PHP_VER}-pdo

# 4. Composer
if ! command -v composer &>/dev/null; then
    log "Installation de Composer..."
    curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer
fi

# 5. Utilisateur applicatif
if ! id "$VPS_USER" &>/dev/null; then
    log "Création de l'utilisateur $VPS_USER..."
    useradd -m -s /bin/bash -G www-data "$VPS_USER"
fi

# 6. Répertoire application
log "Création du répertoire $APP_DIR..."
mkdir -p "$APP_DIR"
chown "$VPS_USER":"$VPS_USER" "$APP_DIR"

# 7. Clonage du repo
log "Clonage du repo Git..."
sudo -u "$VPS_USER" git clone "$REPO_URL" "$APP_DIR" || warn "Repo déjà cloné — skip"

# 8. MySQL — création DB + user
log "Configuration MySQL..."
if [[ -z "$MYSQL_ROOT_PASS" ]]; then
    read -rsp "Mot de passe root MySQL : " MYSQL_ROOT_PASS; echo
fi
if [[ -z "$MYSQL_PASS" ]]; then
    read -rsp "Mot de passe pour l'utilisateur $MYSQL_USER MySQL : " MYSQL_PASS; echo
fi
mysql -u root -p"$MYSQL_ROOT_PASS" <<SQL
CREATE DATABASE IF NOT EXISTS \`${MYSQL_DB}\` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'localhost' IDENTIFIED BY '${MYSQL_PASS}';
GRANT ALL PRIVILEGES ON \`${MYSQL_DB}\`.* TO '${MYSQL_USER}'@'localhost';
FLUSH PRIVILEGES;
SQL
log "Base de données '$MYSQL_DB' et utilisateur '$MYSQL_USER' créés."

# 9. Copier le .env de production
log "Configuration du .env..."
if [[ ! -f "$APP_DIR/.env" ]]; then
    cp "$APP_DIR/.env.example" "$APP_DIR/.env" 2>/dev/null || warn ".env.example absent — copier .env manuellement"
fi
warn "⚠  Éditez $APP_DIR/.env et renseignez DB_PASSWORD=$MYSQL_PASS et les autres secrets"

# 10. Composer install (prod)
log "Installation des dépendances Composer (prod)..."
cd "$APP_DIR"
sudo -u "$VPS_USER" composer install --no-dev --optimize-autoloader --no-interaction

# 11. Clé Laravel
sudo -u "$VPS_USER" php${PHP_VER} artisan key:generate --force

# 12. Migrations
log "Migrations initiales..."
sudo -u "$VPS_USER" php${PHP_VER} artisan migrate --force

# 13. Caches
log "Caches de production..."
sudo -u "$VPS_USER" php${PHP_VER} artisan config:cache
sudo -u "$VPS_USER" php${PHP_VER} artisan route:cache
sudo -u "$VPS_USER" php${PHP_VER} artisan view:cache
sudo -u "$VPS_USER" php${PHP_VER} artisan storage:link --force

# 14. Permissions
log "Permissions..."
chown -R "$VPS_USER":www-data "$APP_DIR/storage" "$APP_DIR/bootstrap/cache"
chmod -R 775 "$APP_DIR/storage" "$APP_DIR/bootstrap/cache"

# 15. PHP-FPM
log "Configuration PHP-FPM..."
cp "$APP_DIR/deploy/php-fpm.conf" "/etc/php/${PHP_VER}/fpm/pool.d/drpharma.conf"
# Désactiver le pool www par défaut
sed -i 's/^\[www\]/[www_disabled]/' "/etc/php/${PHP_VER}/fpm/pool.d/www.conf" || true
mkdir -p /var/log/php
systemctl reload php${PHP_VER}-fpm

# 16. Nginx
log "Configuration Nginx..."
cp "$APP_DIR/deploy/nginx.conf" "/etc/nginx/sites-available/drpharma"
ln -sf "/etc/nginx/sites-available/drpharma" "/etc/nginx/sites-enabled/drpharma"
rm -f /etc/nginx/sites-enabled/default
nginx -t && systemctl reload nginx

# 17. SSL (Let's Encrypt)
log "Certificat SSL Let's Encrypt..."
certbot --nginx -d "$DOMAIN" -d "www.$DOMAIN" --non-interactive --agree-tos -m "admin@${DOMAIN}" || \
    warn "Certbot échoué — vérifier que le DNS pointe vers ce serveur"

# 18. Supervisor (queues)
log "Configuration Supervisor..."
cp "$APP_DIR/deploy/supervisor.conf" "/etc/supervisor/conf.d/drpharma.conf"
supervisorctl reread
supervisorctl update
supervisorctl start drpharma-workers:*

# 19. Scheduler systemd
log "Configuration du scheduler Laravel (systemd timer)..."
cp "$APP_DIR/deploy/drpharma-scheduler.service" "/etc/systemd/system/"
cp "$APP_DIR/deploy/drpharma-scheduler.timer"   "/etc/systemd/system/"
systemctl daemon-reload
systemctl enable --now drpharma-scheduler.timer

# 20. Firewall UFW
log "Configuration du firewall UFW..."
ufw --force enable
ufw allow OpenSSH
ufw allow 'Nginx Full'
ufw status

log ""
log "=== Installation terminée ! ==="
echo ""
echo "  Site   : https://$DOMAIN"
echo "  API    : https://$DOMAIN/api/health"
echo ""
warn "Pensez à :"
warn "  1. Éditer $APP_DIR/.env (DB_PASSWORD, secrets JEKO, Firebase, etc.)"
warn "  2. Copier storage/app/firebase-credentials.json sur le serveur"
warn "  3. Vérifier : supervisorctl status drpharma-workers:*"
warn "  4. Vérifier : systemctl status drpharma-scheduler.timer"
