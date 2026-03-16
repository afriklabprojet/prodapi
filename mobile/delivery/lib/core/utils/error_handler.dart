import 'package:dio/dio.dart';
import 'app_exceptions.dart';

/// Classe utilitaire pour convertir les erreurs techniques en messages compréhensibles
/// et en exceptions typées [AppException].
class ErrorHandler {
  /// Nettoie un message d'erreur pour l'affichage utilisateur
  /// Supprime les préfixes "Exception:" et rend le message plus lisible
  static String cleanMessage(dynamic error) {
    if (error is AppException) return error.userMessage;

    String message = error.toString();
    
    // Supprimer les préfixes "Exception:" répétés
    while (message.startsWith('Exception: ')) {
      message = message.substring(11);
    }
    
    // Si le message est vide après nettoyage
    if (message.trim().isEmpty) {
      return 'Une erreur est survenue. Veuillez réessayer.';
    }
    
    return message;
  }

  // ── Conversion vers AppException ────────────────────

  /// Convertit n'importe quelle erreur en [AppException] typée.
  static AppException toAppException(dynamic error, {String? fallbackMessage}) {
    if (error is AppException) return error;
    if (error is DioException) return _dioToAppException(error, fallbackMessage: fallbackMessage);

    final msg = error.toString().toLowerCase();
    if (msg.contains('socketexception') ||
        msg.contains('connection refused') ||
        msg.contains('network is unreachable') ||
        msg.contains('xmlhttprequest')) {
      return const NetworkException();
    }
    if (msg.contains('timeout')) {
      return const NetworkException(
        message: 'Timeout',
        userMessage: 'La connexion a pris trop de temps. Veuillez réessayer.',
      );
    }

    return ApiException(
      message: error.toString(),
      userMessage: fallbackMessage ?? cleanMessage(error),
    );
  }

  static AppException _dioToAppException(DioException error, {String? fallbackMessage}) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const NetworkException(
          message: 'Timeout',
          userMessage: 'La connexion a pris trop de temps. Vérifiez votre connexion.',
        );
      case DioExceptionType.connectionError:
        return const NetworkException();
      case DioExceptionType.cancel:
        return const ApiException(
          message: 'Request cancelled',
          userMessage: 'Requête annulée.',
        );
      case DioExceptionType.badCertificate:
        return const ApiException(
          message: 'Bad certificate',
          userMessage: 'Erreur de sécurité. Contactez le support.',
        );
      case DioExceptionType.badResponse:
        return _statusCodeToException(error, fallbackMessage);
      case DioExceptionType.unknown:
        final errStr = error.error.toString();
        if (errStr.contains('SocketException') || errStr.contains('XMLHttpRequest')) {
          return const NetworkException();
        }
        return ApiException(
          message: errStr,
          userMessage: fallbackMessage ?? 'Une erreur est survenue. Veuillez réessayer.',
        );
    }
  }

  static AppException _statusCodeToException(DioException error, String? fallbackMessage) {
    final statusCode = error.response?.statusCode;
    final serverMessage = _extractServerMessage(error);
    final errorCode = _extractErrorCode(error);

    switch (statusCode) {
      case 401:
        return const SessionExpiredException();
      case 403:
        return ForbiddenException(
          message: '403 Forbidden: $serverMessage',
          userMessage: serverMessage ?? 'Accès refusé.',
          code: errorCode,
        );
      case 404:
        return NotFoundException(
          message: '404 Not Found',
          userMessage: serverMessage ?? 'Élément introuvable.',
        );
      case 409:
        return ConflictException(
          message: '409 Conflict',
          userMessage: serverMessage ?? 'Cette action ne peut pas être effectuée actuellement.',
        );
      case 422:
        return ValidationException(
          message: '422 Validation Error',
          userMessage: serverMessage ?? 'Données invalides. Vérifiez les informations saisies.',
          fieldErrors: _extractFieldErrors(error),
        );
      case 429:
        return const RateLimitException();
      case 500:
      case 502:
      case 503:
        return const ServerException();
      default:
        return ApiException(
          statusCode: statusCode,
          message: 'HTTP $statusCode',
          userMessage: serverMessage ?? fallbackMessage ?? 'Une erreur est survenue. Veuillez réessayer.',
        );
    }
  }

  // ── Compatibilité existante ─────────────────────────

  /// Convertit une erreur Dio en message user-friendly
  static String getReadableMessage(dynamic error, {String? defaultMessage}) {
    return toAppException(error, fallbackMessage: defaultMessage).userMessage;
  }

  static String? _extractServerMessage(DioException error) {
    try {
      final data = error.response?.data;
      if (data is Map) {
        return data['message'] as String?;
      }
    } catch (_) {}
    return null;
  }

  static String? _extractErrorCode(DioException error) {
    try {
      final data = error.response?.data;
      if (data is Map) {
        return data['error_code'] as String?;
      }
    } catch (_) {}
    return null;
  }

  static Map<String, List<String>> _extractFieldErrors(DioException error) {
    try {
      final data = error.response?.data;
      if (data is Map && data.containsKey('errors')) {
        final errors = data['errors'] as Map;
        return errors.map((key, value) {
          final messages = value is List
              ? value.map((e) => e.toString()).toList()
              : [value.toString()];
          return MapEntry(key.toString(), messages);
        });
      }
    } catch (_) {}
    return {};
  }

  /// Messages spécifiques pour les livraisons
  static String getDeliveryErrorMessage(dynamic error) {
    if (error is DioException) {
      final statusCode = error.response?.statusCode;
      final serverMessage = _extractServerMessage(error);
      final errorCode = _extractErrorCode(error);
      
      if (statusCode == 403) {
        if (errorCode == 'COURIER_PROFILE_NOT_FOUND') {
          return 'Votre profil coursier n\'est pas configuré. Contactez le support.';
        }
        return serverMessage ?? 'Vous n\'êtes pas autorisé à effectuer cette action.';
      }
      
      if (statusCode == 404) {
        return 'Livraison introuvable ou déjà prise en charge par un autre coursier.';
      }
      
      if (statusCode == 409) {
        return serverMessage ?? 'Cette livraison n\'est plus disponible.';
      }
    }
    
    return getReadableMessage(error, defaultMessage: 'Impossible de traiter la livraison.');
  }

  /// Messages spécifiques pour le profil
  static String getProfileErrorMessage(dynamic error) {
    if (error is DioException) {
      final statusCode = error.response?.statusCode;
      final errorCode = _extractErrorCode(error);
      
      if (statusCode == 403 && errorCode == 'COURIER_PROFILE_NOT_FOUND') {
        return 'Profil coursier non trouvé. Ce compte n\'est pas configuré comme livreur.';
      }
      
      if (statusCode == 401) {
        return 'Session expirée. Veuillez vous reconnecter.';
      }
    }
    
    return getReadableMessage(error, defaultMessage: 'Impossible de charger le profil.');
  }

  /// Messages spécifiques pour les messages/chat
  static String getChatErrorMessage(dynamic error) {
    return getReadableMessage(error, defaultMessage: 'Impossible d\'envoyer le message.');
  }
}
