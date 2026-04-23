# Rotation Clés Google Cloud — Action Manuelle Requise

**URL** : https://console.cloud.google.com/apis/credentials?project=dr-pharma-6027d

## Clés à révoquer

| # | Valeur (à chercher) | Usage | Fichiers historique |
|---|---------------------|-------|---------------------|
| 1 | `AIzaSyDtk…pigSQ` | Google Maps (web + APK) | `mobile/client/config/prod.env` + `web/index.html` |
| 2 | `AIzaSyBPZ…6_EeM` | Firebase Auth (Web) | `mobile/client/web/test_otp.html` |
| 3 | `AIzaSyBuh…qf_sI` | Firebase Auth (server tests) | `scripts/*.js` |

## Étape 1 — Révoquer (invalide immédiatement les valeurs leakées)

1. GCP Console → APIs & Services → **Credentials**
2. Pour chaque clé ci-dessus : **Actions → Delete** (ou Regenerate si tu veux garder le nom)
3. Confirmer → la clé devient HTTP 403 partout

## Étape 2 — Créer nouvelles clés avec restrictions

### Nouvelle clé Google Maps (Web + Android)

- **Application restrictions** :
  - Web : HTTP referrers → `https://drlpharma.pro/*`, `https://*.drlpharma.pro/*`
  - Android : package `com.afriklab.drpharma.client` + SHA-1 fingerprint release
- **API restrictions** : Maps JavaScript API, Geocoding API, Places API, Directions API

### Nouvelle clé Firebase Web (si `test_otp.html` reste utilisé)

- **Application restrictions** : HTTP referrers → `https://drlpharma.pro/*`
- **API restrictions** : Identity Toolkit API, Firebase Installations API

*(Alternative recommandée : supprimer `mobile/client/web/test_otp.html` — outil de debug uniquement.)*

### Nouvelle clé Firebase Server (scripts de test)

- **Application restrictions** : IP addresses → IP de ton mac de dev uniquement
- **API restrictions** : Identity Toolkit, Android Device Verification

## Étape 3 — Appliquer les nouvelles clés

```bash
cd /Users/teya2023/Downloads/DR-PHARMA

# 1. Créer le fichier local (gitignored)
cp mobile/client/config/prod.env mobile/client/config/prod.env.local
# Éditer prod.env.local avec la NOUVELLE clé Maps
nano mobile/client/config/prod.env.local

# 2. Pour les scripts Node
export FIREBASE_API_KEY=<NOUVELLE_CLE_SERVER>
node scripts/firebase_check_apis.js

# 3. Pour build APK
cd mobile/client
flutter build apk --release \
  --dart-define-from-file=config/prod.env.local \
  --obfuscate --split-debug-info=../../builds/symbols/client/<version>

# 4. Pour build Web
cd /Users/teya2023/Downloads/DR-PHARMA
./scripts/inject-web-keys.sh    # injecte dans index.html
cd mobile/client
flutter build web --release --dart-define-from-file=config/prod.env.local
# APRES build: git checkout -- web/index.html    (restaure placeholder)
```

## Étape 4 — Marquer les alertes GitHub comme résolues

```bash
# Après révocation côté GCP, marquer comme revoked
for n in 2 3 4; do
  gh api -X PATCH "repos/afriklabprojet/prodapi/secret-scanning/alerts/$n" \
    -f state=resolved -f resolution=revoked
done

# Alert #1 (firebase-credentials.json) : fichier retiré du HEAD,
# mais toujours dans commit 6ee2627. Action: révoquer le service account sur GCP IAM,
# puis:
gh api -X PATCH "repos/afriklabprojet/prodapi/secret-scanning/alerts/1" \
  -f state=resolved -f resolution=revoked
```

## Étape 5 — Vérifier firebase-credentials.json (Alert #1)

**URL** : https://console.cloud.google.com/iam-admin/serviceaccounts?project=dr-pharma-6027d

1. Identifier le service account référencé dans `storage/app/firebase-credentials.json`
   (commit historique `6ee2627`). Si tu n'as plus le fichier local :
   ```bash
   git show 6ee2627:storage/app/firebase-credentials.json | grep client_email
   ```
2. IAM → Service Accounts → clic sur le SA → **Keys** → supprimer TOUTES les clés existantes
3. Créer une nouvelle clé (si nécessaire pour la prod) → télécharger JSON → déposer sur VPS uniquement :
   ```bash
   scp new-firebase-creds.json root@drlpharma.pro:/var/www/drpharma/storage/app/firebase-credentials.json
   ssh root@drlpharma.pro 'chmod 600 /var/www/drpharma/storage/app/firebase-credentials.json && chown www-data:www-data $_'
   ```
4. Laravel config `config/firebase.php` ou similaire doit pointer vers ce chemin.
