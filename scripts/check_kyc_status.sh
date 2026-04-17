#!/bin/bash
# =============================================================
# Script de diagnostic KYC/Liveness - DR-PHARMA
# Vérifie que le système de vérification biométrique est opérationnel
# =============================================================
#
# Usage local:  ./scripts/check_kyc_status.sh
# Usage serveur: ./scripts/check_kyc_status.sh --remote
# =============================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
API_DIR="${SCRIPT_DIR}/../api"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

pass() { echo -e "  ${GREEN}✓${NC} $1"; }
fail() { echo -e "  ${RED}✗${NC} $1"; ERRORS=$((ERRORS + 1)); }
warn() { echo -e "  ${YELLOW}⚠${NC} $1"; }

ERRORS=0

# ---- Mode distant (SSH sur le serveur) ----
if [[ "${1:-}" == "--remote" ]]; then
    REMOTE_HOST="${CPANEL_USER:-kvyajoqt}@${REMOTE_HOST:-drlpharma.com}"
    DEPLOY_PATH="${DEPLOY_PATH:-/home/kvyajoqt/public_html}"
    
    echo "=========================================="
    echo "  KYC Diagnostic - Serveur distant"
    echo "=========================================="
    echo ""
    
    ssh "${REMOTE_HOST}" bash -s "${DEPLOY_PATH}" << 'REMOTE_DIAG'
set -euo pipefail
DEPLOY_PATH="$1"
cd "${DEPLOY_PATH}"

echo "[1] Variables .env"
if grep -q "^GOOGLE_VISION_ENABLED=true" .env 2>/dev/null; then
    echo "  ✓ GOOGLE_VISION_ENABLED=true"
elif grep -q "^GOOGLE_VISION_ENABLED=" .env 2>/dev/null; then
    VALUE=$(grep "^GOOGLE_VISION_ENABLED=" .env | head -1)
    echo "  ✗ ${VALUE} (devrait être true!)"
else
    echo "  ✗ GOOGLE_VISION_ENABLED absent du .env!"
fi

if grep -q "^GOOGLE_APPLICATION_CREDENTIALS=" .env 2>/dev/null; then
    CRED_PATH=$(grep "^GOOGLE_APPLICATION_CREDENTIALS=" .env | cut -d= -f2)
    echo "  ✓ GOOGLE_APPLICATION_CREDENTIALS=${CRED_PATH}"
else
    echo "  ✗ GOOGLE_APPLICATION_CREDENTIALS absent du .env!"
fi

echo ""
echo "[2] Fichier credentials"
CRED_FILE="${DEPLOY_PATH}/storage/app/firebase-credentials.json"
if [ -f "${CRED_FILE}" ]; then
    echo "  ✓ ${CRED_FILE} existe"
    if [ -r "${CRED_FILE}" ]; then
        echo "  ✓ Fichier lisible"
    else
        echo "  ✗ Fichier NON lisible (permissions!)"
    fi
    # Vérifier le contenu JSON
    if php -r "echo json_decode(file_get_contents('${CRED_FILE}'))->project_id ?? 'INVALID';" 2>/dev/null; then
        echo ""
    else
        echo "  ✗ JSON invalide"
    fi
else
    echo "  ✗ ${CRED_FILE} ABSENT!"
fi

echo ""
echo "[3] Config cache Laravel"
if [ -f "bootstrap/cache/config.php" ]; then
    CACHED_VAL=$(php -r "echo (require 'bootstrap/cache/config.php')['services']['google_vision']['enabled'] ?? 'undefined';" 2>/dev/null || echo "ERROR")
    if [[ "$CACHED_VAL" == "1" ]]; then
        echo "  ✓ Config cache: google_vision.enabled = true"
    elif [[ "$CACHED_VAL" == "" || "$CACHED_VAL" == "0" ]]; then
        echo "  ✗ Config cache: google_vision.enabled = false (stale cache!)"
        echo "    → Fix: php artisan config:clear && php artisan config:cache"
    else
        echo "  ⚠ Config cache: google_vision.enabled = ${CACHED_VAL}"
    fi
else
    echo "  ⚠ Pas de config cache (utilise .env en direct)"
fi

echo ""
echo "[4] PHP Extensions"
php -r "echo extension_loaded('grpc') ? '  ✓ grpc extension loaded' : '  ⚠ grpc extension not loaded (OK, using REST transport)';"
echo ""
php -r "echo extension_loaded('openssl') ? '  ✓ openssl extension loaded' : '  ✗ openssl extension MISSING!';"
echo ""

echo ""
echo "[5] Google Cloud Vision package"
if [ -f "vendor/google/cloud-vision/src/V1/Client/ImageAnnotatorClient.php" ]; then
    echo "  ✓ google/cloud-vision installé"
else
    echo "  ✗ google/cloud-vision NON installé! Exécuter: composer install"
fi

echo ""
echo "[6] Test artisan diagnostics"
php artisan tinker --execute="
\$s = app(\App\Services\LivenessService::class);
\$d = \$s->getDiagnostics();
echo 'enabled_config: ' . var_export(\$d['enabled_config'], true) . PHP_EOL;
echo 'enabled_runtime: ' . var_export(\$d['enabled_runtime'], true) . PHP_EOL;
echo 'client_initialized: ' . var_export(\$d['client_initialized'], true) . PHP_EOL;
echo 'credentials_exists: ' . var_export(\$d['credentials_exists'], true) . PHP_EOL;
echo 'php_version: ' . \$d['php_version'] . PHP_EOL;
" 2>/dev/null || echo "  ✗ Impossible d'exécuter le diagnostic"

echo ""
echo "[7] Logs récents liveness"
grep -i "liveness\|vision\|biométrique\|kyc" storage/logs/laravel.log 2>/dev/null | tail -10 || echo "  Aucun log récent"

echo ""
echo "=========================================="
REMOTE_DIAG

    exit 0
fi

# ---- Mode local ----
echo "=========================================="
echo "  KYC Diagnostic - Local"
echo "=========================================="
echo ""

cd "${API_DIR}"

echo "[1] Variables .env"
if grep -q "^GOOGLE_VISION_ENABLED=true" .env 2>/dev/null; then
    pass "GOOGLE_VISION_ENABLED=true"
elif grep -q "^GOOGLE_VISION_ENABLED=" .env 2>/dev/null; then
    fail "$(grep "^GOOGLE_VISION_ENABLED=" .env | head -1) (devrait être true!)"
else
    fail "GOOGLE_VISION_ENABLED absent du .env"
fi

CRED_PATH=$(grep "^GOOGLE_APPLICATION_CREDENTIALS=" .env 2>/dev/null | cut -d= -f2 || echo "")
if [ -n "${CRED_PATH}" ]; then
    pass "GOOGLE_APPLICATION_CREDENTIALS=${CRED_PATH}"
else
    fail "GOOGLE_APPLICATION_CREDENTIALS absent du .env"
fi

echo ""
echo "[2] Fichier credentials"
FULL_CRED="${API_DIR}/${CRED_PATH}"
if [ -f "${FULL_CRED}" ]; then
    pass "Fichier existe: ${FULL_CRED}"
    PROJECT=$(php -r "echo json_decode(file_get_contents('${FULL_CRED}'))->project_id ?? 'INVALID';" 2>/dev/null)
    if [ "${PROJECT}" != "INVALID" ] && [ -n "${PROJECT}" ]; then
        pass "project_id: ${PROJECT}"
    else
        fail "Contenu JSON invalide"
    fi
else
    fail "Fichier credentials introuvable: ${FULL_CRED}"
fi

echo ""
echo "[3] Config services.php"
ENABLED=$(php artisan tinker --execute="echo config('services.google_vision.enabled') ? 'true' : 'false';" 2>/dev/null || echo "ERROR")
if [[ "${ENABLED}" == *"true"* ]]; then
    pass "config('services.google_vision.enabled') = true"
else
    fail "config('services.google_vision.enabled') = ${ENABLED}"
fi

echo ""
echo "[4] Google Cloud Vision package"
if [ -f "vendor/google/cloud-vision/src/V1/Client/ImageAnnotatorClient.php" ]; then
    pass "google/cloud-vision installé"
else
    fail "google/cloud-vision manquant"
fi

echo ""
echo "[5] Service LivenessService"
DIAG=$(php artisan tinker --execute="
\$s = app(\App\Services\LivenessService::class);
\$d = \$s->getDiagnostics();
echo json_encode(\$d);
" 2>/dev/null || echo "{}")

if echo "${DIAG}" | php -r "
\$d = json_decode(file_get_contents('php://stdin'), true);
if (!is_array(\$d)) { echo 'ERROR: cannot parse diagnostics'; exit(1); }
echo 'enabled_runtime: ' . (\$d['enabled_runtime'] ? 'true' : 'false') . PHP_EOL;
echo 'client_initialized: ' . (\$d['client_initialized'] ? 'true' : 'false') . PHP_EOL;
echo 'credentials_exists: ' . (\$d['credentials_exists'] ? 'true' : 'false') . PHP_EOL;
exit(\$d['enabled_runtime'] && \$d['client_initialized'] ? 0 : 1);
" 2>/dev/null; then
    pass "Service actif et fonctionnel"
else
    fail "Service NON fonctionnel"
fi

echo ""
echo "[6] .env.example (defaults)"
EXAMPLE_VAL=$(grep "^GOOGLE_VISION_ENABLED=" .env.example 2>/dev/null | cut -d= -f2 || echo "")
if [[ "${EXAMPLE_VAL}" == "false" ]]; then
    warn ".env.example a GOOGLE_VISION_ENABLED=false (risque si copié tel quel)"
elif [[ -z "${EXAMPLE_VAL}" ]]; then
    warn "GOOGLE_VISION_ENABLED absent de .env.example"
else
    pass ".env.example: GOOGLE_VISION_ENABLED=${EXAMPLE_VAL}"
fi

echo ""
echo "=========================================="
if [ ${ERRORS} -eq 0 ]; then
    echo -e "  ${GREEN}✅ KYC opérationnel${NC}"
else
    echo -e "  ${RED}❌ ${ERRORS} problème(s) détecté(s)${NC}"
fi
echo "=========================================="
echo ""
echo "Pour tester sur le serveur: $0 --remote"
echo ""
