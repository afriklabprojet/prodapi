#!/bin/bash
# DR-PHARMA FTPS Deployment Script
set -e

API_DIR="/Users/teya2023/Downloads/DR-PHARMA/api"
FTP_HOST="drlpharma.com"
FTP_PORT="21"
FTP_USER="kvyajoqt"
FTP_PASS="+5Hdy7u2iAB-M8"
REMOTE_DIR="/public_html"

echo "=========================================="
echo "  DR-PHARMA - Déploiement FTPS"
echo "=========================================="

cd "$API_DIR"

echo "[1/2] Uploading files via FTPS..."

lftp -c "
set ftp:ssl-allow yes;
set ftp:ssl-force yes;
set ftp:ssl-protect-data yes;
set ssl:verify-certificate no;
set mirror:parallel-transfer-count 5;
set net:max-retries 3;
set net:reconnect-interval-base 5;
open ftp://${FTP_USER}:${FTP_PASS}@${FTP_HOST}:${FTP_PORT};
mirror --reverse --verbose --only-newer \
  --exclude .env \
  --exclude .env.production \
  --exclude .env.example \
  --exclude .env.local \
  --exclude .git/ \
  --exclude .gitignore \
  --exclude .gitattributes \
  --exclude tests/ \
  --exclude node_modules/ \
  --exclude .phpunit.result.cache \
  --exclude .DS_Store \
  --exclude .vscode/ \
  --exclude storage/logs/ \
  --exclude storage/framework/cache/data/ \
  --exclude storage/framework/sessions/ \
  --exclude storage/framework/views/ \
  --exclude storage/app/firebase-credentials.json \
  --exclude package-lock.json \
  --exclude phpunit.xml \
  --exclude openapi.yaml \
  --exclude README.md \
  --parallel=5 \
  ${API_DIR} ${REMOTE_DIR};
bye;
"

echo ""
echo "[2/2] Deployment complete!"
echo ""
echo "  URL:   https://drlpharma.com"
echo "  Admin: https://drlpharma.com/admin"
echo ""
echo "  NOTE: Run migrations manually via cPanel Terminal:"
echo "    cd ~/public_html && php artisan migrate --force"
echo "    cd ~/public_html && php artisan config:cache"
echo "    cd ~/public_html && php artisan route:cache"
echo ""
