import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/register_page.dart';
import '../../features/auth/presentation/pages/forgot_password_page.dart';
import '../../features/dashboard/presentation/pages/dashboard_page.dart';
import '../../features/notifications/presentation/pages/notifications_page.dart';
import '../../features/profile/presentation/pages/security_settings_page.dart';
import '../../features/profile/presentation/pages/appearance_settings_page.dart';
import '../../features/profile/presentation/pages/notification_settings_page.dart';
import '../../features/profile/presentation/pages/help_support_page.dart';
import '../../features/profile/presentation/pages/legal_page.dart';
import '../../features/reports/presentation/pages/reports_dashboard_page.dart';
import '../../features/inventory/presentation/pages/enhanced_scanner_page.dart';
import '../../features/orders/presentation/pages/order_details_wrapper_page.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/auth/presentation/providers/state/auth_state.dart';
import '../presentation/pages/splash_page.dart';
import '../presentation/pages/onboarding_page.dart';

/// Notifier pour rafraîchir le router quand l'état d'authentification change.
/// Stocke une copie locale de l'AuthState pour éviter :
/// 1. La recréation complète du GoRouter à chaque changement d'état
/// 2. Le cycle ref.read() pendant la notification (erreur Riverpod)
class RouterNotifier extends ChangeNotifier {
  final Ref _ref;
  late AuthState _authState;

  RouterNotifier(this._ref) {
    _authState = _ref.read(authProvider);
    _ref.listen<AuthState>(
      authProvider,
      (_, next) {
        _authState = next;
        notifyListeners();
      },
    );
  }

  AuthState get authState => _authState;
}

final _routerNotifierProvider = ChangeNotifierProvider<RouterNotifier>((ref) {
  return RouterNotifier(ref);
});

final routerProvider = Provider<GoRouter>((ref) {
  final notifier = ref.watch(_routerNotifierProvider);

  return GoRouter(
    initialLocation: '/',
    refreshListenable: notifier,
    redirect: (context, state) {
      final authState = notifier.authState;
      final isLoggedIn = authState.status == AuthStatus.authenticated;
      final currentPath = state.uri.path;
      
      final isSplash = currentPath == '/';
      final isOnboarding = currentPath == '/onboarding';
      final isLoggingIn = currentPath == '/login';
      final isRegistering = currentPath == '/register';
      final isRecoveringPassword = currentPath == '/forgot-password';
      final isPublicLegal = currentPath == '/terms' || currentPath == '/privacy';

      // Splash, onboarding, and public legal pages: no redirect
      if (isSplash || isOnboarding || isPublicLegal) return null;

      // Sur une page d'auth (login, register, forgot-password) :
      // Ne jamais rediriger pendant loading, error ou registered
      // → permet de rester sur la page pour voir le résultat
      if (isLoggingIn || isRegistering || isRecoveringPassword) {
        // Si authentifié (login réussi), rediriger vers dashboard
        if (isLoggedIn) return '/dashboard';
        // Sinon, rester sur la page (loading, error, registered, unauthenticated, initial)
        return null;
      }

      // Page protégée : rediriger vers login si pas authentifié
      if (!isLoggedIn) {
        return '/login';
      }

      return null;
    },
    routes: [
      GoRoute(path: '/', builder: (context, state) => const SplashPage()),
      GoRoute(path: '/onboarding', builder: (context, state) => const OnboardingPage()),
      GoRoute(path: '/login', builder: (context, state) => const LoginPage()),

      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterPage(),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordPage(),
      ),
      GoRoute(
        path: '/dashboard',
        builder: (context, state) => const DashboardPage(),
      ),
      GoRoute(
        path: '/notifications',
        builder: (context, state) => const NotificationsPage(),
      ),
      GoRoute(
        path: '/security-settings',
        builder: (context, state) => const SecuritySettingsPage(),
      ),
      GoRoute(
        path: '/appearance-settings',
        builder: (context, state) => const AppearanceSettingsPage(),
      ),
      GoRoute(
        path: '/notification-settings',
        builder: (context, state) => const NotificationSettingsPage(),
      ),
      GoRoute(
        path: '/help-support',
        builder: (context, state) => const HelpSupportPage(),
      ),
      GoRoute(
        path: '/terms',
        builder: (context, state) => const LegalPage(type: 'terms'),
      ),
      GoRoute(
        path: '/privacy',
        builder: (context, state) => const LegalPage(type: 'privacy'),
      ),
      GoRoute(
        path: '/reports',
        builder: (context, state) => const ReportsDashboardPage(),
      ),
      GoRoute(
        path: '/scanner',
        builder: (context, state) => const EnhancedScannerPage(),
      ),
      GoRoute(
        path: '/orders/:id',
        builder: (context, state) {
          final orderId = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
          return OrderDetailsWrapperPage(orderId: orderId);
        },
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(title: const Text('Page introuvable')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text('Route introuvable: ${state.uri}',
                style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.go('/dashboard'),
              child: const Text('Retour au tableau de bord'),
            ),
          ],
        ),
      ),
    ),
  );
});

