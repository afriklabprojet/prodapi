#!/bin/bash

##############################################################################
# Script de vérification des améliorations du module Traitements
# Version: 1.0.0
# Auteur: Équipe DR-PHARMA
##############################################################################

set -e  # Exit on error

# Couleurs pour l'output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Compteurs
TOTAL_CHECKS=0
PASSED_CHECKS=0
FAILED_CHECKS=0
WARNING_CHECKS=0

# Dossier du projet
PROJECT_DIR="/Users/teya2023/Downloads/DR-PHARMA/mobile/client"

##############################################################################
# Fonctions utilitaires
##############################################################################

print_header() {
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

print_section() {
    echo ""
    echo -e "${YELLOW}▶ $1${NC}"
}

check_pass() {
    ((PASSED_CHECKS++))
    ((TOTAL_CHECKS++))
    echo -e "  ${GREEN}✓${NC} $1"
}

check_fail() {
    ((FAILED_CHECKS++))
    ((TOTAL_CHECKS++))
    echo -e "  ${RED}✗${NC} $1"
}

check_warning() {
    ((WARNING_CHECKS++))
    ((TOTAL_CHECKS++))
    echo -e "  ${YELLOW}⚠${NC} $1"
}

##############################################################################
# Vérifications
##############################################################################

verify_structure() {
    print_section "Vérification de la structure des fichiers"
    
    # Nouveaux fichiers
    if [ -f "$PROJECT_DIR/lib/features/treatments/presentation/widgets/widgets.dart" ]; then
        check_pass "widgets.dart existe"
    else
        check_fail "widgets.dart manquant"
    fi
    
    if [ -f "$PROJECT_DIR/lib/features/treatments/presentation/pages/treatments_list_page.dart" ]; then
        check_pass "treatments_list_page.dart existe"
    else
        check_fail "treatments_list_page.dart manquant"
    fi
    
    if [ -f "$PROJECT_DIR/test/features/treatments/presentation/widgets/widgets_test.dart" ]; then
        check_pass "widgets_test.dart existe"
    else
        check_fail "widgets_test.dart manquant"
    fi
    
    # Fichiers modifiés
    if [ -f "$PROJECT_DIR/lib/features/treatments/data/datasources/treatments_local_datasource.dart" ]; then
        check_pass "treatments_local_datasource.dart existe"
    else
        check_fail "treatments_local_datasource.dart manquant"
    fi
}

verify_documentation() {
    print_section "Vérification de la documentation"
    
    local docs=(
        "TREATMENTS_IMPROVEMENTS.md"
        "TREATMENTS_MIGRATION_GUIDE.md"
        "TREATMENTS_ARCHITECTURE.md"
        "TREATMENTS_CHANGELOG.md"
        "TREATMENTS_FINAL_REPORT.md"
        "TREATMENTS_QUICK_START.md"
    )
    
    for doc in "${docs[@]}"; do
        if [ -f "$PROJECT_DIR/docs/$doc" ]; then
            check_pass "$doc existe"
        else
            check_fail "$doc manquant"
        fi
    done
}

verify_code_quality() {
    print_section "Vérification de la qualité du code"
    
    cd "$PROJECT_DIR"
    
    # Vérifier dart analyze
    echo "  Exécution de dart analyze..."
    if dart analyze lib/features/treatments/ 2>&1 | grep -q "No issues found"; then
        check_pass "Aucun warning dart analyze"
    else
        local warnings=$(dart analyze lib/features/treatments/ 2>&1 | grep -c "warning" || echo "0")
        if [ "$warnings" -eq 0 ]; then
            check_pass "Aucun warning dart analyze"
        else
            check_warning "$warnings warning(s) trouvé(s)"
        fi
    fi
}

verify_tests() {
    print_section "Vérification des tests"
    
    cd "$PROJECT_DIR"
    
    # Compter les tests
    local test_count=$(grep -c "testWidgets\|test(" test/features/treatments/presentation/widgets/widgets_test.dart || echo "0")
    
    if [ "$test_count" -ge 20 ]; then
        check_pass "$test_count tests trouvés (>= 20)"
    else
        check_fail "Seulement $test_count tests trouvés (< 20)"
    fi
    
    # Exécuter les tests
    echo "  Exécution des tests..."
    if flutter test test/features/treatments/presentation/widgets/widgets_test.dart --reporter compact 2>&1 | grep -q "All tests passed"; then
        check_pass "Tous les tests passent"
    else
        # Compter les tests qui passent
        local passed=$(flutter test test/features/treatments/presentation/widgets/widgets_test.dart --reporter compact 2>&1 | grep -oP '\+\K\d+' | head -1 || echo "0")
        if [ "$passed" -gt 0 ]; then
            check_warning "$passed test(s) passent (vérifier les échecs)"
        else
            check_fail "Échec d'exécution des tests"
        fi
    fi
}

verify_widgets() {
    print_section "Vérification des widgets"
    
    local widgets_file="$PROJECT_DIR/lib/features/treatments/presentation/widgets/widgets.dart"
    
    # Vérifier les widgets requis
    local required_widgets=(
        "TreatmentCard"
        "TreatmentCardSkeleton"
        "TreatmentsEmptyState"
        "TreatmentsErrorState"
    )
    
    for widget in "${required_widgets[@]}"; do
        if grep -q "class $widget" "$widgets_file"; then
            check_pass "$widget défini"
        else
            check_fail "$widget manquant"
        fi
    done
}

verify_singleton() {
    print_section "Vérification du pattern singleton"
    
    local datasource_file="$PROJECT_DIR/lib/features/treatments/data/datasources/treatments_local_datasource.dart"
    
    # Vérifier le singleton
    if grep -q "static TreatmentsLocalDatasource? _instance" "$datasource_file" && \
       grep -q "factory TreatmentsLocalDatasource()" "$datasource_file"; then
        check_pass "Pattern singleton implémenté"
    else
        check_fail "Pattern singleton manquant"
    fi
    
    # Vérifier auto-init
    if grep -q "Future<Box<TreatmentModel>> get box async" "$datasource_file"; then
        check_pass "Auto-initialisation implémentée"
    else
        check_fail "Auto-initialisation manquante"
    fi
}

verify_features() {
    print_section "Vérification des fonctionnalités"
    
    local list_page="$PROJECT_DIR/lib/features/treatments/presentation/pages/treatments_list_page.dart"
    
    # Recherche
    if grep -q "TextField\|TextFormField" "$list_page" && grep -q "search\|filter" "$list_page"; then
        check_pass "Recherche implémentée"
    else
        check_warning "Recherche non détectée (vérifier manuellement)"
    fi
    
    # Animations
    if grep -q "AnimationController\|FadeTransition\|ScaleTransition" "$list_page"; then
        check_pass "Animations implémentées"
    else
        check_warning "Animations non détectées (vérifier widgets.dart)"
    fi
    
    # Skeleton
    if grep -q "TreatmentCardSkeleton" "$list_page"; then
        check_pass "Skeleton loading utilisé"
    else
        check_fail "Skeleton loading non utilisé"
    fi
    
    # Pull-to-refresh
    if grep -q "RefreshIndicator" "$list_page"; then
        check_pass "Pull-to-refresh implémenté"
    else
        check_warning "Pull-to-refresh non détecté"
    fi
}

verify_lines_of_code() {
    print_section "Statistiques de code"
    
    # Widgets
    local widgets_lines=$(wc -l < "$PROJECT_DIR/lib/features/treatments/presentation/widgets/widgets.dart" || echo "0")
    echo -e "  widgets.dart: ${BLUE}$widgets_lines${NC} lignes"
    
    # List page
    local list_page_lines=$(wc -l < "$PROJECT_DIR/lib/features/treatments/presentation/pages/treatments_list_page.dart" || echo "0")
    echo -e "  treatments_list_page.dart: ${BLUE}$list_page_lines${NC} lignes"
    
    # Tests
    local test_lines=$(wc -l < "$PROJECT_DIR/test/features/treatments/presentation/widgets/widgets_test.dart" || echo "0")
    echo -e "  widgets_test.dart: ${BLUE}$test_lines${NC} lignes"
    
    # Total
    local total_lines=$((widgets_lines + list_page_lines + test_lines))
    echo -e "  ${GREEN}Total nouveau code: $total_lines lignes${NC}"
    
    if [ "$total_lines" -ge 1500 ]; then
        check_pass "Volume de code suffisant (>= 1500 lignes)"
    else
        check_warning "Volume de code: $total_lines lignes (< 1500)"
    fi
}

##############################################################################
# Main
##############################################################################

main() {
    print_header "🔍 Vérification des améliorations du module Traitements"
    
    echo ""
    echo "Projet: $PROJECT_DIR"
    echo "Date: $(date '+%Y-%m-%d %H:%M:%S')"
    echo ""
    
    # Vérifier que le projet existe
    if [ ! -d "$PROJECT_DIR" ]; then
        echo -e "${RED}Erreur: Le dossier du projet n'existe pas${NC}"
        exit 1
    fi
    
    # Exécuter les vérifications
    verify_structure
    verify_documentation
    verify_widgets
    verify_singleton
    verify_features
    verify_code_quality
    verify_tests
    verify_lines_of_code
    
    # Résumé
    print_header "📊 Résumé"
    echo ""
    echo -e "  Total de vérifications: ${BLUE}$TOTAL_CHECKS${NC}"
    echo -e "  ${GREEN}Réussies: $PASSED_CHECKS${NC}"
    echo -e "  ${RED}Échouées: $FAILED_CHECKS${NC}"
    echo -e "  ${YELLOW}Avertissements: $WARNING_CHECKS${NC}"
    echo ""
    
    # Score
    local score=$((PASSED_CHECKS * 100 / TOTAL_CHECKS))
    echo -e "  Score: ${BLUE}$score%${NC}"
    echo ""
    
    # Status final
    if [ "$FAILED_CHECKS" -eq 0 ]; then
        if [ "$WARNING_CHECKS" -eq 0 ]; then
            echo -e "${GREEN}✓ Tous les checks sont passés !${NC}"
            echo ""
            exit 0
        else
            echo -e "${YELLOW}⚠ Quelques avertissements détectés${NC}"
            echo ""
            exit 0
        fi
    else
        echo -e "${RED}✗ Certains checks ont échoué${NC}"
        echo ""
        exit 1
    fi
}

# Exécuter
main "$@"
