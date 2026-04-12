# Guide de Style de Code - DR-PHARMA

Ce document définit les conventions de code pour l'application Flutter DR-PHARMA.

## Table des Matières

- [Principes généraux](#principes-généraux)
- [Dart et Flutter](#dart-et-flutter)
- [Architecture](#architecture)
- [State Management (Riverpod)](#state-management-riverpod)
- [Navigation (GoRouter)](#navigation-gorouter)
- [Widgets](#widgets)
- [Gestion des erreurs](#gestion-des-erreurs)
- [Internationalisation](#internationalisation)
- [Performance](#performance)

---

## Principes généraux

### DRY (Don't Repeat Yourself)
Extraire le code dupliqué dans des fonctions ou widgets réutilisables.

### KISS (Keep It Simple, Stupid)
Préférer les solutions simples aux abstractions complexes.

### SOLID
- **S**ingle Responsibility : Une classe = une responsabilité
- **O**pen/Closed : Ouvert à l'extension, fermé à la modification
- **L**iskov Substitution : Les sous-classes doivent être substituables
- **I**nterface Segregation : Plusieurs petites interfaces > une grosse
- **D**ependency Inversion : Dépendre des abstractions, pas des implémentations

---

## Dart et Flutter

### Typage

```dart
// ✅ BON - Typage explicite
final List<Product> products = [];
Future<UserModel> fetchUser(String userId) async { ... }

// ❌ MAUVAIS - Types implicites ou dynamic
final products = [];
Future fetchUser(userId) async { ... }
```

### Null Safety

```dart
// ✅ BON - Vérification null explicite
if (user != null) {
  print(user.name);
}

// ✅ BON - Opérateurs null-aware
final name = user?.name ?? 'Inconnu';

// ❌ MAUVAIS - Force unwrap sans vérification
print(user!.name);
```

### Const et Final

```dart
// ✅ BON - const pour les valeurs compile-time
const maxItems = 100;
const primaryColor = Color(0xFF2E7D32);

// ✅ BON - final pour les valeurs runtime
final createdAt = DateTime.now();
final user = ref.watch(userProvider);

// ❌ MAUVAIS - var sans raison
var maxItems = 100; // Jamais réassigné
```

### Collections

```dart
// ✅ BON - Collection literals
final items = <String>[];
final map = <String, int>{};

// ✅ BON - Spread operator
final allItems = [...items1, ...items2];

// ✅ BON - Collection if/for
final widgets = [
  for (final item in items)
    ItemWidget(item: item),
  if (showMore) const LoadMoreButton(),
];
```

### Async/Await

```dart
// ✅ BON - async/await clair
Future<void> loadData() async {
  try {
    final user = await userRepository.fetchUser();
    final orders = await orderRepository.fetchOrders(user.id);
    state = AsyncData(orders);
  } catch (e, stack) {
    state = AsyncError(e, stack);
  }
}

// ✅ BON - Requêtes parallèles
final results = await Future.wait([
  fetchUser(),
  fetchOrders(),
  fetchNotifications(),
]);
```

---

## Architecture

### Clean Architecture

Respecter la séparation en 3 couches :

```
feature/
├── data/           # Implémentation
│   ├── datasources/  # Sources de données (API, cache)
│   ├── models/       # DTOs avec fromJson/toJson
│   └── repositories/ # Implémentation des repositories
│
├── domain/         # Logique métier
│   ├── entities/     # Entités pures (pas de dépendances)
│   └── usecases/     # Cas d'utilisation
│
└── presentation/   # UI
    ├── pages/        # Écrans complets
    ├── providers/    # State management
    └── widgets/      # Composants UI
```

### Dépendances

```
┌──────────────┐
│ Presentation │ ──▶ Domain ◀── Data
└──────────────┘
      │                           │
      └───────────────────────────┘
              UI dépend de Data
              via injection
```

### Repositories

```dart
// ✅ BON - Interface abstraite
abstract class CartRepository {
  Future<Cart> getCart();
  Future<void> addItem(String productId, int quantity);
  Future<void> removeItem(String productId);
}

// ✅ BON - Implémentation
class CartRepositoryImpl implements CartRepository {
  final CartRemoteDataSource _remote;
  final CartLocalDataSource _local;

  CartRepositoryImpl(this._remote, this._local);

  @override
  Future<Cart> getCart() async {
    try {
      final cart = await _remote.getCart();
      await _local.cacheCart(cart);
      return cart;
    } catch (e) {
      return await _local.getCachedCart();
    }
  }
}
```

---

## State Management (Riverpod)

### Providers

```dart
// ✅ BON - Provider simple pour les services
final cartServiceProvider = Provider<CartService>((ref) {
  return CartService(ref.read(cartRepositoryProvider));
});

// ✅ BON - StateNotifierProvider pour l'état mutable
final cartProvider = StateNotifierProvider<CartNotifier, CartState>((ref) {
  return CartNotifier(ref.read(cartServiceProvider));
});

// ✅ BON - FutureProvider pour les données async
final userProvider = FutureProvider<User>((ref) async {
  return ref.read(userRepositoryProvider).getCurrentUser();
});

// ✅ BON - Provider family pour les paramètres
final productProvider = FutureProvider.family<Product, String>((ref, id) async {
  return ref.read(productRepositoryProvider).getProduct(id);
});
```

### StateNotifier

```dart
// ✅ BON - État immuable
@immutable
class CartState {
  final List<CartItem> items;
  final bool isLoading;
  final String? error;

  const CartState({
    this.items = const [],
    this.isLoading = false,
    this.error,
  });

  CartState copyWith({
    List<CartItem>? items,
    bool? isLoading,
    String? error,
  }) {
    return CartState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

// ✅ BON - Notifier avec méthodes claires
class CartNotifier extends StateNotifier<CartState> {
  final CartService _service;

  CartNotifier(this._service) : super(const CartState());

  Future<void> addItem(Product product, int quantity) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _service.addItem(product, quantity);
      final items = await _service.getItems();
      state = state.copyWith(items: items, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}
```

### Consumer vs ref.watch

```dart
// ✅ BON - Consumer pour reconstruire une partie du widget
Widget build(BuildContext context) {
  return Column(
    children: [
      const Header(), // Ne reconstruit pas
      Consumer(
        builder: (context, ref, child) {
          final cart = ref.watch(cartProvider);
          return CartSummary(cart: cart);
        },
      ),
    ],
  );
}

// ✅ BON - ref.watch dans ConsumerWidget
class CartPage extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(cartProvider);
    return CartView(cart: cart);
  }
}
```

---

## Navigation (GoRouter)

### Définition des routes

```dart
// ✅ BON - Routes typées
sealed class AppRoutes {
  static const home = '/';
  static const product = '/product/:id';
  static const cart = '/cart';
  static const checkout = '/checkout';

  static String productPath(String id) => '/product/$id';
}

// ✅ BON - Configuration GoRouter
final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    routes: [
      GoRoute(
        path: AppRoutes.home,
        builder: (context, state) => const HomePage(),
      ),
      GoRoute(
        path: AppRoutes.product,
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return ProductPage(productId: id);
        },
      ),
    ],
    redirect: (context, state) {
      final isLoggedIn = ref.read(authProvider).isLoggedIn;
      final isAuthRoute = state.matchedLocation.startsWith('/auth');
      
      if (!isLoggedIn && !isAuthRoute) {
        return '/auth/login';
      }
      return null;
    },
  );
});
```

### Navigation

```dart
// ✅ BON - Navigation typée
context.go(AppRoutes.home);
context.push(AppRoutes.productPath(product.id));

// ✅ BON - Retour avec résultat
final result = await context.push<bool>('/confirm');
if (result == true) {
  // Confirmé
}

// ❌ MAUVAIS - Strings hardcodées
context.go('/product/123');
```

---

## Widgets

### Composition

```dart
// ✅ BON - Widgets petits et composables
class ProductCard extends StatelessWidget {
  final Product product;
  
  const ProductCard({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: [
          ProductImage(url: product.imageUrl),
          ProductInfo(product: product),
          ProductActions(product: product),
        ],
      ),
    );
  }
}
```

### Const constructors

```dart
// ✅ BON - Const widget
class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;

  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
  });
  
  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      child: Text(label),
    );
  }
}

// ✅ BON - Utilisation avec const
const PrimaryButton(label: 'Valider', onPressed: _onSubmit);
```

### Clés

```dart
// ✅ BON - Key pour les listes dynamiques
ListView.builder(
  itemCount: items.length,
  itemBuilder: (context, index) {
    final item = items[index];
    return ItemWidget(
      key: ValueKey(item.id),
      item: item,
    );
  },
);
```

---

## Gestion des erreurs

### Hiérarchie d'exceptions

```dart
// ✅ BON - Exceptions typées
sealed class AppException implements Exception {
  String get message;
  String get code;
}

class NetworkException extends AppException {
  @override
  final String message;
  @override
  final String code;
  
  NetworkException({required this.message, this.code = 'NETWORK_ERROR'});
}

class AuthException extends AppException {
  // ...
}
```

### Gestion centralisée

```dart
// ✅ BON - ErrorHandler centralisé
class ErrorHandler {
  static void handle(Object error, StackTrace stack) {
    // Log vers Crashlytics
    CrashlyticsService.recordError(error, stack);
    
    // Afficher message utilisateur
    final message = _getUserMessage(error);
    showErrorSnackBar(message);
  }
  
  static String _getUserMessage(Object error) {
    if (error is NetworkException) {
      return 'Erreur de connexion. Vérifiez votre internet.';
    }
    if (error is AuthException) {
      return 'Session expirée. Veuillez vous reconnecter.';
    }
    return 'Une erreur est survenue.';
  }
}
```

---

## Internationalisation

### Utilisation

```dart
// ✅ BON - Via AppLocalizations
final l10n = AppLocalizations.of(context);
Text(l10n.addToCart);
Text(l10n.itemsInCart(cart.itemCount));

// ❌ MAUVAIS - Strings hardcodées
Text('Ajouter au panier');
```

### Paramètres

```dart
// ✅ BON - Méthode avec paramètres dans AppLocalizations
String orderNumber(String id) => locale.languageCode == 'fr'
    ? 'Commande n°$id'
    : 'Order #$id';

String itemsInCart(int count) => locale.languageCode == 'fr'
    ? '$count article${count > 1 ? 's' : ''} dans le panier'
    : '$count item${count > 1 ? 's' : ''} in cart';
```

---

## Performance

### Images

```dart
// ✅ BON - Image.network avec cache et placeholder
CachedNetworkImage(
  imageUrl: product.imageUrl,
  placeholder: (context, url) => const ShimmerPlaceholder(),
  errorWidget: (context, url, error) => const Icon(Icons.error),
);

// ✅ BON - Précacher les images critiques
@override
void didChangeDependencies() {
  super.didChangeDependencies();
  precacheImage(NetworkImage(heroImageUrl), context);
}
```

### Listes

```dart
// ✅ BON - ListView.builder pour les longues listes
ListView.builder(
  itemCount: products.length,
  itemBuilder: (context, index) {
    return ProductCard(product: products[index]);
  },
);

// ✅ BON - Slivers pour les layouts complexes
CustomScrollView(
  slivers: [
    const SliverAppBar(/* ... */),
    SliverList.builder(
      itemCount: items.length,
      itemBuilder: (context, index) => ItemWidget(item: items[index]),
    ),
  ],
);

// ❌ MAUVAIS - Column + SingleChildScrollView pour longues listes
SingleChildScrollView(
  child: Column(
    children: products.map((p) => ProductCard(product: p)).toList(),
  ),
);
```

### Rebuilds

```dart
// ✅ BON - Extraire les widgets constants
class MyPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Header(), // Ne reconstruit jamais
        const _StaticSection(), // Widget privé constant
        Consumer(
          builder: (context, ref, child) {
            final data = ref.watch(dataProvider);
            return DataView(data: data);
          },
        ),
      ],
    );
  }
}
```

---

## Checklist de revue de code

### Avant de soumettre

- [ ] Code formaté avec `dart format`
- [ ] Pas de warnings `flutter analyze`
- [ ] Tous les tests passent
- [ ] Pas de `print()` statements
- [ ] Pas de `// TODO` non traités
- [ ] Types explicites partout
- [ ] Gestion d'erreur appropriée
- [ ] Strings internationalisées
- [ ] Widgets const quand possible
- [ ] Clés pour les listes dynamiques

---

*Dernière mise à jour : Avril 2026*
