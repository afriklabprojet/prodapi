import '../utils/error_translator.dart';

/// Classes d'erreur (Failure) pour la couche domaine.
///
/// Utilisées avec [Either<Failure, T>] de dartz pour
/// propager les erreurs de manière typée.

abstract class Failure {
  final String message;
  final Object? originalError;

  const Failure(this.message, {this.originalError});

  @override
  String toString() => message;
}

class ServerFailure extends Failure {
  const ServerFailure(super.message, {super.originalError});
}

class NetworkFailure extends Failure {
  const NetworkFailure(super.message, {super.originalError});
}

class ValidationFailure extends Failure {
  final Map<String, List<String>> errors;

  ValidationFailure(this.errors, {super.originalError})
      : super(_buildMessage(errors));

  static String _buildMessage(Map<String, List<String>> errors) {
    final messages = errors.values
        .expand((v) => v)
        .map(ErrorTranslator.toFrench)
        .toList();
    return messages.join(', ');
  }
}

class UnauthorizedFailure extends Failure {
  const UnauthorizedFailure(super.message, {super.originalError});
}

class ForbiddenFailure extends Failure {
  final String? errorCode;

  const ForbiddenFailure(super.message, {this.errorCode, super.originalError});
}

class CacheFailure extends Failure {
  const CacheFailure(super.message, {super.originalError});
}
