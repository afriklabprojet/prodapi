/// Hiérarchie d'exceptions typées pour l'application.
///
/// Permet de distinguer les types d'erreurs dans les catch blocks et
/// d'afficher des messages adaptés à l'utilisateur.
library;

/// Exception de base de l'application.
/// Toutes les exceptions métier en héritent.
sealed class AppException implements Exception {
  /// Message technique (pour les logs)
  final String message;

  /// Message lisible pour l'utilisateur
  final String userMessage;

  /// Code d'erreur optionnel (ex: 'COURIER_PROFILE_NOT_FOUND')
  final String? code;

  const AppException({
    required this.message,
    required this.userMessage,
    this.code,
  });

  @override
  String toString() => userMessage;
}

/// Erreur réseau (pas de connexion, timeout, DNS…)
class NetworkException extends AppException {
  const NetworkException({
    super.message = 'Network error',
    super.userMessage = 'Impossible de se connecter. Vérifiez votre connexion internet.',
    super.code,
  });
}

/// Erreur renvoyée par l'API (4xx / 5xx).
class ApiException extends AppException {
  final int? statusCode;
  final Map<String, dynamic>? errors;

  const ApiException({
    required super.message,
    required super.userMessage,
    super.code,
    this.statusCode,
    this.errors,
  });
}

/// Session expirée (401 Unauthorized).
class SessionExpiredException extends AppException {
  const SessionExpiredException({
    super.message = '401 Unauthorized',
    super.userMessage = 'Session expirée. Veuillez vous reconnecter.',
    super.code = 'SESSION_EXPIRED',
  });
}

/// Accès refusé (403 Forbidden).
class ForbiddenException extends AppException {
  const ForbiddenException({
    super.message = '403 Forbidden',
    super.userMessage = 'Accès refusé.',
    super.code,
  });
}

/// Ressource introuvable (404 Not Found).
class NotFoundException extends AppException {
  const NotFoundException({
    super.message = '404 Not Found',
    super.userMessage = 'Élément introuvable.',
    super.code,
  });
}

/// Erreur de validation (422 Unprocessable Entity).
class ValidationException extends AppException {
  final Map<String, List<String>> fieldErrors;

  const ValidationException({
    super.message = '422 Validation Error',
    super.userMessage = 'Données invalides. Vérifiez les informations saisies.',
    super.code,
    this.fieldErrors = const {},
  });

  /// Récupère le premier message d'erreur de tous les champs.
  String get firstFieldError {
    for (final errors in fieldErrors.values) {
      if (errors.isNotEmpty) return errors.first;
    }
    return userMessage;
  }
}

/// Erreur serveur (500, 502, 503…).
class ServerException extends AppException {
  const ServerException({
    super.message = 'Server error',
    super.userMessage = 'Le serveur rencontre des difficultés. Réessayez plus tard.',
    super.code,
  });
}

/// Erreur de cache / stockage local.
class CacheException extends AppException {
  const CacheException({
    super.message = 'Cache error',
    super.userMessage = 'Erreur de données locales.',
    super.code,
  });
}

/// Conflit (409) – ex: livraison déjà prise.
class ConflictException extends AppException {
  const ConflictException({
    super.message = '409 Conflict',
    super.userMessage = 'Cette action ne peut pas être effectuée actuellement.',
    super.code,
  });
}

/// Trop de requêtes (429 Rate Limit).
class RateLimitException extends AppException {
  const RateLimitException({
    super.message = '429 Too Many Requests',
    super.userMessage = 'Trop de requêtes. Veuillez patienter quelques instants.',
    super.code,
  });
}
