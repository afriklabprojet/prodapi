#!/bin/bash
# =============================================================================
# fetch_cert_hashes.sh — Génère les SHA-256 hashes pour le Certificate Pinning
# =============================================================================
#
# Usage:
#   ./scripts/fetch_cert_hashes.sh [domain]
#
# Exemple:
#   ./scripts/fetch_cert_hashes.sh api.drlpharma.com
#
# Les hashes générés doivent être copiés dans:
#   mobile/client/lib/core/security/certificate_pinning.dart
#
# =============================================================================

set -euo pipefail

DOMAIN="${1:-api.drlpharma.com}"
PORT="${2:-443}"

echo "============================================"
echo "Certificate Pinning Hash Generator"
echo "============================================"
echo ""
echo "Domain: ${DOMAIN}:${PORT}"
echo ""

# Vérifier que openssl est disponible
if ! command -v openssl &> /dev/null; then
    echo "❌ openssl est requis. Installez-le avec: brew install openssl"
    exit 1
fi

echo "📡 Connexion au serveur..."
echo ""

# Récupérer la chaîne de certificats
CERTS=$(openssl s_client -servername "$DOMAIN" -connect "${DOMAIN}:${PORT}" -showcerts </dev/null 2>/dev/null)

if [ -z "$CERTS" ]; then
    echo "❌ Impossible de se connecter à ${DOMAIN}:${PORT}"
    exit 1
fi

echo "🔐 Certificats trouvés:"
echo ""

# Extraire et hasher chaque certificat de la chaîne
INDEX=0
echo "$CERTS" | awk '/-----BEGIN CERTIFICATE-----/,/-----END CERTIFICATE-----/' | while IFS= read -r line; do
    if [[ "$line" == "-----BEGIN CERTIFICATE-----" ]]; then
        CERT_FILE=$(mktemp)
        echo "$line" > "$CERT_FILE"
    elif [[ "$line" == "-----END CERTIFICATE-----" ]]; then
        echo "$line" >> "$CERT_FILE"
        INDEX=$((INDEX + 1))
        
        # Extraire le sujet
        SUBJECT=$(openssl x509 -in "$CERT_FILE" -noout -subject 2>/dev/null | sed 's/subject=//')
        
        # Extraire la date d'expiration
        EXPIRY=$(openssl x509 -in "$CERT_FILE" -noout -enddate 2>/dev/null | sed 's/notAfter=//')
        
        # Calculer le hash SHA-256 du certificat DER
        HASH=$(openssl x509 -in "$CERT_FILE" -outform DER 2>/dev/null | openssl dgst -sha256 -binary | openssl base64)
        
        echo "  📜 Certificat #${INDEX}"
        echo "     Sujet: ${SUBJECT}"
        echo "     Expire: ${EXPIRY}"
        echo "     Hash:   sha256/${HASH}"
        echo ""
        
        rm -f "$CERT_FILE"
    else
        if [ -n "${CERT_FILE:-}" ]; then
            echo "$line" >> "$CERT_FILE"
        fi
    fi
done

echo "============================================"
echo "📋 Copiez les hashes ci-dessus dans:"
echo "   mobile/client/lib/core/security/certificate_pinning.dart"
echo ""
echo "⚠️  Incluez TOUJOURS le certificat leaf ET intermédiaire"
echo "   pour survivre aux renouvellements automatiques."
echo "============================================"
