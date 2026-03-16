#!/bin/bash
# =============================================================
# build_prod.sh — Builder l'app delivery pour la production
# =============================================================
# Usage: ./build_prod.sh [apk|appbundle|ios]
# Exemple: ./build_prod.sh apk
#          ./build_prod.sh appbundle
# =============================================================

# --- Configuration production ---
API_BASE_URL="https://drlpharma.com/api"
GOOGLE_MAPS_API_KEY=""           # ← OBLIGATOIRE : votre clé Google Maps
SUPPORT_PHONE="+22507000000000"
SUPPORT_WHATSAPP="22507000000000"
SUPPORT_EMAIL="support@drlpharma.com"
PRIVACY_URL="https://drlpharma.com/privacy"
TERMS_URL="https://drlpharma.com/terms"

# --- Vérification ---
if [ -z "$GOOGLE_MAPS_API_KEY" ]; then
  echo "⚠️  GOOGLE_MAPS_API_KEY est vide ! Éditez ce script pour ajouter votre clé."
  echo "   Obtenez-la sur https://console.cloud.google.com/apis/credentials"
  exit 1
fi

# --- Build ---
TARGET="${1:-apk}"

# Créer le dossier pour les symboles de debug
mkdir -p build/debug-info

flutter build "$TARGET" --release \
  --obfuscate \
  --split-debug-info=build/debug-info \
  --dart-define=API_BASE_URL="$API_BASE_URL" \
  --dart-define=GOOGLE_MAPS_API_KEY="$GOOGLE_MAPS_API_KEY" \
  --dart-define=SUPPORT_PHONE="$SUPPORT_PHONE" \
  --dart-define=SUPPORT_WHATSAPP="$SUPPORT_WHATSAPP" \
  --dart-define=SUPPORT_EMAIL="$SUPPORT_EMAIL" \
  --dart-define=PRIVACY_URL="$PRIVACY_URL" \
  --dart-define=TERMS_URL="$TERMS_URL"
