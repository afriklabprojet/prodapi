#!/bin/bash
# ==============================================================================
# clean_regenerate.sh - Nettoyage et régénération des fichiers
# ==============================================================================
# Execute : chmod +x scripts/clean_regenerate.sh && ./scripts/clean_regenerate.sh
# Utile après un changement de branche ou en cas de problèmes de build
# ==============================================================================

set -e

# Couleurs
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}╔══════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║           DR-PHARMA - Nettoyage & Régénération                    ║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════════════════════════════╝${NC}"
echo ""

# ==============================================================================
# 1. Nettoyage Flutter
# ==============================================================================
echo -e "${YELLOW}▶ [1/6] Nettoyage Flutter...${NC}"
flutter clean
echo -e "${GREEN}✓ Flutter clean terminé${NC}"

# ==============================================================================
# 2. Suppression des fichiers générés
# ==============================================================================
echo ""
echo -e "${YELLOW}▶ [2/6] Suppression des fichiers générés...${NC}"

# Fichiers .g.dart et .freezed.dart
find lib -name "*.g.dart" -delete 2>/dev/null || true
find lib -name "*.freezed.dart" -delete 2>/dev/null || true
find lib -name "*.mocks.dart" -delete 2>/dev/null || true

# Cache Dart
rm -rf .dart_tool/

echo -e "${GREEN}✓ Fichiers générés supprimés${NC}"

# ==============================================================================
# 3. Récupération des dépendances
# ==============================================================================
echo ""
echo -e "${YELLOW}▶ [3/6] Récupération des dépendances...${NC}"
flutter pub get
echo -e "${GREEN}✓ Dépendances récupérées${NC}"

# ==============================================================================
# 4. Régénération avec build_runner
# ==============================================================================
echo ""
echo -e "${YELLOW}▶ [4/6] Régénération (build_runner)...${NC}"

# Vérifier si build_runner est disponible
if flutter pub deps | grep -q "build_runner"; then
    flutter pub run build_runner build --delete-conflicting-outputs
    echo -e "${GREEN}✓ Fichiers régénérés${NC}"
else
    echo -e "${YELLOW}⚠ build_runner non trouvé, étape ignorée${NC}"
fi

# ==============================================================================
# 5. Régénération des localisations
# ==============================================================================
echo ""
echo -e "${YELLOW}▶ [5/6] Régénération des localisations...${NC}"

if [ -f "l10n.yaml" ]; then
    flutter gen-l10n
    echo -e "${GREEN}✓ Localisations régénérées${NC}"
else
    echo -e "${YELLOW}⚠ l10n.yaml non trouvé, étape ignorée${NC}"
fi

# ==============================================================================
# 6. Vérification finale
# ==============================================================================
echo ""
echo -e "${YELLOW}▶ [6/6] Vérification finale...${NC}"

# Analyse rapide
if flutter analyze --no-pub 2>&1 | grep -q "No issues found"; then
    echo -e "${GREEN}✓ Aucun problème détecté${NC}"
else
    ISSUES=$(flutter analyze --no-pub 2>&1 | grep -c "•" || echo "0")
    echo -e "${YELLOW}⚠ $ISSUES problèmes détectés (flutter analyze pour détails)${NC}"
fi

# ==============================================================================
# Résumé
# ==============================================================================
echo ""
echo -e "${BLUE}══════════════════════════════════════════════════════════════════${NC}"
echo ""
echo -e "${GREEN}✅ Nettoyage et régénération terminés !${NC}"
echo ""
echo "Prochaines étapes :"
echo "  • flutter run -d <device>  - Lancer l'app"
echo "  • flutter test            - Exécuter les tests"
echo "  • ./scripts/dev_check.sh  - Vérification complète"
echo ""
