import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/auth_response_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/usecases/get_current_user_usecase.dart';
import '../../domain/usecases/login_usecase.dart';
import '../../domain/usecases/logout_usecase.dart';
import '../../domain/usecases/register_usecase.dart';
import 'auth_state.dart';

class AuthNotifier extends StateNotifier<AuthState> {
  final LoginUseCase loginUseCase;
  final RegisterUseCase registerUseCase;
  final LogoutUseCase logoutUseCase;
  final GetCurrentUserUseCase getCurrentUserUseCase;
  final AuthRepository authRepository;

  AuthNotifier({
    required this.loginUseCase,
    required this.registerUseCase,
    required this.logoutUseCase,
    required this.getCurrentUserUseCase,
    required this.authRepository,
  }) : super(const AuthState.initial()) {
    _checkAuthStatus();
  }

  /// Helper pour éviter l'assertion Riverpod "setState after dispose"
  void _safeSetState(AuthState newState) {
    if (mounted) {
      state = newState;
    }
  }

  Future<void> _checkAuthStatus() async {
    final result = await getCurrentUserUseCase();
    result.fold(
      (failure) => _safeSetState(const AuthState.unauthenticated()),
      (user) => _safeSetState(AuthState.authenticated(user)),
    );
  }

  Future<void> login({required String email, required String password}) async {
    _safeSetState(const AuthState.loading());

    final result = await loginUseCase(email: email, password: password);

    if (!mounted) return;

    result.fold(
      (failure) {
        if (failure is ValidationFailure) {
          _safeSetState(
            AuthState.error(message: failure.message, errors: failure.errors),
          );
        } else {
          _safeSetState(AuthState.error(message: failure.message));
        }
      },
      (authResponse) {
        _safeSetState(AuthState.authenticated(authResponse.user));
      },
    );
  }

  Future<void> register({
    required String name,
    required String email,
    required String phone,
    required String password,
    required String passwordConfirmation,
    String? address,
  }) async {
    _safeSetState(const AuthState.loading());

    final result = await registerUseCase(
      name: name,
      email: email,
      phone: phone,
      password: password,
      passwordConfirmation: passwordConfirmation,
      address: address,
    );

    if (!mounted) return;

    result.fold(
      (failure) {
        if (failure is ValidationFailure) {
          _safeSetState(
            AuthState.error(message: failure.message, errors: failure.errors),
          );
        } else {
          _safeSetState(AuthState.error(message: failure.message));
        }
      },
      (authResponse) {
        _safeSetState(AuthState.authenticated(authResponse.user));
      },
    );
  }

  Future<void> logout() async {
    _safeSetState(const AuthState.loading());

    final result = await logoutUseCase();

    if (!mounted) return;

    result.fold(
      (failure) => _safeSetState(AuthState.error(message: failure.message)),
      (_) => _safeSetState(const AuthState.unauthenticated()),
    );
  }

  /// Clear auth state immediately without loading state.
  /// Use this when navigating back from OTP page to avoid showing splash.
  void clearAuthStateSync() {
    _safeSetState(const AuthState.unauthenticated());
    // Perform logout in background (fire and forget)
    logoutUseCase();
  }

  /// Vérifie l'OTP Firebase et met à jour l'état d'authentification
  Future<Either<Failure, AuthResponseEntity>> verifyFirebaseOtp({
    required String phone,
    required String firebaseUid,
    required String firebaseIdToken,
  }) async {
    _safeSetState(const AuthState.loading());

    final result = await authRepository.verifyFirebaseOtp(
      phone: phone,
      firebaseUid: firebaseUid,
      firebaseIdToken: firebaseIdToken,
    );

    if (!mounted) return result;

    result.fold(
      (failure) {
        if (failure is ValidationFailure) {
          _safeSetState(
            AuthState.error(message: failure.message, errors: failure.errors),
          );
        } else {
          _safeSetState(AuthState.error(message: failure.message));
        }
      },
      (authResponse) {
        _safeSetState(AuthState.authenticated(authResponse.user));
      },
    );

    return result;
  }

  /// Vérifie l'OTP backend (Infobip) et met à jour l'état d'authentification
  Future<Either<Failure, AuthResponseEntity>> verifyBackendOtp({
    required String identifier,
    required String otp,
  }) async {
    _safeSetState(const AuthState.loading());

    final result = await authRepository.verifyOtp(
      identifier: identifier,
      otp: otp,
    );

    if (!mounted) return result;

    result.fold(
      (failure) {
        if (failure is ValidationFailure) {
          _safeSetState(
            AuthState.error(message: failure.message, errors: failure.errors),
          );
        } else {
          _safeSetState(AuthState.error(message: failure.message));
        }
      },
      (authResponse) {
        _safeSetState(AuthState.authenticated(authResponse.user));
      },
    );

    return result;
  }

  /// Renvoie l'OTP via le backend (Infobip SMS/WhatsApp)
  Future<Either<Failure, Map<String, dynamic>>> resendBackendOtp({
    required String identifier,
  }) async {
    return await authRepository.resendOtp(identifier: identifier);
  }

  void clearError() {
    if (state.status == AuthStatus.error) {
      _safeSetState(const AuthState.unauthenticated());
    }
  }

  /// Se connecte ou crée un compte via Google Sign-In
  Future<void> loginWithGoogle() async {
    _safeSetState(const AuthState.loading());

    final result = await authRepository.loginWithGoogle();

    if (!mounted) return;

    result.fold(
      (failure) => _safeSetState(AuthState.error(message: failure.message)),
      (authResponse) =>
          _safeSetState(AuthState.authenticated(authResponse.user)),
    );
  }
}
