# CHANGELOG - Module Adresses

Tous les changements notables du module d'adresses seront documentés dans ce fichier.

## [2.0.0] - 2026-04-09

### ✨ Ajouté
- **Nouveau widget `AddressCard`** : Widget réutilisable et hautement configurable
  - Support du swipe-to-delete avec confirmation
  - Affichage enrichi des détails (téléphone, instructions, GPS)
  - Badge visuel pour l'adresse par défaut
  - Menu d'actions contextuel
  - Animations d'entrée fluides

- **Fonctionnalité de recherche** : Recherche locale par nom, adresse ou ville
  - S'active automatiquement si plus de 3 adresses
  - Filtrage en temps réel
  - Interface de dialogue dédiée

- **Animations de liste** : 
  - Effet stagger pour l'apparition progressive des cartes
  - Transitions de fondu et glissement
  - Animation controller avec gestion du cycle de vie

- **Feedbacks visuels enrichis** :
  - Snackbars avec icônes pour chaque action
  - Confirmations avant suppression
  - Indicateur de chargement linéaire
  - États vides et d'erreur améliorés

- **Widget `_AddressListSkeleton`** : Skeleton loading personnalisé
  - Imite la structure finale des cartes
  - Animation shimmer intégrée
  - Meilleure expérience de chargement

- **Tests unitaires complets** :
  - Couverture > 90% du widget AddressCard
  - Tests d'interaction (tap, swipe, menu)
  - Tests d'affichage conditionnel
  - Tests des dialogues de confirmation

- **Documentation complète** :
  - Guide d'amélioration (ADDRESSES_IMPROVEMENTS.md)
  - Guide de migration (ADDRESSES_MIGRATION_GUIDE.md)
  - Exemples de code et patterns
  - Résolution de problèmes courants

### 🎨 Amélioré
- **Design des cartes d'adresses** :
  - Bordure spéciale pour l'adresse par défaut
  - Icônes contextuelles pour chaque information
  - Meilleure hiérarchie visuelle
  - Section dédiée pour les informations optionnelles
  - Coins arrondis et élévation moderne

- **États de l'interface** :
  - État d'erreur avec icône et CTA clair
  - État vide avec illustration engageante
  - Messages d'erreur plus explicites
  - Design responsive et adaptatif

- **Organisation du code** :
  - Séparation du widget AddressCard dans son propre fichier
  - Méthodes handler dédiées pour chaque action
  - Meilleure gestion du state management
  - Code plus maintenable et testable

- **Performances** :
  - Utilisation de ValueKey pour optimisation du rendu
  - Gestion propre des animations (dispose)
  - Filtrage local sans appels API supplémentaires

### 🔄 Modifié
- **`addresses_list_page.dart`** :
  - Refactoring complet avec SingleTickerProviderStateMixin
  - Extraction de la logique dans des méthodes dédiées
  - Migration vers le nouveau widget AddressCard
  - Ajout d'un AnimationController pour les animations

- **FAB (Floating Action Button)** :
  - Changement de `FloatingActionButton` vers `FloatingActionButton.extended`
  - Ajout d'une icône spécifique (`add_location_alt_outlined`)
  - Meilleure visibilité et accessibilité

- **AppBar** :
  - Ajout d'un bouton de recherche (si > 3 adresses)
  - Tooltip ajouté pour l'accessibilité

### 🗑️ Supprimé
- Ancien widget `_AddressCard` intégré dans la page
- Code dupliqué pour l'affichage des états
- Logique inline dans les callbacks

### 🐛 Corrigé
- Gestion du `mounted` check avant l'affichage des Snackbars
- Dispose proper de l'AnimationController
- Keys manquantes dans les listes pour de meilleures performances
- Gestion des addresses sans détails optionnels

### 🔒 Sécurité
- Confirmation obligatoire avant suppression d'adresse
- Validation du contexte avant navigation
- Gestion d'erreur robuste dans tous les callbacks

## [1.0.0] - Date antérieure

### Version initiale
- Liste basique d'adresses
- CRUD simple (Create, Read, Update, Delete)
- Gestion des adresses par défaut
- États de chargement et d'erreur basiques

---

## Types de changements

- `✨ Ajouté` : Nouvelles fonctionnalités
- `🎨 Amélioré` : Améliorations de l'existant
- `🔄 Modifié` : Changements dans les fonctionnalités existantes
- `🗑️ Supprimé` : Fonctionnalités retirées
- `🐛 Corrigé` : Corrections de bugs
- `🔒 Sécurité` : Correctifs de sécurité
- `⚡ Performance` : Améliorations de performance
- `📝 Documentation` : Changements de documentation

## Notes de migration

### De v1.0.0 vers v2.0.0

1. **Import nécessaire** :
   ```dart
   import '../widgets/address_card.dart';
   // ou
   import '../widgets/widgets.dart';
   ```

2. **Remplacement du widget** :
   - Ancien : `_AddressCard(...)` 
   - Nouveau : `AddressCard(...)`

3. **Ajout de keys** :
   ```dart
   AddressCard(
     key: ValueKey(address.id), // Important !
     ...
   )
   ```

4. **Handlers recommandés** :
   - Créer des méthodes `_handleX()` pour chaque action
   - Vérifier `mounted` avant les opérations async

5. **Tests** :
   - Ajouter des tests pour vos nouveaux usages du widget
   - S'inspirer de `address_card_test.dart`

Pour plus de détails, consultez [ADDRESSES_MIGRATION_GUIDE.md](./ADDRESSES_MIGRATION_GUIDE.md).

---

**Contributeurs** : Senior Fullstack Team
**Dernière mise à jour** : 9 avril 2026
