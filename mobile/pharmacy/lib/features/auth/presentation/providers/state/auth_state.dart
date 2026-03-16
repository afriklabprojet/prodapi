import '../../../domain/entities/user_entity.dart';

/// États d'authentification
enum AuthStatus {
  initial,
  loading,
  authenticated,
  unauthenticated,
  registered,
  error,
}

/// État complet de l'authentification
class AuthState {
  final AuthStatus status;
  final UserEntity? user;
  final String? errorMessage;
  final Object? originalError;
  final Map<String, String>? fieldErrors;

  const AuthState({
    this.status = AuthStatus.initial,
    this.user,
    this.errorMessage,
    this.originalError,
    this.fieldErrors,
  });

  AuthState copyWith({
    AuthStatus? status,
    UserEntity? user,
    String? errorMessage,
    Object? originalError,
    Map<String, String>? fieldErrors,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      errorMessage: errorMessage,
      originalError: originalError,
      fieldErrors: fieldErrors,
    );
  }

  /// Vérifie si des erreurs de champ existent.
  bool get hasFieldErrors => fieldErrors != null && fieldErrors!.isNotEmpty;

  /// Récupère l'erreur d'un champ spécifique.
  String? getFieldError(String fieldName) => fieldErrors?[fieldName];

  @override
  String toString() => 'AuthState(status: $status, user: ${user?.email}, error: $errorMessage)';
}
