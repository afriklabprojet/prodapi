#!/bin/bash
# ==============================================================================
# test_coverage.sh - Tests avec rapport de couverture
# ==============================================================================
# Execute : chmod +x scripts/test_coverage.sh && ./scripts/test_coverage.sh
# Ouvre automatiquement le rapport HTML dans le navigateur
# ==============================================================================

set -e

# Couleurs
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}╔══════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║           DR-PHARMA - Couverture de tests                         ║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════════════════════════════╝${NC}"
echo ""

# ==============================================================================
# 1. Nettoyage des anciens rapports
# ==============================================================================
echo -e "${YELLOW}▶ Nettoyage des anciens rapports...${NC}"
rm -rf coverage/
mkdir -p coverage

# ==============================================================================
# 2. Exécution des tests avec couverture
# ==============================================================================
echo -e "${YELLOW}▶ Exécution des tests avec couverture...${NC}"
flutter test --coverage --no-pub

# ==============================================================================
# 3. Vérification de la disponibilité de lcov
# ==============================================================================
if ! command -v lcov &> /dev/null; then
    echo -e "${YELLOW}⚠ lcov non installé. Installation...${NC}"
    if [[ "$OSTYPE" == "darwin"* ]]; then
        brew install lcov
    else
        sudo apt-get install -y lcov
    fi
fi

if ! command -v genhtml &> /dev/null; then
    echo -e "${YELLOW}⚠ genhtml non disponible. Le rapport HTML ne sera pas généré.${NC}"
    echo -e "${GREEN}✓ Couverture brute disponible dans coverage/lcov.info${NC}"
    exit 0
fi

# ==============================================================================
# 4. Filtrage des fichiers générés
# ==============================================================================
echo -e "${YELLOW}▶ Filtrage des fichiers générés...${NC}"
lcov --remove coverage/lcov.info \
    'lib/**/*.g.dart' \
    'lib/**/*.freezed.dart' \
    'lib/**/*.part.dart' \
    'lib/**/generated/**' \
    'lib/firebase_options.dart' \
    -o coverage/lcov_filtered.info \
    --ignore-errors unused

# ==============================================================================
# 5. Génération du rapport HTML
# ==============================================================================
echo -e "${YELLOW}▶ Génération du rapport HTML...${NC}"
genhtml coverage/lcov_filtered.info \
    -o coverage/html \
    --title "DR-PHARMA Coverage" \
    --legend \
    --highlight \
    --branch-coverage

# ==============================================================================
# 6. Calcul du pourcentage de couverture
# ==============================================================================
COVERAGE=$(lcov --summary coverage/lcov_filtered.info 2>&1 | grep "lines" | grep -oP '\d+\.\d+%' | head -1)

echo ""
echo -e "${BLUE}══════════════════════════════════════════════════════════════════${NC}"
echo ""
echo -e "${GREEN}✅ Rapport généré : coverage/html/index.html${NC}"
echo -e "${GREEN}📊 Couverture : ${COVERAGE:-N/A}${NC}"
echo ""

# ==============================================================================
# 7. Ouverture automatique du rapport
# ==============================================================================
if [[ "$OSTYPE" == "darwin"* ]]; then
    open coverage/html/index.html
elif command -v xdg-open &> /dev/null; then
    xdg-open coverage/html/index.html
else
    echo -e "${YELLOW}Ouvrez manuellement : coverage/html/index.html${NC}"
fi
