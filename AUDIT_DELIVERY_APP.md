# AUDIT COMPLET — App Delivery (DR-PHARMA Coursier)

**Date** : 24 mars 2026\
**Scope** : Flutter mobile (`mobile/delivery/`) + API Laravel (`api/`) +
Firestore\
**Fichiers analysés** : 181 fichiers Dart + backend PHP\
**Résultat** : **43 problèmes détectés** (8 CRITIQUES, 12 HAUTS, 14 MOYENS, 9
BAS)

---

## RÉSUMÉ EXÉCUTIF

| Sévérité    | Nombre | Action requise             |
| ----------- | ------ | -------------------------- |
| 🔴 CRITIQUE | 8      | Corriger immédiatement     |
| 🟠 HAUT     | 12     | Corriger avant release     |
| 🟡 MOYEN    | 14     | Planifier dans le sprint   |
| 🔵 BAS      | 9      | Backlog / bonnes pratiques |

---

## 🔴 PROBLÈMES CRITIQUES (8)

### C1. Path Traversal — SecureDocumentController (API)

**Fichier** : `api/app/Http/Controllers/Api/SecureDocumentController.php`\
**Risque** : Un attaquant peut télécharger n'importe quel fichier serveur
(`../../config/services.php`, `.env`)\
**Cause** : Le paramètre `$filename` n'est pas assaini

```php
// VULNÉRABLE
$path = "{$type}/{$filename}";
return Storage::disk('local')->download($path);
```

**Correctif** :

```php
$filename = basename($filename); // Empêcher la traversée
$path = "{$type}/{$filename}";
```

---

### C2. Endpoint Debug public — `/debug/pharmacies-audit`

**Fichier** : `api/routes/api.php` (≈L423)\
**Risque** : Toute personne peut énumérer les pharmacies, statuts et compteurs
de produits sans authentification\
**Correctif** : Supprimer ou protéger avec
`middleware(['auth:sanctum', 'admin'])`

---

### C3. Coordonnées GPS stockées en clair (SharedPreferences)

**Fichier** : `lib/core/services/background_location_service.dart` (L115-118)\
**Risque** : Historique de localisation des livreurs accessible à quiconque a
accès au device

```dart
// VULNÉRABLE
await prefs.setDouble('last_latitude', position.latitude);
await prefs.setDouble('last_longitude', position.longitude);
```

**Correctif** : Utiliser Hive chiffré via `EncryptedStorageService`

---

### C4. Règles Firestore trop permissives

**Fichier** : `firestore.rules` (L9-27)\
**Risque** : N'importe quel utilisateur authentifié peut lire la position de
TOUS les coursiers et TOUTES les livraisons

```
// VULNÉRABLE — tout authentifié peut lire tout
allow read: if request.auth != null;
```

**Correctif** :

```
// Coursiers : seul le propriétaire ou le client assigné peut lire
match /couriers/{courierId} {
  allow read: if request.auth != null 
    && (request.auth.uid == courierId 
        || request.auth.token.role == 'client');
  allow write: if request.auth.uid == courierId 
    && request.auth.token.role == 'courier';
}

// Livraisons : seuls les participants
match /deliveries/{deliveryId} {
  allow read: if request.auth != null
    && (resource.data.courier_id == request.auth.uid
        || resource.data.client_id == request.auth.uid);
}
```

---

### C5. Validation Deep Link paiement insuffisante

**Fichier** : `lib/data/services/jeko_payment_service.dart` (L317-360)\
**Risque** : Si `reference == null && _pendingPaymentReference == null`, le code
retourne silencieusement sans notifier l'UI. Un deep link malveillant peut
trigger le callback succès via URL crafted.\
**Correctif** : Ajouter une erreur stream et vérifier la correspondance des
références

---

### C6. isMinifyEnabled = false en release (APK)

**Fichier** : `android/app/build.gradle.kts` (L68-70)\
**Risque** : Le code source Dart est lisible dans l'APK. Rétro-ingénierie
facile, extraction des endpoints API et logique métier.

```kotlin
// VULNÉRABLE
isMinifyEnabled = false
isShrinkResources = false
```

**Correctif** :

```kotlin
isMinifyEnabled = true
isShrinkResources = true
```

---

### C7. Race condition — initialisation Hive chiffré

**Fichier** : `lib/core/services/encrypted_storage_service.dart` (L16-18)\
**Risque** : Appels concurrents à `initialize()` passent le check `_initialized`
avant complétion, créant des instances de cipher multiples et potentielle
corruption de données\
**Correctif** : Utiliser un `Completer` ou un lock (`synchronized` package)

---

### C8. Référence de paiement statique — race condition

**Fichier** : `lib/data/services/jeko_payment_service.dart` (L37-41)\
**Risque** : Variable `static String? _pendingPaymentReference` partagée
globalement. Si 2 paiements lancés rapidement, le second écrase la référence du
premier → paiements mal attribués\
**Correctif** : Utiliser un `Map<String, Completer>` pour gérer les paiements
concurrents

---

## 🟠 PROBLÈMES HAUTS (12)

### H1. Token exposé dans background task

**Fichier** : `background_location_service.dart` (L128-130)\
Le token est utilisé dans le service background sans vérification de
validité/expiration. Si le token est révoqué, le background continue d'envoyer
des requêtes avec un token invalide.

### H2. StreamController non garanti disposé

**Fichier** : `auth_session_service.dart` (L21)\
`StreamController.broadcast()` créé mais `dispose()` n'est jamais forcé d'être
appelé. Le stream reste ouvert → fuite mémoire sur les sessions longues.

### H3. Stream de position non annulé correctement

**Fichier** : `live_tracking_service.dart` (L89-98)\
Si `stopLiveTracking()` est appelé avant que `_positionSubscription` soit
initialisé, le stream continue. Pas de handler `onError` sur la souscription.

### H4. Timer resource leak

**Fichier** : `live_tracking_service.dart` (L119-126)\
`_updateTimer?.cancel()` sans vérification null complète. Si appelé avant l'init
du timer, possible erreur runtime.

### H5. Fire-and-forget `goOffline()` sans gestion d'erreur

**Fichier** : `firestore_tracking_service.dart` (L219)\
Le coursier reste "en ligne" dans Firestore si `goOffline()` échoue
silencieusement dans `dispose()`.

### H6. Brute force PIN sans rate limiting distribué

**Fichier API** : `WalletController.php` (L140)\
La vérification PIN (4 chiffres = 10,000 combinaisons) n'a que la validation
Laravel. Pas de protection Redis/cache contre les tentatives multiples.

### H7. Geofencing resources non nettoyées

**Fichier** : `home_screen.dart` dispose\
`clearAllZones()` pas appelé → les zones persistent après destruction du widget.

### H8. Polling timer paiement jamais annulé en cas d'échec

**Fichier** : `payment_webview_screen.dart` (L93)\
Le Timer.periodic continue si l'API de vérification échoue sans jamais
converger. Drain batterie + réseau.

### H9. URL matching paiement par substring

**Fichier** : `payment_webview_screen.dart` (L103-110)\
`url.contains(path)` au lieu de `uri.path == path`. Un attaquant peut crafter
une URL contenant le path de succès dans un paramètre query.

### H10. Webhook IP whitelist vide par défaut

**Fichier API** : `JekoWebhookController.php`\
Si `JEKO_WEBHOOK_IPS` n'est pas configuré, TOUTE IP peut envoyer des webhooks
(protection HMAC existe mais défense en profondeur manquante).

### H11. CORS credentials + origine par défaut localhost

**Fichier** : `api/config/cors.php` (L49)\
`supports_credentials: true` avec `FRONTEND_URL` par défaut
`http://localhost:3000`. En prod si non configuré, les requêtes localhost sont
acceptées.

### H12. Dual source of truth — `_isOnline` dans HomeScreen

**Fichier** : `home_screen.dart` (L34, L105-110)\
L'état online/offline a deux sources (variable locale + provider), créant des
désynchronisations où l'UI montre "en ligne" alors que le backend est "hors
ligne".

---

## 🟡 PROBLÈMES MOYENS (14)

| #   | Fichier                            | Problème                                                                          |
| --- | ---------------------------------- | --------------------------------------------------------------------------------- |
| M1  | `cache_service.dart` L207          | Timestamp corrompu dans le cache → suppression silencieuse sans validation        |
| M2  | `auth_session_service.dart` L54-83 | Reset flag 2s après expiration → re-login rapide ignoré                           |
| M3  | `location_service.dart` L152-180   | Stream subscription sans handler onError/onDone                                   |
| M4  | `connectivity_service.dart` L38-47 | `_pingDio` lazy init non thread-safe                                              |
| M5  | `offline_service.dart` L120-148    | Données livrée désérialisées sans validation                                      |
| M6  | `home_screen.dart` L89-98          | Geofence subscription dupliquée possible si widget reconstruit                    |
| M7  | `wallet_data.dart` L49-62          | Fallback DateTime.now() silencieux sur parse échoué → mauvais timestamps          |
| M8  | `user.dart` L45-50                 | `_forceInt()` convertit null → 0 pour les IDs → requêtes API incorrectes          |
| M9  | `delivery.dart` L14-18             | Coordonnées toutes nullables → crash possible sur la carte si manquantes          |
| M10 | `wallet_screen.dart` L15-17        | Provider redéfini localement → conflit avec wallet_provider.dart                  |
| M11 | `history_providers.dart` L66-75    | Mix `ref.watch()`/`ref.read()` → rebuilds inutiles                                |
| M12 | `api/routes/api.php` L160          | Routes KYC sans middleware `courier` → rôle customer peut potentiellement accéder |
| M13 | `api/InventoryController.php`      | Multi-pharmacie → `first()` ne vérifie pas quelle pharmacie                       |
| M14 | API                                | Pas de headers de sécurité (`X-Content-Type-Options`, `X-Frame-Options`, `HSTS`)  |

---

## 🔵 PROBLÈMES BAS (9)

| #  | Problème                                                                                           |
| -- | -------------------------------------------------------------------------------------------------- |
| B1 | `background_location_service.dart` — constantes strings dupliquées (`background_location_enabled`) |
| B2 | `live_tracking_service.dart` — pas de retry si Firestore heartbeat échoue                          |
| B3 | `safe_json_utils.dart` — pas de validation format avant parse string → int/double                  |
| B4 | `cache_service.dart` — TTLs hardcodés au lieu de AppConfig                                         |
| B5 | `connectivity_service.dart` — flag `_disposed` pas volatile                                        |
| B6 | `profile_provider.dart` — pas de cache, refetch à chaque render                                    |
| B7 | Mots magiques (status values, URLs) dispersés dans le code au lieu de constantes                   |
| B8 | `const` keywords manquants dans plusieurs écrans (performance mineure)                             |
| B9 | `change_password_screen.dart` — scoring force mot de passe incohérent                              |

---

## ARCHITECTURE — POINTS POSITIFS ✅

| Aspect              | Statut  | Notes                                                 |
| ------------------- | ------- | ----------------------------------------------------- |
| State Management    | ✅ Bien | Riverpod correctement utilisé, providers scopés       |
| Auth Flow           | ✅ Bien | Sanctum + Firebase dual-auth, token sécurisé          |
| Error Handling      | ✅ Bien | Chaîne d'erreur transparente (fix session précédente) |
| Offline Mode        | ✅ Bien | Cache Hive + sync manager                             |
| Retry Logic         | ✅ Bien | Backoff exponentiel + jitter                          |
| HMAC Webhooks       | ✅ Bien | `hash_equals()` timing-safe                           |
| Session Expiry      | ✅ Bien | Listener global + redirect auto                       |
| Splash Non-blocking | ✅ Bien | Aucun async avant runApp()                            |
| 422 Handling        | ✅ Bien | Erreurs Laravel propagées proprement                  |

---

## PLAN D'ACTION RECOMMANDÉ

### Sprint 1 — Sécurité critique (immédiat)

1. [ ] **C1** — Ajouter `basename()` dans SecureDocumentController
2. [ ] **C2** — Supprimer ou protéger `/debug/pharmacies-audit`
3. [ ] **C4** — Réécrire les règles Firestore avec ownership
4. [ ] **C6** — Activer `isMinifyEnabled = true` dans build.gradle.kts
5. [ ] **H9** — Corriger URL matching paiement (uri.path au lieu de contains)
6. [ ] **H6** — Rate limiting distribué pour PIN brute force

### Sprint 2 — Fiabilité (cette semaine)

7. [ ] **C3** — Migrer location storage vers Hive chiffré
8. [ ] **C5** — Renforcer validation deep link paiement
9. [ ] **C7** — Ajouter Completer pour init Hive thread-safe
10. [ ] **H2** — Garantir disposal de StreamController
11. [ ] **H3/H4** — Corriger streams et timers dans live_tracking
12. [ ] **H5** — Loguer erreurs goOffline dans Firestore tracking

### Sprint 3 — Robustesse (cette semaine)

13. [ ] **H8** — Timer polling paiement avec max attempts
14. [ ] **H12** — Unifier source of truth `_isOnline`
15. [ ] **M8** — Lancer erreur au lieu de ID=0 silencieux
16. [ ] **M10** — Supprimer provider wallet redéfini localement
17. [ ] **M14** — Ajouter security headers côté API

### Backlog

18. [ ] Tous les problèmes MOYENS (M1-M14) restants
19. [ ] Tous les problèmes BAS (B1-B9)
