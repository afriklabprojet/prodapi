# Meilleures Pratiques - Écrans de Liste Flutter

Guide des best practices pour créer des écrans de liste modernes et performants dans Flutter.

## 🎯 Architecture

### 1. Séparation des préoccupations

```dart
// ✅ BON : Séparation claire
lib/features/ma_feature/
├── presentation/
│   ├── pages/
│   │   └── list_page.dart         // Logique de la page
│   ├── widgets/
│   │   ├── item_card.dart         // Widget réutilisable
│   │   └── list_skeleton.dart     // État de chargement
│   └── providers/
│       └── feature_notifier.dart  // State management

// ❌ MAUVAIS : Tout dans un seul fichier
lib/
└── list_page.dart  // 1000+ lignes
```

### 2. Widget réutilisable

```dart
// ✅ BON : Widget indépendant
class ItemCard extends StatelessWidget {
  final Item item;
  final VoidCallback onTap;
  final VoidCallback? onDelete;
  
  const ItemCard({
    super.key,
    required this.item,
    required this.onTap,
    this.onDelete,
  });
}

// ❌ MAUVAIS : Widget imbriqué privé
class _MyListPage extends State<MyListPage> {
  Widget _buildCard(Item item) { ... } // Difficile à tester
}
```

## 🎨 UI/UX

### 1. États multiples

Gérer tous les états possibles de votre liste :

```dart
Widget _buildBody(State state) {
  // 1. Chargement initial
  if (state.isLoading && state.items.isEmpty) {
    return const LoadingSkeleton();
  }
  
  // 2. Erreur sans données
  if (state.error != null && state.items.isEmpty) {
    return ErrorState(
      error: state.error,
      onRetry: () => reload(),
    );
  }
  
  // 3. Liste vide
  if (state.items.isEmpty) {
    return EmptyState(
      onAction: () => navigateToAdd(),
    );
  }
  
  // 4. Données avec possibilité de refresh
  return RefreshIndicator(
    onRefresh: () => reload(),
    child: ListView.builder(...),
  );
}
```

### 2. Design moderne des cartes

```dart
// Principes d'un bon design de carte :
Card(
  elevation: 2,                           // Élévation subtile
  margin: const EdgeInsets.only(bottom: 12),
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(12),  // Coins arrondis
  ),
  child: InkWell(                         // Feedback tactile
    onTap: onTap,
    borderRadius: BorderRadius.circular(12),
    child: Padding(
      padding: const EdgeInsets.all(16),  // Padding généreux
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête avec icône
          _buildHeader(),
          const SizedBox(height: 12),     // Espacement cohérent
          // Contenu principal
          _buildContent(),
          // Contenu secondaire optionnel
          if (hasExtraInfo) ...[
            const SizedBox(height: 12),
            _buildExtraInfo(),
          ],
        ],
      ),
    ),
  ),
)
```

### 3. Skeleton Loading

```dart
class ItemSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ShimmerLoading(width: 40, height: 40),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ShimmerLoading(width: 150, height: 16),
                      SizedBox(height: 8),
                      ShimmerLoading(width: 100, height: 12),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            ShimmerLoading(width: double.infinity, height: 14),
          ],
        ),
      ),
    );
  }
}
```

## ⚡ Performance

### 1. Keys appropriées

```dart
// ✅ BON : Key basée sur l'ID unique
ListView.builder(
  itemBuilder: (context, index) {
    final item = items[index];
    return ItemCard(
      key: ValueKey(item.id),  // Important !
      item: item,
    );
  },
)

// ❌ MAUVAIS : Pas de key ou key d'index
return ItemCard(item: items[index]); // Problèmes de performance
return ItemCard(key: ValueKey(index), ...); // ID change en permanence
```

### 2. Optimisation du ListView

```dart
// Pour de longues listes
ListView.builder(
  // Améliore les performances en spécifiant la hauteur
  itemExtent: 100.0,
  
  // Ou pour des hauteurs variables
  prototypeItem: const ItemCard(item: dummyItem),
  
  // Garde les items en cache
  cacheExtent: 500.0,
  
  itemBuilder: (context, index) => ItemCard(...),
)
```

### 3. Gestion mémoire

```dart
class _MyPageState extends State<MyPage> 
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(...);
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _controller.dispose();         // Toujours dispose !
    _scrollController.dispose();
    super.dispose();
  }
}
```

## ✨ Animations

### 1. Animation d'entrée progressive

```dart
class _MyPageState extends State<MyPage> 
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    Future.microtask(() {
      _animationController.forward();
    });
  }

  Widget _buildAnimatedList(List items) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return ListView.builder(
          itemCount: items.length,
          itemBuilder: (context, index) {
            // Animation progressive (stagger)
            final animation = Tween<double>(begin: 0.0, end: 1.0)
              .animate(CurvedAnimation(
                parent: _animationController,
                curve: Interval(
                  (index / items.length) * 0.5,
                  ((index + 1) / items.length) * 0.5 + 0.5,
                  curve: Curves.easeOut,
                ),
              ));

            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: animation.drive(
                  Tween<Offset>(
                    begin: const Offset(0.3, 0),
                    end: Offset.zero,
                  ),
                ),
                child: ItemCard(item: items[index]),
              ),
            );
          },
        );
      },
    );
  }
}
```

### 2. Transitions entre états

```dart
// Transition fluide entre chargement et contenu
AnimatedSwitcher(
  duration: const Duration(milliseconds: 300),
  child: state.isLoading
    ? LoadingSkeleton(key: ValueKey('loading'))
    : ItemList(key: ValueKey('content'), items: state.items),
)
```

## 🎭 Interactions

### 1. Swipe-to-delete

```dart
Dismissible(
  key: Key('item_${item.id}'),
  direction: DismissDirection.endToStart,
  
  // Confirmation avant suppression
  confirmDismiss: (direction) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirmer la suppression'),
        content: Text('Êtes-vous sûr de vouloir supprimer "${item.name}" ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text('Supprimer'),
          ),
        ],
      ),
    );
  },
  
  // Arrière-plan du swipe
  background: Container(
    alignment: Alignment.centerRight,
    padding: EdgeInsets.only(right: 20),
    color: Colors.red,
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.delete_outline, color: Colors.white, size: 32),
        SizedBox(height: 4),
        Text('Supprimer', style: TextStyle(color: Colors.white)),
      ],
    ),
  ),
  
  onDismissed: (direction) => onDelete(),
  child: ItemCard(item: item),
)
```

### 2. Feedbacks visuels

```dart
// Feedback après action
Future<void> _handleDelete(int id) async {
  try {
    await deleteItem(id);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 12),
              Text('Élément supprimé'),
            ],
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          action: SnackBarAction(
            label: 'ANNULER',
            textColor: Colors.white,
            onPressed: () => _undoDelete(id),
          ),
        ),
      );
    }
  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error_outline, color: Colors.white),
              SizedBox(width: 12),
              Text('Erreur : impossible de supprimer'),
            ],
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}
```

### 3. Pull-to-refresh

```dart
RefreshIndicator(
  onRefresh: () async {
    await ref.read(provider.notifier).refresh();
  },
  child: ListView.builder(...),
)
```

## 🔍 Recherche et Filtres

### 1. Recherche simple

```dart
class _MyPageState extends State<MyPage> {
  String _searchQuery = '';
  
  List<Item> get _filteredItems {
    if (_searchQuery.isEmpty) return items;
    
    final query = _searchQuery.toLowerCase();
    return items.where((item) {
      return item.name.toLowerCase().contains(query) ||
             item.description.toLowerCase().contains(query);
    }).toList();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Ma Liste'),
        actions: [
          IconButton(
            icon: Icon(Icons.search),
            onPressed: () => _showSearchDialog(),
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: _filteredItems.length,
        itemBuilder: (context, index) {
          return ItemCard(item: _filteredItems[index]);
        },
      ),
    );
  }
  
  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Rechercher'),
        content: TextField(
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Nom, description...',
            prefixIcon: Icon(Icons.search),
          ),
          onChanged: (value) {
            setState(() => _searchQuery = value);
            Navigator.pop(context);
          },
        ),
      ),
    );
  }
}
```

## 🧪 Tests

### 1. Tests de widgets

```dart
testWidgets('should display list of items', (tester) async {
  final items = [
    Item(id: 1, name: 'Item 1'),
    Item(id: 2, name: 'Item 2'),
  ];
  
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: ListView.builder(
          itemCount: items.length,
          itemBuilder: (context, index) {
            return ItemCard(
              item: items[index],
              onTap: () {},
            );
          },
        ),
      ),
    ),
  );

  expect(find.text('Item 1'), findsOneWidget);
  expect(find.text('Item 2'), findsOneWidget);
});
```

### 2. Tests d'interaction

```dart
testWidgets('should call onTap when item is tapped', (tester) async {
  var tapped = false;
  final item = Item(id: 1, name: 'Test');
  
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: ItemCard(
          item: item,
          onTap: () => tapped = true,
        ),
      ),
    ),
  );

  await tester.tap(find.byType(ItemCard));
  await tester.pumpAndSettle();

  expect(tapped, isTrue);
});
```

## 📋 Checklist

Avant de finaliser votre écran de liste, vérifiez :

- [ ] Widget de carte extrait et réutilisable
- [ ] Tests unitaires du widget (>80% couverture)
- [ ] Tous les états gérés (loading, error, empty, data)
- [ ] Keys appropriées sur les items de liste
- [ ] Animation d'entrée progressive
- [ ] Pull-to-refresh implémenté
- [ ] Skeleton loading pendant le chargement
- [ ] Feedbacks visuels pour chaque action
- [ ] Confirmation avant actions destructives
- [ ] Gestion du `mounted` check dans les callbacks async
- [ ] Dispose des controllers
- [ ] Recherche/filtres (si > 10 items)
- [ ] Accessibilité (semantic labels, contrast)
- [ ] Performance testée (listes de 100+ items)
- [ ] Documentation des patterns utilisés

## 📚 Ressources

- [Flutter Performance Best Practices](https://docs.flutter.dev/perf/best-practices)
- [Effective Dart](https://dart.dev/guides/language/effective-dart)
- [Material Design Guidelines](https://material.io/design)
- [Flutter Widget Testing](https://docs.flutter.dev/cookbook/testing/widget)

---

**Maintenu par** : L'équipe Mobile DR-PHARMA
**Dernière mise à jour** : 9 avril 2026
