import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../features/auth/data/datasources/auth_local_datasource.dart';

/// Type de callback pour la déconnexion globale
typedef OnUnauthorizedCallback = void Function();

/// Intercepteur global pour gérer les erreurs 401 avec token refresh.
///
/// Flux :
/// 1. Injecte le Bearer token dans chaque requête.
/// 2. Sur 401 (route protégée), tente un refresh via [_tryRefreshToken].
/// 3. Si le refresh réussit, rejoue la requête originale.
/// 4. Si le refresh échoue, déconnecte l'utilisateur une seule fois
///    (les requêtes concurrentes sont mises en file d'attente via un
///    [Completer] partagé).
class AuthInterceptor extends Interceptor {
  final AuthLocalDataSource _localDataSource;
  final OnUnauthorizedCallback? _onUnauthorized;
  final String _baseUrl;
  final Dio? _testPlainDio;

  /// Dio léger sans intercepteurs, utilisé uniquement pour la validation
  /// de session. Évite la récursion (pas d'AuthInterceptor dessus).
  late final Dio _plainDio =
      _testPlainDio ??
      Dio(
        BaseOptions(
          baseUrl: _baseUrl,
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
          headers: {'Accept': 'application/json'},
        ),
      );

  /// Routes qui ne déclenchent PAS de logout auto sur 401
  static const _publicRoutes = {
    '/login',
    '/register',
    '/forgot-password',
    '/reset-password',
    '/verify-otp',
  };

  /// Paramètres sensibles à masquer dans les logs (Set pour O(1) lookup)
  static const _sensitiveParams = {
    'token',
    'password',
    'secret',
    'key',
    'auth',
    'bearer',
    'otp',
    'code',
  };

  /// Completer partagé pour sérialiser les tentatives de refresh.
  /// `null` = pas de refresh en cours.
  Completer<bool>? _refreshCompleter;

  /// Référence au Dio principal (avec intercepteurs), injecté après
  /// construction par [attachDio] pour pouvoir rejouer les requêtes.
  Dio? _mainDio;

  AuthInterceptor({
    required AuthLocalDataSource localDataSource,
    required String baseUrl,
    OnUnauthorizedCallback? onUnauthorized,
    @visibleForTesting Dio? testPlainDio,
  }) : _localDataSource = localDataSource,
       _baseUrl = baseUrl,
       _onUnauthorized = onUnauthorized,
       _testPlainDio = testPlainDio;

  /// Attache le Dio principal (celui qui porte cet intercepteur).
  /// Appelé par [ApiClient] après construction.
  void attachDio(Dio dio) => _mainDio = dio;

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _localDataSource.getToken();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }

    if (kDebugMode) {
      debugPrint(
        '🌐 [AuthInterceptor] ${options.method} ${_sanitizeUri(options.uri)}',
      );
    }

    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final statusCode = err.response?.statusCode;
    final path = err.requestOptions.path;

    if (kDebugMode) {
      debugPrint('❌ [AuthInterceptor] Error $statusCode on $path');
    }

    // Ignorer les 401 sur les routes publiques
    if (statusCode != 401 || _isPublicRoute(path)) {
      return handler.next(err);
    }

    // Tenter un refresh (sérialisé via Completer)
    final refreshed = await _enqueueRefresh();

    if (refreshed && _mainDio != null) {
      // Rejouer la requête originale avec le nouveau token
      try {
        final token = await _localDataSource.getToken();
        final opts = err.requestOptions;
        opts.headers['Authorization'] = 'Bearer $token';
        final response = await _mainDio!.fetch(opts);
        return handler.resolve(response);
      } on DioException catch (retryError) {
        return handler.next(retryError);
      }
    }

    // Refresh échoué → propager l'erreur originale
    handler.next(err);
  }

  // ── Helpers ──────────────────────────────────────────────

  bool _isPublicRoute(String path) {
    return _publicRoutes.any((route) => path.contains(route));
  }

  /// Sanitize URI for logging - masks sensitive query parameters
  String _sanitizeUri(Uri uri) {
    if (uri.queryParameters.isEmpty) {
      return uri.path;
    }

    final sanitizedParams = uri.queryParameters.map((key, value) {
      final isStrictlySensitive = _sensitiveParams.any(
        (param) => key.toLowerCase().contains(param),
      );
      return MapEntry(key, isStrictlySensitive ? '[REDACTED]' : value);
    });

    return '${uri.path}?${sanitizedParams.entries.map((e) => '${e.key}=${e.value}').join('&')}';
  }

  /// Sérialise les tentatives de refresh : la première requête 401
  /// lance [_tryRefreshToken], les suivantes attendent le même résultat.
  Future<bool> _enqueueRefresh() async {
    if (_refreshCompleter != null) {
      // Un refresh est déjà en cours → attendre son résultat
      return _refreshCompleter!.future;
    }

    _refreshCompleter = Completer<bool>();

    try {
      final success = await _tryRefreshToken();
      _refreshCompleter!.complete(success);
      return success;
    } catch (e) {
      _refreshCompleter!.complete(false);
      return false;
    } finally {
      _refreshCompleter = null;
    }
  }

  /// Tente de rafraîchir le token.
  ///
  /// L'API actuelle (Sanctum) ne fournit pas de refresh endpoint séparé.
  /// On valide la session via GET /auth/me :
  /// - Si 200 → le token est encore valide (erreur 401 transitoire) → succès.
  /// - Sinon → session expirée → on déconnecte.
  ///
  /// Quand un endpoint POST /auth/refresh sera ajouté côté API,
  /// il suffit de remplacer le corps de cette méthode.
  Future<bool> _tryRefreshToken() async {
    try {
      final token = await _localDataSource.getToken();
      if (token == null || token.isEmpty) {
        await _forceLogout();
        return false;
      }

      if (kDebugMode) {
        debugPrint('🔄 [AuthInterceptor] Attempting session validation…');
      }

      final response = await _plainDio.get(
        '/auth/me',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode == 200) {
        if (kDebugMode) {
          debugPrint('✅ [AuthInterceptor] Session still valid');
        }
        return true;
      }

      await _forceLogout();
      return false;
    } catch (_) {
      await _forceLogout();
      return false;
    }
  }

  /// Nettoyage complet : clear local data + notifier l'app.
  Future<void> _forceLogout() async {
    try {
      if (kDebugMode) {
        debugPrint('🔐 [AuthInterceptor] Session expired — logging out…');
      }
      await _localDataSource.clearAuthData();
      _onUnauthorized?.call();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ [AuthInterceptor] Error during logout: $e');
      }
    }
  }

  /// Libère les ressources. Appeler quand l'intercepteur n'est plus utilisé.
  void dispose() {
    _plainDio.close();
    _mainDio = null;
    _refreshCompleter = null;
  }
}

/// Extension pour créer l'intercepteur avec Riverpod
extension AuthInterceptorX on AuthLocalDataSource {
  AuthInterceptor createInterceptor({
    required String baseUrl,
    OnUnauthorizedCallback? onUnauthorized,
  }) {
    return AuthInterceptor(
      localDataSource: this,
      baseUrl: baseUrl,
      onUnauthorized: onUnauthorized,
    );
  }
}
