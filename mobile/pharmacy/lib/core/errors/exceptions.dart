/// Exceptions de la couche data / réseau.
///
/// Levées dans ApiClient et les DataSources,
/// puis converties en [Failure] dans les Repositories.

class ServerException implements Exception {
  final String message;
  final int? statusCode;

  const ServerException({required this.message, this.statusCode});

  @override
  String toString() => 'ServerException($statusCode): $message';
}

class NetworkException implements Exception {
  final String message;

  const NetworkException({required this.message});

  @override
  String toString() => 'NetworkException: $message';
}

class ValidationException implements Exception {
  final Map<String, List<String>> errors;

  const ValidationException({required this.errors});

  String get message {
    final messages = errors.values.expand((v) => v).toList();
    return messages.isNotEmpty ? messages.first : 'Erreur de validation';
  }

  @override
  String toString() => 'ValidationException: $errors';
}

class UnauthorizedException implements Exception {
  final String message;

  const UnauthorizedException({required this.message});

  @override
  String toString() => 'UnauthorizedException: $message';
}

class ForbiddenException implements Exception {
  final String message;
  final String? errorCode;

  const ForbiddenException({required this.message, this.errorCode});

  @override
  String toString() => 'ForbiddenException: $message (code: $errorCode)';
}

class CacheException implements Exception {
  final String message;

  const CacheException({required this.message});

  @override
  String toString() => 'CacheException: $message';
}
