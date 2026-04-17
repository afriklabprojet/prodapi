import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/errors/failure.dart';
import '../../domain/repositories/auth_repository.dart';
import '../providers/auth_di_providers.dart';
import 'state/auth_state.dart';

/// AuthNotifier gère l'état d'authentification global de l'application.
///
/// Pattern: StateNotifier avec gestion sécurisée du mounted state.
class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _repository;
  bool _isInitialized = false;

  AuthNotifier(this._repository) : super(const AuthState());

  // ============================================================
  // HELPERS
  // ============================================================

  /// Log helper - no-op in release mode
  void _log(String message) {
    if (kDebugMode) debugPrint('[AuthNotifier] $message');
  }

  /// Safe state update - prevents "setState after dispose"
  void _setState(AuthState newState) {
    if (mounted) state = newState;
  }

  /// Sets loading state
  void _setLoading() => _setState(state.copyWith(
        status: AuthStatus.loading,
        errorMessage: null,
        originalError: null,
      ));

  /// Sets error state from Failure
  void _setError(Failure failure, {Map<String, String>? fieldErrors}) {
    _log('❌ Error: ${failure.message}');
    _setState(state.copyWith(
      status: AuthStatus.error,
      errorMessage: failure.message,
      originalError: failure.originalError,
      fieldErrors: fieldErrors,
    ));
  }

  /// Sets error state from exception
  void _setException(Object error, [StackTrace? stack]) {
    _log('💥 Exception: $error');
    if (kDebugMode && stack != null) debugPrint('$stack');
    _setState(state.copyWith(
      status: AuthStatus.error,
      errorMessage: 'Erreur inattendue: $error',
      originalError: error,
    ));
  }

  // ============================================================
  // INITIALIZATION
  // ============================================================

  /// Initialise l'état d'auth. Appelé une seule fois au démarrage.
  Future<void> initialize() async {
    if (_isInitialized) return;
    _isInitialized = true;
    await checkAuthStatus();
  }

  Future<void> checkAuthStatus() async {
    _log('🔍 checkAuthStatus()');

    final result = await _repository.getCurrentUser();
    if (!mounted) return;

    result.fold(
      (failure) {
        _log('🔍 No user: ${failure.message}');
        _setState(state.copyWith(status: AuthStatus.unauthenticated, errorMessage: null));
      },
      (user) {
        _log('🔍 User found: ${user.email}');
        _setState(state.copyWith(status: AuthStatus.authenticated, user: user, errorMessage: null));
      },
    );
  }

  // ============================================================
  // LOGIN
  // ============================================================

  Future<void> login(String email, String password) async {
    _log('🔑 login($email)');
    _setLoading();

    try {
      final result = await _repository.login(email: email, password: password);
      if (!mounted) return;

      result.fold(
        _setError,
        (authResponse) {
          _log('✅ Login OK: ${authResponse.user.email}');
          _setState(state.copyWith(
            status: AuthStatus.authenticated,
            user: authResponse.user,
          ));
        },
      );
    } catch (e, stack) {
      if (!mounted) return;
      _setException(e, stack);
    }
  }

  /// Login with biometric authentication (uses saved email, server validates biometric token)
  Future<void> loginWithBiometric(String email) async {
    _log('🔐 loginWithBiometric($email)');
    _setLoading();

    try {
      final result = await _repository.loginWithBiometric(email: email);
      if (!mounted) return;

      result.fold(
        _setError,
        (authResponse) {
          _log('✅ Biometric OK: ${authResponse.user.email}');
          _setState(state.copyWith(
            status: AuthStatus.authenticated,
            user: authResponse.user,
          ));
        },
      );
    } catch (e, stack) {
      if (!mounted) return;
      _setException(e, stack);
    }
  }

  // ============================================================
  // REGISTER
  // ============================================================

  Future<void> register({
    required String name,
    required String pName,
    required String email,
    required String phone,
    required String password,
    required String licenseNumber,
    required String city,
    required String address,
    required double latitude,
    required double longitude,
  }) async {
    _log('📝 register($email)');
    _setState(state.copyWith(
      status: AuthStatus.loading,
      errorMessage: null,
      fieldErrors: null,
    ));

    final result = await _repository.register(
      name: name,
      pName: pName,
      email: email,
      phone: phone,
      password: password,
      licenseNumber: licenseNumber,
      city: city,
      address: address,
      latitude: latitude,
      longitude: longitude,
    );

    if (!mounted) return;

    result.fold(
      (failure) {
        Map<String, String>? fieldErrors;
        if (failure is ValidationFailure) {
          fieldErrors = _extractFieldErrors(failure.errors);
          _log('❌ Validation errors: $fieldErrors');
        }
        _setError(failure, fieldErrors: fieldErrors);
      },
      (authResponse) {
        _log('✅ Register OK');
        _setState(state.copyWith(
          status: AuthStatus.registered,
          user: authResponse.user,
          fieldErrors: null,
        ));
      },
    );
  }

  // ============================================================
  // FIELD ERROR HANDLING
  // ============================================================

  /// Extracts first error message for each field from validation errors
  Map<String, String> _extractFieldErrors(Map<String, List<String>> errors) {
    return {
      for (final entry in errors.entries)
        if (entry.value.isNotEmpty)
          _mapApiFieldToFormField(entry.key): _translateErrorMessage(entry.value.first),
    };
  }

  /// Maps API field names to form field names
  static const _fieldMapping = {
    'email': 'email',
    'phone': 'phone',
    'password': 'password',
    'name': 'name',
    'p_name': 'pharmacy_name',
    'pharmacy_name': 'pharmacy_name',
    'license_number': 'license',
    'city': 'city',
    'address': 'address',
  };

  String _mapApiFieldToFormField(String apiField) =>
      _fieldMapping[apiField] ?? apiField;

  /// Translates API error messages to user-friendly French messages
  String _translateErrorMessage(String message) {
    final lowerMsg = message.toLowerCase();

    if (lowerMsg.contains('already been taken') || lowerMsg.contains('déjà utilisé')) {
      if (lowerMsg.contains('email')) return 'Cette adresse email est déjà utilisée';
      if (lowerMsg.contains('phone')) return 'Ce numéro de téléphone est déjà utilisé';
      if (lowerMsg.contains('license')) return 'Ce numéro de licence est déjà enregistré';
      return 'Cette valeur est déjà utilisée';
    }

    if (lowerMsg.contains('required') || lowerMsg.contains('requis')) {
      return 'Ce champ est requis';
    }

    if (lowerMsg.contains('must be at least') || lowerMsg.contains('minimum')) {
      return 'Valeur trop courte';
    }

    if (lowerMsg.contains('invalid') || lowerMsg.contains('invalide')) {
      return 'Format invalide';
    }

    return message;
  }

  // ============================================================
  // STATE MANAGEMENT
  // ============================================================

  /// Resets state to unauthenticated (after registration or navigation to login)
  void resetToUnauthenticated() {
    _log('🔄 resetToUnauthenticated()');
    _setState(const AuthState(status: AuthStatus.unauthenticated));
  }

  /// Clears error message and resets status to unauthenticated
  void clearError() {
    if (state.status == AuthStatus.error) {
      _setState(AuthState(
        status: AuthStatus.unauthenticated,
        user: state.user,
      ));
    } else if (state.errorMessage != null || state.fieldErrors != null) {
      _setState(state.copyWith(
        errorMessage: null,
        fieldErrors: null,
      ));
    }
  }

  /// Clear only field errors (useful when user starts typing)
  void clearFieldError(String fieldName) {
    final errors = state.fieldErrors;
    if (errors != null && errors.containsKey(fieldName)) {
      final newErrors = Map<String, String>.from(errors)..remove(fieldName);
      _setState(state.copyWith(
        fieldErrors: newErrors.isEmpty ? null : newErrors,
      ));
    }
  }

  // ============================================================
  // LOGOUT / PROFILE
  // ============================================================

  Future<void> logout() async {
    _log('🚪 logout()');
    _setState(state.copyWith(status: AuthStatus.loading));
    await _repository.logout();
    if (!mounted) return;
    _setState(state.copyWith(status: AuthStatus.unauthenticated, user: null));
  }

  Future<void> forgotPassword(String email) async {
    _log('🔑 forgotPassword($email)');
    await _repository.forgotPassword(email: email);
  }

  Future<void> updateProfile({
    String? name,
    String? email,
    String? phone,
  }) async {
    _log('✏️ updateProfile()');
    _setState(state.copyWith(status: AuthStatus.loading));
    try {
      await _repository.updateProfile(
        name: name,
        email: email,
        phone: phone,
      );
      await checkAuthStatus();
    } catch (e, stack) {
      if (!mounted) return;
      _setException(e, stack);
      rethrow;
    }
  }
}

// ============================================================
// PROVIDER
// ============================================================

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.watch(authRepositoryProvider));
});
