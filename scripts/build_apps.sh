#!/bin/bash
# ===================================================
# DR-PHARMA — Build All Flutter Apps
# ===================================================
# Génère les APK/AAB pour les 3 apps Flutter
#
# Usage:
#   ./scripts/build_apps.sh                    # Build APK debug (défaut)
#   ./scripts/build_apps.sh --release          # Build APK release
#   ./scripts/build_apps.sh --appbundle        # Build AAB (Play Store)
#   ./scripts/build_apps.sh --ios              # Build iOS
#
# Prérequis:
#   - Flutter SDK installé
#   - key.properties configuré pour chaque app (si --release/--appbundle)
#   - GOOGLE_MAPS_API_KEY dans local.properties
# ===================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
MOBILE_DIR="$PROJECT_DIR/mobile"

BUILD_MODE="apk"
RELEASE_FLAG=""
EXTRA_ARGS=""

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --release)
            RELEASE_FLAG="--release"
            shift
            ;;
        --appbundle)
            BUILD_MODE="appbundle"
            RELEASE_FLAG="--release"
            shift
            ;;
        --ios)
            BUILD_MODE="ios"
            RELEASE_FLAG="--release"
            shift
            ;;
        --dart-define=*)
            EXTRA_ARGS="$EXTRA_ARGS $1"
            shift
            ;;
        *)
            echo "❌ Option inconnue: $1"
            echo "Usage: $0 [--release] [--appbundle] [--ios] [--dart-define=KEY=VALUE]"
            exit 1
            ;;
    esac
done

echo "🏗️  DR-PHARMA — Build des applications Flutter"
echo "================================================="
echo "  Mode: $BUILD_MODE ${RELEASE_FLAG:-debug}"
echo ""

APPS=("client" "delivery" "pharmacy")
APP_NAMES=("DR-PHARMA Client" "DR-PHARMA Coursier" "DR-PHARMA Pharmacie")
SUCCESS=0
FAILED=0

for i in "${!APPS[@]}"; do
    APP="${APPS[$i]}"
    NAME="${APP_NAMES[$i]}"
    APP_DIR="$MOBILE_DIR/$APP"
    
    echo ""
    echo "📱 [$NAME] Building..."
    echo "─────────────────────────────────────────"
    
    if [ ! -d "$APP_DIR" ]; then
        echo "   ❌ Dossier non trouvé: $APP_DIR"
        FAILED=$((FAILED + 1))
        continue
    fi
    
    cd "$APP_DIR"
    
    # Get dependencies
    echo "   📦 flutter pub get..."
    flutter pub get --quiet 2>/dev/null || true
    
    # Analyze before building
    echo "   🔍 flutter analyze..."
    if ! flutter analyze lib/ --no-fatal-infos 2>/dev/null; then
        echo "   ⚠️  Analyse warnings détectées (non-bloquant)"
    fi
    
    # Build
    echo "   🔨 Building $BUILD_MODE $RELEASE_FLAG..."
    # Injecter automatiquement les variables d'env si le fichier config existe
    DEFINE_FILE=""
    if [ -f "$APP_DIR/config/prod.env" ] && [ -n "$RELEASE_FLAG" ]; then
        DEFINE_FILE="--dart-define-from-file=config/prod.env"
    elif [ -f "$APP_DIR/config/dev.env" ] && [ -z "$RELEASE_FLAG" ]; then
        DEFINE_FILE="--dart-define-from-file=config/dev.env"
    fi

    # === Obfuscation Dart en release ===
    # Les symboles sont exportes vers build/symbols/<app>/<version>/ — a archiver
    # ailleurs (S3/git-lfs) pour pouvoir deobfusquer les stack traces Sentry plus tard.
    OBFUSCATE_FLAGS=""
    if [ -n "$RELEASE_FLAG" ] && [ "$BUILD_MODE" != "ios" ]; then
        VERSION=$(grep "^version:" pubspec.yaml | head -1 | awk '{print $2}')
        SYMBOLS_DIR="$PROJECT_DIR/builds/symbols/$APP/$VERSION"
        mkdir -p "$SYMBOLS_DIR"
        OBFUSCATE_FLAGS="--obfuscate --split-debug-info=$SYMBOLS_DIR"
        echo "   🔒 Obfuscation Dart activee, symboles: $SYMBOLS_DIR"
    fi

    BUILD_CMD="flutter build $BUILD_MODE $RELEASE_FLAG $DEFINE_FILE $OBFUSCATE_FLAGS $EXTRA_ARGS"
    
    if eval "$BUILD_CMD"; then
        echo "   ✅ $NAME build réussi !"
        SUCCESS=$((SUCCESS + 1))
        
        # Show output location
        if [ "$BUILD_MODE" = "apk" ]; then
            echo "   📂 Output: build/app/outputs/flutter-apk/"
        elif [ "$BUILD_MODE" = "appbundle" ]; then
            echo "   📂 Output: build/app/outputs/bundle/release/"
        elif [ "$BUILD_MODE" = "ios" ]; then
            echo "   📂 Output: build/ios/ipa/"
        fi
    else
        echo "   ❌ $NAME build ÉCHOUÉ"
        FAILED=$((FAILED + 1))
    fi
done

cd "$PROJECT_DIR"

echo ""
echo "================================================="
echo "📊 Résultats: $SUCCESS réussi(s), $FAILED échoué(s) sur ${#APPS[@]}"
echo ""

if [ $FAILED -gt 0 ]; then
    echo "⚠️  Certains builds ont échoué. Vérifiez les erreurs ci-dessus."
    exit 1
else
    echo "✅ Tous les builds ont réussi !"
    
    if [ -n "$RELEASE_FLAG" ]; then
        echo ""
        echo "📝 Prochaines étapes:"
        echo "   1. Tester les APK/AAB sur un appareil physique"
        echo "   2. Uploader sur Play Console (AAB) ou TestFlight (iOS)"
        echo "   3. Soumettre pour review"
    fi
fi
