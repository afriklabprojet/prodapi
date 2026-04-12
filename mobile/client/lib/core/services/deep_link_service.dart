import 'dart:async';
import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../contracts/deep_link_contract.dart';
import '../constants/storage_keys.dart';
import 'app_logger.dart';

/// Implémentation du service de deep linking
///
/// Gère les liens profonds entrants, stocke les liens en attente
/// pour les utilisateurs non authentifiés, et les consomme après login.
///
/// Flux typique :
/// 1. L'app reçoit un deep link (ex: drpharma://orders/123/tracking)
/// 2. Si l'utilisateur est authentifié → navigation immédiate
/// 3. Si non authentifié → stockage du lien + redirection vers login
/// 4. Après login → consommation du lien en attente → navigation
class DeepLinkService implements DeepLinkContract {
  final SharedPreferences _prefs;

  /// Callback pour vérifier si l'utilisateur est authentifié
  final bool Function() _isAuthenticated;

  /// Callback pour naviguer vers une route
  final void Function(String path, {Map<String, dynamic>? extra}) _navigate;

  /// StreamController pour les deep links entrants
  final _deepLinkController = StreamController<DeepLinkData>.broadcast();

  /// URI initiale de lancement de l'app
  DeepLinkData? _initialDeepLink;

  bool _isInitialized = false;

  /// Schémas URI supportés
  static const supportedSchemes = ['drpharma', 'https', 'http'];

  /// Hôtes supportés pour les liens http/https
  static const supportedHosts = [
    'drpharma.ci',
    'www.drpharma.ci',
    'app.drpharma.ci',
  ];

  DeepLinkService({
    required SharedPreferences prefs,
    required bool Function() isAuthenticated,
    required void Function(String path, {Map<String, dynamic>? extra}) navigate,
  }) : _prefs = prefs,
       _isAuthenticated = isAuthenticated,
       _navigate = navigate;

  @override
  Future<void> init() async {
    if (_isInitialized) return;

    // Capturer l'URI initiale de lancement via WidgetsBinding
    try {
      final initialUri =
          WidgetsBinding.instance.platformDispatcher.defaultRouteName;
      if (initialUri.isNotEmpty && initialUri != '/') {
        final parsed = _parseUri(initialUri);
        if (parsed != null) {
          _initialDeepLink = parsed;
        }
      }
    } catch (e, stackTrace) {
      AppLogger.warning(
        'DeepLinkService: Failed to get initial URI',
        error: e,
        stackTrace: stackTrace,
      );
    }

    _isInitialized = true;
  }

  @override
  void dispose() {
    _deepLinkController.close();
  }

  @override
  Future<DeepLinkData?> getInitialDeepLink() async => _initialDeepLink;

  @override
  Stream<DeepLinkData> get deepLinkStream => _deepLinkController.stream;

  @override
  Future<DeepLinkResult> handleDeepLink(Uri uri) async {
    final deepLinkData = _parseUri(uri.toString());
    if (deepLinkData == null) {
      return DeepLinkResult.invalid;
    }

    // Vérifier si la route nécessite une authentification
    if (requiresAuth(deepLinkData)) {
      if (!_isAuthenticated()) {
        // Stocker le deep link pour après le login
        await storePendingDeepLink(deepLinkData);
        // Naviguer vers login
        _navigate('/login');
        return DeepLinkResult.requiresAuth;
      }
    }

    // Naviguer vers la destination
    _navigate(deepLinkData.path, extra: deepLinkData.extra);
    _deepLinkController.add(deepLinkData);

    return DeepLinkResult.handled;
  }

  @override
  Future<void> storePendingDeepLink(DeepLinkData deepLink) async {
    await _prefs.setString(
      StorageKeys.pendingDeepLink,
      jsonEncode(deepLink.toJson()),
    );
  }

  @override
  Future<DeepLinkData?> consumePendingDeepLink() async {
    final stored = _prefs.getString(StorageKeys.pendingDeepLink);
    if (stored == null) return null;

    // Supprimer immédiatement pour éviter double traitement
    await _prefs.remove(StorageKeys.pendingDeepLink);

    try {
      final json = jsonDecode(stored) as Map<String, dynamic>;
      return DeepLinkData.fromJson(json);
    } catch (e, stackTrace) {
      AppLogger.warning(
        'DeepLinkService: Failed to parse pending deep link',
        error: e,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  @override
  bool requiresAuth(DeepLinkData data) {
    final path = data.path;

    // Routes publiques accessibles sans authentification
    const publicRoutes = [
      '/',
      '/onboarding',
      '/login',
      '/register',
      '/forgot-password',
      '/otp-verification',
      '/pharmacies',
      '/products',
      '/help',
      '/terms',
      '/privacy',
      '/legal',
    ];

    // Vérifier les routes publiques exactes
    if (publicRoutes.contains(path)) {
      return false;
    }

    // Vérifier les préfixes de routes publiques (pharmacies/123, products/456)
    const publicPrefixes = ['/pharmacies/', '/products/'];
    for (final prefix in publicPrefixes) {
      if (path.startsWith(prefix)) {
        return false;
      }
    }

    // Toute autre route nécessite une authentification
    return true;
  }

  /// Parse une URI en DeepLinkData
  DeepLinkData? _parseUri(String uriString) {
    try {
      final uri = Uri.tryParse(uriString);
      if (uri == null) return null;

      // Vérifier le schéma (allow empty for relative paths)
      if (uri.scheme.isNotEmpty && !supportedSchemes.contains(uri.scheme)) {
        return null;
      }

      // Pour http/https, vérifier l'hôte
      if ((uri.scheme == 'http' || uri.scheme == 'https') &&
          uri.host.isNotEmpty &&
          !supportedHosts.contains(uri.host)) {
        return null;
      }

      String path = uri.path;

      // Pour les schémas custom (drpharma://), l'hôte est la première partie du path
      if (uri.scheme == 'drpharma' && uri.host.isNotEmpty) {
        path = '/${uri.host}${uri.path}';
      }

      // Normaliser le path
      if (path.isEmpty) path = '/';
      if (!path.startsWith('/')) path = '/$path';

      return DeepLinkData(
        uri: uri,
        path: path,
        queryParams: uri.queryParameters,
        receivedAt: DateTime.now(),
      );
    } catch (e, stackTrace) {
      AppLogger.warning(
        'DeepLinkService: Failed to parse URI $uriString',
        error: e,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  /// Convertir un DeepLinkData en URI pour le router
  String buildRouteFromDeepLink(DeepLinkData data) {
    if (data.queryParams.isEmpty) {
      return data.path;
    }

    final queryString = data.queryParams.entries
        .map(
          (e) =>
              '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}',
        )
        .join('&');

    return '${data.path}?$queryString';
  }
}

/// Provider pour SharedPreferences (défini dans config/providers.dart)
/// N'incluez pas ce fichier directement, utilisez config/providers.dart

/// Provider pour le deep link en attente (consommé après login)
/// Usage: Après login, appelez consumePendingDeepLink() pour rediriger vers la destination originale
final pendingDeepLinkProvider = FutureProvider<DeepLinkData?>((ref) async {
  // Note: Cette implémentation nécessite que deepLinkServiceProvider soit
  // correctement configuré dans config/providers.dart
  try {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(StorageKeys.pendingDeepLink);
    if (stored == null) return null;

    // Supprimer immédiatement pour éviter double traitement
    await prefs.remove(StorageKeys.pendingDeepLink);

    final json = jsonDecode(stored) as Map<String, dynamic>;
    return DeepLinkData.fromJson(json);
  } catch (e, stackTrace) {
    AppLogger.warning(
      'pendingDeepLinkProvider: Failed to parse pending deep link',
      error: e,
      stackTrace: stackTrace,
    );
    return null;
  }
});
