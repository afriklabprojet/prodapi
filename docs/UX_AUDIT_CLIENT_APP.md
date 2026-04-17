# 🔍 Audit UX — DR-PHARMA Client Mobile

**Date** : Juin 2025  
**Périmètre** : Application Flutter Client (`mobile/client/`)  
**Auditeur** : Expert UX/UI  
**Score global** : **7.5 / 10**

---

## 📊 Synthèse Exécutive

L'application DR-PHARMA présente une **base UX solide** avec un design system Material 3 mature, un support dark mode étendu, et des patterns modernes (shimmer, empty states, haptic feedback). L'architecture est ambitieuse (46 pages, 12 modules) et la couverture fonctionnelle est impressionnante pour une app de pharmacie en ligne.

**Points forts majeurs** : design premium cohérent, gestion offline, accessibilité partielle, protection des données non sauvées.

**Faiblesses structurelles** : 31 `GestureDetector` sans feedback ripple, 0 animation de transition entre pages, dark mode incomplet sur certains écrans, fichiers trop longs (6 fichiers > 1000 lignes).

---

## 📱 Périmètre Audité

| Catégorie | Détail |
|-----------|--------|
| **Pages** | 46 pages, 12 modules feature |
| **Routes** | ~35 routes GoRouter avec auth guard |
| **Navigation** | 4 onglets bottom nav (Accueil, Commandes, Portefeuille, Profil) |
| **Design System** | Material 3 + tokens custom (couleurs, typo, dimensions) |
| **Widgets partagés** | 10 core widgets (shimmer, empty state, connectivity banner...) |
| **Services** | 26+ services (Firebase, analytics, OTP, tracking, offline queue...) |

---

## 🏆 Scorecard par Écran

| # | Écran | Lignes | Dark Mode | Empty State | Error State | Loading | A11y | Score |
|---|-------|--------|-----------|-------------|-------------|---------|------|-------|
| 1 | **Panier** | 477 | ✅ | ✅ | ✅ | ⚠️ | ✅✅ | **8.5** |
| 2 | **Checkout** | 644 | ⚠️ cassé | N/A | ✅ | ✅ | ✅ | **7.0** |
| 3 | **Liste commandes** | 491 | ✅ | ✅ | ✅ | ✅ | ✅ | **8.0** |
| 4 | **Détail commande** | 1072 | ⚠️ partiel | ✅ | ✅ | ✅ | ⚠️ | **7.5** |
| 5 | **Tracking livreur** | 823 | ❌ absent | ⚠️ | ✅ | ✅ | ❌ | **6.5** |
| 6 | **Détail produit** | 1014 | ✅ | N/A | ✅ | ⚠️ | ✅ | **8.0** |
| 7 | **Liste pharmacies** | 1391 | ✅ | ⚠️ | ✅ | ✅ | ⚠️ | **7.5** |
| 8 | **Détail pharmacie** | 1354 | ✅ | ✅ | ✅ | ⚠️ | ⚠️ | **7.0** |
| 9 | **Profil** | 1227 | ✅ | ✅ | ✅ | ✅ | ⚠️ | **8.0** |
| 10 | **Portefeuille** | 1115 | ⚠️ partiel | ✅ | ✅ | ✅ | ⚠️ | **7.5** |
| 11 | **Upload ordonnance** | 587 | ✅ | ✅ | ✅ | ✅ | ⚠️ | **8.0** |
| 12 | **Adresses** | 394 | ⚠️ partiel | ✅ | ✅ | ✅ | ⚠️ | **7.5** |
| 13 | **Chat livreur** | ~500 | ⚠️ | ✅ | ✅ | ✅ | ⚠️ | **7.5** |
| 14 | **Traitements** | ~600 | ✅ | ✅ | ✅ | ✅ | ✅ | **8.0** |
| 15 | **Fidélité** | ~500 | ⚠️ | ✅ | ❌ | ✅ | ⚠️ | **7.0** |
| 16 | **Notifications** | ~400 | ⚠️ | ✅ | ✅ | ✅ | ✅ | **7.0** |
| 17 | **Router** | ~400 | — | — | ✅ | — | — | **7.0** |
| 18 | **Quick Actions** | ~200 | ✅ | — | — | — | ✅ | **8.0** |

---

## 🔴 Problèmes Critiques (P0)

### 1. Zero Animation de Transition — Router

**Impact** : Toute la navigation est abrupte. Les pages apparaissent/disparaissent instantanément.

**Cause** : `app_router.dart` utilise `builder:` au lieu de `pageBuilder:` avec `CustomTransitionPage`.

**Fix** : Ajouter des transitions globales (slide horizontal pour push, fade pour les modals).

```dart
// Exemple de fix dans le router
pageBuilder: (context, state) => CustomTransitionPage(
  child: const MyPage(),
  transitionsBuilder: (context, animation, secondaryAnimation, child) =>
    SlideTransition(
      position: Tween(begin: const Offset(1, 0), end: Offset.zero)
        .animate(CurvedAnimation(parent: animation, curve: Curves.easeInOut)),
      child: child,
    ),
),
```

---

### 2. Dark Mode Cassé — Checkout + Tracking

**Impact** : En dark mode, certaines sections deviennent illisibles (texte sombre sur fond sombre).

**Checkout** : `_buildAddressSummary` et `_buildPaymentSummary` utilisent `Colors.grey[50]` / `Colors.grey[200]!`.

**Tracking** : Aucune vérification `Brightness.dark` dans les overlays/cards de la page.

**Fix** : Remplacer les couleurs hardcodées par `context.cardBackground` / `Theme.of(context).colorScheme.surface`.

---

### 3. 31 GestureDetector sans Feedback Material

**Impact** : Pas d'effet ripple → l'utilisateur ne sait pas si son tap a été enregistré. Non conforme Material Design Guidelines.

**Distribution** :

| Zone | Instances | Fichiers principaux |
|------|-----------|-------------------|
| Home widgets | 8 | `quick_actions_grid`, `favorite_products`, `home_search_bar` |
| Products | 5 | `all_products_page`, `favorites_page` |
| Profile | 3 | `profile_page` |
| Orders | 5 | `tracking_page`, `order_details_page`, `rating_bottom_sheet` |
| Autres | 10 | `loyalty_page`, `smart_refill_banner`, `on_duty_map`... |

**Fix** : Migration progressive `GestureDetector` → `InkWell` (avec `Material` parent et `borderRadius`) ou widgets Material natifs.

---

## 🟡 Problèmes Importants (P1)

### 4. Fichiers > 1000 Lignes (Maintenabilité)

6 fichiers dépassent 1000 lignes, rendant la maintenance et les tests difficiles :

| Fichier | Lignes |
|---------|--------|
| `pharmacies_list_page_v2.dart` | 1391 |
| `pharmacy_details_page.dart` | 1354 |
| `profile_page.dart` | 1227 |
| `wallet_page.dart` | 1115 |
| `order_details_page.dart` | 1072 |
| `product_details_page.dart` | 1014 |

**Recommandation** : Extraire les sections en sous-widgets (`_StatusCard` → `OrderStatusCard`, etc.).

---

### 5. Shimmer Loading pas Dark-Mode Aware

**Impact** : Les skeletons shimmer utilisent `AppColors.shimmerBase` (#E0E0E0) fixe → gris clair sur fond sombre en dark mode.

**Fix** : Adapter `shimmerBase`/`shimmerHighlight` selon `Theme.of(context).brightness`.

---

### 6. Navigation Incohérente (GoRouter vs Navigator.push)

Certains écrans utilisent `Navigator.push` ou `Navigator.pushNamed` au lieu de GoRouter :

| Écran | Problème |
|-------|----------|
| `prescription_upload_page.dart` | `Navigator.pushNamed('/login')` |
| `wallet_page.dart` (TopUp) | `Navigator.push` Material route |

**Impact** : Deep links cassés, historique de navigation incohérent, perte de contexte.

---

### 7. Accessibilité Incomplète sur Certains Écrans

**Bien fait** : `cart_page` (Semantics riches), `quick_actions_grid` (Semantics.button + label).

**Manquant** :
- Tracking page : aucun `Semantics` sur la carte ou les contrôles
- Pharmacy details : quick actions (Appeler/Email/Itinéraire) sans labels
- Loyalty page : bouton "Échanger" potentiellement < 48dp
- Notifications : bottom sheet sans adaptation dark mode
- Profile : `GestureDetector` edit sans tooltip/Semantics

---

## 🟢 Problèmes Mineurs (P2)

### 8. Chat Livreur — Détails Clavier

- `textInputAction` n'est pas défini comme `TextInputAction.send` → le clavier affiche "Retour"
- Pas de scroll automatique quand le clavier apparaît
- Pas d'indicateur "en train de taper"

### 9. Notifications — Groupement Temporel Manquant

La liste de notifications est plate. Pas de sections "Aujourd'hui", "Hier", "Plus ancien" → difficile de naviguer dans l'historique.

### 10. Fidélité — Pas d'Historique de Points

L'utilisateur voit son solde de points mais ne peut pas voir quand/comment il les a gagnés.

### 11. Traitements — Pas de Vue "Prises du Jour"

La page liste les traitements mais ne montre pas une vue calendrier/timeline des prises quotidiennes.

### 12. Panier → Checkout — Stock Non Vérifié

Le CTA "Passer la commande" peut être validé même avec des articles en "stock insuffisant".

### 13. Product Details — Back Button Potentiellement Invisible

Le `BackButton(color: AppColors.textPrimary)` sur le SliverAppBar transparent peut être invisible sur des images produit sombres.

### 14. Pharmacie Détails — Pas de Catalogue Produits

L'utilisateur ne peut pas voir/commander les produits d'une pharmacie depuis sa page détaillée.

### 15. Router — Route `editTreatment` sans null-check

`state.extra as TreatmentEntity` crashe si accédé via deep link sans extra.

---

## 💪 Forces UX Majeures

### Ce qui est Excellent

| # | Pattern | Où |
|---|---------|-----|
| 1 | **Design Premium Cohérent** — gradients, blur, shadows, animations d'entrée | Pharmacy details, Profile, Quick Actions |
| 2 | **Gestion Offline Complète** — `ConnectivityBanner` + `OfflineQueue` + cache | Global |
| 3 | **Undo Pattern** — suppression avec annulation dans le panier | Cart |
| 4 | **Stale Position Detection** — avertissement quand le tracking est périmé | Tracking |
| 5 | **PopScope Guard** — protection contre la perte de données non sauvées | Prescription Upload |
| 6 | **Semantics Riches** — labels complets sur les items panier | Cart, Product Details |
| 7 | **Error Handling Granulaire** — messages spécifiques par code HTTP | Prescription Upload |
| 8 | **Gamification** — tiers fidélité, badges profil, stats commandes | Profile, Loyalty |
| 9 | **Smart Refill** — rappels proactifs de renouvellement | Home |
| 10 | **Responsive Utils** — breakpoints mobile/tablet/desktop | Global |
| 11 | **Material 3** — design system complet light + dark | Theme |
| 12 | **Duplicate Detection** — empêche les soumissions en double | Prescriptions |
| 13 | **Deep Link Support** — App Links Android + pending deep link storage | Router |
| 14 | **Haptic Feedback** — retour tactile sur les interactions importantes | Bottom nav, Orders, Product |
| 15 | **Auto-scroll Carousels** — pharmacies (3s) + promos (4s) | Home |

---

## 📋 Plan d'Action Recommandé

### Sprint 1 — Quick Wins (Impact élevé, Effort faible)

| # | Action | Fichiers | Effort |
|---|--------|----------|--------|
| 1 | Ajouter transitions router (fade/slide) | `app_router.dart` | 1h |
| 2 | Fix dark mode checkout (couleurs hardcodées) | `checkout_page.dart` | 30min |
| 3 | Fix dark mode tracking page | `tracking_page.dart` | 1h |
| 4 | Fix shimmer dark mode | `shimmer_loading.dart` | 20min |
| 5 | `textInputAction.send` sur le chat | `courier_chat_page.dart` | 5min |
| 6 | Fix navigation incohérente (GoRouter partout) | `prescription_upload_page.dart`, `wallet_page.dart` | 30min |

### Sprint 2 — GestureDetector Migration

| # | Action | Instances | Effort |
|---|--------|-----------|--------|
| 7 | Remplacer `GestureDetector` → `InkWell`/Material | 31 instances, ~15 fichiers | 3h |

### Sprint 3 — Améliorations UX

| # | Action | Fichiers | Effort |
|---|--------|----------|--------|
| 8 | Groupement notifications par date | `notifications_page.dart` | 2h |
| 9 | Historique points fidélité | `loyalty_page.dart` + API | 4h |
| 10 | Validation stock avant checkout | `cart_page.dart` | 1h |
| 11 | Back button avec fond sur product details | `product_details_page.dart` | 15min |
| 12 | Améliorer message tracking sans livreur | `tracking_page.dart` | 30min |

### Sprint 4 — Refactoring & Maintenabilité

| # | Action | Fichiers | Effort |
|---|--------|----------|--------|
| 13 | Décomposer fichiers > 1000 lignes | 6 fichiers | 8h |
| 14 | Audit Semantics complet | Tous les écrans | 4h |
| 15 | Supprimer `state_widgets.dart` (deprecated) | `state_widgets.dart` | 15min |

---

## 📈 Métriques Post-Audit Attendues

| Métrique | Avant | Cible |
|----------|-------|-------|
| Score UX global | 7.5/10 | **9.0/10** |
| GestureDetector sans ripple | 31 | **0** |
| Fichiers > 1000 lignes | 6 | **0** |
| Écrans sans dark mode | 3 | **0** |
| Transitions de navigation | 0 | **35** (toutes les routes) |
| Couverture Semantics | ~60% | **95%** |

---

*Cet audit couvre l'ensemble de l'application client (46 pages, 12 modules). Les recommandations sont classées par ratio impact/effort pour un déploiement progressif.*
