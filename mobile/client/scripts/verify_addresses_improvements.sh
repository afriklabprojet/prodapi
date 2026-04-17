#!/bin/bash

# Script de vérification pour l'amélioration du module Adresses
# Usage: ./scripts/verify_addresses_improvements.sh

echo "🔍 Vérification des améliorations du module Adresses..."
echo "=================================================="
echo ""

# Couleurs pour l'affichage
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Compteurs
PASS=0
FAIL=0
WARN=0

# Fonction de vérification
check_file() {
    local file=$1
    local description=$2
    
    if [ -f "$file" ]; then
        echo -e "${GREEN}✓${NC} $description"
        ((PASS++))
        return 0
    else
        echo -e "${RED}✗${NC} $description"
        echo -e "   ${RED}Fichier manquant: $file${NC}"
        ((FAIL++))
        return 1
    fi
}

# Fonction de vérification optionnelle (warning)
check_file_warn() {
    local file=$1
    local description=$2
    
    if [ -f "$file" ]; then
        echo -e "${GREEN}✓${NC} $description"
        ((PASS++))
        return 0
    else
        echo -e "${YELLOW}⚠${NC} $description"
        echo -e "   ${YELLOW}Fichier optionnel manquant: $file${NC}"
        ((WARN++))
        return 1
    fi
}

echo "📁 Vérification des fichiers source..."
echo "--------------------------------------"
check_file "lib/features/addresses/presentation/widgets/address_card.dart" "Widget AddressCard"
check_file "lib/features/addresses/presentation/widgets/widgets.dart" "Fichier d'export widgets"
check_file "lib/features/addresses/presentation/pages/addresses_list_page.dart" "Page liste d'adresses"
echo ""

echo "🧪 Vérification des fichiers de test..."
echo "--------------------------------------"
check_file "test/features/addresses/presentation/widgets/address_card_test.dart" "Tests AddressCard"
echo ""

echo "📖 Vérification de la documentation..."
echo "--------------------------------------"
check_file "docs/features/README.md" "Index documentation"
check_file "docs/features/ADDRESSES_IMPROVEMENTS.md" "Guide d'amélioration"
check_file "docs/features/ADDRESSES_MIGRATION_GUIDE.md" "Guide de migration"
check_file "docs/features/ADDRESSES_CHANGELOG.md" "Changelog"
check_file "docs/features/ADDRESSES_ARCHITECTURE.md" "Architecture"
check_file "docs/features/ADDRESSES_IMPROVEMENT_REPORT.md" "Rapport d'amélioration"
check_file "docs/features/ADDRESSES_QUICK_START.md" "Quick start guide"
check_file "docs/features/ADDRESSES_FILES_SUMMARY.md" "Récapitulatif fichiers"
check_file "docs/best-practices/FLUTTER_LIST_SCREENS.md" "Best practices Flutter"
echo ""

echo "🔧 Vérification de la configuration..."
echo "--------------------------------------"
check_file_warn "pubspec.yaml" "Configuration Flutter"
check_file_warn "analysis_options.yaml" "Options d'analyse"
echo ""

echo "📊 Analyse statique du code (dart analyze)..."
echo "--------------------------------------"
if command -v dart &> /dev/null; then
    if dart analyze lib/features/addresses/ 2>&1 | grep -q "No issues found"; then
        echo -e "${GREEN}✓${NC} Aucune erreur d'analyse trouvée"
        ((PASS++))
    else
        echo -e "${YELLOW}⚠${NC} Des warnings/erreurs d'analyse existent"
        echo -e "   ${YELLOW}Exécutez 'dart analyze' pour plus de détails${NC}"
        ((WARN++))
    fi
else
    echo -e "${YELLOW}⚠${NC} Dart CLI non trouvé, analyse ignorée"
    ((WARN++))
fi
echo ""

echo "🧪 Exécution des tests..."
echo "--------------------------------------"
if command -v flutter &> /dev/null; then
    if flutter test test/features/addresses/presentation/widgets/address_card_test.dart &> /dev/null; then
        echo -e "${GREEN}✓${NC} Tous les tests passent"
        ((PASS++))
    else
        echo -e "${RED}✗${NC} Des tests échouent"
        echo -e "   ${RED}Exécutez 'flutter test test/features/addresses/' pour plus de détails${NC}"
        ((FAIL++))
    fi
else
    echo -e "${YELLOW}⚠${NC} Flutter CLI non trouvé, tests ignorés"
    ((WARN++))
fi
echo ""

echo "📝 Vérification du format du code..."
echo "--------------------------------------"
if command -v dart &> /dev/null; then
    # Créer une liste des fichiers à vérifier
    FILES_TO_CHECK=(
        "lib/features/addresses/presentation/widgets/address_card.dart"
        "lib/features/addresses/presentation/widgets/widgets.dart"
        "lib/features/addresses/presentation/pages/addresses_list_page.dart"
        "test/features/addresses/presentation/widgets/address_card_test.dart"
    )
    
    ALL_FORMATTED=true
    for file in "${FILES_TO_CHECK[@]}"; do
        if [ -f "$file" ]; then
            if dart format --set-exit-if-changed "$file" &> /dev/null; then
                : # Fichier déjà formatté, ne rien faire
            else
                ALL_FORMATTED=false
                break
            fi
        fi
    done
    
    if [ "$ALL_FORMATTED" = true ]; then
        echo -e "${GREEN}✓${NC} Tous les fichiers sont correctement formatés"
        ((PASS++))
    else
        echo -e "${YELLOW}⚠${NC} Certains fichiers nécessitent un formatage"
        echo -e "   ${YELLOW}Exécutez 'dart format lib/features/addresses/' pour corriger${NC}"
        ((WARN++))
    fi
else
    echo -e "${YELLOW}⚠${NC} Dart CLI non trouvé, vérification du format ignorée"
    ((WARN++))
fi
echo ""

echo "=================================================="
echo "📊 RÉSUMÉ"
echo "=================================================="
echo -e "${GREEN}✓ Réussis:${NC} $PASS"
echo -e "${RED}✗ Échecs:${NC} $FAIL"
echo -e "${YELLOW}⚠ Warnings:${NC} $WARN"
echo ""

# Code de sortie
if [ $FAIL -gt 0 ]; then
    echo -e "${RED}❌ Vérification échouée${NC}"
    echo -e "${RED}Des problèmes critiques ont été détectés.${NC}"
    echo ""
    exit 1
elif [ $WARN -gt 0 ]; then
    echo -e "${YELLOW}⚠️  Vérification réussie avec warnings${NC}"
    echo -e "${YELLOW}Tous les fichiers requis sont présents mais certaines optimisations sont recommandées.${NC}"
    echo ""
    exit 0
else
    echo -e "${GREEN}✅ Vérification complète réussie !${NC}"
    echo -e "${GREEN}Tous les fichiers sont présents et valides.${NC}"
    echo ""
    echo "🚀 Prochaines étapes:"
    echo "   1. git add <fichiers>"
    echo "   2. git commit -m \"feat(addresses): modernize addresses list screen v2.0.0\""
    echo "   3. git push origin <branch>"
    echo "   4. Créer une Pull Request"
    echo ""
    exit 0
fi
