import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../config/providers.dart';
import '../contracts/deep_link_contract.dart';
import '../services/deep_link_service.dart';
import '../widgets/app_snackbar.dart';

/// ─────────────────────────────────────────────────────────
/// Deep Link Auth Handler
/// ─────────────────────────────────────────────────────────
///
/// Gère les deep links pour les utilisateurs non connectés:
/// 1. Intercepte le deep link entrant
/// 2. Vérifie si l'utilisateur est authentifié
/// 3. Si non connecté : stocke le deep link + redirige vers login
/// 4. Après login réussi : consomme le deep link et navigue
///
/// Usage dans GoRouter redirect:
/// ```dart
/// GoRouter(
///   redirect: (context, state) {
///     return DeepLinkAuthHandler.handleRouteAuth(
///       ref: ref,
///       currentPath: state.matchedLocation,
///       isAuthenticated: authState.isAuthenticated,
///     );
///   },
/// );
/// ```
class DeepLinkAuthHandler {
  /// Routes publiques accessibles sans authentification
  static const Set<String> publicRoutes = {
    '/',
    '/splash',
    '/onboarding',
    '/login',
    '/register',
    '/forgot-password',
    '/otp-verification',
    '/change-password',
    '/pharmacies',
    '/products',
    '/help',
    '/terms',
    '/privacy',
    '/legal',
  };

  /// Préfixes de routes publiques
  static const List<String> publicPrefixes = ['/pharmacies/', '/products/'];

  /// Vérifie si une route nécessite l'authentification
  static bool requiresAuth(String path) {
    // Routes publiques exactes
    if (publicRoutes.contains(path)) {
      return false;
    }

    // Préfixes publics (ex: /pharmacies/123)
    for (final prefix in publicPrefixes) {
      if (path.startsWith(prefix)) {
        return false;
      }
    }

    // Tout le reste nécessite auth
    return true;
  }

  /// Gère la logique de redirection avec deep link
  /// Retourne le path de redirection ou null si pas de redirection
  static String? handleRouteAuth({
    required WidgetRef ref,
    required String currentPath,
    required bool isAuthenticated,
    bool isLoading = false,
  }) {
    // Si en cours de chargement, ne rien faire
    if (isLoading) return null;

    // Route publique = pas de redirection
    if (!requiresAuth(currentPath)) return null;

    // Utilisateur connecté = pas de redirection
    if (isAuthenticated) return null;

    // Utilisateur non connecté sur une route protégée
    // → Stocker le deep link et rediriger vers login
    _storePendingDeepLink(ref, currentPath);
    return '/login';
  }

  /// Stocke le deep link en attente
  static Future<void> _storePendingDeepLink(WidgetRef ref, String path) async {
    try {
      final deepLinkService = ref.read(deepLinkServiceProvider);
      final deepLinkData = DeepLinkData(
        uri: Uri.parse(path),
        path: path,
        queryParams: {},
        receivedAt: DateTime.now(),
      );
      await deepLinkService.storePendingDeepLink(deepLinkData);
      debugPrint('[DeepLinkAuthHandler] Stored pending deep link: $path');
    } catch (e) {
      debugPrint('[DeepLinkAuthHandler] Error storing deep link: $e');
    }
  }

  /// Consomme le deep link en attente après login réussi
  /// Retourne le path à naviguer ou null si pas de deep link
  ///
  /// [onError] - Callback optionnel appelé en cas d'erreur de parsing
  /// Utile pour afficher un snackbar ou log analytics
  static Future<String?> consumePendingDeepLink(
    WidgetRef ref, {
    void Function(Object error, StackTrace? stackTrace)? onError,
  }) async {
    try {
      debugPrint(
        '[DeepLinkAuthHandler] Attempting to consume pending deep link...',
      );
      final pendingDeepLink = await ref.read(pendingDeepLinkProvider.future);

      if (pendingDeepLink != null) {
        // Validate the path before returning
        final path = pendingDeepLink.path;
        if (path.isEmpty || !path.startsWith('/')) {
          debugPrint('[DeepLinkAuthHandler] Invalid deep link path: "$path"');
          onError?.call(
            FormatException('Invalid deep link path: "$path"'),
            StackTrace.current,
          );
          return null;
        }

        debugPrint(
          '[DeepLinkAuthHandler] Successfully consumed deep link: $path',
        );
        debugPrint(
          '[DeepLinkAuthHandler] Query params: ${pendingDeepLink.queryParams}',
        );
        debugPrint(
          '[DeepLinkAuthHandler] Received at: ${pendingDeepLink.receivedAt}',
        );
        return path;
      } else {
        debugPrint('[DeepLinkAuthHandler] No pending deep link found');
      }
    } catch (e, stackTrace) {
      debugPrint('[DeepLinkAuthHandler] Error consuming deep link: $e');
      debugPrint('[DeepLinkAuthHandler] Stack trace: $stackTrace');
      onError?.call(e, stackTrace);
    }
    return null;
  }
}

/// ─────────────────────────────────────────────────────────
/// Mixin for pages that need deep link handling
/// ─────────────────────────────────────────────────────────
///
/// Usage:
/// ```dart
/// class HomePage extends ConsumerStatefulWidget { ... }
///
/// class _HomePageState extends ConsumerState<HomePage>
///     with DeepLinkHandlerMixin {
///
///   @override
///   void initState() {
///     super.initState();
///     checkAndHandlePendingDeepLink(); // Vérifie les deep links en attente
///   }
/// }
/// ```
mixin DeepLinkHandlerMixin<T extends ConsumerStatefulWidget>
    on ConsumerState<T> {
  /// Vérifie et gère les deep links en attente
  ///
  /// [showErrorSnackbar] - Si true, affiche un snackbar en cas d'erreur
  Future<void> checkAndHandlePendingDeepLink({
    bool showErrorSnackbar = true,
  }) async {
    final path = await DeepLinkAuthHandler.consumePendingDeepLink(
      ref,
      onError: showErrorSnackbar
          ? (error, stackTrace) {
              if (mounted) {
                AppSnackbar.warning(
                  context,
                  'Impossible de traiter le lien. Veuillez réessayer.',
                );
              }
            }
          : null,
    );

    if (path != null && mounted) {
      // Petit délai pour laisser le temps à la page de se construire
      await Future.delayed(const Duration(milliseconds: 100));
      if (mounted) {
        debugPrint('[DeepLinkHandlerMixin] Navigating to: $path');
        context.go(path);
      }
    }
  }
}

/// ─────────────────────────────────────────────────────────
/// Post-Login Deep Link Handler Widget
/// ─────────────────────────────────────────────────────────
///
/// Widget wrapper qui vérifie automatiquement les deep links
/// après une connexion réussie.
///
/// Usage:
/// ```dart
/// // Dans le callback de login réussi
/// Navigator.of(context).pushReplacement(
///   MaterialPageRoute(
///     builder: (_) => PostLoginDeepLinkHandler(
///       onNoDeepLink: () => context.go('/home'),
///     ),
///   ),
/// );
/// ```
class PostLoginDeepLinkHandler extends ConsumerStatefulWidget {
  /// Callback appelé s'il n'y a pas de deep link en attente
  final VoidCallback onNoDeepLink;

  /// Widget à afficher pendant le chargement
  final Widget? loadingWidget;

  const PostLoginDeepLinkHandler({
    super.key,
    required this.onNoDeepLink,
    this.loadingWidget,
  });

  @override
  ConsumerState<PostLoginDeepLinkHandler> createState() =>
      _PostLoginDeepLinkHandlerState();
}

class _PostLoginDeepLinkHandlerState
    extends ConsumerState<PostLoginDeepLinkHandler> {
  @override
  void initState() {
    super.initState();
    _handlePostLogin();
  }

  Future<void> _handlePostLogin() async {
    final path = await DeepLinkAuthHandler.consumePendingDeepLink(ref);

    if (!mounted) return;

    if (path != null) {
      context.go(path);
    } else {
      widget.onNoDeepLink();
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.loadingWidget ??
        const Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Connexion en cours...'),
              ],
            ),
          ),
        );
  }
}

/// ─────────────────────────────────────────────────────────
/// Extension pour GoRouter avec deep link support
/// ─────────────────────────────────────────────────────────
extension GoRouterDeepLinkExtension on GoRouter {
  /// Vérifie les deep links en attente et navigue si nécessaire
  Future<void> handlePendingDeepLink(WidgetRef ref) async {
    final path = await DeepLinkAuthHandler.consumePendingDeepLink(ref);
    if (path != null) {
      go(path);
    }
  }
}
