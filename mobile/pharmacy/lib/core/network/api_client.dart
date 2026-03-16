import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../constants/app_constants.dart';
import '../errors/exceptions.dart';
import '../utils/error_mapper.dart';
import 'auth_interceptor.dart';

/// Interceptor that retries failed requests on transient network errors.
class RetryInterceptor extends Interceptor {
  final Dio dio;
  final int maxRetries;
  final Duration retryDelay;

  RetryInterceptor({
    required this.dio,
    this.maxRetries = 3,
    this.retryDelay = const Duration(seconds: 1),
  });

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (_shouldRetry(err)) {
      final retryCount = (err.requestOptions.extra['retryCount'] as int?) ?? 0;
      if (retryCount < maxRetries) {
        final delay = retryDelay * (retryCount + 1); // linear backoff
        if (kDebugMode) {
          debugPrint('🔄 [Retry] Attempt ${retryCount + 1}/$maxRetries after ${delay.inMilliseconds}ms');
        }
        await Future.delayed(delay);
        err.requestOptions.extra['retryCount'] = retryCount + 1;
        try {
          final response = await dio.fetch(err.requestOptions);
          return handler.resolve(response);
        } on DioException catch (e) {
          return handler.next(e);
        }
      }
    }
    return handler.next(err);
  }

  bool _shouldRetry(DioException err) {
    // Retry on connection issues & timeouts, not on 4xx client errors
    if (err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.sendTimeout ||
        err.type == DioExceptionType.receiveTimeout ||
        err.type == DioExceptionType.connectionError) {
      return true;
    }
    // Retry on 5xx server errors
    final statusCode = err.response?.statusCode;
    if (statusCode != null && statusCode >= 500) {
      return true;
    }
    return false;
  }
}

class ApiClient {
  late final Dio _dio;

  Dio get dio => _dio;

  ApiClient({AuthInterceptor? authInterceptor}) {
    if (kDebugMode) debugPrint('🔧 [ApiClient] Initialisation - baseUrl: ${AppConstants.apiBaseUrl}');
    
    _dio = Dio(
      BaseOptions(
        baseUrl: AppConstants.apiBaseUrl,
        connectTimeout: AppConstants.apiTimeout,
        receiveTimeout: AppConstants.apiTimeout,
        sendTimeout: AppConstants.apiTimeout,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // 1. Auth interceptor (token injection + 401 handling) — first in chain
    if (authInterceptor != null) {
      _dio.interceptors.add(authInterceptor);
    }

    // 2. Retry interceptor for transient failures
    _dio.interceptors.add(
      RetryInterceptor(dio: _dio),
    );

    // 3. Logging interceptor (debug only)
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          if (kDebugMode) debugPrint('➡️ [ApiClient] REQUEST: ${options.method} ${options.uri}');
          return handler.next(options);
        },
        onResponse: (response, handler) {
          if (kDebugMode) debugPrint('⬅️ [ApiClient] RESPONSE: ${response.statusCode} ${response.requestOptions.uri}');
          return handler.next(response);
        },
        onError: (error, handler) {
          if (kDebugMode) debugPrint('❌ [ApiClient] ERROR: ${error.type} - ${error.message}');
          return handler.next(error);
        },
      ),
    );
  }

  Options authorizedOptions(String token) {
    return Options(headers: {'Authorization': 'Bearer $token'});
  }

  /// @deprecated Token is now managed by AuthInterceptor via secure storage.
  /// Kept for backward compatibility — will be removed.
  void setToken(String token) {}

  /// @deprecated Token is now managed by AuthInterceptor via secure storage.
  /// Kept for backward compatibility — will be removed.
  void clearToken() {}

  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.get(
        path,
        queryParameters: queryParameters,
        options: options,
      );
      return response;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Response> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.post(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return response;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Response> put(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.put(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return response;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Response> delete(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.delete(
        path,
        queryParameters: queryParameters,
        options: options,
      );
      return response;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Response> uploadMultipart(
    String path, {
    required FormData formData,
    Map<String, dynamic>? queryParameters,
    Options? options,
    ProgressCallback? onSendProgress,
  }) async {
    try {
      final response = await _dio.post(
        path,
        data: formData,
        queryParameters: queryParameters,
        options: options,
        onSendProgress: onSendProgress,
      );
      return response;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Exception _handleError(DioException error) {
    // Log détaillé pour le debug
    _logApiError(error);
    
    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout) {
      return NetworkException(
        message: 'Délai de connexion dépassé. Vérifiez votre connexion internet.',
      );
    }

    if (error.type == DioExceptionType.connectionError) {
      return NetworkException(
        message: 'Impossible de se connecter au serveur. Vérifiez votre connexion.',
      );
    }

    if (error.response != null) {
      final statusCode = error.response!.statusCode;
      final data = error.response!.data;

      if (statusCode == 401) {
        // Identifiants invalides ou session expirée
        String? errorCode;
        String message = 'Session expirée. Veuillez vous reconnecter.';
        
        if (data is Map) {
          errorCode = data['error_code']?.toString();
          final serverMessage = data['message']?.toString();
          // Utiliser ErrorMapper pour un message UX propre
          message = ErrorMapper.format(errorCode, serverMessage);
        }
        return UnauthorizedException(message: message);
      }
      
      if (statusCode == 403) {
        // Compte non approuvé, suspendu ou rejeté
        String message = 'Accès refusé';
        String? errorCode;
        if (data is Map) {
          message = data['message'] ?? message;
          errorCode = data['error_code'];
          // Ajouter les détails si disponibles
          if (data['details'] != null) {
            message = '$message\n\n${data['details']}';
          }
        }
        return ForbiddenException(message: message, errorCode: errorCode);
      }
      
      if (statusCode == 404) {
        final serverMessage = data is Map ? data['message'] : null;
        return ServerException(
          message: serverMessage ?? 'Ressource non trouvée',
          statusCode: statusCode,
        );
      }

      if (statusCode == 422 && data is Map && data['errors'] != null) {
        if (kDebugMode) debugPrint("API Validation Error Data: ${data['errors']}");
        return ValidationException(
          errors: Map<String, List<String>>.from(
            data['errors'].map(
              (key, value) => MapEntry(key, List<String>.from(value)),
            ),
          ),
        );
      }

      if (statusCode == 422 && data is Map && data['message'] != null) {
        return ServerException(
          message: data['message'],
          statusCode: statusCode,
        );
      }

      return ServerException(
        message: data is Map ? (data['message'] ?? 'Erreur serveur') : 'Erreur serveur',
        statusCode: statusCode,
      );
    }

    return ServerException(message: error.message ?? 'Erreur inconnue');
  }
  
  void _logApiError(DioException error) {
    final baseUrl = error.requestOptions.baseUrl;
    final path = error.requestOptions.path;
    final method = error.requestOptions.method;
    final statusCode = error.response?.statusCode;
    final data = error.response?.data;
    
    // Safely extract message from response
    String? serverMessage;
    if (data is Map) {
      serverMessage = data['message']?.toString();
    }
    
    if (kDebugMode) debugPrint('═══════════════════════════════════════════════════════════');
    if (statusCode == 404) {
      if (kDebugMode) debugPrint('❌ [API ERROR 404] Endpoint non trouvé');
      if (kDebugMode) debugPrint('   URL complète: $baseUrl$path');
      if (kDebugMode) debugPrint('   Méthode: $method');
      if (kDebugMode) debugPrint('   Message serveur: ${serverMessage ?? 'Non disponible'}');
      if (kDebugMode) debugPrint('   Conseil: Vérifiez que la route existe dans api.php');
    } else if (statusCode == 401) {
      if (kDebugMode) debugPrint('🔐 [API ERROR 401] Non authentifié');
      if (kDebugMode) debugPrint('   URL: $path');
      if (kDebugMode) debugPrint('   Conseil: Vérifiez le token d\'authentification');
    } else if (statusCode == 500) {
      if (kDebugMode) debugPrint('🔥 [API ERROR 500] Erreur serveur interne');
      if (kDebugMode) debugPrint('   URL: $path');
      if (kDebugMode) debugPrint('   Message: ${serverMessage ?? 'N/A'}');
    } else if (error.type == DioExceptionType.connectionError) {
      if (kDebugMode) debugPrint('🌐 [API ERROR] Impossible de se connecter');
      if (kDebugMode) debugPrint('   URL tentée: $baseUrl');
      if (kDebugMode) debugPrint('   Conseil: Vérifiez que le serveur Laravel est démarré (php artisan serve)');
    } else {
      if (kDebugMode) debugPrint('⚠️ [API ERROR] Code: $statusCode');
      if (kDebugMode) debugPrint('   URL: $path');
    }
    if (kDebugMode) debugPrint('═══════════════════════════════════════════════════════════');
  }

  /// Parse response.data de manière sûre (String JSON ou Map)
  static Map<String, dynamic> parseResponseData(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    if (data is String) {
      try {
        final parsed = jsonDecode(data);
        if (parsed is Map<String, dynamic>) return parsed;
      } catch (e) {
        if (kDebugMode) debugPrint('⚠️ [API] Erreur parsing JSON: $e');
      }
    }
    throw FormatException('Réponse inattendue du serveur (type: ${data.runtimeType})');
  }
}
