#!/bin/bash
# ==============================================================================
# build_release.sh - Script de build pour release
# ==============================================================================
# Execute : chmod +x scripts/build_release.sh && ./scripts/build_release.sh [android|ios|all]
# ==============================================================================

set -e

# Couleurs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
BUILD_DIR="build/releases"
VERSION=$(grep 'version:' pubspec.yaml | awk '{print $2}' | tr '+' '_')
DATE=$(date +%Y%m%d_%H%M)

# Arguments
PLATFORM=${1:-"all"}

# ==============================================================================
# Fonctions
# ==============================================================================

print_header() {
    echo -e "${BLUE}╔══════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║           DR-PHARMA - Build Release v$VERSION${NC}"
    echo -e "${BLUE}╚══════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

check_environment() {
    echo -e "${YELLOW}▶ Vérification de l'environnement...${NC}"
    
    # Flutter
    if ! command -v flutter &> /dev/null; then
        echo -e "${RED}✗ Flutter non installé${NC}"
        exit 1
    fi
    
    # Doctor (avertissements seulement)
    flutter doctor -v > /dev/null 2>&1 || true
    
    echo -e "${GREEN}✓ Environnement OK${NC}"
    echo ""
}

clean_build() {
    echo -e "${YELLOW}▶ Nettoyage du build précédent...${NC}"
    flutter clean
    flutter pub get
    echo -e "${GREEN}✓ Nettoyage terminé${NC}"
    echo ""
}

run_checks() {
    echo -e "${YELLOW}▶ Vérifications pré-build...${NC}"
    
    # Analyse
    if flutter analyze --no-pub 2>&1 | grep -q "error •"; then
        echo -e "${RED}✗ Erreurs détectées dans le code${NC}"
        flutter analyze --no-pub
        exit 1
    fi
    
    # Tests
    if ! flutter test --no-pub; then
        echo -e "${RED}✗ Tests échoués${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}✓ Vérifications OK${NC}"
    echo ""
}

build_android() {
    echo -e "${YELLOW}▶ Build Android (APK + AAB)...${NC}"
    
    # APK
    flutter build apk --release --obfuscate --split-debug-info=build/debug-info
    
    # AAB pour Play Store
    flutter build appbundle --release --obfuscate --split-debug-info=build/debug-info
    
    # Copie dans le dossier releases
    mkdir -p "$BUILD_DIR/android"
    cp build/app/outputs/flutter-apk/app-release.apk "$BUILD_DIR/android/dr-pharma-$VERSION-$DATE.apk"
    cp build/app/outputs/bundle/release/app-release.aab "$BUILD_DIR/android/dr-pharma-$VERSION-$DATE.aab"
    
    echo -e "${GREEN}✓ Android build terminé${NC}"
    echo -e "  📦 APK: $BUILD_DIR/android/dr-pharma-$VERSION-$DATE.apk"
    echo -e "  📦 AAB: $BUILD_DIR/android/dr-pharma-$VERSION-$DATE.aab"
    echo ""
}

build_ios() {
    if [[ "$OSTYPE" != "darwin"* ]]; then
        echo -e "${YELLOW}⚠ Build iOS ignoré (macOS requis)${NC}"
        return
    fi
    
    echo -e "${YELLOW}▶ Build iOS...${NC}"
    
    # Archive
    flutter build ios --release --obfuscate --split-debug-info=build/debug-info
    
    # IPA (nécessite codesign configuré)
    if [ -f "ios/ExportOptions.plist" ]; then
        flutter build ipa --release --export-options-plist=ios/ExportOptions.plist
        
        mkdir -p "$BUILD_DIR/ios"
        cp build/ios/ipa/*.ipa "$BUILD_DIR/ios/dr-pharma-$VERSION-$DATE.ipa" 2>/dev/null || true
        
        echo -e "${GREEN}✓ iOS build terminé${NC}"
        echo -e "  📦 IPA: $BUILD_DIR/ios/dr-pharma-$VERSION-$DATE.ipa"
    else
        echo -e "${YELLOW}⚠ ExportOptions.plist manquant - archive non signée${NC}"
        echo -e "  📂 Archive disponible dans: build/ios/archive/"
    fi
    echo ""
}

print_summary() {
    echo -e "${BLUE}══════════════════════════════════════════════════════════════════${NC}"
    echo ""
    echo -e "${GREEN}✅ BUILD TERMINÉ${NC}"
    echo ""
    echo "📁 Fichiers générés dans: $BUILD_DIR"
    ls -la "$BUILD_DIR"/*/* 2>/dev/null || echo "  (voir les sous-dossiers)"
    echo ""
    
    # Tailles des fichiers
    if [ -f "$BUILD_DIR/android/dr-pharma-$VERSION-$DATE.apk" ]; then
        APK_SIZE=$(du -h "$BUILD_DIR/android/dr-pharma-$VERSION-$DATE.apk" | cut -f1)
        echo -e "📱 Taille APK: $APK_SIZE"
    fi
    
    echo ""
}

# ==============================================================================
# Main
# ==============================================================================

print_header
check_environment
clean_build
run_checks

case $PLATFORM in
    android)
        build_android
        ;;
    ios)
        build_ios
        ;;
    all)
        build_android
        build_ios
        ;;
    *)
        echo -e "${RED}Usage: $0 [android|ios|all]${NC}"
        exit 1
        ;;
esac

print_summary
