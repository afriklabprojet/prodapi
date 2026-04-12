/// Exceptions pour la couche Data de l'application

/// Exception serveur (erreurs HTTP)
class ServerException implements Exception {
  final String message;
  final int? statusCode;
  /// Données brutes de la réponse serveur (utile pour PAYMENT_IN_PROGRESS / redirect_url)
  final Map<String, dynamic>? responseData;

  ServerException({required this.message, this.statusCode, this.responseData});

  @override
  String toString() => 'ServerException: $message (status: $statusCode)';
}

/// Exception réseau (pas de connexion)
class NetworkException implements Exception {
  final String message;

  NetworkException({this.message = 'Erreur de connexion réseau'});

  @override
  String toString() => 'NetworkException: $message';
}

/// Exception d'authentification (401)
class UnauthorizedException implements Exception {
  final String message;

  UnauthorizedException({this.message = 'Session expirée'});

  @override
  String toString() => 'UnauthorizedException: $message';
}

/// Exception de validation (422)
class ValidationException implements Exception {
  final Map<String, List<String>> errors;

  ValidationException({required this.errors});

  String get firstError {
    if (errors.isEmpty) return 'Erreur de validation';
    final firstKey = errors.keys.first;
    return errors[firstKey]?.first ?? 'Erreur de validation';
  }

  @override
  String toString() => 'ValidationException: $errors';
}

/// Exception de cache
class CacheException implements Exception {
  final String message;

  CacheException({this.message = 'Erreur de cache'});

  @override
  String toString() => 'CacheException: $message';
}
