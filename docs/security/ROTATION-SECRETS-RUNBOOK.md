# Runbook Rotation Secrets — Post-Leak .backup-api-env/

**Date leak détecté** : 23 avril 2026
**Commit orphan à GC** : `1c9aa74`
**Priorité** : P0 — exécuter AVANT envoi demande GC GitHub Support

---

## Ordre d'exécution (impact croissant)

### 1. APP_KEY Laravel (sans interruption si fait proprement)

**⚠️ Attention** : invalide toutes les sessions + cookies chiffrés + tokens signés.
Acceptable en prod si on prévient les users OU en fenêtre maintenance.

```bash
ssh root@drlpharma.pro
cd /var/www/drpharma

# Backup .env
cp .env .env.backup-$(date +%Y%m%d-%H%M%S)

# Générer nouvelle clé (ne pas écrire directement — la capturer)
NEW_KEY=$(php artisan key:generate --show)
echo "Nouvelle APP_KEY: $NEW_KEY"

# Remplacer dans .env
sed -i "s|^APP_KEY=.*|APP_KEY=$NEW_KEY|" .env

# Vider caches
php artisan config:clear && php artisan cache:clear
php artisan config:cache && php artisan route:cache

# Redémarrer queue workers (supervisor)
supervisorctl restart all

# Vérifier
php artisan tinker --execute="echo config('app.key');"
```

**Impact utilisateurs** : déconnexion forcée de tous (tokens Sanctum invalidés).

---

### 2. DB_PASSWORD MySQL (fenêtre de maintenance ~30s)

```bash
ssh root@drlpharma.pro
cd /var/www/drpharma

# Générer mot de passe fort
NEW_DB_PWD=$(openssl rand -base64 32 | tr -d '/+=' | cut -c1-24)
DB_USER=$(grep ^DB_USERNAME= .env | cut -d= -f2)
DB_NAME=$(grep ^DB_DATABASE= .env | cut -d= -f2)

# Backup .env
cp .env .env.backup-db-$(date +%Y%m%d-%H%M%S)

# Changer le password MySQL (nécessite le password root MySQL)
mysql -u root -p -e "ALTER USER '$DB_USER'@'localhost' IDENTIFIED BY '$NEW_DB_PWD'; FLUSH PRIVILEGES;"

# Mettre à jour .env
sed -i "s|^DB_PASSWORD=.*|DB_PASSWORD=$NEW_DB_PWD|" .env

# Recharger config + redémarrer php-fpm + queue
php artisan config:cache
systemctl restart php8.3-fpm
supervisorctl restart all

# Vérifier connexion DB
php artisan migrate:status 2>&1 | head -5
```

**Impact** : ~5-10s de 500 le temps que php-fpm redémarre.

---

### 3. JEKO_API_KEY + JEKO_WEBHOOK_SECRET (passerelle paiement)

**Action hors-serveur** :

1. Connexion dashboard Jeko : https://jeko.io (ou URL fournisseur)
2. Section **API Keys** → générer nouvelle clé → **copier**
3. Section **Webhooks** → régénérer secret → **copier**
4. **NE PAS désactiver l'ancienne clé immédiatement** (grace period 24h pour les paiements en cours)

```bash
ssh root@drlpharma.pro
cd /var/www/drpharma
cp .env .env.backup-jeko-$(date +%Y%m%d-%H%M%S)

# Éditer manuellement (valeurs sensibles)
nano .env
# Remplacer JEKO_API_KEY=... et JEKO_WEBHOOK_SECRET=...

php artisan config:cache
supervisorctl restart all

# Test paiement via sandbox ou montant min
```

**Après 24h** : désactiver l'ancienne clé dans le dashboard Jeko.

---

### 4. INFOBIP_API_KEY (SMS OTP)

1. Connexion Infobip Portal : https://portal.infobip.com
2. **Developers → API Keys** → *Create new* → copier
3. Ancienne clé : laisser active 1h puis révoquer

```bash
ssh root@drlpharma.pro
cd /var/www/drpharma
nano .env
# INFOBIP_API_KEY=...

php artisan config:cache
supervisorctl restart all

# Test: envoyer OTP vers numéro test
php artisan tinker --execute="\App\Services\SmsService::class; // adapter"
```

---

### 5. GOOGLE_MAPS_API_KEY

1. https://console.cloud.google.com/apis/credentials
2. **Créer une nouvelle clé** (ne pas juste régénérer — l'ancienne reste compromise)
3. **Restrictions** (OBLIGATOIRE) :
   - **Application** : HTTP referrers →
     - `https://drlpharma.pro/*`
     - `https://*.drlpharma.pro/*`
   - **API** : Maps JavaScript, Geocoding, Places (ou selon usage)
4. Supprimer l'ancienne clé APRÈS déploiement nouvelle

```bash
ssh root@drlpharma.pro
cd /var/www/drpharma
nano .env
# GOOGLE_MAPS_API_KEY=...

php artisan config:cache
```

**Côté mobile** : la clé est compilée dans l'APK/IPA → nécessite nouveau build + release des 3 apps (client, pharmacy, delivery).

```bash
# Sur mac local
cd /Users/teya2023/Downloads/DR-PHARMA/mobile/client
# Mettre à jour config/prod.env: GOOGLE_MAPS_API_KEY=...
flutter build apk --release --dart-define-from-file=config/prod.env \
  --obfuscate --split-debug-info=../../builds/symbols/client/$(grep ^version pubspec.yaml | awk '{print $2}')
# Idem pour pharmacy et delivery
```

---

## Checklist de validation post-rotation

- [ ] APP_KEY rotée — `config('app.key')` retourne nouvelle valeur
- [ ] DB_PASSWORD rotée — `php artisan migrate:status` fonctionne
- [ ] Login user test → nouveau token généré
- [ ] Paiement Jeko test (sandbox) → webhook reçu
- [ ] OTP Infobip → SMS reçu
- [ ] Carte Google Maps → s'affiche sur apps mobile + web
- [ ] Queue workers running → `supervisorctl status`
- [ ] Logs sans erreurs : `tail -100 storage/logs/laravel.log | grep -i error`
- [ ] Anciennes clés révoquées (Jeko +24h, Infobip +1h, Maps immédiat)

---

## Rollback

Chaque étape crée `.env.backup-<scope>-<timestamp>`. En cas de panne :

```bash
cd /var/www/drpharma
ls -lt .env.backup-* | head -5
cp .env.backup-XXX .env
php artisan config:cache
systemctl restart php8.3-fpm
supervisorctl restart all
```

---

## Après rotation complète

- [ ] Envoyer demande GC GitHub Support (`docs/github-support-gc-request.md`)
- [ ] Activer Secret Scanning : Settings → Code security → Secret scanning → Enable
- [ ] Activer Push Protection : même menu → Push protection → Enable
- [ ] Supprimer `.env.backup-*` des VPS après 7 jours si tout stable
