import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../config/providers.dart';
import '../../features/auth/presentation/pages/splash_page.dart';
import '../../features/auth/presentation/pages/onboarding_page.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/register_page.dart';
import '../../features/auth/presentation/pages/forgot_password_page.dart';
import '../../features/auth/presentation/pages/otp_verification_page.dart';
import '../../features/auth/presentation/pages/change_password_page.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/auth/presentation/providers/auth_state.dart';
import '../contracts/deep_link_contract.dart';
import '../handlers/deep_link_auth_handler.dart';
import '../../main_shell_page.dart';
import '../../features/pharmacies/presentation/pages/pharmacies_list_page_v2.dart';
import '../../features/pharmacies/presentation/pages/pharmacy_details_page.dart';
import '../../features/pharmacies/presentation/pages/pharmacies_map_page.dart';
import '../../features/pharmacies/presentation/pages/on_duty_pharmacies_map_page.dart';
import '../../features/products/presentation/pages/product_details_page.dart';
import '../../features/products/presentation/pages/all_products_page.dart';
import '../../features/products/presentation/pages/frequent_products_list_page.dart';
import '../../features/products/presentation/pages/favorites_page.dart';
import '../../features/orders/presentation/pages/cart_page.dart';
import '../../features/orders/presentation/pages/checkout_page.dart';
import '../../features/orders/presentation/pages/orders_list_page.dart';
import '../../features/orders/presentation/pages/order_details_page.dart';
import '../../features/orders/presentation/pages/tracking_page_wrapper.dart';
import '../../features/orders/presentation/pages/order_confirmation_page.dart';
import '../../features/orders/domain/entities/delivery_address_entity.dart';
import '../../features/prescriptions/presentation/pages/prescriptions_list_page.dart';
import '../../features/prescriptions/presentation/pages/prescription_details_page.dart';
import '../../features/prescriptions/presentation/pages/prescription_upload_page.dart';
import '../../features/prescriptions/presentation/pages/prescription_scanner_page.dart';
import '../../features/addresses/presentation/pages/addresses_list_page.dart';
import '../../features/addresses/presentation/pages/add_address_page.dart';
import '../../features/addresses/presentation/pages/edit_address_page.dart';
import '../../features/addresses/domain/entities/address_entity.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
import '../../features/profile/presentation/pages/edit_profile_page.dart';
import '../../features/profile/presentation/pages/notification_settings_page.dart';
import '../../features/profile/presentation/pages/help_support_page.dart';
import '../../features/profile/presentation/pages/terms_page.dart';
import '../../features/profile/presentation/pages/privacy_policy_page.dart';
import '../../features/profile/presentation/pages/legal_notices_page.dart';
import '../../features/notifications/presentation/pages/notifications_page.dart';
import '../../features/wallet/presentation/pages/wallet_page.dart';
import '../../features/treatments/presentation/pages/treatments_page.dart';
import '../../features/treatments/presentation/pages/add_treatment_page.dart';
import '../../features/loyalty/presentation/pages/loyalty_page.dart';
import '../../features/products/domain/entities/product_entity.dart';
import '../../features/treatments/domain/entities/treatment_entity.dart';
import '../services/navigation_service.dart';

/// Helper pour afficher une page d'erreur quand un paramètre de route est invalide
Widget _buildInvalidRouteErrorPage(BuildContext context, String message) {
  return Scaffold(
    appBar: AppBar(
      title: const Text('Erreur'),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => context.canPop() ? context.pop() : context.go('/home'),
      ),
    ),
    body: Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.orange),
            const SizedBox(height: 16),
            Text(
              'Paramètre invalide',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => context.go('/home'),
              icon: const Icon(Icons.home),
              label: const Text('Retour à l\'accueil'),
            ),
          ],
        ),
      ),
    ),
  );
}

/// Routes de l'application - Constantes type-safe
abstract class AppRoutes {
  // Auth
  static const splash = '/';
  static const onboarding = '/onboarding';
  static const login = '/login';
  static const register = '/register';
  static const forgotPassword = '/forgot-password';
  static const otpVerification = '/otp-verification';
  static const changePassword = '/change-password';

  // Main
  static const home = '/home';

  // Pharmacies
  static const pharmacies = '/pharmacies';
  static const pharmacyDetails = '/pharmacies/:id';
  static const pharmaciesMap = '/pharmacies/map';
  static const onDutyPharmacies = '/on-duty-pharmacies';

  // Products
  static const products = '/products';
  static const productDetails = '/products/:id';
  static const frequentProducts = '/frequent-products';
  static const favorites = '/favorites';

  // Orders
  static const cart = '/cart';
  static const checkout = '/checkout';
  static const orders = '/orders';
  static const orderDetails = '/orders/:id';
  static const orderTracking = '/orders/:id/tracking';
  static const orderConfirmation = '/orders/confirmation';

  // Prescriptions
  static const prescriptions = '/prescriptions';
  static const prescriptionDetails = '/prescriptions/:id';
  static const prescriptionUpload = '/prescriptions/upload';
  static const prescriptionScanner = '/prescriptions/scan';

  // Addresses
  static const addresses = '/addresses';
  static const addressesSelect = '/addresses/select';
  static const addAddress = '/addresses/add';
  static const editAddress = '/addresses/edit';

  // Profile
  static const profile = '/profile';
  static const editProfile = '/profile/edit';
  static const notificationSettings = '/profile/notifications';

  // Treatments (Mes traitements)
  static const treatments = '/treatments';
  static const addTreatment = '/treatments/add';
  static const editTreatment = '/treatments/edit';

  // Loyalty
  static const loyalty = '/loyalty';

  // Wallet
  static const wallet = '/wallet';
  static const walletTopUp = '/wallet/topup';
  static const walletWithdraw = '/wallet/withdraw';

  // Payment callbacks (deep link depuis Jeko)
  static const paymentSuccess = '/payment/success';
  static const paymentError = '/payment/error';

  // Notifications
  static const notifications = '/notifications';

  // Legal & Support
  static const help = '/help';
  static const terms = '/terms';
  static const privacy = '/privacy';
  static const legal = '/legal';
}

/// Notifier pour rafraîchir le router quand l'état d'authentification change.
/// Stocke une copie locale de l'AuthState pour éviter le cycle
/// ref.read() pendant la notification du provider (erreur Riverpod).
class RouterNotifier extends ChangeNotifier {
  final Ref _ref;
  late AuthState _authState;

  RouterNotifier(this._ref) {
    // Lire la valeur initiale de manière synchrone
    _authState = _ref.read(authProvider);

    // Écouter les changements et cacher la nouvelle valeur AVANT de notifier
    _ref.listen<AuthState>(authProvider, (_, next) {
      _authState = next;
      notifyListeners();
    });
  }

  /// État d'authentification courant (valeur cachée, safe à lire pendant redirect)
  AuthState get authState => _authState;
}

/// Provider pour le notifier
final routerNotifierProvider = ChangeNotifierProvider<RouterNotifier>((ref) {
  return RouterNotifier(ref);
});

/// Helper pour stocker un deep link en attente (utilisateur non connecté)
Future<void> _storePendingDeepLink(Ref ref, String path) async {
  try {
    final deepLinkService = ref.read(deepLinkServiceProvider);
    final deepLinkData = DeepLinkData(
      uri: Uri.parse(path),
      path: path,
      queryParams: {},
      receivedAt: DateTime.now(),
    );
    await deepLinkService.storePendingDeepLink(deepLinkData);
    debugPrint('[Router] Stored pending deep link: $path');
  } catch (e) {
    debugPrint('[Router] Error storing deep link: $e');
  }
}

/// Provider pour le router GoRouter
final routerProvider = Provider<GoRouter>((ref) {
  final notifier = ref.watch(routerNotifierProvider);

  return GoRouter(
    navigatorKey: navigatorKey,
    refreshListenable: notifier,
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: false,

    // Protection des routes — utilise notifier.authState (valeur cachée)
    // au lieu de ref.read(authProvider) pour éviter le cycle Riverpod
    redirect: (context, state) {
      final authState = notifier.authState;
      final isAuthenticated =
          authState.status == AuthStatus.authenticated &&
          authState.user != null;
      final currentPath = state.matchedLocation;

      // Routes publiques (accessibles sans authentification)
      const publicRoutes = [AppRoutes.splash, AppRoutes.onboarding];

      // Si sur splash et l'état auth est résolu (pas initial/loading),
      // rediriger immédiatement pour éviter de rester bloqué
      if (currentPath == AppRoutes.splash) {
        if (authState.status == AuthStatus.authenticated &&
            authState.user != null) {
          final user = authState.user;
          if (user != null && !user.isPhoneVerified) {
            return AppRoutes.otpVerification;
          }
          return AppRoutes.home;
        } else if (authState.status == AuthStatus.unauthenticated ||
            authState.status == AuthStatus.error) {
          return AppRoutes.login;
        }
        // Pour initial/loading, laisser splash gérer
        return null;
      }

      // Routes d'authentification (login, register, forgot-password)
      // Sur ces pages, on ne redirige QUE si authenticated (vers home/OTP)
      // Pour tout autre statut (loading, error, unauthenticated, initial)
      // on RESTE sur la page pour ne pas perdre les données saisies
      const authRoutes = [
        AppRoutes.login,
        AppRoutes.register,
        AppRoutes.forgotPassword,
      ];

      // OTP est accessible aux utilisateurs authentifiés (téléphone non vérifié)
      // ET aux non-authentifiés — ne pas inclure dans authRoutes
      if (currentPath == AppRoutes.otpVerification) {
        // Si l'utilisateur est authentifié ET son téléphone est vérifié,
        // rediriger vers home (la vérification OTP est terminée)
        if (isAuthenticated) {
          final user = authState.user;
          if (user != null && user.isPhoneVerified) {
            return AppRoutes.home;
          }
        }
        return null; // Sinon autoriser l'accès à la page OTP
      }

      // Sur une page d'auth : ne rediriger que si authentifié
      if (authRoutes.contains(currentPath)) {
        if (isAuthenticated) {
          // Si le téléphone n'est pas vérifié, rediriger vers OTP
          final user = authState.user;
          if (user != null && !user.isPhoneVerified) {
            return AppRoutes.otpVerification;
          }
          return AppRoutes.home;
        }
        // Pas authentifié (loading, error, unauthenticated, initial) → rester
        return null;
      }

      // Si l'utilisateur n'est pas authentifié et essaie d'accéder aux routes protégées
      if (!isAuthenticated &&
          !publicRoutes.contains(currentPath) &&
          !authRoutes.contains(currentPath)) {
        // Permettre l'accès initial pendant le chargement
        if (authState.status == AuthStatus.initial ||
            authState.status == AuthStatus.loading) {
          return null;
        }

        // Stocker le deep link en attente pour redirection après login
        if (DeepLinkAuthHandler.requiresAuth(currentPath)) {
          _storePendingDeepLink(ref, currentPath);
        }

        return AppRoutes.login;
      }

      return null; // Pas de redirection
    },

    routes: [
      // ===== Auth Routes =====
      GoRoute(
        path: AppRoutes.splash,
        name: 'splash',
        builder: (context, state) => const SplashPage(),
      ),
      GoRoute(
        path: AppRoutes.onboarding,
        name: 'onboarding',
        builder: (context, state) => const OnboardingPage(),
      ),
      GoRoute(
        path: AppRoutes.login,
        name: 'login',
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: AppRoutes.register,
        name: 'register',
        builder: (context, state) => const RegisterPage(),
      ),
      GoRoute(
        path: AppRoutes.forgotPassword,
        name: 'forgotPassword',
        builder: (context, state) => const ForgotPasswordPage(),
      ),
      GoRoute(
        path: AppRoutes.otpVerification,
        name: 'otpVerification',
        builder: (context, state) {
          // Le numéro peut venir de state.extra (navigation directe)
          // ou de l'utilisateur authentifié (redirect automatique)
          String phoneNumber = state.extra as String? ?? '';
          if (phoneNumber.isEmpty) {
            phoneNumber = notifier.authState.user?.phone ?? '';
          }
          return OtpVerificationPage(phoneNumber: phoneNumber);
        },
      ),
      GoRoute(
        path: AppRoutes.changePassword,
        name: 'changePassword',
        builder: (context, state) => const ChangePasswordPage(),
      ),

      // ===== Main Routes =====
      GoRoute(
        path: AppRoutes.home,
        name: 'home',
        builder: (context, state) => const MainShellPage(),
      ),

      // ===== Pharmacy Routes =====
      // NOTE: Les routes statiques doivent être déclarées AVANT les routes dynamiques
      // pour éviter que /pharmacies/map soit interprétée comme /pharmacies/:id
      GoRoute(
        path: AppRoutes.pharmacies,
        name: 'pharmacies',
        builder: (context, state) => const PharmaciesListPageV2(),
      ),
      GoRoute(
        path: AppRoutes.pharmaciesMap,
        name: 'pharmaciesMap',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return PharmaciesMapPage(
            pharmacies: extra?['pharmacies'] ?? [],
            userLatitude: extra?['userLatitude'],
            userLongitude: extra?['userLongitude'],
          );
        },
      ),
      GoRoute(
        path: AppRoutes.onDutyPharmacies,
        name: 'onDutyPharmacies',
        builder: (context, state) => const OnDutyPharmaciesMapPage(),
      ),
      // Route dynamique en dernier pour éviter les conflits
      GoRoute(
        path: AppRoutes.pharmacyDetails,
        name: 'pharmacyDetails',
        builder: (context, state) {
          final pharmacyId = int.tryParse(state.pathParameters['id'] ?? '');
          if (pharmacyId == null) {
            return _buildInvalidRouteErrorPage(
              context,
              'ID pharmacie invalide',
            );
          }
          return PharmacyDetailsPage(pharmacyId: pharmacyId);
        },
      ),

      // ===== Product Routes =====
      GoRoute(
        path: '/products',
        name: 'productsList',
        builder: (context, state) {
          final query = state.uri.queryParameters['q'];
          return AllProductsPage(initialQuery: query);
        },
      ),
      GoRoute(
        path: '/products/:id',
        name: 'productDetails',
        builder: (context, state) {
          final productId = int.tryParse(state.pathParameters['id'] ?? '');
          if (productId == null) {
            return _buildInvalidRouteErrorPage(context, 'ID produit invalide');
          }
          return ProductDetailsPage(productId: productId);
        },
      ),
      GoRoute(
        path: AppRoutes.frequentProducts,
        name: 'frequentProducts',
        builder: (context, state) => const FrequentProductsListPage(),
      ),
      GoRoute(
        path: AppRoutes.favorites,
        name: 'favorites',
        builder: (context, state) => const FavoritesPage(),
      ),

      // ===== Order Routes =====
      GoRoute(
        path: AppRoutes.cart,
        name: 'cart',
        builder: (context, state) => const CartPage(),
      ),
      GoRoute(
        path: AppRoutes.checkout,
        name: 'checkout',
        builder: (context, state) => const CheckoutPage(),
      ),
      GoRoute(
        path: AppRoutes.orders,
        name: 'orders',
        builder: (context, state) => const OrdersListPage(),
      ),
      GoRoute(
        path: AppRoutes.orderConfirmation,
        name: 'orderConfirmation',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          final orderId = extra?['orderId'] as int? ?? 0;
          final isPaid = extra?['isPaid'] as bool? ?? false;
          return OrderConfirmationPage(orderId: orderId, isPaid: isPaid);
        },
      ),
      GoRoute(
        path: AppRoutes.orderDetails,
        name: 'orderDetails',
        builder: (context, state) {
          final orderId = int.tryParse(state.pathParameters['id'] ?? '');
          if (orderId == null) {
            return _buildInvalidRouteErrorPage(context, 'ID commande invalide');
          }
          return OrderDetailsPage(orderId: orderId);
        },
      ),
      GoRoute(
        path: AppRoutes.orderTracking,
        name: 'orderTracking',
        builder: (context, state) {
          final orderId = int.tryParse(state.pathParameters['id'] ?? '');

          if (orderId == null) {
            return _buildInvalidRouteErrorPage(
              context,
              'ID de commande invalide',
            );
          }

          // Extra peut être null (deep link), le wrapper gère ce cas
          final extra = state.extra as Map<String, dynamic>?;
          final deliveryAddress =
              extra?['deliveryAddress'] as DeliveryAddressEntity?;
          final pharmacyAddress = extra?['pharmacyAddress'] as String?;

          return TrackingPageWrapper(
            orderId: orderId,
            deliveryAddress: deliveryAddress,
            pharmacyAddress: pharmacyAddress,
          );
        },
      ),

      // ===== Prescription Routes =====
      // NOTE: Routes statiques avant routes dynamiques
      GoRoute(
        path: AppRoutes.prescriptions,
        name: 'prescriptions',
        builder: (context, state) => const PrescriptionsListPage(),
      ),
      GoRoute(
        path: AppRoutes.prescriptionUpload,
        name: 'prescriptionUpload',
        builder: (context, state) => const PrescriptionUploadPage(),
      ),
      GoRoute(
        path: AppRoutes.prescriptionScanner,
        name: 'prescriptionScanner',
        builder: (context, state) => const PrescriptionScannerPage(),
      ),
      // Route dynamique en dernier
      GoRoute(
        path: AppRoutes.prescriptionDetails,
        name: 'prescriptionDetails',
        builder: (context, state) {
          final prescriptionId = int.tryParse(state.pathParameters['id'] ?? '');
          if (prescriptionId == null) {
            return _buildInvalidRouteErrorPage(
              context,
              'ID ordonnance invalide',
            );
          }
          return PrescriptionDetailsPage(prescriptionId: prescriptionId);
        },
      ),

      // ===== Address Routes =====
      // NOTE: Routes statiques avant routes dynamiques
      GoRoute(
        path: AppRoutes.addresses,
        name: 'addresses',
        builder: (context, state) => const AddressesListPage(),
      ),
      GoRoute(
        path: AppRoutes.addressesSelect,
        name: 'addressesSelect',
        builder: (context, state) =>
            const AddressesListPage(selectionMode: true),
      ),
      GoRoute(
        path: AppRoutes.addAddress,
        name: 'addAddress',
        builder: (context, state) => const AddAddressPage(),
      ),
      GoRoute(
        path: AppRoutes.editAddress,
        name: 'editAddress',
        builder: (context, state) {
          final address = state.extra as AddressEntity?;
          if (address == null) {
            return _buildInvalidRouteErrorPage(
              context,
              'Adresse non spécifiée',
            );
          }
          return EditAddressPage(address: address);
        },
      ),

      // ===== Profile Routes =====
      GoRoute(
        path: AppRoutes.profile,
        name: 'profile',
        builder: (context, state) => const ProfilePage(),
      ),
      GoRoute(
        path: AppRoutes.editProfile,
        name: 'editProfile',
        builder: (context, state) => const EditProfilePage(),
      ),
      GoRoute(
        path: AppRoutes.notificationSettings,
        name: 'notificationSettings',
        builder: (context, state) => const NotificationSettingsPage(),
      ),

      // ===== Treatments Routes =====
      GoRoute(
        path: AppRoutes.treatments,
        name: 'treatments',
        builder: (context, state) => const TreatmentsPage(),
      ),
      GoRoute(
        path: AppRoutes.addTreatment,
        name: 'addTreatment',
        builder: (context, state) {
          final product = state.extra as ProductEntity?;
          return AddTreatmentPage(initialProduct: product);
        },
      ),
      GoRoute(
        path: AppRoutes.editTreatment,
        name: 'editTreatment',
        builder: (context, state) {
          final treatment = state.extra as TreatmentEntity;
          return AddTreatmentPage(initialTreatment: treatment);
        },
      ),

      // ===== Loyalty Route =====
      GoRoute(
        path: AppRoutes.loyalty,
        name: 'loyalty',
        builder: (context, state) => const LoyaltyPage(),
      ),

      // ===== Payment Callback Routes =====
      // drpharma:///payment/success?reference=XXX → wallet (deep link custom scheme)
      GoRoute(
        path: AppRoutes.paymentSuccess,
        name: 'paymentSuccess',
        redirect: (context, state) => AppRoutes.wallet,
      ),
      // drpharma:///payment/error?reference=XXX → wallet
      GoRoute(
        path: AppRoutes.paymentError,
        name: 'paymentError',
        redirect: (context, state) => AppRoutes.wallet,
      ),
      // Android App Links: https://drlpharma.pro/api/payments/callback/success → wallet
      // Wave ouvre cette URL après paiement → Android ouvre l'app directement (pas Chrome)
      GoRoute(
        path: '/api/payments/callback/success',
        name: 'appLinkPaymentSuccess',
        redirect: (context, state) => AppRoutes.wallet,
      ),
      GoRoute(
        path: '/api/payments/callback/error',
        name: 'appLinkPaymentError',
        redirect: (context, state) => AppRoutes.wallet,
      ),

      // ===== Wallet Routes =====
      GoRoute(
        path: AppRoutes.wallet,
        name: 'wallet',
        builder: (context, state) => const WalletPage(),
      ),
      GoRoute(
        path: AppRoutes.walletTopUp,
        name: 'walletTopUp',
        builder: (context, state) => const TopUpPage(),
      ),
      GoRoute(
        path: AppRoutes.walletWithdraw,
        name: 'walletWithdraw',
        builder: (context, state) => const WithdrawPage(),
      ),

      // ===== Notification Routes =====
      GoRoute(
        path: AppRoutes.notifications,
        name: 'notifications',
        builder: (context, state) => const NotificationsPage(),
      ),

      // ===== Legal & Support Routes =====
      GoRoute(
        path: AppRoutes.help,
        name: 'help',
        builder: (context, state) => const HelpSupportPage(),
      ),
      GoRoute(
        path: AppRoutes.terms,
        name: 'terms',
        builder: (context, state) => const TermsPage(),
      ),
      GoRoute(
        path: AppRoutes.privacy,
        name: 'privacy',
        builder: (context, state) => const PrivacyPolicyPage(),
      ),
      GoRoute(
        path: AppRoutes.legal,
        name: 'legal',
        builder: (context, state) => const LegalNoticesPage(),
      ),
    ],

    // Error page
    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(title: const Text('Erreur')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Page non trouvée',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              state.uri.toString(),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go(AppRoutes.home),
              child: const Text('Retour à l\'accueil'),
            ),
          ],
        ),
      ),
    ),
  );
});

/// Extension pour faciliter la navigation type-safe
extension GoRouterExtension on BuildContext {
  // Auth navigation - utilise go() car on ne veut pas revenir en arrière
  void goToLogin() => go(AppRoutes.login);
  void goToRegister() => go(AppRoutes.register);
  void goToForgotPassword() =>
      push(AppRoutes.forgotPassword); // push pour permettre retour
  void goToHome() => go(AppRoutes.home);
  void goToOnboarding() => go(AppRoutes.onboarding);
  void goToOtpVerification(String phoneNumber) => push(
    AppRoutes.otpVerification,
    extra: phoneNumber,
  ); // push pour permettre retour

  // Pharmacy navigation - utilise push() pour garder home dans la stack
  void goToPharmacies() => push(AppRoutes.pharmacies);
  void goToPharmacy({required int pharmacyId}) =>
      push('/pharmacies/$pharmacyId');
  void goToPharmacyDetails(int pharmacyId) => push('/pharmacies/$pharmacyId');
  void goToOnDutyPharmacies() => push(AppRoutes.onDutyPharmacies);
  void goToPharmaciesMap({
    required List pharmacies,
    double? userLatitude,
    double? userLongitude,
  }) => push(
    '/pharmacies/map',
    extra: {
      'pharmacies': pharmacies,
      'userLatitude': userLatitude,
      'userLongitude': userLongitude,
    },
  );

  // Product navigation - utilise push()
  void goToProducts() => pushNamed('productsList');
  void goToProductsSearch(String query) =>
      push('/products?q=${Uri.encodeComponent(query)}');
  void goToProductDetails(int productId) => push('/products/$productId');
  void goToFavorites() => push(AppRoutes.favorites);

  // Order navigation - utilise push() sauf pour orders list
  void goToCart() => push(AppRoutes.cart);
  void goToCheckout() => push(AppRoutes.checkout);
  void goToOrders() => push(AppRoutes.orders);
  void goToOrderDetails(int orderId) => push('/orders/$orderId');
  void goToOrderConfirmation({required int orderId, required bool isPaid}) =>
      go(
        AppRoutes.orderConfirmation,
        extra: {'orderId': orderId, 'isPaid': isPaid},
      );
  void goToOrderTracking({
    required int orderId,
    required DeliveryAddressEntity deliveryAddress,
    String? pharmacyAddress,
  }) => push(
    '/orders/$orderId/tracking',
    extra: {
      'deliveryAddress': deliveryAddress,
      'pharmacyAddress': pharmacyAddress,
    },
  );

  // Prescription navigation - utilise push()
  void goToPrescriptions() => push(AppRoutes.prescriptions);
  void goToPrescriptionDetails(int prescriptionId) =>
      push('/prescriptions/$prescriptionId');
  void goToPrescriptionUpload() => push(AppRoutes.prescriptionUpload);
  void goToPrescriptionScanner() => push(AppRoutes.prescriptionScanner);

  // Address navigation - utilise push()
  void goToAddresses() => push(AppRoutes.addresses);
  void goToAddAddress() => push(AppRoutes.addAddress);
  void goToEditAddress(AddressEntity address) =>
      push(AppRoutes.editAddress, extra: address);

  // Profile navigation - utilise push()
  void goToProfile() => push(AppRoutes.profile);
  void goToEditProfile() => push(AppRoutes.editProfile);
  void goToNotificationSettings() => push(AppRoutes.notificationSettings);

  // Treatments navigation - utilise push()
  void goToTreatments() => push(AppRoutes.treatments);
  void goToAddTreatment() => push(AppRoutes.addTreatment);
  void goToEditTreatment(TreatmentEntity treatment) =>
      push(AppRoutes.editTreatment, extra: treatment);

  // Loyalty
  void goToLoyalty() => push(AppRoutes.loyalty);

  // Wallet - utilise push()
  void goToWallet() => push(AppRoutes.wallet);
  void goToWalletTopUp() => push(AppRoutes.walletTopUp);
  void goToWalletWithdraw() => push(AppRoutes.walletWithdraw);

  // Notifications - utilise push()
  void goToNotifications() => push(AppRoutes.notifications);

  // Alias explicites pour push (backwards compatibility)
  void pushToPharmacyDetails(int pharmacyId) => push('/pharmacies/$pharmacyId');
  void pushToProductDetails(int productId) => push('/products/$productId');
  void pushToOrderDetails(int orderId) => push('/orders/$orderId');
  void pushToPrescriptionDetails(int prescriptionId) =>
      push('/prescriptions/$prescriptionId');
  void pushToCart() => push(AppRoutes.cart);
  void pushToCheckout() => push(AppRoutes.checkout);
}
