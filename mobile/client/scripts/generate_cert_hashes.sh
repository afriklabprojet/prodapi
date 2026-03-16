#!/bin/bash
# =============================================================================
# Script de génération des hashes de certificats pour DR-PHARMA
# =============================================================================
# 
# Usage: ./generate_cert_hashes.sh <domain>
# Example: ./generate_cert_hashes.sh api.drlpharma.com
#
# Ce script génère les hashes SHA-256 nécessaires pour le Certificate Pinning

set -e

DOMAIN=${1:-"api.drlpharma.com"}
PORT=${2:-443}

echo "=============================================="
echo "  Certificate Pinning Hash Generator"
echo "  DR-PHARMA Mobile App"
echo "=============================================="
echo ""
echo "Domain: $DOMAIN"
echo "Port: $PORT"
echo ""

# Créer un dossier temporaire
TEMP_DIR=$(mktemp -d)
trap "rm -rf $TEMP_DIR" EXIT

# Récupérer la chaîne de certificats
echo "📥 Fetching certificate chain..."
openssl s_client -servername "$DOMAIN" -connect "$DOMAIN:$PORT" -showcerts < /dev/null 2>/dev/null | \
  awk '/-----BEGIN CERTIFICATE-----/,/-----END CERTIFICATE-----/' > "$TEMP_DIR/fullchain.pem"

# Séparer les certificats
csplit -f "$TEMP_DIR/cert-" -b "%02d.pem" "$TEMP_DIR/fullchain.pem" '/-----BEGIN CERTIFICATE-----/' '{*}' 2>/dev/null || true

echo ""
echo "🔐 Certificate Hashes (SHA-256 Base64):"
echo "========================================"
echo ""

CERT_NUM=0
for cert in "$TEMP_DIR"/cert-*.pem; do
  if [ -s "$cert" ]; then
    # Vérifier que c'est un certificat valide
    if openssl x509 -in "$cert" -noout 2>/dev/null; then
      CERT_NUM=$((CERT_NUM + 1))
      
      # Obtenir les informations du certificat
      SUBJECT=$(openssl x509 -in "$cert" -noout -subject 2>/dev/null | sed 's/subject=//')
      ISSUER=$(openssl x509 -in "$cert" -noout -issuer 2>/dev/null | sed 's/issuer=//')
      EXPIRY=$(openssl x509 -in "$cert" -noout -enddate 2>/dev/null | sed 's/notAfter=//')
      
      # Générer le hash DER en Base64
      HASH=$(openssl x509 -in "$cert" -outform DER 2>/dev/null | openssl dgst -sha256 -binary | openssl base64)
      
      echo "Certificate #$CERT_NUM"
      echo "  Subject: $SUBJECT"
      echo "  Issuer:  $ISSUER"
      echo "  Expires: $EXPIRY"
      echo ""
      echo "  Hash: 'sha256/$HASH',"
      echo ""
      echo "---"
    fi
  fi
done

echo ""
echo "=============================================="
echo "📋 Copy these hashes to:"
echo "   lib/core/security/certificate_pinning.dart"
echo ""
echo "⚠️  IMPORTANT:"
echo "   - Update hashes 30 days BEFORE expiration"
echo "   - Always keep at least 2 hashes (current + backup)"
echo "   - Test thoroughly after updating"
echo "=============================================="
