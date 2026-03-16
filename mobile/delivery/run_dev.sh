#!/bin/bash
# =============================================================
# run_dev.sh — Lancer l'app delivery en mode développement
# =============================================================
# Usage: ./run_dev.sh [device]
# Exemple: ./run_dev.sh
#          ./run_dev.sh chrome
# =============================================================

# --- Configuration développement ---
API_BASE_URL="http://10.0.2.2:8000/api"
GOOGLE_MAPS_API_KEY=""  # ← Mettez votre clé Google Maps ici

# --- Configuration support (optionnel, les defaults suffisent en dev) ---
# SUPPORT_PHONE="+22507000000000"
# SUPPORT_WHATSAPP="22507000000000"
# SUPPORT_EMAIL="support@drlpharma.com"

# --- Lancement ---
DEVICE="${1:-}"
DEVICE_FLAG=""
if [ -n "$DEVICE" ]; then
  DEVICE_FLAG="-d $DEVICE"
fi

flutter run $DEVICE_FLAG \
  --dart-define=API_BASE_URL="$API_BASE_URL" \
  --dart-define=GOOGLE_MAPS_API_KEY="$GOOGLE_MAPS_API_KEY"
