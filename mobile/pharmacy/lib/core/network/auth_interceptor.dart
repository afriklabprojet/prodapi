import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../features/auth/data/datasources/auth_local_datasource.dart';

/// Type de callback pour la déconnexion globale
typedef OnUnauthorizedCallback = void Function();

/// Intercepteur global pour gérer les erreurs 401
/// 
/// Responsabilités:
/// - Détecter les 401 sur les routes protégées (pas /login, /register)
/// - Nettoyer les données d'authentification
/// - Notifier l'app pour rediriger vers login
/// 
/// Usage:
/// ```dart
/// dio.interceptors.add(
///   AuthInterceptor(
///     localDataSource: authLocalDataSource,
///     onUnauthorized: () => ref.read(authNotifierProvider.notifier).logout(),
///   ),
/// );
/// ```
class AuthInterceptor extends Interceptor {
  final AuthLocalDataSource _localDataSource;
  final OnUnauthorizedCallback? _onUnauthorized;
  
  /// Routes qui ne déclenchent PAS de logout auto sur 401
  static const _publicRoutes = [
    '/login',
    '/register',
    '/forgot-password',
    '/reset-password',
    '/verify-otp',
  ];
  
  /// Flag pour éviter les appels multiples de logout
  bool _isLoggingOut = false;
  
  AuthInterceptor({
    required AuthLocalDataSource localDataSource,
    OnUnauthorizedCallback? onUnauthorized,
  })  : _localDataSource = localDataSource,
        _onUnauthorized = onUnauthorized;
  
  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Ajouter le token automatiquement si présent
    final token = await _localDataSource.getToken();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    
    if (kDebugMode) {
      debugPrint('🌐 [AuthInterceptor] ${options.method} ${options.uri}');
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
    
    // Si 401 sur une route protégée
    if (statusCode == 401 && !_isPublicRoute(path)) {
      await _handleUnauthorized();
    }
    
    handler.next(err);
  }
  
  /// Vérifie si la route est publique (ne nécessite pas de logout)
  bool _isPublicRoute(String path) {
    return _publicRoutes.any((route) => path.contains(route));
  }
  
  /// Gère une erreur 401 : clear data + notify app
  Future<void> _handleUnauthorized() async {
    // Protection contre les appels multiples
    if (_isLoggingOut) return;
    _isLoggingOut = true;
    
    try {
      if (kDebugMode) {
        debugPrint('🔐 [AuthInterceptor] Session expired - logging out...');
      }
      
      // 1. Clear les données locales
      await _localDataSource.clearAuthData();
      
      // 2. Notifier l'app
      _onUnauthorized?.call();
      
      if (kDebugMode) {
        debugPrint('✅ [AuthInterceptor] Logout completed');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ [AuthInterceptor] Error during logout: $e');
      }
    } finally {
      // Reset le flag après un délai pour éviter les boucles
      Future.delayed(const Duration(seconds: 2), () {
        _isLoggingOut = false;
      });
    }
  }
}

/// Extension pour créer l'intercepteur avec Riverpod
extension AuthInterceptorX on AuthLocalDataSource {
  AuthInterceptor createInterceptor({
    OnUnauthorizedCallback? onUnauthorized,
  }) {
    return AuthInterceptor(
      localDataSource: this,
      onUnauthorized: onUnauthorized,
    );
  }
}
