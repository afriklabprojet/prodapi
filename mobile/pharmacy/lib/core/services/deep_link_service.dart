import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';

/// Service de gestion des deep links
/// Gère cold start + runtime deep links avec validation
class DeepLinkService {
  static DeepLinkService? _instance;
  static DeepLinkService get instance => _instance ??= DeepLinkService._();
  
  DeepLinkService._();
  
  final _appLinks = AppLinks();
  StreamSubscription<Uri>? _linkSubscription;
  GoRouter? _router;
  Uri? _pendingDeepLink;
  bool _isInitialized = false;
  
  /// Routes autorisées pour les deep links
  /// Chaque route doit correspondre à une route GoRouter valide
  static const _allowedDeepLinkPaths = [
    // Commandes
    '/orders',
    '/order',
    // Ordonnances
    '/prescriptions',
    '/prescription',
    // Inventaire & Produits
    '/inventory',
    '/product',
    '/scanner',
    // Finances
    '/wallet',
    '/reports',
    // Notifications
    '/notifications',
    // Profil & Paramètres
    '/profile',
    '/settings',
    // Pages légales
    '/terms',
    '/privacy',
    // Mode garde & urgences
    '/on-call',
  ];
  
  /// Initialise le service de deep links
  /// Doit être appelé après la création du GoRouter
  Future<void> initialize(GoRouter router) async {
    if (_isInitialized) return;
    
    _router = router;
    _isInitialized = true;
    
    try {
      // 1. Vérifier le deep link de cold start
      final initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) {
        if (kDebugMode) {
          debugPrint('🔗 [DeepLink] Cold start link: $initialUri');
        }
        _handleDeepLink(initialUri, isColdStart: true);
      }
      
      // 2. Écouter les deep links en runtime
      _linkSubscription = _appLinks.uriLinkStream.listen(
        (Uri uri) {
          if (kDebugMode) {
            debugPrint('🔗 [DeepLink] Runtime link: $uri');
          }
          _handleDeepLink(uri, isColdStart: false);
        },
        onError: (error) {
          if (kDebugMode) {
            debugPrint('❌ [DeepLink] Error: $error');
          }
        },
      );
      
      if (kDebugMode) {
        debugPrint('✅ [DeepLink] Service initialized');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ [DeepLink] Initialization failed: $e');
      }
    }
  }
  
  /// Traite un deep link
  void _handleDeepLink(Uri uri, {required bool isColdStart}) {
    final path = uri.path;
    
    // Valider le path
    if (!_isAllowedPath(path)) {
      if (kDebugMode) {
        debugPrint('⚠️ [DeepLink] Blocked unauthorized path: $path');
      }
      return;
    }
    
    // Si c'est un cold start et que l'auth n'est pas prête, stocker pour plus tard
    if (isColdStart && _router == null) {
      _pendingDeepLink = uri;
      if (kDebugMode) {
        debugPrint('⏳ [DeepLink] Pending until router ready: $path');
      }
      return;
    }
    
    _navigateToDeepLink(uri);
  }
  
  /// Vérifie si le path est autorisé
  bool _isAllowedPath(String path) {
    return _allowedDeepLinkPaths.any((allowed) => path.startsWith(allowed));
  }
  
  /// Navigue vers le deep link
  void _navigateToDeepLink(Uri uri) {
    if (_router == null) return;
    
    final path = uri.path;
    final queryParams = uri.queryParameters;
    
    try {
      // Construire la route avec les query params
      String fullPath = path;
      if (queryParams.isNotEmpty) {
        final queryString = queryParams.entries
            .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
            .join('&');
        fullPath = '$path?$queryString';
      }
      
      _router!.go(fullPath);
      
      if (kDebugMode) {
        debugPrint('✅ [DeepLink] Navigated to: $fullPath');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ [DeepLink] Navigation failed: $e');
      }
    }
  }
  
  /// Traite le deep link en attente (après que l'auth soit prête)
  void processPendingDeepLink() {
    if (_pendingDeepLink != null) {
      if (kDebugMode) {
        debugPrint('📬 [DeepLink] Processing pending: ${_pendingDeepLink!.path}');
      }
      _navigateToDeepLink(_pendingDeepLink!);
      _pendingDeepLink = null;
    }
  }
  
  /// Vérifie s'il y a un deep link en attente
  bool get hasPendingDeepLink => _pendingDeepLink != null;
  
  /// Retourne le pending deep link path (pour debug)
  String? get pendingDeepLinkPath => _pendingDeepLink?.path;
  
  /// Génère un deep link pour l'app
  Uri generateDeepLink({
    required String path,
    Map<String, String>? queryParams,
  }) {
    // Utiliser le scheme de l'app (à configurer dans le manifest)
    return Uri(
      scheme: 'drpharma',
      host: 'pharmacy',
      path: path,
      queryParameters: queryParams,
    );
  }
  
  /// Génère un lien de partage pour une commande
  Uri generateOrderShareLink(String orderId) {
    return generateDeepLink(
      path: '/order/$orderId',
    );
  }
  
  /// Clean up
  void dispose() {
    _linkSubscription?.cancel();
    _linkSubscription = null;
    _router = null;
    _pendingDeepLink = null;
    _isInitialized = false;
  }
}
