#!/bin/bash
# ==============================================================================
# dev_check.sh - Script de vérification avant commit
# ==============================================================================
# Execute : chmod +x scripts/dev_check.sh && ./scripts/dev_check.sh
# ==============================================================================

set -e

# Couleurs pour l'affichage
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Variables
ERRORS=0
WARNINGS=0

echo -e "${BLUE}╔══════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║           DR-PHARMA - Vérification avant commit                   ║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════════════════════════════╝${NC}"
echo ""

# ==============================================================================
# 1. Vérification du formatage
# ==============================================================================
echo -e "${YELLOW}▶ [1/5] Vérification du formatage...${NC}"

UNFORMATTED=$(dart format --output=none --set-exit-if-changed lib test 2>&1 || true)
if echo "$UNFORMATTED" | grep -q "Formatted"; then
    echo -e "${RED}  ✗ Fichiers non formatés détectés${NC}"
    echo "$UNFORMATTED" | head -10
    echo ""
    echo -e "${YELLOW}  ⚡ Correction automatique...${NC}"
    dart format lib test
    echo -e "${GREEN}  ✓ Formatage corrigé${NC}"
    WARNINGS=$((WARNINGS + 1))
else
    echo -e "${GREEN}  ✓ Formatage OK${NC}"
fi

# ==============================================================================
# 2. Analyse statique
# ==============================================================================
echo ""
echo -e "${YELLOW}▶ [2/5] Analyse statique (flutter analyze)...${NC}"

ANALYZE_OUTPUT=$(flutter analyze --no-pub 2>&1 || true)
ANALYZE_ERRORS=$(echo "$ANALYZE_OUTPUT" | grep -c "error •" || true)
ANALYZE_WARNINGS=$(echo "$ANALYZE_OUTPUT" | grep -c "warning •" || true)
ANALYZE_INFOS=$(echo "$ANALYZE_OUTPUT" | grep -c "info •" || true)

if [ "$ANALYZE_ERRORS" -gt 0 ]; then
    echo -e "${RED}  ✗ $ANALYZE_ERRORS erreur(s) trouvée(s)${NC}"
    echo "$ANALYZE_OUTPUT" | grep "error •" | head -10
    ERRORS=$((ERRORS + ANALYZE_ERRORS))
elif [ "$ANALYZE_WARNINGS" -gt 0 ]; then
    echo -e "${YELLOW}  ⚠ $ANALYZE_WARNINGS warning(s), $ANALYZE_INFOS info(s)${NC}"
    WARNINGS=$((WARNINGS + ANALYZE_WARNINGS))
else
    echo -e "${GREEN}  ✓ Aucun problème détecté${NC}"
fi

# ==============================================================================
# 3. Vérification des imports
# ==============================================================================
echo ""
echo -e "${YELLOW}▶ [3/5] Vérification des imports inutilisés...${NC}"

UNUSED_IMPORTS=$(grep -r "import '.*';" lib --include="*.dart" -l 2>/dev/null | while read -r file; do
    dart analyze "$file" 2>&1 | grep -l "unused_import" || true
done | head -5)

if [ -n "$UNUSED_IMPORTS" ]; then
    echo -e "${YELLOW}  ⚠ Imports potentiellement inutilisés détectés${NC}"
    WARNINGS=$((WARNINGS + 1))
else
    echo -e "${GREEN}  ✓ Imports OK${NC}"
fi

# ==============================================================================
# 4. Tests unitaires
# ==============================================================================
echo ""
echo -e "${YELLOW}▶ [4/5] Exécution des tests unitaires...${NC}"

TEST_OUTPUT=$(flutter test --no-pub 2>&1 || true)
if echo "$TEST_OUTPUT" | grep -q "All tests passed"; then
    PASSED=$(echo "$TEST_OUTPUT" | grep -oP '\+\d+' | head -1 | tr -d '+')
    echo -e "${GREEN}  ✓ Tous les tests passent ($PASSED tests)${NC}"
elif echo "$TEST_OUTPUT" | grep -q "No tests ran"; then
    echo -e "${YELLOW}  ⚠ Aucun test trouvé${NC}"
    WARNINGS=$((WARNINGS + 1))
else
    FAILED=$(echo "$TEST_OUTPUT" | grep -oP '\-\d+' | head -1 | tr -d '-')
    echo -e "${RED}  ✗ $FAILED test(s) échoué(s)${NC}"
    echo "$TEST_OUTPUT" | grep -A 5 "FAILED" | head -20
    ERRORS=$((ERRORS + 1))
fi

# ==============================================================================
# 5. Vérification des TODOs critiques
# ==============================================================================
echo ""
echo -e "${YELLOW}▶ [5/5] Vérification des TODOs critiques...${NC}"

FIXME_COUNT=$(grep -r "FIXME" lib --include="*.dart" 2>/dev/null | wc -l | tr -d ' ')
HACK_COUNT=$(grep -r "HACK" lib --include="*.dart" 2>/dev/null | wc -l | tr -d ' ')

if [ "$FIXME_COUNT" -gt 0 ] || [ "$HACK_COUNT" -gt 0 ]; then
    echo -e "${YELLOW}  ⚠ $FIXME_COUNT FIXME, $HACK_COUNT HACK trouvés${NC}"
    WARNINGS=$((WARNINGS + 1))
else
    echo -e "${GREEN}  ✓ Aucun FIXME/HACK${NC}"
fi

# ==============================================================================
# Résumé
# ==============================================================================
echo ""
echo -e "${BLUE}══════════════════════════════════════════════════════════════════${NC}"
echo ""

if [ "$ERRORS" -gt 0 ]; then
    echo -e "${RED}❌ ÉCHEC : $ERRORS erreur(s), $WARNINGS warning(s)${NC}"
    echo -e "${RED}   Corrigez les erreurs avant de commit.${NC}"
    exit 1
elif [ "$WARNINGS" -gt 0 ]; then
    echo -e "${YELLOW}⚠️  OK AVEC WARNINGS : $WARNINGS warning(s)${NC}"
    echo -e "${YELLOW}   Vous pouvez commit, mais pensez à corriger les warnings.${NC}"
    exit 0
else
    echo -e "${GREEN}✅ SUCCÈS : Tout est OK !${NC}"
    echo -e "${GREEN}   Vous pouvez commit en toute sécurité.${NC}"
    exit 0
fi
