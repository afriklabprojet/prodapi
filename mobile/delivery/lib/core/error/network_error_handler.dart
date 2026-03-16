import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'error_boundary.dart';

/// Handler spécialisé pour les erreurs réseau/API
class NetworkErrorHandler {
  static final NetworkErrorHandler _instance = NetworkErrorHandler._internal();
  factory NetworkErrorHandler() => _instance;
  NetworkErrorHandler._internal();

  /// Transforme une exception Dio en message utilisateur
  static String getErrorMessage(dynamic error) {
    if (error is DioException) {
      return _handleDioError(error);
    }
    
    if (error is String) {
      return error;
    }
    
    return 'Une erreur inattendue est survenue';
  }

  static String _handleDioError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
        return 'Connexion trop lente. Vérifiez votre connexion internet.';
        
      case DioExceptionType.sendTimeout:
        return 'Envoi des données trop lent. Réessayez.';
        
      case DioExceptionType.receiveTimeout:
        return 'Le serveur met trop de temps à répondre.';
        
      case DioExceptionType.badCertificate:
        return 'Erreur de sécurité. Contactez le support.';
        
      case DioExceptionType.badResponse:
        return _handleStatusCode(error.response?.statusCode);
        
      case DioExceptionType.cancel:
        return 'Requête annulée';
        
      case DioExceptionType.connectionError:
        return 'Impossible de se connecter au serveur. Vérifiez votre connexion.';
        
      case DioExceptionType.unknown:
        if (error.message?.contains('SocketException') ?? false) {
          return 'Pas de connexion internet';
        }
        return 'Erreur de connexion inconnue';
    }
  }

  static String _handleStatusCode(int? statusCode) {
    if (statusCode == null) {
      return 'Erreur de communication avec le serveur';
    }

    switch (statusCode) {
      case 400:
        return 'Requête invalide. Vérifiez les données saisies.';
      case 401:
        return 'Session expirée. Veuillez vous reconnecter.';
      case 403:
        return 'Accès refusé. Vous n\'avez pas les permissions nécessaires.';
      case 404:
        return 'Ressource introuvable.';
      case 408:
        return 'Délai d\'attente dépassé. Réessayez.';
      case 409:
        return 'Conflit de données. L\'élément existe peut-être déjà.';
      case 422:
        return 'Données invalides. Vérifiez les informations saisies.';
      case 429:
        return 'Trop de requêtes. Attendez un moment avant de réessayer.';
      case 500:
        return 'Erreur interne du serveur. Réessayez plus tard.';
      case 502:
        return 'Service temporairement indisponible.';
      case 503:
        return 'Service en maintenance. Réessayez plus tard.';
      case 504:
        return 'Le serveur ne répond pas. Réessayez.';
      default:
        if (statusCode >= 400 && statusCode < 500) {
          return 'Erreur de requête (Code: $statusCode)';
        }
        if (statusCode >= 500) {
          return 'Erreur serveur (Code: $statusCode)';
        }
        return 'Erreur inconnue (Code: $statusCode)';
    }
  }

  /// Vérifie si l'erreur nécessite une reconnexion
  static bool requiresReAuth(dynamic error) {
    if (error is DioException) {
      return error.response?.statusCode == 401;
    }
    return false;
  }

  /// Vérifie si l'erreur est due à un problème réseau
  static bool isNetworkError(dynamic error) {
    if (error is DioException) {
      return error.type == DioExceptionType.connectionError ||
             error.type == DioExceptionType.connectionTimeout ||
             (error.message?.contains('SocketException') ?? false);
    }
    return false;
  }

  /// Vérifie si on peut réessayer automatiquement
  static bool isRetryable(dynamic error) {
    if (error is DioException) {
      // Erreurs de timeout ou serveur peuvent être réessayées
      return error.type == DioExceptionType.connectionTimeout ||
             error.type == DioExceptionType.sendTimeout ||
             error.type == DioExceptionType.receiveTimeout ||
             (error.response?.statusCode ?? 0) >= 500;
    }
    return false;
  }

  /// Exécute une requête avec retry automatique
  static Future<T> withRetry<T>(
    Future<T> Function() request, {
    int maxRetries = 3,
    Duration delay = const Duration(seconds: 1),
    bool Function(dynamic)? shouldRetry,
  }) async {
    int attempts = 0;
    
    while (true) {
      try {
        return await request();
      } catch (e) {
        attempts++;
        
        final canRetry = shouldRetry?.call(e) ?? isRetryable(e);
        
        if (!canRetry || attempts >= maxRetries) {
          rethrow;
        }
        
        if (kDebugMode) {
          debugPrint('⚠️ Retry attempt $attempts/$maxRetries after ${delay.inSeconds}s');
        }
        
        // Exponential backoff
        await Future.delayed(Duration(milliseconds: delay.inMilliseconds * attempts));
      }
    }
  }

  /// Reporter l'erreur au système global
  void report(dynamic error, {String? context}) {
    final message = getErrorMessage(error);
    
    GlobalErrorHandler().reportError(
      context != null ? '$context: $message' : message,
      type: isNetworkError(error) ? ErrorType.network : ErrorType.api,
    );
  }
}

/// Extension pratique pour les résultats de requêtes
class ApiResult<T> {
  final T? data;
  final String? error;
  final int? statusCode;

  ApiResult._({this.data, this.error, this.statusCode});

  factory ApiResult.success(T data) => ApiResult._(data: data);
  factory ApiResult.failure(String error, {int? statusCode}) => 
      ApiResult._(error: error, statusCode: statusCode);

  bool get isSuccess => error == null && data != null;
  bool get isFailure => !isSuccess;

  /// Transformer le résultat si succès
  ApiResult<R> map<R>(R Function(T) transform) {
    if (isSuccess) {
      return ApiResult.success(transform(data as T));
    }
    return ApiResult.failure(error!, statusCode: statusCode);
  }

  /// Exécuter une action selon le résultat
  void when({
    required void Function(T data) success,
    required void Function(String error) failure,
  }) {
    if (isSuccess) {
      success(data as T);
    } else {
      failure(error!);
    }
  }

  /// Obtenir la valeur ou une valeur par défaut
  T getOrElse(T defaultValue) => data ?? defaultValue;
}

/// Extension pour transformer Try/Catch en ApiResult
extension FutureApiResult<T> on Future<T> {
  Future<ApiResult<T>> toResult() async {
    try {
      final data = await this;
      return ApiResult.success(data);
    } catch (e) {
      return ApiResult.failure(NetworkErrorHandler.getErrorMessage(e));
    }
  }
}
