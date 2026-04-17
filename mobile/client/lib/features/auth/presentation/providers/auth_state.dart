import 'package:equatable/equatable.dart';
import '../../domain/entities/user_entity.dart';

enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

class AuthState extends Equatable {
  final AuthStatus status;
  final UserEntity? user;
  final String? errorMessage;
  final Map<String, List<String>>? validationErrors;

  const AuthState({
    required this.status,
    this.user,
    this.errorMessage,
    this.validationErrors,
  });

  const AuthState.initial()
    : status = AuthStatus.initial,
      user = null,
      errorMessage = null,
      validationErrors = null;

  const AuthState.loading({this.user})
    : status = AuthStatus.loading,
      errorMessage = null,
      validationErrors = null;

  const AuthState.authenticated(this.user)
    : status = AuthStatus.authenticated,
      errorMessage = null,
      validationErrors = null;

  const AuthState.unauthenticated()
    : status = AuthStatus.unauthenticated,
      user = null,
      errorMessage = null,
      validationErrors = null;

  const AuthState.error({
    required String message,
    Map<String, List<String>>? errors,
  }) : status = AuthStatus.error,
       user = null,
       errorMessage = message,
       validationErrors = errors;

  AuthState copyWith({
    AuthStatus? status,
    UserEntity? user,
    bool clearUser = false,
    String? errorMessage,
    bool clearError = false,
    Map<String, List<String>>? validationErrors,
    bool clearValidationErrors = false,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: clearUser ? null : (user ?? this.user),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      validationErrors: clearValidationErrors ? null : (validationErrors ?? this.validationErrors),
    );
  }

  @override
  List<Object?> get props => [status, user, errorMessage, validationErrors];
}
