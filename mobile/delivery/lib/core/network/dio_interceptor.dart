import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../services/auth_session_service.dart';
import '../services/secure_token_service.dart';

class AuthInterceptor extends Interceptor {
  /// Routes exclues de la gestion automatique du 401
  /// (login et register ne doivent pas déclencher une expiration de session)
  static const _excludedPaths = [
    '/auth/login',
    '/auth/register/courier',
  ];

  @override
  Future<void> onRequest(
      RequestOptions options, RequestInterceptorHandler handler) async {
    final token = await SecureTokenService.instance.getToken();

    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    
    options.headers['Accept'] = 'application/json';

    super.onRequest(options, handler);
  }
  
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final path = err.requestOptions.path;
    final statusCode = err.response?.statusCode;

    if (statusCode == 401 && !_isExcludedPath(path)) {
      // Token expiré ou invalide → nettoyer et notifier l'UI
      if (kDebugMode) debugPrint('🔐 [API ERROR 401] Session expirée sur: $path');
      if (kDebugMode) debugPrint('   → Déclenchement du nettoyage de session');
      AuthSessionService.instance.onSessionExpired();
    } else if (statusCode == 401) {
      if (kDebugMode) debugPrint('🔐 [API ERROR 401] Identifiants invalides sur: $path');
    } else if (statusCode == 404) {
      if (kDebugMode) debugPrint('═══════════════════════════════════════════════════════════');
      if (kDebugMode) debugPrint('❌ [API ERROR 404] Endpoint non trouvé');
      if (kDebugMode) debugPrint('   URL: ${err.requestOptions.baseUrl}${err.requestOptions.path}');
      if (kDebugMode) debugPrint('   Method: ${err.requestOptions.method}');
      if (kDebugMode) debugPrint('   Message: ${err.response?.data?['message'] ?? 'Resource not found'}');
      if (kDebugMode) debugPrint('═══════════════════════════════════════════════════════════');
    } else if (statusCode == 500) {
      if (kDebugMode) debugPrint('🔥 [API ERROR 500] Erreur serveur');
      if (kDebugMode) debugPrint('   URL: $path');
      if (kDebugMode) debugPrint('   Message: ${err.response?.data?['message'] ?? 'Internal server error'}');
    } else if (err.type == DioExceptionType.connectionError) {
      if (kDebugMode) debugPrint('🌐 [API ERROR] Impossible de se connecter au serveur');
      if (kDebugMode) debugPrint('   URL tentée: ${err.requestOptions.baseUrl}');
      if (kDebugMode) debugPrint('   Vérifiez que le serveur est démarré et accessible');
    }
    
    super.onError(err, handler);
  }

  /// Vérifie si le path est exclu de la gestion automatique du 401
  bool _isExcludedPath(String path) {
    return _excludedPaths.any((excluded) => path.contains(excluded));
  }
}
