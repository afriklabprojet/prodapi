import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../constants/api_constants.dart';
import '../services/auth_session_service.dart';
import '../services/secure_token_service.dart';

class AuthInterceptor extends Interceptor {
  final Dio dio;

  AuthInterceptor({required this.dio});

  /// Routes exclues de la gestion automatique du 401
  /// (les endpoints pré-authentification ne doivent pas déclencher une expiration de session)
  static const _excludedPaths = [
    '/auth/login',
    '/auth/register/courier',
    '/auth/refresh',
    '/auth/resend',
    '/auth/verify',
    '/auth/verify-reset-otp',
    '/auth/forgot-password',
  ];

  /// Empêche le refresh concurrent de tokens
  Completer<bool>? _refreshCompleter;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Ne pas ajouter le token sur les endpoints pré-authentification
    if (!_isExcludedPath(options.path)) {
      final token = await SecureTokenService.instance.getToken();
      if (token != null) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    }

    options.headers['Accept'] = 'application/json';

    super.onRequest(options, handler);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final path = err.requestOptions.path;
    final statusCode = err.response?.statusCode;

    if (statusCode == 401 && !_isExcludedPath(path)) {
      // Tenter un refresh token avant d'expirer la session
      final refreshed = await _attemptTokenRefresh();
      if (refreshed) {
        // Relancer la requête originale avec le nouveau token
        try {
          final newToken = await SecureTokenService.instance.getToken();
          err.requestOptions.headers['Authorization'] = 'Bearer $newToken';
          final response = await dio.fetch(err.requestOptions);
          return handler.resolve(response);
        } on DioException catch (retryError) {
          return handler.reject(retryError);
        }
      }
      // Le refresh a échoué → nettoyer et notifier l'UI
      if (kDebugMode) {
        debugPrint('🔐 [API ERROR 401] Session expirée sur: $path');
        debugPrint(
          '   → Refresh échoué, déclenchement du nettoyage de session',
        );
      }
      AuthSessionService.instance.onSessionExpired();
    } else if (statusCode == 401) {
      if (kDebugMode) {
        debugPrint('🔐 [API ERROR 401] Identifiants invalides sur: $path');
      }
    } else if (statusCode == 404) {
      if (kDebugMode) {
        debugPrint(
          '═══════════════════════════════════════════════════════════',
        );
        debugPrint('❌ [API ERROR 404] Endpoint non trouvé');
        debugPrint(
          '   URL: ${err.requestOptions.baseUrl}${err.requestOptions.path}',
        );
        debugPrint('   Method: ${err.requestOptions.method}');
        debugPrint(
          '   Message: ${err.response?.data?['message'] ?? 'Resource not found'}',
        );
        debugPrint(
          '═══════════════════════════════════════════════════════════',
        );
      }
    } else if (statusCode == 500) {
      if (kDebugMode) {
        debugPrint('🔥 [API ERROR 500] Erreur serveur');
        debugPrint('   URL: $path');
        debugPrint(
          '   Message: ${err.response?.data?['message'] ?? 'Internal server error'}',
        );
      }
    } else if (err.type == DioExceptionType.connectionError) {
      if (kDebugMode) {
        debugPrint('🌐 [API ERROR] Impossible de se connecter au serveur');
        debugPrint('   URL tentée: ${err.requestOptions.baseUrl}');
        debugPrint('   Vérifiez que le serveur est démarré et accessible');
      }
    }

    super.onError(err, handler);
  }

  /// Tente un refresh token. Gère la concurrence (un seul refresh à la fois).
  Future<bool> _attemptTokenRefresh() async {
    // Si un refresh est déjà en cours, attendre son résultat
    if (_refreshCompleter != null) {
      return _refreshCompleter!.future;
    }

    _refreshCompleter = Completer<bool>();
    try {
      final refreshToken = await SecureTokenService.instance.getRefreshToken();
      if (refreshToken == null || refreshToken.isEmpty) {
        _refreshCompleter!.complete(false);
        return false;
      }

      if (kDebugMode) debugPrint('🔄 [Auth] Tentative de refresh token...');

      final response = await dio.post(
        ApiConstants.refreshToken,
        data: {'refresh_token': refreshToken},
        options: Options(headers: {'Authorization': 'Bearer $refreshToken'}),
      );

      final data = response.data is Map<String, dynamic>
          ? response.data as Map<String, dynamic>
          : <String, dynamic>{};
      final innerData = data['data'] ?? data;

      final newToken = innerData['token'] as String?;
      if (newToken == null || newToken.isEmpty) {
        _refreshCompleter!.complete(false);
        return false;
      }

      await SecureTokenService.instance.setToken(newToken);

      final newRefreshToken = innerData['refresh_token'] as String?;
      if (newRefreshToken != null && newRefreshToken.isNotEmpty) {
        await SecureTokenService.instance.setRefreshToken(newRefreshToken);
      }

      if (kDebugMode) debugPrint('✅ [Auth] Token refresh réussi');
      _refreshCompleter!.complete(true);
      return true;
    } catch (e) {
      if (kDebugMode) debugPrint('❌ [Auth] Token refresh échoué: $e');
      _refreshCompleter!.complete(false);
      return false;
    } finally {
      _refreshCompleter = null;
    }
  }

  /// Vérifie si le path est exclu de la gestion automatique du 401
  bool _isExcludedPath(String path) {
    return _excludedPaths.any((excluded) => path.contains(excluded));
  }
}
