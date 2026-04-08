#!/bin/bash
# Script de déploiement API DR-PHARMA
# Usage: ./scripts/deploy_api.sh

set -e

SERVER="root@204.168.193.244"
REMOTE_PATH="/var/www/dr-pharma/api"

echo "🚀 Déploiement API DR-PHARMA..."
echo ""

# Connexion et exécution des commandes
ssh -o StrictHostKeyChecking=no $SERVER << 'EOF'
cd /var/www/dr-pharma/api || cd /home/dr-pharma/api || { echo "❌ Dossier API introuvable"; exit 1; }

echo "📥 Récupération des modifications..."
git pull origin main

echo "🔧 Installation des dépendances..."
composer install --no-dev --optimize-autoloader

echo "🧹 Nettoyage du cache..."
php artisan config:clear
php artisan cache:clear
php artisan route:clear
php artisan view:clear

echo "🔄 Optimisation..."
php artisan config:cache
php artisan route:cache

echo "📋 Correction des livreurs KYC..."
php artisan courier:fix-kyc-status || echo "⚠️ Commande KYC ignorée (peut-être aucun livreur à corriger)"

echo "✅ Vérification des routes..."
php artisan route:list --path=courier/gamification

echo ""
echo "✅ Déploiement terminé avec succès!"
EOF

echo ""
echo "🎉 Déploiement complété!"
