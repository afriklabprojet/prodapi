# Documentation API - Services Core

Cette documentation décrit les services principaux de l'application DR-PHARMA Client.

## Architecture des Services

```
lib/core/services/
├── auth_service.dart          # Authentification Firebase
├── cart_service.dart          # Gestion du panier
├── firebase_service.dart      # Configuration Firebase
├── notification_service.dart  # Push notifications
├── cache_service.dart         # Cache local
├── analytics_service.dart     # Analytics/tracking
├── crashlytics_service.dart   # Crash reporting
├── messaging/                 # Services de messagerie
└── ...
```

## Services Principaux

### AuthService

Service d'authentification gérant la connexion, l'inscription et la session utilisateur.

#### Méthodes

| Méthode | Description | Paramètres | Retour |
|---------|-------------|------------|--------|
| `signInWithPhone` | Connexion par OTP SMS | `phoneNumber: String` | `Future<UserCredential>` |
| `verifyOTP` | Vérification du code OTP | `otp: String, verificationId: String` | `Future<UserCredential>` |
| `signOut` | Déconnexion | - | `Future<void>` |
| `getCurrentUser` | Utilisateur actuel | - | `User?` |
| `isAuthenticated` | État d'authentification | - | `bool` |

#### Exemple d'utilisation

```dart
final authService = ref.read(authServiceProvider);

// Connexion
await authService.signInWithPhone('+225 07 00 00 00 00');

// Vérification OTP
await authService.verifyOTP('123456', verificationId);

// Déconnexion
await authService.signOut();
```

---

### CartService

Service de gestion du panier d'achat.

#### État

```dart
class CartState {
  final List<CartItem> items;
  final int subtotal;
  final int deliveryFee;
  final int total;
  final String? pharmacyId;
}
```

#### Méthodes

| Méthode | Description | Paramètres | Retour |
|---------|-------------|------------|--------|
| `addItem` | Ajouter un produit | `product: Product, quantity: int` | `void` |
| `removeItem` | Retirer un produit | `productId: String` | `void` |
| `updateQuantity` | Modifier quantité | `productId: String, quantity: int` | `void` |
| `clearCart` | Vider le panier | - | `void` |
| `getTotal` | Calcul du total | - | `int` |

#### Exemple d'utilisation

```dart
final cartService = ref.read(cartServiceProvider);

// Ajouter au panier
cartService.addItem(product, quantity: 2);

// Modifier quantité
cartService.updateQuantity(productId, 3);

// Calculer total
final total = cartService.getTotal();
```

---

### NotificationService

Service de gestion des notifications push via Firebase Cloud Messaging.

#### Méthodes

| Méthode | Description | Paramètres | Retour |
|---------|-------------|------------|--------|
| `initialize` | Initialisation FCM | - | `Future<void>` |
| `getToken` | Récupérer le token FCM | - | `Future<String?>` |
| `subscribeToTopic` | S'abonner à un topic | `topic: String` | `Future<void>` |
| `handleMessage` | Traiter une notification | `message: RemoteMessage` | `void` |

#### Topics disponibles

- `all` - Notifications générales
- `promotions` - Offres et promotions
- `pharmacy_{id}` - Notifications d'une pharmacie
- `order_{id}` - Mises à jour commande

#### Exemple d'utilisation

```dart
final notifService = ref.read(notificationServiceProvider);

// Initialiser
await notifService.initialize();

// S'abonner aux promos
await notifService.subscribeToTopic('promotions');
```

---

### CacheService

Service de cache local pour les données hors-ligne.

#### Méthodes

| Méthode | Description | Paramètres | Retour |
|---------|-------------|------------|--------|
| `get<T>` | Lire du cache | `key: String` | `T?` |
| `set<T>` | Écrire dans le cache | `key: String, value: T, ttl: Duration?` | `Future<void>` |
| `remove` | Supprimer une entrée | `key: String` | `Future<void>` |
| `clear` | Vider le cache | - | `Future<void>` |
| `isExpired` | Vérifier expiration | `key: String` | `bool` |

#### Clés de cache standard

```dart
class CacheKeys {
  static const String user = 'user_profile';
  static const String pharmacies = 'pharmacies_list';
  static const String categories = 'product_categories';
  static const String cart = 'cart_items';
  static const String addresses = 'user_addresses';
  static const String favorites = 'favorite_products';
}
```

#### Exemple d'utilisation

```dart
final cache = ref.read(cacheServiceProvider);

// Sauvegarder avec TTL de 1 heure
await cache.set('pharmacies', pharmacyList, ttl: Duration(hours: 1));

// Lire du cache
final pharmacies = cache.get<List<Pharmacy>>('pharmacies');

// Vérifier expiration
if (cache.isExpired('pharmacies')) {
  // Rafraîchir depuis l'API
}
```

---

### CrashlyticsService

Service de suivi des erreurs et crashs via Firebase Crashlytics.

#### Méthodes

| Méthode | Description | Paramètres | Retour |
|---------|-------------|------------|--------|
| `init` | Initialisation | - | `Future<void>` |
| `recordError` | Enregistrer erreur | `error: dynamic, stack: StackTrace?` | `Future<void>` |
| `recordNetworkError` | Erreur réseau | `url: String, statusCode: int, error: String` | `Future<void>` |
| `recordAuthError` | Erreur auth | `type: String, message: String` | `Future<void>` |
| `recordPaymentError` | Erreur paiement | `method: String, error: String` | `Future<void>` |
| `setUserIdentifier` | Identifier l'utilisateur | `userId: String` | `Future<void>` |
| `log` | Ajouter un log | `message: String` | `void` |

#### Exemple d'utilisation

```dart
// Initialisation au démarrage
await CrashlyticsService.init();

// Enregistrer une erreur
try {
  await riskyOperation();
} catch (e, stack) {
  await CrashlyticsService.recordError(e, stack);
}

// Identifier l'utilisateur
await CrashlyticsService.setUserIdentifier(userId);
```

---

### AnalyticsService

Service d'analytics pour le tracking des événements utilisateur.

#### Événements standard

| Événement | Description | Paramètres |
|-----------|-------------|------------|
| `screen_view` | Vue d'écran | `screen_name, screen_class` |
| `add_to_cart` | Ajout au panier | `item_id, item_name, price, quantity` |
| `begin_checkout` | Début checkout | `value, items_count` |
| `purchase` | Achat complété | `transaction_id, value, items` |
| `search` | Recherche | `search_term` |
| `select_pharmacy` | Sélection pharmacie | `pharmacy_id, pharmacy_name` |

#### Exemple d'utilisation

```dart
final analytics = ref.read(analyticsServiceProvider);

// Tracker un écran
analytics.logScreenView('ProductDetail', 'ProductDetailPage');

// Tracker un achat
analytics.logPurchase(
  transactionId: orderId,
  value: total,
  items: cartItems,
);
```

---

### BiometricService

Service d'authentification biométrique (Face ID / Touch ID).

#### Méthodes

| Méthode | Description | Retour |
|---------|-------------|--------|
| `isAvailable` | Biométrie disponible | `Future<bool>` |
| `authenticate` | Authentifier | `Future<bool>` |
| `getBiometricType` | Type de biométrie | `Future<BiometricType>` |

#### Exemple d'utilisation

```dart
final biometric = ref.read(biometricServiceProvider);

if (await biometric.isAvailable()) {
  final success = await biometric.authenticate();
  if (success) {
    // Utilisateur authentifié
  }
}
```

---

### SecureStorageService

Service de stockage sécurisé pour les données sensibles.

#### Méthodes

| Méthode | Description | Paramètres | Retour |
|---------|-------------|------------|--------|
| `write` | Écrire donnée sécurisée | `key: String, value: String` | `Future<void>` |
| `read` | Lire donnée sécurisée | `key: String` | `Future<String?>` |
| `delete` | Supprimer donnée | `key: String` | `Future<void>` |
| `deleteAll` | Tout supprimer | - | `Future<void>` |

#### Clés sécurisées

```dart
class SecureKeys {
  static const String authToken = 'auth_token';
  static const String refreshToken = 'refresh_token';
  static const String userPin = 'user_pin';
  static const String biometricEnabled = 'biometric_enabled';
}
```

---

### WhatsAppService

Service d'intégration WhatsApp pour le support client.

#### Méthodes

| Méthode | Description | Paramètres | Retour |
|---------|-------------|------------|--------|
| `openChat` | Ouvrir conversation | `phoneNumber: String, message: String?` | `Future<void>` |
| `shareOrder` | Partager commande | `orderId: String` | `Future<void>` |
| `contactSupport` | Contacter support | `subject: String?` | `Future<void>` |

#### Exemple d'utilisation

```dart
final whatsapp = ref.read(whatsappServiceProvider);

// Contacter le support
await whatsapp.contactSupport('Question sur ma commande #12345');

// Partager une commande
await whatsapp.shareOrder(orderId);
```

---

## Providers Riverpod

Tous les services sont accessibles via des providers Riverpod:

```dart
// Auth
final authServiceProvider = Provider<AuthService>(...);

// Cart
final cartServiceProvider = StateNotifierProvider<CartService, CartState>(...);

// Notifications
final notificationServiceProvider = Provider<NotificationService>(...);

// Cache
final cacheServiceProvider = Provider<CacheService>(...);

// Analytics
final analyticsServiceProvider = Provider<AnalyticsService>(...);
```

## Gestion des erreurs

Tous les services utilisent un système d'erreurs centralisé:

```dart
abstract class AppException implements Exception {
  String get message;
  String get code;
}

class NetworkException extends AppException { ... }
class AuthException extends AppException { ... }
class PaymentException extends AppException { ... }
class ValidationException extends AppException { ... }
```

## Bonnes pratiques

1. **Toujours utiliser les providers** - Ne pas instancier les services directement
2. **Gérer les erreurs** - Utiliser try/catch avec les types d'exception appropriés
3. **Logger les erreurs critiques** - Utiliser CrashlyticsService pour les erreurs importantes
4. **Cache intelligent** - Utiliser CacheService avec TTL approprié
5. **Analytics cohérents** - Toujours tracker les événements business importants

## Tests

Pour tester les services, utiliser les mocks fournis:

```dart
// Dans les tests
final mockAuthService = MockAuthService();
when(mockAuthService.isAuthenticated).thenReturn(true);

// Override du provider
overrides: [
  authServiceProvider.overrideWithValue(mockAuthService),
]
```
