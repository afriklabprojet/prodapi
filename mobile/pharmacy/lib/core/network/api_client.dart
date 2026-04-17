import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../constants/app_constants.dart';
import '../errors/exceptions.dart';
import '../utils/error_mapper.dart';
import '../services/performance_service.dart';
import 'auth_interceptor.dart';
import 'certificate_pinning.dart';

/// Interceptor that retries failed requests with exponential backoff + jitter.
/// This provides better resilience for transient network failures.
class RetryInterceptor extends Interceptor {
  final Dio dio;
  final int maxRetries;
  final Duration baseDelay;
  static final _random = Random();

  RetryInterceptor({
    required this.dio,
    this.maxRetries = 3,
    this.baseDelay = const Duration(milliseconds: 500),
  });

  /// Status codes that should trigger retry
  static const _retryableStatusCodes = {500, 502, 503, 504};

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (_shouldRetry(err)) {
      final retryCount = (err.requestOptions.extra['retryCount'] as int?) ?? 0;
      if (retryCount < maxRetries) {
        final delay = _calculateBackoff(retryCount);
        
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

  /// Exponential backoff: 500ms, 1s, 2s with ±25% jitter
  Duration _calculateBackoff(int retryCount) {
    final exponentialDelay = baseDelay * (1 << retryCount);
    final jitter = (exponentialDelay.inMilliseconds * 0.25 * (_random.nextDouble() * 2 - 1)).toInt();
    return Duration(milliseconds: exponentialDelay.inMilliseconds + jitter);
  }

  bool _shouldRetry(DioException err) {
    // Retry on connection issues & timeouts
    switch (err.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.connectionError:
        return true;
      default:
        break;
    }
    // Retry on 5xx server errors
    final statusCode = err.response?.statusCode;
    return statusCode != null && _retryableStatusCodes.contains(statusCode);
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

    // 0. Certificate pinning (protection MITM)
    CertificatePinning.apply(_dio);

    // 1. Auth interceptor (token injection + 401 handling) — first in chain
    if (authInterceptor != null) {
      _dio.interceptors.add(authInterceptor);
    }

    // 2. Retry interceptor for transient failures (exponential backoff)
    _dio.interceptors.add(
      RetryInterceptor(dio: _dio),
    );

    // 3. Performance monitoring interceptor (Firebase Performance)
    _dio.interceptors.add(PerformanceInterceptor());

    // 4. Logging interceptor (debug only)
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

  /// Ferme les connexions. Appeler quand le client n'est plus utilisé.
  void dispose() {
    _dio.close();
  }

  @Deprecated('Token is now managed by AuthInterceptor via secure storage')
  void setToken(String token) {}

  @Deprecated('Token is now managed by AuthInterceptor via secure storage')
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
          final rawMessage = data['message'];
          errorCode = data['error_code'];
          message = ErrorMapper.format(errorCode, rawMessage);
          // Ajouter les détails si disponibles
          if (data['details'] != null) {
            message = '$message\n\n${data['details']}';
          }
        }
        return ForbiddenException(message: message, errorCode: errorCode);
      }
      
      if (statusCode == 404) {
        final serverMessage = data is Map ? data['message']?.toString() : null;
        return ServerException(
          message: ErrorMapper.format(null, serverMessage ?? 'Ressource non trouvée'),
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
          message: ErrorMapper.format(null, data['message']),
          statusCode: statusCode,
        );
      }

      return ServerException(
        message: data is Map
            ? ErrorMapper.format(null, data['message']?.toString() ?? 'Erreur serveur')
            : 'Erreur serveur',
        statusCode: statusCode,
      );
    }

    return ServerException(message: error.message ?? 'Erreur inconnue');
  }
  
  void _logApiError(DioException error) {
    if (!kDebugMode) return;
    
    final baseUrl = error.requestOptions.baseUrl;
    final path = error.requestOptions.path;
    final method = error.requestOptions.method;
    final statusCode = error.response?.statusCode;
    final data = error.response?.data;
    
    // Safely extract message from response
    final serverMessage = data is Map ? data['message']?.toString() : null;
    
    final buffer = StringBuffer()
      ..writeln('═══════════════════════════════════════════════════════════');
    
    switch (statusCode) {
      case 404:
        buffer
          ..writeln('❌ [API ERROR 404] Endpoint non trouvé')
          ..writeln('   URL complète: $baseUrl$path')
          ..writeln('   Méthode: $method')
          ..writeln('   Message serveur: ${serverMessage ?? 'Non disponible'}')
          ..writeln('   Conseil: Vérifiez que la route existe dans api.php');
      case 401:
        buffer
          ..writeln('🔐 [API ERROR 401] Non authentifié')
          ..writeln('   URL: $path')
          ..writeln('   Conseil: Vérifiez le token d\'authentification');
      case 500:
        buffer
          ..writeln('🔥 [API ERROR 500] Erreur serveur interne')
          ..writeln('   URL: $path')
          ..writeln('   Message: ${serverMessage ?? 'N/A'}');
      case null when error.type == DioExceptionType.connectionError:
        buffer
          ..writeln('🌐 [API ERROR] Impossible de se connecter')
          ..writeln('   URL tentée: $baseUrl')
          ..writeln('   Conseil: Vérifiez que le serveur Laravel est démarré (php artisan serve)');
      default:
        buffer
          ..writeln('⚠️ [API ERROR] Code: $statusCode')
          ..writeln('   URL: $path');
    }
    
    buffer.writeln('═══════════════════════════════════════════════════════════');
    debugPrint(buffer.toString());
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
