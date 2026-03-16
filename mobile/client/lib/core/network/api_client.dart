import 'dart:convert';
import 'dart:ui' show VoidCallback;
import 'package:dio/dio.dart';
import '../constants/api_constants.dart';
import '../errors/exceptions.dart';
import '../services/app_logger.dart';
import '../security/certificate_pinning.dart';
import 'retry_interceptor.dart';

class ApiClient {
  late final Dio _dio;
  String? _accessToken;

  /// Callback optionnel pour gérer la déconnexion automatique sur 401
  VoidCallback? onUnauthorized;

  ApiClient({bool enableCertificatePinning = true, this.onUnauthorized}) {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: ApiConstants.connectionTimeout,
        receiveTimeout: ApiConstants.receiveTimeout,
        sendTimeout: const Duration(seconds: 60),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // Configurer le Certificate Pinning pour la sécurité
    if (enableCertificatePinning) {
      _dio.enableCertificatePinning();
      _dio.interceptors.add(CertificatePinningInterceptor());
    }

    // Retry interceptor for transient failures (must be added BEFORE auth)
    _dio.interceptors.add(
      RetryInterceptor(dio: _dio, maxRetries: 2, retryDelay: const Duration(seconds: 1)),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          // Add auth token if available
          if (_accessToken != null) {
            options.headers['Authorization'] = 'Bearer $_accessToken';
            AppLogger.debug('[ApiClient] Request to ${options.path} with token');
          } else {
            AppLogger.warning('[ApiClient] Request to ${options.path} WITHOUT token!');
          }
          return handler.next(options);
        },
        onError: (error, handler) {
          // Auto-logout on 401 (session expired) — sauf pour login
          if (error.response?.statusCode == 401 && 
              !error.requestOptions.path.contains('/login')) {
            clearToken();
            onUnauthorized?.call();
          }
          return handler.next(error);
        },
      ),
    );
  }

  void setToken(String token) {
    _accessToken = token;
    // Ne PAS logger le token, même partiellement - risque de sécurité
    AppLogger.debug('[ApiClient] Token configured');
  }

  void clearToken() {
    _accessToken = null;
    AppLogger.debug('[ApiClient] Token cleared');
  }

  bool get hasToken => _accessToken != null;

  Options authorizedOptions(String token) {
    return Options(headers: {'Authorization': 'Bearer $token'});
  }

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
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.sendTimeout) {
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
        // Extraire le message d'erreur du serveur
        String errorMessage = 'Session expirée. Veuillez vous reconnecter.';
        if (data is Map) {
          errorMessage = data['message'] ?? errorMessage;
          // Si c'est une erreur d'identifiants, utiliser un message clair
          if (data['error_code'] == 'INVALID_CREDENTIALS') {
            errorMessage = 'Email ou mot de passe incorrect';
          }
        }
        return ServerException(
          message: errorMessage,
          statusCode: 401,
        );
      }
      
      if (statusCode == 403) {
        final serverMessage = data is Map ? data['message'] : null;
        final errorCode = data is Map ? data['error_code'] : null;
        
        // Messages spécifiques selon le code d'erreur
        String message;
        if (errorCode == 'PHONE_NOT_VERIFIED') {
          message = 'Veuillez d\'abord vérifier votre numéro de téléphone.';
        } else if (serverMessage != null && serverMessage.contains('Rôle requis')) {
          message = 'Ce compte n\'a pas accès à cette application. Veuillez utiliser le bon compte.';
        } else {
          message = serverMessage ?? 'Accès non autorisé';
        }
        
        return ServerException(
          message: message,
          statusCode: statusCode,
        );
      }
      
      if (statusCode == 404) {
        final serverMessage = data is Map ? data['message'] : null;
        return ServerException(
          message: serverMessage ?? 'Ressource non trouvée',
          statusCode: statusCode,
        );
      }

      if (statusCode == 422 && data is Map && data['errors'] != null) {
        return ValidationException(
          errors: Map<String, List<String>>.from(
            data['errors'].map(
              (key, value) => MapEntry(key, List<String>.from(value)),
            ),
          ),
        );
      }

      return ServerException(
        message: data is Map ? (data['message'] ?? 'Erreur serveur') : 'Erreur serveur',
        statusCode: statusCode,
      );
    }

    // Pas de réponse du serveur - probablement un problème de connexion
    // Vérifier les différents types d'erreurs Dio
    if (error.type == DioExceptionType.unknown) {
      // Erreur inconnue - généralement un problème réseau
      return NetworkException(
        message: 'Impossible de se connecter au serveur. Vérifiez que le serveur est démarré.',
      );
    }
    
    if (error.type == DioExceptionType.cancel) {
      return NetworkException(
        message: 'Requête annulée.',
      );
    }
    
    if (error.type == DioExceptionType.badResponse) {
      return ServerException(
        message: 'Réponse invalide du serveur.',
      );
    }

    // Message d'erreur par défaut plus explicite
    final errorMsg = error.message;
    if (errorMsg != null && errorMsg.isNotEmpty) {
      // Si le message contient des indices sur le type d'erreur
      if (errorMsg.toLowerCase().contains('connection') ||
          errorMsg.toLowerCase().contains('socket') ||
          errorMsg.toLowerCase().contains('network')) {
        return NetworkException(
          message: 'Problème de connexion. Vérifiez votre internet et que le serveur est accessible.',
        );
      }
      return ServerException(message: errorMsg);
    }
    
    return NetworkException(
      message: 'Impossible de contacter le serveur. Vérifiez votre connexion internet.',
    );
  }
  
  void _logApiError(DioException error) {
    final baseUrl = error.requestOptions.baseUrl;
    final path = error.requestOptions.path;
    final method = error.requestOptions.method;
    final statusCode = error.response?.statusCode;
    
    AppLogger.debug('═══════════════════════════════════════════════════════════');
    if (statusCode == 404) {
      AppLogger.error('[API ERROR 404] Endpoint non trouvé');
      AppLogger.debug('   URL complète: $baseUrl$path');
      AppLogger.debug('   Méthode: $method');
      AppLogger.debug('   Message serveur: ${error.response?.data?['message'] ?? 'Non disponible'}');
    } else if (statusCode == 401) {
      AppLogger.auth('[API ERROR 401] Non authentifié');
      AppLogger.debug('   URL: $path');
    } else if (statusCode == 403) {
      final errorCode = error.response?.data?['error_code'];
      AppLogger.error('[API ERROR 403] Accès interdit');
      AppLogger.debug('   URL: $path');
      AppLogger.debug('   Message: ${error.response?.data?['message'] ?? 'Non disponible'}');
      if (errorCode != null) AppLogger.debug('   Code erreur: $errorCode');
      if (errorCode == 'PHONE_NOT_VERIFIED') {
        AppLogger.info('   💡 Conseil: Le numéro de téléphone doit être vérifié');
      } else if (error.response?.data?['message']?.contains('Rôle requis') == true) {
        AppLogger.info('   💡 Conseil: Ce compte n\'a pas le bon rôle pour cette application');
      }
    } else if (statusCode == 500) {
      AppLogger.error('[API ERROR 500] Erreur serveur interne');
      AppLogger.debug('   URL: $path');
    } else if (error.type == DioExceptionType.connectionError) {
      AppLogger.error('[API ERROR] Impossible de se connecter');
      AppLogger.debug('   URL tentée: $baseUrl');
      AppLogger.info('   Conseil: Vérifiez que le serveur Laravel est démarré');
    } else if (statusCode == 422) {
      AppLogger.error('[API ERROR 422] Validation échouée');
      AppLogger.debug('   URL: $path');
      AppLogger.debug('   Méthode: $method');
      // SÉCURITÉ: Ne pas logger les données sensibles (passwords, tokens, etc.)
      AppLogger.debug('   Data envoyée: [MASQUÉ POUR SÉCURITÉ]');
      AppLogger.debug('   Validation errors: ${_extractValidationErrors(error.response?.data)}');
    } else {
      AppLogger.warning('[API ERROR] Code: $statusCode');
      AppLogger.debug('   URL: $path');
    }
    AppLogger.debug('═══════════════════════════════════════════════════════════');
  }
  
  /// Extrait uniquement les clés en erreur de validation (sans valeurs sensibles)
  String _extractValidationErrors(dynamic data) {
    if (data is Map && data['errors'] is Map) {
      final errors = data['errors'] as Map;
      return errors.keys.join(', ');
    }
    return 'Non disponible';
  }

  /// Parse response.data de manière sûre.
  /// Dio peut retourner un String (JSON brut) au lieu d'un Map selon la config.
  /// Cette méthode gère les deux cas.
  static Map<String, dynamic> parseResponseData(dynamic data) {
    if (data is Map<String, dynamic>) {
      return data;
    }
    if (data is String) {
      try {
        final parsed = jsonDecode(data);
        if (parsed is Map<String, dynamic>) {
          return parsed;
        }
      } catch (_) {}
    }
    throw FormatException(
      'Réponse inattendue du serveur (type: ${data.runtimeType})',
    );
  }
}
