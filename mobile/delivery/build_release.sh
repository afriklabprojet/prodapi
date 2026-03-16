#!/bin/bash

# =============================================================================
# DR-PHARMA Courier - Script de Build APK Release
# =============================================================================
# Ce script génère l'APK de release pour l'application courier
# 
# Usage:
#   ./build_release.sh [options]
#
# Options:
#   --clean     Nettoyer le projet avant le build
#   --aab       Générer un Android App Bundle (pour Play Store)
#   --apk       Générer un APK (défaut)
#   --all       Générer APK et AAB
# =============================================================================

set -e  # Arrêter le script en cas d'erreur

# Couleurs pour les messages
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Répertoire de sortie
OUTPUT_DIR="build/app/outputs"
RELEASE_DIR="releases"

echo -e "${BLUE}╔═══════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║       DR-PHARMA Courier - Build Release Script            ║${NC}"
echo -e "${BLUE}╚═══════════════════════════════════════════════════════════╝${NC}"
echo ""

# Parser les arguments
BUILD_APK=true
BUILD_AAB=false
CLEAN=false

for arg in "$@"; do
    case $arg in
        --clean)
            CLEAN=true
            ;;
        --aab)
            BUILD_AAB=true
            BUILD_APK=false
            ;;
        --apk)
            BUILD_APK=true
            ;;
        --all)
            BUILD_APK=true
            BUILD_AAB=true
            ;;
        *)
            echo -e "${YELLOW}Option inconnue: $arg${NC}"
            ;;
    esac
done

# Vérifier que Flutter est installé
if ! command -v flutter &> /dev/null; then
    echo -e "${RED}❌ Flutter n'est pas installé ou n'est pas dans le PATH${NC}"
    exit 1
fi

# Vérifier la présence du fichier key.properties
if [ ! -f "android/key.properties" ]; then
    echo -e "${YELLOW}⚠️  Fichier key.properties manquant. L'APK sera signé avec la clé debug.${NC}"
    echo -e "${YELLOW}    Pour un build de production, créez android/key.properties${NC}"
fi

# Vérifier la présence du keystore
if [ -f "android/key.properties" ]; then
    KEYSTORE_PATH=$(grep "storeFile" android/key.properties | cut -d'=' -f2)
    if [ ! -f "android/$KEYSTORE_PATH" ]; then
        echo -e "${YELLOW}⚠️  Keystore non trouvé: android/$KEYSTORE_PATH${NC}"
        echo -e "${YELLOW}    Générez-le avec: ./generate_keystore.sh${NC}"
    fi
fi

# Nettoyage si demandé
if [ "$CLEAN" = true ]; then
    echo -e "${BLUE}🧹 Nettoyage du projet...${NC}"
    flutter clean
    echo -e "${GREEN}✅ Nettoyage terminé${NC}"
fi

# Récupérer les dépendances
echo -e "${BLUE}📦 Récupération des dépendances...${NC}"
flutter pub get
echo -e "${GREEN}✅ Dépendances récupérées${NC}"

# Créer le dossier de release
mkdir -p "$RELEASE_DIR"

# Build APK
if [ "$BUILD_APK" = true ]; then
    echo ""
    echo -e "${BLUE}🔨 Construction de l'APK Release...${NC}"
    mkdir -p build/debug-info
    flutter build apk --release --split-per-abi \
      --obfuscate --split-debug-info=build/debug-info
    
    echo -e "${GREEN}✅ APK généré avec succès !${NC}"
    echo ""
    echo -e "${BLUE}📁 Fichiers générés:${NC}"
    
    # Copier les APKs dans le dossier releases
    if [ -d "$OUTPUT_DIR/flutter-apk" ]; then
        cp "$OUTPUT_DIR/flutter-apk/app-armeabi-v7a-release.apk" "$RELEASE_DIR/drpharma-courier-arm32.apk" 2>/dev/null || true
        cp "$OUTPUT_DIR/flutter-apk/app-arm64-v8a-release.apk" "$RELEASE_DIR/drpharma-courier-arm64.apk" 2>/dev/null || true
        cp "$OUTPUT_DIR/flutter-apk/app-x86_64-release.apk" "$RELEASE_DIR/drpharma-courier-x86_64.apk" 2>/dev/null || true
        cp "$OUTPUT_DIR/flutter-apk/app-release.apk" "$RELEASE_DIR/drpharma-courier-universal.apk" 2>/dev/null || true
        
        echo -e "   ${GREEN}• $RELEASE_DIR/drpharma-courier-arm64.apk${NC} (Recommandé pour la plupart des appareils)"
        echo -e "   ${GREEN}• $RELEASE_DIR/drpharma-courier-arm32.apk${NC} (Anciens appareils)"
        echo -e "   ${GREEN}• $RELEASE_DIR/drpharma-courier-universal.apk${NC} (Compatible tous appareils)"
    fi
fi

# Build AAB (pour Play Store)
if [ "$BUILD_AAB" = true ]; then
    echo ""
    echo -e "${BLUE}🔨 Construction de l'App Bundle (AAB)...${NC}"
    mkdir -p build/debug-info
    flutter build appbundle --release \
      --obfuscate --split-debug-info=build/debug-info
    
    echo -e "${GREEN}✅ AAB généré avec succès !${NC}"
    
    # Copier l'AAB dans le dossier releases
    if [ -f "$OUTPUT_DIR/bundle/release/app-release.aab" ]; then
        cp "$OUTPUT_DIR/bundle/release/app-release.aab" "$RELEASE_DIR/drpharma-courier.aab"
        echo -e "   ${GREEN}• $RELEASE_DIR/drpharma-courier.aab${NC} (Pour Google Play Store)"
    fi
fi

echo ""
echo -e "${GREEN}╔═══════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║               Build terminé avec succès ! 🎉              ║${NC}"
echo -e "${GREEN}╚═══════════════════════════════════════════════════════════╝${NC}"
echo ""

# Afficher la taille des fichiers
echo -e "${BLUE}📊 Tailles des fichiers:${NC}"
if [ -d "$RELEASE_DIR" ]; then
    ls -lh "$RELEASE_DIR"/*.apk 2>/dev/null || true
    ls -lh "$RELEASE_DIR"/*.aab 2>/dev/null || true
fi

echo ""
echo -e "${YELLOW}📱 Pour installer l'APK sur un appareil connecté:${NC}"
echo -e "   adb install -r $RELEASE_DIR/drpharma-courier-arm64.apk"
echo ""
