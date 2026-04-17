# Meilleures Pratiques - Module Traitements

Guide des patterns et bonnes pratiques à suivre, basé sur les améliorations du module traitements.

---

## 🎯 Principes généraux

### 1. Architecture Clean

✅ **À faire** :
- Séparer clairement Domain / Data / Presentation
- Garder les entités dans `domain/entities/`
- Reposit interfaces dans `domain/repositories/`
- Implémentations dans `data/repositories/`

❌ **À éviter** :
- Mélanger logique métier et UI
- Dépendances circulaires entre layers
- Business logic dans les widgets

### 2. State Management

✅ **À faire** :
- Utiliser Riverpod pour tous les états
- StateNotifier pour état complexe
- Provider pour services simples
- États immutables avec `copyWith()`

❌ **À éviter** :
- setState() pour état global
- Mutable state
- State management mixte (Riverpod + Provider + setState)

---

## 🏗️ Design Patterns

### Singleton pour Datasources

**Quand l'utiliser** : Pour tous les datasources locaux (Hive, SharedPreferences, SQLite)

✅ **Pattern correct** :
```dart
class MyDatasource {
  static MyDatasource? _instance;
  static bool _isInitialized = false;
  
  MyDatasource._(); // Private constructor
  
  factory MyDatasource() {
    _instance ??= MyDatasource._();
    return _instance!;
  }
  
  Future<Box<MyModel>> get box async {
    if (_box == null || !_box!.isOpen) {
      await init();
    }
    return _box!;
  }
  
  Future<void> init() async {
    if (_isInitialized) return;
    _box = await Hive.openBox<MyModel>('my_box');
    _isInitialized = true;
  }
}
```

❌ **Pattern incorrect** :
```dart
class MyDatasource {
  Box<MyModel>? _box;
  
  // Nouvelle instance à chaque appel
  MyDatasource();
  
  // Peut échouer si init() pas appelé
  Box<MyModel> get box => _box!;
}
```

**Avantages** :
- Une seule instance partagée
- Auto-initialisation sûre
- Pas d'erreur "not initialized"
- Thread-safe

### Repository Pattern

✅ **À faire** :
```dart
// Interface dans domain
abstract class MyRepository {
  Future<Either<Failure, List<MyEntity>>> getAll();
}

// Implémentation dans data
class MyRepositoryImpl implements MyRepository {
  final MyDatasource datasource;
  
  @override
  Future<Either<Failure, List<MyEntity>>> getAll() async {
    try {
      final models = await datasource.getAll();
      return Right(models.map((m) => m.toEntity()).toList());
    } catch (e) {
      return Left(CacheFailure());
    }
  }
}
```

**Avantages** :
- Abstraction de la source de données
- Facile de changer la source (local → remote)
- Testable avec mocks

---

## 🎨 UI/UX Best Practices

### Skeleton Loading

✅ **À utiliser** : Pour tous les chargements initiaux de listes

```dart
Widget build(BuildContext context, WidgetRef ref) {
  final state = ref.watch(myProvider);
  
  if (state.status == Status.loading) {
    return ListView.builder(
      itemCount: 3, // Nombre de skeletons
      itemBuilder: (context, index) => const MyCardSkeleton(),
    );
  }
  
  return ListView.builder(
    itemCount: state.items.length,
    itemBuilder: (context, index) => MyCard(item: state.items[index]),
  );
}
```

❌ **À éviter** : CircularProgressIndicator pour les listes

**Skeleton widget pattern** :
```dart
class MyCardSkeleton extends StatefulWidget {
  const MyCardSkeleton({super.key});

  @override
  State<MyCardSkeleton> createState() => _MyCardSkeletonState();
}

class _MyCardSkeletonState extends State<MyCardSkeleton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: 0.3 + (_controller.value * 0.4), // 0.3 → 0.7
          child: Card(/* structure similaire à la vraie carte */),
        );
      },
    );
  }
}
```

### Stagger Animations

✅ **À utiliser** : Pour listes qui apparaissent progressivement

```dart
ListView.builder(
  itemCount: items.length,
  itemBuilder: (context, index) {
    return MyCard(
      item: items[index],
      animationDelay: index * 50, // 50ms entre chaque
    );
  },
)
```

**Widget avec animation** :
```dart
class MyCard extends StatefulWidget {
  final MyItem item;
  final int animationDelay;
  
  const MyCard({
    super.key,
    required this.item,
    this.animationDelay = 0,
  });

  @override
  State<MyCard> createState() => _MyCardState();
}

class _MyCardState extends State<MyCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    // Délai avant animation
    Future.delayed(Duration(milliseconds: widget.animationDelay), () {
      if (mounted) {
        _controller.forward();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Card(/* contenu */),
      ),
    );
  }
}
```

**Limites** : Max 5 secondes de délai total (100 items * 50ms)

### Enhanced SnackBars

✅ **Pattern standard** :
```dart
void showSuccessSnackBar(BuildContext context, String message, {String? action}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Row(
        children: [
          const Icon(Icons.check_circle, color: Colors.white),
          const SizedBox(width: 12),
          Expanded(child: Text(message)),
        ],
      ),
      backgroundColor: AppColors.success,
      action: action != null
          ? SnackBarAction(
              label: action,
              textColor: Colors.white,
              onPressed: () { /* action */ },
            )
          : null,
    ),
  );
}

void showErrorSnackBar(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Row(
        children: [
          const Icon(Icons.error, color: Colors.white),
          const SizedBox(width: 12),
          Expanded(child: Text(message)),
        ],
      ),
      backgroundColor: AppColors.error,
      action: SnackBarAction(
        label: 'Réessayer',
        textColor: Colors.white,
        onPressed: () { /* retry */ },
      ),
    ),
  );
}
```

**Créer un helper** :
```dart
// lib/core/utils/snackbar_utils.dart
class SnackBarUtils {
  static void showSuccess(BuildContext context, String message, {String? action}) { }
  static void showError(BuildContext context, String message, {VoidCallback? onRetry}) { }
  static void showInfo(BuildContext context, String message) { }
  static void showWarning(BuildContext context, String message) { }
}
```

### Swipe to Delete

✅ **Pattern avec confirmation** :
```dart
Dismissible(
  key: Key(item.id),
  direction: DismissDirection.horizontal,
  background: Container(
    color: Colors.red,
    alignment: Alignment.centerRight,
    padding: const EdgeInsets.only(right: 20),
    child: const Icon(Icons.delete, color: Colors.white, size: 32),
  ),
  confirmDismiss: (direction) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: const Text('Êtes-vous sûr de vouloir supprimer cet élément ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Supprimer', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    ) ?? false;
  },
  onDismissed: (direction) {
    widget.onDelete?.call();
  },
  child: /* votre carte */,
)
```

❌ **À éviter** : Suppression sans confirmation

---

## 🧩 Widgets Réutilisables

### Structure recommandée

```dart
// lib/features/my_feature/presentation/widgets/widgets.dart

// Widgets principaux
export 'my_card.dart';
export 'my_card_skeleton.dart';
export 'my_empty_state.dart';
export 'my_error_state.dart';
```

### Pattern Empty State

```dart
class MyEmptyState extends StatelessWidget {
  final String message;
  final VoidCallback? onAdd;
  
  const MyEmptyState({
    super.key,
    required this.message,
    this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inbox_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: Theme.of(context).textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
          if (onAdd != null) ...[
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: const Text('Ajouter'),
            ),
          ],
        ],
      ),
    );
  }
}
```

### Pattern Error State

```dart
class MyErrorState extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  
  const MyErrorState({
    super.key,
    required this.message,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 80,
            color: AppColors.error,
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: Theme.of(context).textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Réessayer'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
```

---

## 🧪 Testing Best Practices

### Widget Tests Structure

```dart
void main() {
  group('MyWidget Tests', () {
    late MyEntity mockEntity;

    setUp(() {
      // Setup commun
      mockEntity = MyEntity(/* données de test */);
    });

    group('Display Tests', () {
      testWidgets('devrait afficher le titre', (tester) async {
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: MyWidget(entity: mockEntity),
            ),
          ),
        );

        expect(find.text(mockEntity.title), findsOneWidget);
      });
    });

    group('Interaction Tests', () {
      testWidgets('devrait appeler callback au tap', (tester) async {
        bool tapped = false;

        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: MyWidget(
                entity: mockEntity,
                onTap: () => tapped = true,
              ),
            ),
          ),
        );

        await tester.tap(find.byType(MyWidget));
        await tester.pumpAndSettle();

        expect(tapped, true);
      });
    });

    group('Animation Tests', () {
      testWidgets('devrait avoir FadeTransition', (tester) async {
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: MyWidget(entity: mockEntity),
            ),
          ),
        );

        expect(find.byType(FadeTransition), findsOneWidget);
      });
    });
  });
}
```

### Test Conventions

✅ **À faire** :
- Grouper les tests par fonctionnalité
- Nommer les tests en français (description claire)
- `setUp()` pour les données communes
- `pumpAndSettle()` pour attendre les animations
- Vérifier les callbacks avec des flags booléens

❌ **À éviter** :
- Tests trop génériques ("devrait fonctionner")
- Pas de `pumpAndSettle()` avant assertions
- Accès direct aux private members
- Tests fragiles (dépendant de l'ordre d'exécution)

---

## 📝 Documentation

### Structure de fichier

```dart
/// Widget pour afficher une carte de traitement avec animations.
///
/// Fonctionnalités :
/// - Animations d'entrée (fade + scale)
/// - Swipe-to-delete avec confirmation
/// - Hero transition pour l'icône
/// - Badges d'urgence (rouge/orange)
///
/// Exemple :
/// ```dart
/// TreatmentCard(
///   treatment: myTreatment,
///   animationDelay: 100,
///   onDelete: () => deleteTreatment(),
/// )
/// ```
class TreatmentCard extends StatefulWidget {
  /// Le traitement à afficher
  final TreatmentEntity treatment;
  
  /// Délai avant l'animation en millisecondes (défaut: 0)
  final int animationDelay;
  
  /// Callback appelé au tap sur la carte
  final VoidCallback? onTap;
  
  const TreatmentCard({
    super.key,
    required this.treatment,
    this.animationDelay = 0,
    this.onTap,
  });
}
```

### README par module

**Créer** : `lib/features/my_feature/README.md`

```markdown
# Module My Feature

## Structure

- `domain/` : Entities, repositories, usecases
- `data/` : Models, datasources, repository implementations
- `presentation/` : Pages, widgets, providers, states

## Widgets

- `MyCard` : Carte principale avec animations
- `MyCardSkeleton` : Loading state
- `MyEmptyState` : État vide
- `MyErrorState` : État d'erreur

## Usage

[Voir MIGRATION_GUIDE.md](../../../docs/MY_FEATURE_MIGRATION_GUIDE.md)
```

---

## 🚀 Performance

### Lazy Loading

✅ **ListView.builder** pour listes longues :
```dart
ListView.builder(
  itemCount: items.length,
  itemBuilder: (context, index) => MyCard(item: items[index]),
)
```

❌ **ListView avec children** :
```dart
ListView(
  children: items.map((item) => MyCard(item: item)).toList(),
)
```

### const Constructors

✅ **À utiliser partout où possible** :
```dart
const MyWidget({
  super.key,
  required this.data,
});
```

**Avantages** :
- Réutilise les instances
- Moins d'allocations mémoire
- Meilleure performance

### Avoid Rebuilds

✅ **Consumer localisé** :
```dart
Consumer(
  builder: (context, ref, child) {
    final specific = ref.watch(specificProvider);
    return Text(specific.value);
  },
)
```

❌ **ConsumerWidget global** (rebuild tout) :
```dart
class MyPage extends ConsumerWidget {
  Widget build(context, ref) {
    final everything = ref.watch(megaProvider);
    // Tout rebuild quand n'importe quoi change
  }
}
```

---

## 🔒 Sécurité

### Soft Delete

✅ **Pattern recommandé** :
```dart
class MyEntity {
  final bool isActive; // false = deleted
  
  // Dans datasource
  Future<void> delete(String id) async {
    final item = await getById(id);
    await update(item.copyWith(isActive: false));
  }
  
  // Dans getAllActive
  Future<List<MyEntity>> getAllActive() async {
    final all = await getAll();
    return all.where((item) => item.isActive).toList();
  }
}
```

**Avantages** :
- Possibilité de restaurer
- Historique complet
- Audit trail

### Validation

✅ **Dans les entités** :
```dart
class MyEntity {
  final String name;
  
  MyEntity({
    required this.name,
  }) : assert(name.isNotEmpty, 'Name cannot be empty');
}
```

---

## 📊 Monitoring

### Logging Pattern

```dart
import 'package:logger/logger.dart';

final logger = Logger();

// Dans les méthodes
Future<void> myMethod() async {
  logger.d('Starting myMethod');
  try {
    // ...
    logger.i('myMethod completed successfully');
  } catch (e, stackTrace) {
    logger.e('myMethod failed', error: e, stackTrace: stackTrace);
    rethrow;
  }
}
```

---

## ✅ Checklist avant commit

- [ ] `dart format` exécuté
- [ ] `dart analyze` sans warnings
- [ ] Tests ajoutés pour nouveau code
- [ ] Tests existants passent
- [ ] Documentation mise à jour
- [ ] Pas de `print()` ou `debugPrint()` dans le code
- [ ] Pas de TODO non résolus
- [ ] Code reviewed

---

**Dernière mise à jour** : 2024-01-15  
**Version** : 1.0.0  
**Auteur** : Équipe DR-PHARMA
