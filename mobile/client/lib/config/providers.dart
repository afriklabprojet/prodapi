import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/network/api_client.dart';
import '../core/services/search_history_service.dart';

// Auth
import '../features/auth/data/datasources/auth_local_datasource.dart';
import '../features/auth/data/datasources/auth_remote_datasource.dart';
import '../features/auth/data/repositories/auth_repository_impl.dart';
import '../features/auth/domain/repositories/auth_repository.dart';

// Orders
import '../features/orders/data/datasources/orders_local_datasource.dart';
import '../features/orders/data/datasources/orders_remote_datasource.dart';
import '../features/orders/data/repositories/orders_repository_impl.dart';
import '../features/orders/domain/repositories/orders_repository.dart';

// Products
import '../features/products/data/datasources/products_remote_datasource.dart';
import '../features/products/data/datasources/products_local_datasource.dart';
import '../features/products/data/repositories/products_repository_impl.dart';
import '../features/products/domain/repositories/products_repository.dart';

// Pharmacies
import '../features/pharmacies/data/datasources/pharmacies_remote_datasource.dart';
import '../features/pharmacies/data/repositories/pharmacies_repository_impl.dart';
import '../features/pharmacies/domain/repositories/pharmacies_repository.dart';
import '../features/pharmacies/domain/usecases/get_pharmacies_usecase.dart';
import '../features/pharmacies/domain/usecases/get_nearby_pharmacies_usecase.dart';
import '../features/pharmacies/domain/usecases/get_on_duty_pharmacies_usecase.dart';
import '../features/pharmacies/domain/usecases/get_pharmacy_details_usecase.dart';
import '../features/pharmacies/domain/usecases/get_featured_pharmacies_usecase.dart';
import '../features/pharmacies/presentation/providers/pharmacies_notifier.dart';
import '../features/pharmacies/presentation/providers/pharmacies_state.dart';

// Profile
import '../features/profile/data/datasources/profile_local_datasource.dart';
import '../features/profile/data/datasources/profile_remote_datasource.dart';
import '../features/profile/data/repositories/profile_repository_impl.dart';
import '../features/profile/domain/repositories/profile_repository.dart';

// Wallet
import '../features/wallet/data/datasources/wallet_remote_datasource.dart';
import '../features/wallet/data/repositories/wallet_repository_impl.dart';
import '../features/wallet/domain/repositories/wallet_repository.dart';

// Services
import '../core/services/notification_service.dart';
import '../core/services/analytics_service.dart';
import '../core/services/deep_link_service.dart';
import '../core/services/auth_service.dart';
import '../core/services/cart_service.dart';
import '../core/contracts/cart_contract.dart';
import '../features/auth/domain/usecases/update_password_usecase.dart';

// ──────────────────────────────────────────────────────────
// Core Providers
// ──────────────────────────────────────────────────────────

/// SharedPreferences — overridden in main.dart with the actual instance
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('sharedPreferencesProvider must be overridden');
});

/// Search History Service
final searchHistoryServiceProvider = Provider<SearchHistoryService>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return SearchHistoryService(prefs);
});

/// API Client singleton
final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient();
});

// ──────────────────────────────────────────────────────────
// Auth
// ──────────────────────────────────────────────────────────

final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return AuthRemoteDataSourceImpl(apiClient: apiClient);
});

final authLocalDataSourceProvider = Provider<AuthLocalDataSource>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return AuthLocalDataSourceImpl(sharedPreferences: prefs);
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(
    remoteDataSource: ref.watch(authRemoteDataSourceProvider),
    localDataSource: ref.watch(authLocalDataSourceProvider),
    apiClient: ref.watch(apiClientProvider),
  );
});

// ──────────────────────────────────────────────────────────
// Auth Service (nouveau service d'authentification)
// ──────────────────────────────────────────────────────────

/// AuthService — Service d'authentification production-ready
/// Gère: login auto-détection email/phone, OTP, session persistante, stream
final authServiceProvider = Provider<AuthService>((ref) {
  final remoteDataSource = ref.watch(authRemoteDataSourceProvider);
  return AuthService(
    remoteDataSource: remoteDataSource,
    otpTimeout: const Duration(minutes: 2),
    otpResendDelay: const Duration(seconds: 30),
  );
});

// ──────────────────────────────────────────────────────────
// Cart Service
// ──────────────────────────────────────────────────────────

/// CartService — Service de panier production-ready
/// Gère: add/remove/update, persistance locale, sync backend, conflits
final cartServiceProvider = Provider<CartService>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return CartService(
    prefs: prefs,
    maxCartItems: 50,
    cartExpirationDuration: const Duration(days: 7),
    debounceDuration: const Duration(milliseconds: 500),
    // Backend sync callbacks - à configurer quand l'API est prête
    // fetchServerCart: () async => remoteDataSource.getCart(),
    // pushToServer: (cart) async => remoteDataSource.saveCart(cart),
  );
});

/// Stream du panier pour UI réactive
final cartStreamProvider = StreamProvider<CartData>((ref) {
  final cartService = ref.watch(cartServiceProvider);
  return cartService.cartStream;
});

/// Stream du statut de synchronisation
final cartSyncStatusProvider = StreamProvider<CartSyncStatus>((ref) {
  final cartService = ref.watch(cartServiceProvider);
  return cartService.syncStatusStream;
});

/// Données actuelles du panier (synchrone)
final currentCartProvider = Provider<CartData>((ref) {
  final cartService = ref.watch(cartServiceProvider);
  return cartService.currentCart;
});

// ──────────────────────────────────────────────────────────
// Orders
// ──────────────────────────────────────────────────────────

final ordersRemoteDataSourceProvider = Provider<OrdersRemoteDataSource>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return OrdersRemoteDataSource(apiClient);
});

final ordersLocalDataSourceProvider = Provider<OrdersLocalDataSource>((ref) {
  return OrdersLocalDataSourceImpl();
});

final ordersRepositoryProvider = Provider<OrdersRepository>((ref) {
  return OrdersRepositoryImpl(
    remoteDataSource: ref.watch(ordersRemoteDataSourceProvider),
    localDataSource: ref.watch(ordersLocalDataSourceProvider),
  );
});

// ──────────────────────────────────────────────────────────
// Products
// ──────────────────────────────────────────────────────────

final productsRemoteDataSourceProvider = Provider<ProductsRemoteDataSource>((
  ref,
) {
  final apiClient = ref.watch(apiClientProvider);
  return ProductsRemoteDataSource(apiClient);
});

final productsRepositoryProvider = Provider<ProductsRepository>((ref) {
  return ProductsRepositoryImpl(
    remoteDataSource: ref.watch(productsRemoteDataSourceProvider),
    localDataSource: ProductsLocalDataSource(),
  );
});

// ──────────────────────────────────────────────────────────
// Pharmacies
// ──────────────────────────────────────────────────────────

final pharmaciesRemoteDataSourceProvider = Provider<PharmaciesRemoteDataSource>(
  (ref) {
    final apiClient = ref.watch(apiClientProvider);
    return PharmaciesRemoteDataSource(apiClient);
  },
);

final pharmaciesRepositoryProvider = Provider<PharmaciesRepository>((ref) {
  return PharmaciesRepositoryImpl(
    remoteDataSource: ref.watch(pharmaciesRemoteDataSourceProvider),
  );
});

final pharmaciesProvider =
    StateNotifierProvider<PharmaciesNotifier, PharmaciesState>((ref) {
      final repository = ref.watch(pharmaciesRepositoryProvider);
      return PharmaciesNotifier(
        getPharmaciesUseCase: GetPharmaciesUseCase(repository),
        getNearbyPharmaciesUseCase: GetNearbyPharmaciesUseCase(repository),
        getOnDutyPharmaciesUseCase: GetOnDutyPharmaciesUseCase(repository),
        getPharmacyDetailsUseCase: GetPharmacyDetailsUseCase(repository),
        getFeaturedPharmaciesUseCase: GetFeaturedPharmaciesUseCase(repository),
      );
    });

// ──────────────────────────────────────────────────────────
// Profile
// ──────────────────────────────────────────────────────────

final profileRemoteDataSourceProvider = Provider<ProfileRemoteDataSource>((
  ref,
) {
  final apiClient = ref.watch(apiClientProvider);
  return ProfileRemoteDataSource(apiClient);
});

final profileLocalDataSourceProvider = Provider<ProfileLocalDataSource>((ref) {
  return ProfileLocalDataSource();
});

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepositoryImpl(
    remoteDataSource: ref.watch(profileRemoteDataSourceProvider),
    localDataSource: ref.watch(profileLocalDataSourceProvider),
  );
});

// ──────────────────────────────────────────────────────────
// Notification Service
// ──────────────────────────────────────────────────────────

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});

/// Sync FCM token with backend when user is authenticated
/// Call this after successful login
Future<void> syncFcmTokenAfterLogin(WidgetRef ref) async {
  final notificationService = ref.read(notificationServiceProvider);
  final apiClient = ref.read(apiClientProvider);
  await notificationService.syncTokenToBackend(apiClient);
}

/// Remove FCM token from backend on logout
Future<void> removeFcmTokenOnLogout(WidgetRef ref) async {
  final notificationService = ref.read(notificationServiceProvider);
  final apiClient = ref.read(apiClientProvider);
  await notificationService.removeTokenFromBackend(apiClient);
}

// ──────────────────────────────────────────────────────────
// Update Password Use Case
// ──────────────────────────────────────────────────────────

final updatePasswordUseCaseProvider = Provider<UpdatePasswordUseCase>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return UpdatePasswordUseCase(apiClient);
});

// ──────────────────────────────────────────────────────────
// Analytics Service
// ──────────────────────────────────────────────────────────

/// Analytics service provider
/// Par défaut utilise DebugAnalyticsProvider en mode debug
/// Pour Firebase Analytics, décommentez le code dans firebase_analytics_provider.dart
/// et ajoutez firebase_analytics à pubspec.yaml
final analyticsServiceProvider = Provider<AnalyticsService>((ref) {
  return AnalyticsService(
    providers: [
      // Uncomment if you add firebase_analytics to pubspec.yaml:
      // FirebaseAnalyticsProvider(),
      DebugAnalyticsProvider(enabled: true),
    ],
  );
});

// ──────────────────────────────────────────────────────────
// Deep Link Service
// ──────────────────────────────────────────────────────────

/// Deep link service provider — connecté à AuthService
/// Gère les deep links pour les utilisateurs non connectés
final deepLinkServiceProvider = Provider<DeepLinkService>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  final authService = ref.watch(authServiceProvider);

  return DeepLinkService(
    prefs: prefs,
    isAuthenticated: () => authService.currentUser != null,
    navigate: (path, {extra}) {
      // Note: La navigation est gérée par le router dans app_router.dart
      // Ce callback est principalement pour le logging
    },
  );
});

// ──────────────────────────────────────────────────────────
// Wallet
// ──────────────────────────────────────────────────────────

final walletRemoteDataSourceProvider = Provider<WalletRemoteDataSource>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return WalletRemoteDataSource(apiClient);
});

final walletRepositoryProvider = Provider<WalletRepository>((ref) {
  return WalletRepositoryImpl(
    remoteDataSource: ref.watch(walletRemoteDataSourceProvider),
  );
});
