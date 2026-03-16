#!/bin/bash
# ===================================================
# DR-PHARMA — Génération des Keystores Android
# ===================================================
# Ce script génère les 3 keystores pour les apps Android
# et configure automatiquement les fichiers key.properties.
#
# Usage:  chmod +x scripts/generate_keystores.sh
#         ./scripts/generate_keystores.sh
# ===================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

echo "🔐 DR-PHARMA — Génération des Keystores Android"
echo "================================================="
echo ""

# Demander le mot de passe
read -sp "🔑 Mot de passe pour les keystores (min 6 chars): " STORE_PASSWORD
echo ""
if [ ${#STORE_PASSWORD} -lt 6 ]; then
    echo "❌ Le mot de passe doit contenir au moins 6 caractères."
    exit 1
fi

APPS=("client" "delivery" "pharmacy")
ALIASES=("drpharma-client" "drpharma-courier" "drpharma-pharmacy")
NAMES=("DR-PHARMA" "DR-PHARMA Coursier" "DR-PHARMA Pharmacie")

for i in "${!APPS[@]}"; do
    APP="${APPS[$i]}"
    ALIAS="${ALIASES[$i]}"
    CN="${NAMES[$i]}"
    
    APP_DIR="$PROJECT_DIR/mobile/$APP/android"
    KEYSTORE_DIR="$APP_DIR/keystores"
    KEYSTORE_FILE="$KEYSTORE_DIR/$ALIAS.keystore"
    KEY_PROPS="$APP_DIR/key.properties"
    
    echo ""
    echo "📱 [$APP] Génération du keystore..."
    
    # Créer le dossier keystores
    mkdir -p "$KEYSTORE_DIR"
    
    # Vérifier si le keystore existe déjà
    if [ -f "$KEYSTORE_FILE" ]; then
        echo "   ⚠️  Keystore déjà existant: $KEYSTORE_FILE"
        echo "   ⏩ Ignoré (supprimer manuellement pour régénérer)"
        continue
    fi
    
    # Générer le keystore
    keytool -genkey -v \
        -keystore "$KEYSTORE_FILE" \
        -alias "$ALIAS" \
        -keyalg RSA \
        -keysize 2048 \
        -validity 10000 \
        -storepass "$STORE_PASSWORD" \
        -keypass "$STORE_PASSWORD" \
        -dname "CN=$CN, OU=Mobile, O=DRL NEGOCE SARL, L=Abidjan, ST=Lagunes, C=CI" \
        -noprompt
    
    echo "   ✅ Keystore créé: $KEYSTORE_FILE"
    
    # Créer key.properties
    cat > "$KEY_PROPS" << EOF
storePassword=$STORE_PASSWORD
keyPassword=$STORE_PASSWORD
keyAlias=$ALIAS
storeFile=keystores/$ALIAS.keystore
EOF
    
    echo "   ✅ key.properties créé: $KEY_PROPS"
    
    # Ajouter au .gitignore si pas déjà
    GITIGNORE="$APP_DIR/.gitignore"
    if [ -f "$GITIGNORE" ]; then
        if ! grep -q "key.properties" "$GITIGNORE" 2>/dev/null; then
            echo "key.properties" >> "$GITIGNORE"
            echo "keystores/" >> "$GITIGNORE"
        fi
    fi
done

echo ""
echo "================================================="
echo "✅ Tous les keystores ont été générés !"
echo ""
echo "⚠️  IMPORTANT:"
echo "   1. Sauvegarde les keystores dans un endroit sûr (iCloud, 1Password, etc.)"
echo "   2. Les fichiers key.properties et keystores/ sont dans .gitignore"
echo "   3. Ne JAMAIS commit les keystores dans git"
echo "   4. Mot de passe à sauvegarder de manière sécurisée"
echo ""
echo "📝 SHA-256 fingerprints (pour Google Play Console / Firebase):"
for i in "${!APPS[@]}"; do
    APP="${APPS[$i]}"
    ALIAS="${ALIASES[$i]}"
    KEYSTORE_FILE="$PROJECT_DIR/mobile/$APP/android/keystores/$ALIAS.keystore"
    if [ -f "$KEYSTORE_FILE" ]; then
        echo ""
        echo "   [$APP]:"
        keytool -list -v -keystore "$KEYSTORE_FILE" -alias "$ALIAS" -storepass "$STORE_PASSWORD" 2>/dev/null | grep "SHA256:" | sed 's/^/   /'
    fi
done
echo ""
