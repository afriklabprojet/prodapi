#!/bin/bash
# ============================================================
# DR-PHARMA Delivery — Automated Test Coverage Watcher
# ============================================================
# Lance les tests Flutter en continu avec coverage dès qu'un
# fichier .dart est modifié dans lib/ ou test/.
#
# Usage:
#   ./scripts/test_coverage_watch.sh           # Mode watch (boucle)
#   ./scripts/test_coverage_watch.sh --once     # Run unique
#   ./scripts/test_coverage_watch.sh --report   # Run + ouvre le rapport HTML
# ============================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
COVERAGE_DIR="$PROJECT_DIR/coverage"
REPORT_FILE="$COVERAGE_DIR/coverage_report.txt"
HTML_DIR="$COVERAGE_DIR/html"
LOG_FILE="$COVERAGE_DIR/test_watch.log"
DEBOUNCE_SEC=5
RUN_MODE="${1:-watch}"

# Couleurs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

cd "$PROJECT_DIR"

mkdir -p "$COVERAGE_DIR"

# ── Vérifier les outils ──
check_tools() {
  if ! command -v flutter &>/dev/null; then
    echo -e "${RED}✗ Flutter non trouvé dans le PATH${NC}"
    exit 1
  fi
  echo -e "${GREEN}✓ Flutter $(flutter --version 2>&1 | head -1)${NC}"
}

# ── Lancer les tests avec coverage ──
run_tests_with_coverage() {
  local start_time=$(date +%s)
  local timestamp=$(date '+%Y-%m-%d %H:%M:%S')

  echo ""
  echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${CYAN}  🧪 Tests + Coverage — $timestamp${NC}"
  echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo ""

  # Lancer les tests par catégorie pour un feedback plus rapide
  local exit_code=0
  local total_tests=0
  local passed_tests=0
  local failed_tests=0
  local skipped_tests=0

  # 1. Tests models (rapides)
  echo -e "${YELLOW}▶ Models...${NC}"
  if flutter test test/models/ --coverage --machine 2>/dev/null | tee -a "$LOG_FILE" | _parse_results; then
    echo -e "${GREEN}  ✓ Models OK${NC}"
  else
    echo -e "${RED}  ✗ Models FAILED${NC}"
    exit_code=1
  fi

  # 2. Tests repositories
  echo -e "${YELLOW}▶ Repositories...${NC}"
  if flutter test test/repositories/ --coverage --machine 2>/dev/null | tee -a "$LOG_FILE" | _parse_results; then
    echo -e "${GREEN}  ✓ Repositories OK${NC}"
  else
    echo -e "${RED}  ✗ Repositories FAILED${NC}"
    exit_code=1
  fi

  # 3. Tests services
  echo -e "${YELLOW}▶ Services...${NC}"
  if flutter test test/services/ --coverage --machine 2>/dev/null | tee -a "$LOG_FILE" | _parse_results; then
    echo -e "${GREEN}  ✓ Services OK${NC}"
  else
    echo -e "${RED}  ✗ Services FAILED${NC}"
    exit_code=1
  fi

  # 4. Tests core
  echo -e "${YELLOW}▶ Core...${NC}"
  if flutter test test/core/ --coverage --machine 2>/dev/null | tee -a "$LOG_FILE" | _parse_results; then
    echo -e "${GREEN}  ✓ Core OK${NC}"
  else
    echo -e "${RED}  ✗ Core FAILED${NC}"
    exit_code=1
  fi

  # 5. Tests widgets
  echo -e "${YELLOW}▶ Widgets...${NC}"
  if flutter test test/widgets/ --coverage --machine 2>/dev/null | tee -a "$LOG_FILE" | _parse_results; then
    echo -e "${GREEN}  ✓ Widgets OK${NC}"
  else
    echo -e "${RED}  ✗ Widgets FAILED${NC}"
    exit_code=1
  fi

  # 6. Tests security
  echo -e "${YELLOW}▶ Security...${NC}"
  if flutter test test/security/ --coverage --machine 2>/dev/null | tee -a "$LOG_FILE" | _parse_results; then
    echo -e "${GREEN}  ✓ Security OK${NC}"
  else
    echo -e "${RED}  ✗ Security FAILED${NC}"
    exit_code=1
  fi

  local end_time=$(date +%s)
  local duration=$((end_time - start_time))

  echo ""

  # ── Générer le rapport de coverage ──
  if [ -f "$COVERAGE_DIR/lcov.info" ]; then
    _generate_coverage_report
  else
    echo -e "${YELLOW}⚠ Pas de fichier lcov.info généré${NC}"
  fi

  echo ""
  echo -e "${CYAN}⏱ Durée totale: ${duration}s${NC}"

  if [ $exit_code -eq 0 ]; then
    echo -e "${GREEN}━━━ ✅ TOUS LES TESTS PASSENT ━━━${NC}"
  else
    echo -e "${RED}━━━ ❌ DES TESTS ONT ÉCHOUÉ ━━━${NC}"
  fi

  echo ""
  return $exit_code
}

# ── Parser les résultats machine (silencieux) ──
_parse_results() {
  # On laisse passer — le code de retour de flutter test suffit
  cat > /dev/null
  return ${PIPESTATUS[0]:-0}
}

# ── Rapport de coverage ──
_generate_coverage_report() {
  local lcov_file="$COVERAGE_DIR/lcov.info"

  # Filtrer les fichiers générés (.g.dart, .freezed.dart) et les fichiers non-lib
  if command -v lcov &>/dev/null; then
    lcov --remove "$lcov_file" \
      '*.g.dart' \
      '*.freezed.dart' \
      '**/firebase_options.dart' \
      '**/l10n/**' \
      '**/generated/**' \
      -o "$COVERAGE_DIR/lcov_filtered.info" \
      --quiet 2>/dev/null || true

    local filtered="$COVERAGE_DIR/lcov_filtered.info"
    if [ -f "$filtered" ]; then
      lcov_file="$filtered"
    fi
  fi

  # Extraire les stats
  if [ -f "$lcov_file" ]; then
    local total_lines=0
    local covered_lines=0

    while IFS= read -r line; do
      if [[ "$line" == LF:* ]]; then
        total_lines=$((total_lines + ${line#LF:}))
      elif [[ "$line" == LH:* ]]; then
        covered_lines=$((covered_lines + ${line#LH:}))
      fi
    done < "$lcov_file"

    if [ $total_lines -gt 0 ]; then
      local pct=$((covered_lines * 100 / total_lines))
      local color=$GREEN
      if [ $pct -lt 50 ]; then color=$RED; elif [ $pct -lt 75 ]; then color=$YELLOW; fi

      echo -e "${CYAN}📊 Coverage Report:${NC}"
      echo -e "   Lignes couvertes: ${color}${covered_lines}/${total_lines} (${pct}%)${NC}"

      # Rapport par fichier (top uncovered)
      _file_coverage_report "$lcov_file"

      # Sauvegarder le résumé
      {
        echo "=== Coverage Report $(date '+%Y-%m-%d %H:%M:%S') ==="
        echo "Lines: $covered_lines/$total_lines ($pct%)"
        echo ""
      } > "$REPORT_FILE"
    fi

    # Générer HTML si genhtml est disponible
    if command -v genhtml &>/dev/null; then
      genhtml "$lcov_file" -o "$HTML_DIR" --quiet 2>/dev/null && \
        echo -e "${CYAN}📄 Rapport HTML: $HTML_DIR/index.html${NC}" || true
    fi
  fi
}

# ── Top fichiers non couverts ──
_file_coverage_report() {
  local lcov_file="$1"
  local current_file=""
  local file_total=0
  local file_covered=0

  declare -A file_stats

  while IFS= read -r line; do
    case "$line" in
      SF:*)
        current_file="${line#SF:}"
        # Nettoyer le chemin — garder seulement lib/...
        current_file="${current_file#*lib/}"
        file_total=0
        file_covered=0
        ;;
      LF:*)
        file_total=${line#LF:}
        ;;
      LH:*)
        file_covered=${line#LH:}
        ;;
      end_of_record)
        if [ $file_total -gt 0 ]; then
          local file_pct=$((file_covered * 100 / file_total))
          file_stats["$current_file"]="$file_pct% ($file_covered/$file_total)"
        fi
        ;;
    esac
  done < "$lcov_file"

  # Afficher les fichiers les moins couverts (< 50%)
  echo ""
  echo -e "${YELLOW}   ⚠ Fichiers sous 50% de coverage:${NC}"
  local count=0
  for file in "${!file_stats[@]}"; do
    local stat="${file_stats[$file]}"
    local pct="${stat%%\%*}"
    if [ "$pct" -lt 50 ] 2>/dev/null; then
      echo -e "     ${RED}▸ $file — $stat${NC}"
      count=$((count + 1))
      if [ $count -ge 15 ]; then
        echo -e "     ${YELLOW}... et plus${NC}"
        break
      fi
    fi
  done

  if [ $count -eq 0 ]; then
    echo -e "     ${GREEN}Aucun fichier sous 50% ! 🎉${NC}"
  fi
}

# ── Mode Watch avec fswatch ou polling ──
watch_mode() {
  echo -e "${CYAN}👁 Mode watch activé — surveillance de lib/ et test/${NC}"
  echo -e "${CYAN}   Debounce: ${DEBOUNCE_SEC}s | Ctrl+C pour arrêter${NC}"
  echo ""

  # Premier run
  run_tests_with_coverage || true

  if command -v fswatch &>/dev/null; then
    # Utiliser fswatch (macOS — déjà installé avec Homebrew ou Xcode)
    fswatch -r -l "$DEBOUNCE_SEC" \
      --include '\.dart$' \
      --exclude '\.g\.dart$' \
      --exclude '\.freezed\.dart$' \
      --exclude 'build/' \
      lib/ test/ | while read -r _changed_file; do
        echo -e "${YELLOW}📝 Changement détecté${NC}"
        run_tests_with_coverage || true
      done
  else
    echo -e "${YELLOW}⚠ fswatch non trouvé — fallback polling (10s)${NC}"
    echo -e "${YELLOW}  Installer: brew install fswatch${NC}"
    echo ""

    local last_hash=""
    while true; do
      sleep 10
      # Hash rapide des timestamps de modification
      local current_hash
      current_hash=$(find lib/ test/ -name '*.dart' \
        ! -name '*.g.dart' \
        ! -name '*.freezed.dart' \
        -newer "$COVERAGE_DIR/lcov.info" 2>/dev/null | head -20 | sort | md5 2>/dev/null || echo "no_change")

      if [ "$current_hash" != "$last_hash" ] && [ "$current_hash" != "no_change" ]; then
        last_hash="$current_hash"
        echo -e "${YELLOW}📝 Changement détecté (polling)${NC}"
        run_tests_with_coverage || true
      fi
    done
  fi
}

# ── Main ──
main() {
  check_tools

  case "$RUN_MODE" in
    --once)
      echo -e "${CYAN}🧪 Run unique avec coverage${NC}"
      run_tests_with_coverage
      ;;
    --report)
      echo -e "${CYAN}🧪 Run + ouverture rapport HTML${NC}"
      run_tests_with_coverage
      if [ -f "$HTML_DIR/index.html" ]; then
        open "$HTML_DIR/index.html"
      fi
      ;;
    watch|*)
      watch_mode
      ;;
  esac
}

main
