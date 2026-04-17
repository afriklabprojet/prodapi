import 'dart:io' show Platform;

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../constants/ui_constants.dart';
import '../presentation/pages/onboarding_page.dart';
import '../presentation/pages/splash_page.dart';
import '../../features/auth/presentation/pages/forgot_password_page.dart';
import '../../features/auth/presentation/pages/kyc_pending_page.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/register_page.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/auth/presentation/providers/state/auth_state.dart';
import '../../features/chat/presentation/pages/chat_page.dart';
import '../../features/dashboard/presentation/pages/dashboard_page.dart';
import '../../features/inventory/presentation/pages/enhanced_scanner_page.dart';
import '../../features/notifications/presentation/pages/notifications_page.dart';
import '../../features/on_call/presentation/pages/on_call_page.dart';
import '../../features/orders/presentation/pages/order_details_page.dart';
import '../../features/orders/presentation/pages/order_details_wrapper_page.dart';
import '../../features/prescriptions/presentation/pages/prescription_details_page.dart';
import '../../features/prescriptions/presentation/pages/prescription_details_wrapper_page.dart';
import '../../features/prescriptions/presentation/widgets/prescription_image_viewer.dart';
import '../../features/profile/presentation/pages/appearance_settings_page.dart';
import '../../features/profile/presentation/pages/edit_pharmacy_page.dart';
import '../../features/profile/presentation/pages/edit_profile_page.dart';
import '../../features/profile/presentation/pages/help_support_page.dart';
import '../../features/profile/presentation/pages/legal_page.dart';
import '../../features/profile/presentation/pages/notification_settings_page.dart';
import '../../features/profile/presentation/pages/security_settings_page.dart';
import '../../features/reports/presentation/pages/reports_dashboard_page.dart';
import '../../features/team/presentation/pages/team_management_page.dart';
// Entity imports for typed route extras
import '../../features/auth/domain/entities/pharmacy_entity.dart';
import '../../features/auth/domain/entities/user_entity.dart';
import '../../features/orders/domain/entities/order_entity.dart';
import '../../features/prescriptions/data/models/prescription_model.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Route Data Classes (type-safe extras)
// ─────────────────────────────────────────────────────────────────────────────

/// Arguments typés pour la page de chat.
class ChatRouteData {
  final int deliveryId;
  final String participantType;
  final int participantId;
  final String participantName;

  const ChatRouteData({
    required this.deliveryId,
    required this.participantType,
    required this.participantId,
    required this.participantName,
  });
}

/// Arguments typés pour le viewer d'image plein écran.
class PrescriptionImageRouteData {
  final List<String> urls;
  final int initialIndex;
  final String authToken;
  final bool isFullyDispensed;

  const PrescriptionImageRouteData({
    required this.urls,
    required this.initialIndex,
    required this.authToken,
    required this.isFullyDispensed,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// Constantes et helpers
// ─────────────────────────────────────────────────────────────────────────────

/// Vérifie si on est sur iOS (pas sur web)
bool get _isIOS => !kIsWeb && Platform.isIOS;

/// Routes publiques accessibles sans authentification.
const _publicRoutes = {'/', '/onboarding', '/terms', '/privacy'};

/// Routes d'authentification (login, register, forgot-password).
const _authRoutes = {'/login', '/register', '/forgot-password'};

/// Routes autorisées même sans KYC approuvé.
const _allowedWithoutKyc = {'/help-support', '/terms', '/privacy'};

/// Page adaptative : CupertinoPage sur iOS (swipe-back natif),
/// transition Material custom sur Android/Web.
Page<T> _buildAdaptivePage<T>({
  required GoRouterState state,
  required Widget child,
  bool fullscreenDialog = false,
}) {
  if (_isIOS) {
    return CupertinoPage<T>(
      key: state.pageKey,
      child: child,
      fullscreenDialog: fullscreenDialog,
    );
  }

  // Android/Web : transition slide + fade
  return CustomTransitionPage<T>(
    key: state.pageKey,
    child: child,
    fullscreenDialog: fullscreenDialog,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final offsetAnimation = animation.drive(
        Tween(
          begin: const Offset(0.15, 0.0),
          end: Offset.zero,
        ).chain(CurveTween(curve: Curves.easeOutCubic)),
      );
      return SlideTransition(
        position: offsetAnimation,
        child: FadeTransition(
          opacity: CurveTween(curve: Curves.easeOut).animate(animation),
          child: child,
        ),
      );
    },
    transitionDuration: const Duration(milliseconds: 250),
    reverseTransitionDuration: AnimationConstants.standard,
  );
}

/// Helper pour créer une route simple avec page adaptive.
GoRoute _simpleRoute(String path, Widget child, {bool fullscreen = false}) {
  return GoRoute(
    path: path,
    pageBuilder: (context, state) => _buildAdaptivePage(
      state: state,
      child: child,
      fullscreenDialog: fullscreen,
    ),
  );
}

/// Extrait un paramètre int depuis les pathParameters avec fallback.
int _getIntParam(GoRouterState state, String key) =>
    int.tryParse(state.pathParameters[key] ?? '') ?? 0;

/// Extrait l'extra typé ou null.
T? _getTypedExtra<T>(GoRouterState state) => state.extra as T?;

// ─────────────────────────────────────────────────────────────────────────────
// Router Notifier
// ─────────────────────────────────────────────────────────────────────────────

/// Notifier pour rafraîchir le router quand l'état d'authentification change.
/// Stocke une copie locale de l'AuthState pour éviter :
/// 1. La recréation complète du GoRouter à chaque changement d'état
/// 2. Le cycle ref.read() pendant la notification (erreur Riverpod)
class RouterNotifier extends ChangeNotifier {
  final Ref _ref;
  late AuthState _authState;

  RouterNotifier(this._ref) {
    _authState = _ref.read(authProvider);
    _ref.listen<AuthState>(authProvider, (prev, next) {
      _authState = next;
      // Ne notifier le router que pour les transitions de navigation réelles
      // (pas pour loading, error, registered qui sont des états transitoires)
      final navStatuses = {
        AuthStatus.authenticated,
        AuthStatus.unauthenticated,
        AuthStatus.initial,
      };
      if (navStatuses.contains(next.status) && prev?.status != next.status) {
        notifyListeners();
      }
    });
  }

  AuthState get authState => _authState;

  bool get isLoggedIn => _authState.status == AuthStatus.authenticated;

  /// Vérifie si la pharmacie a un KYC approuvé.
  bool get kycApproved {
    final status = _authState.user?.pharmacy?.status ?? 'pending_review';
    return status == 'active' || status == 'approved';
  }
}

final _routerNotifierProvider = ChangeNotifierProvider<RouterNotifier>((ref) {
  return RouterNotifier(ref);
});

// ─────────────────────────────────────────────────────────────────────────────
// Redirect Logic
// ─────────────────────────────────────────────────────────────────────────────

/// Calcule la redirection basée sur l'état d'authentification.
String? _computeRedirect(RouterNotifier notifier, String currentPath) {
  // Routes publiques : pas de redirection
  if (_publicRoutes.contains(currentPath)) return null;

  // Routes d'auth : rediriger si déjà connecté
  if (_authRoutes.contains(currentPath)) {
    if (notifier.isLoggedIn) {
      return notifier.kycApproved ? '/dashboard' : '/kyc-pending';
    }
    return null;
  }

  // Pages protégées : rediriger vers login si pas connecté
  if (!notifier.isLoggedIn) return '/login';

  // KYC check pour les pages protégées
  final isKycPending = currentPath == '/kyc-pending';
  if (isKycPending && notifier.kycApproved) return '/dashboard';
  if (!notifier.kycApproved && !isKycPending) {
    if (!_allowedWithoutKyc.contains(currentPath)) return '/kyc-pending';
  }

  return null;
}

// ─────────────────────────────────────────────────────────────────────────────
// Router Provider
// ─────────────────────────────────────────────────────────────────────────────

final routerProvider = Provider<GoRouter>((ref) {
  final notifier = ref.watch(_routerNotifierProvider);

  return GoRouter(
    initialLocation: '/',
    refreshListenable: notifier,
    redirect: (context, state) => _computeRedirect(notifier, state.uri.path),
    routes: _buildRoutes(),
    errorBuilder: (context, state) => _ErrorPage(uri: state.uri),
  );
});

/// Construit la liste des routes de l'application.
List<RouteBase> _buildRoutes() => [
  // Routes sans transition (pages initiales)
  GoRoute(path: '/', builder: (_, __) => const SplashPage()),
  GoRoute(path: '/onboarding', builder: (_, __) => const OnboardingPage()),
  GoRoute(path: '/login', builder: (_, __) => const LoginPage()),
  GoRoute(path: '/kyc-pending', builder: (_, __) => const KycPendingPage()),
  GoRoute(path: '/dashboard', builder: (_, __) => const DashboardPage()),

  // Routes simples avec transition adaptive
  _simpleRoute('/register', const RegisterPage()),
  _simpleRoute('/forgot-password', const ForgotPasswordPage()),
  _simpleRoute('/notifications', const NotificationsPage()),
  _simpleRoute('/security-settings', const SecuritySettingsPage()),
  _simpleRoute('/appearance-settings', const AppearanceSettingsPage()),
  _simpleRoute('/notification-settings', const NotificationSettingsPage()),
  _simpleRoute('/help-support', const HelpSupportPage()),
  _simpleRoute('/terms', const LegalPage(type: 'terms')),
  _simpleRoute('/privacy', const LegalPage(type: 'privacy')),
  _simpleRoute('/reports', const ReportsDashboardPage()),
  _simpleRoute('/team', const TeamManagementPage()),
  _simpleRoute('/on-call', const OnCallPage()),
  _simpleRoute('/scanner', const EnhancedScannerPage(), fullscreen: true),

  // Routes avec paramètres path
  GoRoute(
    path: '/orders/:id',
    pageBuilder: (_, state) => _buildAdaptivePage(
      state: state,
      child: OrderDetailsWrapperPage(orderId: _getIntParam(state, 'id')),
    ),
  ),
  GoRoute(
    path: '/prescriptions/:id',
    pageBuilder: (_, state) => _buildAdaptivePage(
      state: state,
      child: PrescriptionDetailsWrapperPage(
        prescriptionId: _getIntParam(state, 'id'),
      ),
    ),
  ),

  // Routes avec extras typés
  GoRoute(
    path: '/edit-profile',
    pageBuilder: (_, state) => _buildAdaptivePage(
      state: state,
      child: EditProfilePage(user: state.extra as UserEntity?),
    ),
  ),
  GoRoute(
    path: '/edit-pharmacy',
    pageBuilder: (_, state) {
      final pharmacy = state.extra as PharmacyEntity?;
      if (pharmacy == null)
        return _buildAdaptivePage(state: state, child: const _ErrorPage());
      return _buildAdaptivePage(
        state: state,
        child: EditPharmacyPage(pharmacy: pharmacy),
      );
    },
  ),
  GoRoute(
    path: '/order-details',
    pageBuilder: (_, state) {
      final order = state.extra as OrderEntity?;
      if (order == null)
        return _buildAdaptivePage(state: state, child: const _ErrorPage());
      return _buildAdaptivePage(
        state: state,
        child: OrderDetailsPage(order: order),
      );
    },
  ),
  GoRoute(
    path: '/prescription-details',
    pageBuilder: (_, state) {
      final prescription = state.extra as PrescriptionModel?;
      if (prescription == null)
        return _buildAdaptivePage(state: state, child: const _ErrorPage());
      return _buildAdaptivePage(
        state: state,
        child: PrescriptionDetailsPage(prescription: prescription),
      );
    },
  ),

  // Routes avec extras complexes
  GoRoute(
    path: '/chat',
    pageBuilder: (_, state) {
      final data = _getTypedExtra<ChatRouteData>(state);
      if (data == null)
        return _buildAdaptivePage(state: state, child: const _ErrorPage());
      return _buildAdaptivePage(
        state: state,
        child: ChatPage(
          deliveryId: data.deliveryId,
          participantType: data.participantType,
          participantId: data.participantId,
          participantName: data.participantName,
        ),
      );
    },
  ),
  GoRoute(
    path: '/prescription-image',
    pageBuilder: (_, state) {
      final data = _getTypedExtra<PrescriptionImageRouteData>(state);
      if (data == null)
        return _buildAdaptivePage(state: state, child: const _ErrorPage());
      return _buildAdaptivePage(
        state: state,
        child: FullscreenImageViewer(
          urls: data.urls,
          initialIndex: data.initialIndex,
          authToken: data.authToken,
          isFullyDispensed: data.isFullyDispensed,
        ),
        fullscreenDialog: true,
      );
    },
  ),
];

// ─────────────────────────────────────────────────────────────────────────────
// Error Page Widget
// ─────────────────────────────────────────────────────────────────────────────

class _ErrorPage extends StatelessWidget {
  final Uri? uri;
  const _ErrorPage({this.uri});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Page introuvable')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            if (uri != null)
              Text(
                'Route introuvable: $uri',
                style: const TextStyle(fontSize: 16),
              ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.go('/dashboard'),
              child: const Text('Retour au tableau de bord'),
            ),
          ],
        ),
      ),
    );
  }
}
