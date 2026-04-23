#!/usr/bin/env bash
# Injecte les clés API dans les fichiers web/config AVANT build Flutter web.
# Lit depuis mobile/client/config/prod.env.local (non versionné).
#
# Usage:
#   cp mobile/client/config/prod.env mobile/client/config/prod.env.local
#   # Éditer prod.env.local avec les VRAIES clés
#   ./scripts/inject-web-keys.sh
#   cd mobile/client && flutter build web --release --dart-define-from-file=config/prod.env.local
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
LOCAL_ENV="$ROOT/mobile/client/config/prod.env.local"

if [ ! -f "$LOCAL_ENV" ]; then
    echo "❌ $LOCAL_ENV introuvable"
    echo "   Créer depuis le template: cp mobile/client/config/prod.env $LOCAL_ENV"
    echo "   Puis remplir les vraies clés."
    exit 1
fi

# Charger la clé Maps
MAPS_KEY=$(grep '^GOOGLE_MAPS_API_KEY=' "$LOCAL_ENV" | cut -d= -f2-)

if [ -z "$MAPS_KEY" ] || [ "$MAPS_KEY" = "__SET_BEFORE_BUILD__" ]; then
    echo "❌ GOOGLE_MAPS_API_KEY vide ou placeholder dans $LOCAL_ENV"
    exit 1
fi

INDEX_HTML="$ROOT/mobile/client/web/index.html"
echo "🔧 Injection GOOGLE_MAPS_API_KEY dans web/index.html..."
# Utilise | comme séparateur car la clé peut contenir /
sed -i.bak "s|__GOOGLE_MAPS_API_KEY__|$MAPS_KEY|g" "$INDEX_HTML"
rm -f "$INDEX_HTML.bak"

echo "✅ Fait. Pour reverse (avant commit): git checkout -- $INDEX_HTML"
