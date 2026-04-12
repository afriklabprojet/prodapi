# Guide de Migration - Module Traitements

## 🎯 Introduction

Ce guide explique comment utiliser les nouveaux composants du module traitements et comment migrer du code existant.

## 📦 Import des nouveaux composants

```dart
// Nouveaux widgets
import 'package:drpharma_client/features/treatments/presentation/widgets/widgets.dart';

// Nouvelle page principale
import 'package:drpharma_client/features/treatments/presentation/pages/treatments_list_page.dart';
```

## 🧩 Utilisation des widgets

### 1. TreatmentCard

Widget principal pour afficher une carte de traitement avec animations.

**Exemple complet** :

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drpharma_client/features/treatments/presentation/widgets/widgets.dart';

class MyTreatmentList extends ConsumerWidget {
  const MyTreatmentList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final treatments = ref.watch(treatmentsProvider).treatments;

    return ListView.builder(
      itemCount: treatments.length,
      itemBuilder: (context, index) {
        return TreatmentCard(
          treatment: treatments[index],
          animationDelay: index * 50, // Stagger de 50ms par carte
          onTap: () => _showDetails(context, treatments[index]),
          onDelete: () => _deleteTreatment(ref, treatments[index]),
          onOrder: () => _orderTreatment(ref, treatments[index]),
          onToggleReminder: () => _toggleReminder(ref, treatments[index]),
        );
      },
    );
  }

  void _showDetails(BuildContext context, TreatmentEntity treatment) {
    // Afficher le détail
  }

  void _deleteTreatment(WidgetRef ref, TreatmentEntity treatment) {
    ref.read(treatmentsProvider.notifier).deleteTreatment(treatment.id!);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Traitement supprimé')),
    );
  }

  void _orderTreatment(WidgetRef ref, TreatmentEntity treatment) {
    // Ajouter au panier
  }

  void _toggleReminder(WidgetRef ref, TreatmentEntity treatment) {
    ref.read(treatmentsProvider.notifier).toggleReminder(treatment.id!);
  }
}
```

**Propriétés disponibles** :

| Propriété | Type | Requis | Description |
|-----------|------|--------|-------------|
| `treatment` | `TreatmentEntity` | ✅ | Le traitement à afficher |
| `animationDelay` | `int` | ❌ | Délai d'animation en ms (défaut: 0) |
| `onTap` | `VoidCallback?` | ❌ | Callback au tap sur la carte |
| `onDelete` | `VoidCallback?` | ❌ | Callback pour supprimer |
| `onOrder` | `VoidCallback?` | ❌ | Callback pour commander |
| `onToggleReminder` | `VoidCallback?` | ❌ | Callback pour le rappel |

**Comportements automatiques** :
- ✅ Swipe-to-delete si `onDelete` fourni
- ✅ Bouton commander si `onOrder` fourni
- ✅ Toggle rappel si `onToggleReminder` fourni
- ✅ Badge "En retard" si traitement en retard
- ✅ Badge "Dans X j" si renouvellement proche
- ✅ Bordure rouge si en retard, orange si urgent

### 2. TreatmentCardSkeleton

Widget de chargement animé pour afficher pendant le chargement initial.

**Exemple** :

```dart
class TreatmentsLoading extends StatelessWidget {
  const TreatmentsLoading({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: 3, // Afficher 3 skeletons
      itemBuilder: (context, index) {
        return const TreatmentCardSkeleton();
      },
    );
  }
}
```

**Utilisation avec état** :

```dart
class TreatmentsListWidget extends ConsumerWidget {
  const TreatmentsListWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(treatmentsProvider);

    return state.when(
      loading: () => ListView.builder(
        itemCount: 3,
        itemBuilder: (context, index) => const TreatmentCardSkeleton(),
      ),
      loaded: (treatments) => ListView.builder(
        itemCount: treatments.length,
        itemBuilder: (context, index) => TreatmentCard(
          treatment: treatments[index],
          animationDelay: index * 50,
        ),
      ),
      error: (message) => TreatmentsErrorState(
        message: message,
        onRetry: () => ref.read(treatmentsProvider.notifier).loadTreatments(),
      ),
    );
  }
}
```

### 3. TreatmentsEmptyState

Widget pour afficher un état vide avec un message et un bouton optionnel.

**Exemple simple** :

```dart
class NoTreatmentsView extends StatelessWidget {
  const NoTreatmentsView({super.key});

  @override
  Widget build(BuildContext context) {
    return TreatmentsEmptyState(
      message: 'Aucun traitement enregistré',
      onAdd: () => Navigator.pushNamed(context, '/add-treatment'),
    );
  }
}
```

**Exemple sans bouton** :

```dart
TreatmentsEmptyState(
  message: 'Aucun résultat pour cette recherche',
  onAdd: null, // Pas de bouton
)
```

### 4. TreatmentsErrorState

Widget pour afficher une erreur avec possibilité de réessayer.

**Exemple** :

```dart
class TreatmentsErrorView extends ConsumerWidget {
  const TreatmentsErrorView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return TreatmentsErrorState(
      message: 'Impossible de charger les traitements',
      onRetry: () {
        ref.read(treatmentsProvider.notifier).loadTreatments();
      },
    );
  }
}
```

## 🔄 Migration du code existant

### Avant (ancien treatment_card.dart)

```dart
// Ancienne manière
class OldTreatmentsList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Treatment>>(
      future: loadTreatments(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return CircularProgressIndicator(); // ❌ Pas de skeleton
        }
        
        if (snapshot.hasError) {
          return Text('Erreur'); // ❌ Pas de widget erreur
        }

        final treatments = snapshot.data ?? [];
        
        if (treatments.isEmpty) {
          return Text('Aucun traitement'); // ❌ Pas de widget vide
        }

        return ListView.builder(
          itemCount: treatments.length,
          itemBuilder: (context, index) {
            return TreatmentCard( // ❌ Ancien widget sans animations
              treatment: treatments[index],
            );
          },
        );
      },
    );
  }
}
```

### Après (nouvelle version)

```dart
// Nouvelle manière avec Riverpod et nouveaux widgets
class NewTreatmentsList extends ConsumerWidget {
  const NewTreatmentsList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(treatmentsProvider);

    if (state.status == TreatmentsStatus.loading) {
      return ListView.builder( // ✅ Skeleton loading
        itemCount: 3,
        itemBuilder: (context, index) => const TreatmentCardSkeleton(),
      );
    }

    if (state.status == TreatmentsStatus.error) {
      return TreatmentsErrorState( // ✅ Widget erreur avec retry
        message: state.errorMessage ?? 'Erreur inconnue',
        onRetry: () => ref.read(treatmentsProvider.notifier).loadTreatments(),
      );
    }

    final treatments = state.treatments;

    if (treatments.isEmpty) {
      return TreatmentsEmptyState( // ✅ Widget vide avec CTA
        message: 'Aucun traitement enregistré',
        onAdd: () => Navigator.pushNamed(context, '/add-treatment'),
      );
    }

    return ListView.builder(
      itemCount: treatments.length,
      itemBuilder: (context, index) {
        return TreatmentCard( // ✅ Nouveau widget avec animations
          treatment: treatments[index],
          animationDelay: index * 50, // ✅ Stagger animation
          onTap: () => _showDetails(context, treatments[index]),
          onDelete: () => _deleteTreatment(ref, treatments[index]),
          onOrder: () => _orderTreatment(ref, treatments[index]),
          onToggleReminder: () => _toggleReminder(ref, treatments[index]),
        );
      },
    );
  }

  void _showDetails(BuildContext context, TreatmentEntity treatment) { /* ... */ }
  void _deleteTreatment(WidgetRef ref, TreatmentEntity treatment) { /* ... */ }
  void _orderTreatment(WidgetRef ref, TreatmentEntity treatment) { /* ... */ }
  void _toggleReminder(WidgetRef ref, TreatmentEntity treatment) { /* ... */ }
}
```

## 🎨 Personnalisation

### Personnaliser les animations

**Modifier le délai d'animation** :

```dart
// Animation rapide
TreatmentCard(
  treatment: treatment,
  animationDelay: 0, // Pas de délai
)

// Animation lente
TreatmentCard(
  treatment: treatment,
  animationDelay: 200, // 200ms de délai
)

// Stagger classique
TreatmentCard(
  treatment: treatment,
  animationDelay: index * 50, // 50ms entre chaque carte
)
```

### Personnaliser les couleurs

Les couleurs sont issues de `AppColors`. Pour personnaliser :

```dart
// Dans votre thème
class AppColors {
  static const Color primary = Color(0xFF1976D2);
  static const Color error = Color(0xFFD32F2F);
  static const Color warning = Color(0xFFF57C00);
  static const Color success = Color(0xFF388E3C);
}
```

### Ajouter des actions personnalisées

**Exemple : Ajouter un bouton "Partager"** :

```dart
// Modifier widgets.dart pour ajouter un bouton
Row(
  children: [
    // Boutons existants...
    IconButton(
      icon: const Icon(Icons.share),
      onPressed: () => _shareTreatment(treatment),
    ),
  ],
)
```

## 🔍 Recherche

La recherche est intégrée dans `TreatmentsListPage`.

**Fonctionnement** :
1. Affichage automatique si > 3 traitements
2. Recherche dans : `productName`, `dosage`, `frequency`, `notes`
3. Filtrage en temps réel

**Accéder à la recherche** :

```dart
// Navigation directe vers la page avec recherche
Navigator.pushNamed(context, AppRoutes.treatments);
```

**Désactiver la recherche** :

```dart
// Modifier TreatmentsListPage
final showSearch = treatments.length > 10; // Seuil personnalisé
```

## 📊 Gestion des états

### États possibles

| État | Widget | Description |
|------|--------|-------------|
| `initial` | `SizedBox.shrink()` | État initial |
| `loading` | `TreatmentCardSkeleton` | Chargement en cours |
| `loaded` | `TreatmentCard` | Données chargées |
| `error` | `TreatmentsErrorState` | Erreur survenue |
| `empty` | `TreatmentsEmptyState` | Aucune donnée |

### Pattern recommandé

```dart
Widget build(BuildContext context, WidgetRef ref) {
  final state = ref.watch(treatmentsProvider);

  switch (state.status) {
    case TreatmentsStatus.initial:
      return const SizedBox.shrink();
    case TreatmentsStatus.loading:
      return _buildLoadingList();
    case TreatmentsStatus.error:
      return _buildErrorState(state.errorMessage);
    case TreatmentsStatus.loaded:
      return state.treatments.isEmpty
          ? _buildEmptyState()
          : _buildTreatmentsList(state.treatments);
  }
}
```

## 🧪 Tests

### Tester vos widgets avec les nouveaux composants

```dart
testWidgets('devrait afficher la liste de traitements', (tester) async {
  // Setup
  final mockTreatments = [
    TreatmentEntity(
      id: '1',
      productName: 'Aspirine',
      dosage: '500mg',
      // ...
    ),
  ];

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        treatmentsProvider.overrideWith((ref) => mockTreatments),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: TreatmentsList(),
        ),
      ),
    ),
  );

  // Vérifications
  expect(find.text('Aspirine'), findsOneWidget);
  expect(find.byType(TreatmentCard), findsOneWidget);
});
```

## ❓ FAQ

**Q: Puis-je utiliser l'ancien TreatmentCard ?**  
R: Oui, mais il est recommandé de migrer vers le nouveau pour profiter des animations et fonctionnalités.

**Q: Comment désactiver les animations ?**  
R: Mettez `animationDelay: 0` sur tous les TreatmentCard.

**Q: Le swipe-to-delete est-il obligatoire ?**  
R: Non, si vous ne fournissez pas `onDelete`, la fonctionnalité est désactivée.

**Q: Puis-je personnaliser le skeleton ?**  
R: Oui, modifiez `TreatmentCardSkeleton` dans `widgets.dart`.

**Q: Comment ajouter des champs de recherche personnalisés ?**  
R: Modifiez la méthode `_filterTreatments()` dans `TreatmentsListPage`.

## 📞 Support

Pour toute question ou problème :
1. Consultez les tests dans `widgets_test.dart` pour des exemples d'utilisation
2. Vérifiez la documentation dans `TREATMENTS_ARCHITECTURE.md`
3. Contactez l'équipe de développement

---

**Dernière mise à jour** : $(date +%Y-%m-%d)  
**Version** : 1.0.0
