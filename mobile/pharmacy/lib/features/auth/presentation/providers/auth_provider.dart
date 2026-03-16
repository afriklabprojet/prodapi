import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/errors/failure.dart';
import '../../domain/repositories/auth_repository.dart';
import '../providers/auth_di_providers.dart';
import 'state/auth_state.dart';

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _repository;
  bool _isInitialized = false;

  AuthNotifier(this._repository) : super(const AuthState()) {
    // Ne pas appeler checkAuthStatus ici pour éviter le loading initial
    // L'initialisation sera faite manuellement quand nécessaire
  }

  /// Helper pour éviter l'assertion Riverpod "setState after dispose"
  void _safeSetState(AuthState newState) {
    if (mounted) {
      state = newState;
    }
  }

  /// Initialise le provider en vérifiant l'état d'authentification
  /// Doit être appelé une seule fois au démarrage de l'app
  Future<void> initialize() async {
    if (_isInitialized) return;
    _isInitialized = true;
    await checkAuthStatus();
  }

  Future<void> checkAuthStatus() async {
    if (kDebugMode) debugPrint('🔍 [AuthNotifier] checkAuthStatus() appelé');
    
    final result = await _repository.getCurrentUser();

    if (!mounted) return;

    result.fold(
      (failure) {
        if (kDebugMode) debugPrint('🔍 [AuthNotifier] checkAuthStatus - Pas d\'utilisateur connecté: ${failure.message}');
        _safeSetState(state.copyWith(status: AuthStatus.unauthenticated, errorMessage: null));
      },
      (user) {
        if (kDebugMode) debugPrint('🔍 [AuthNotifier] checkAuthStatus - Utilisateur trouvé: ${user.email}');
        _safeSetState(state.copyWith(status: AuthStatus.authenticated, user: user, errorMessage: null));
      },
    );
  }

  Future<void> login(String email, String password) async {
    if (kDebugMode) debugPrint('🔐 [AuthNotifier] login() appelé avec email: $email');
    if (kDebugMode) debugPrint('🔐 [AuthNotifier] État actuel: ${state.status}');
    
    _safeSetState(state.copyWith(status: AuthStatus.loading, errorMessage: null, originalError: null));
    if (kDebugMode) debugPrint('🔐 [AuthNotifier] État mis à loading');

    try {
      if (kDebugMode) debugPrint('🔐 [AuthNotifier] Appel de repository.login()...');
      final result = await _repository.login(email: email, password: password);
      if (kDebugMode) debugPrint('🔐 [AuthNotifier] Résultat reçu du repository');

      if (!mounted) return;

      result.fold(
        (failure) {
          if (kDebugMode) debugPrint('❌ [AuthNotifier] Échec login: ${failure.message}');
          _safeSetState(state.copyWith(
            status: AuthStatus.error,
            errorMessage: failure.message,
            originalError: failure.originalError,
          ));
        },
        (authResponse) {
          if (kDebugMode) debugPrint('✅ [AuthNotifier] Login réussi pour: ${authResponse.user.email}');
          _safeSetState(state.copyWith(
            status: AuthStatus.authenticated,
            user: authResponse.user,
          ));
        },
      );
    } catch (e, stackTrace) {
      if (kDebugMode) debugPrint('💥 [AuthNotifier] Exception inattendue: $e');
      if (kDebugMode) debugPrint('💥 [AuthNotifier] StackTrace: $stackTrace');
      _safeSetState(state.copyWith(
        status: AuthStatus.error,
        errorMessage: 'Erreur inattendue: $e',
        originalError: e,
      ));
    }
  }

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
    if (kDebugMode) debugPrint('📝 [AuthNotifier] register() appelé');
    _safeSetState(state.copyWith(
      status: AuthStatus.loading, 
      errorMessage: null,
      fieldErrors: null, // Clear previous field errors
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
        if (kDebugMode) debugPrint('❌ [AuthNotifier] Échec inscription: ${failure.message}');
        
        // Extract field-specific errors if it's a validation failure
        Map<String, String>? fieldErrors;
        if (failure is ValidationFailure) {
          fieldErrors = _extractFieldErrors(failure.errors);
          if (kDebugMode) debugPrint('❌ [AuthNotifier] Field errors: $fieldErrors');
        }
        
        _safeSetState(state.copyWith(
          status: AuthStatus.error,
          errorMessage: failure.message,
          fieldErrors: fieldErrors,
        ));
      },
      (authResponse) {
        if (kDebugMode) debugPrint('✅ [AuthNotifier] Inscription réussie');
        _safeSetState(state.copyWith(
          status: AuthStatus.registered,
          user: authResponse.user,
          fieldErrors: null,
        ));
      },
    );
  }
  
  /// Extracts first error message for each field from validation errors
  Map<String, String> _extractFieldErrors(Map<String, List<String>> errors) {
    final Map<String, String> fieldErrors = {};
    
    errors.forEach((field, messages) {
      if (messages.isNotEmpty) {
        // Map API field names to form field names
        final formField = _mapApiFieldToFormField(field);
        fieldErrors[formField] = _translateErrorMessage(messages.first);
      }
    });
    
    return fieldErrors;
  }
  
  /// Maps API field names to form field names
  String _mapApiFieldToFormField(String apiField) {
    const fieldMapping = {
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
    return fieldMapping[apiField] ?? apiField;
  }
  
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

  /// Réinitialise l'état pour revenir à l'écran de login sans loader
  /// Doit être appelé après une inscription réussie ou quand on navigue vers login
  void resetToUnauthenticated() {
    if (kDebugMode) debugPrint('🔄 [AuthNotifier] resetToUnauthenticated() appelé');
    _safeSetState(const AuthState(status: AuthStatus.unauthenticated));
  }

  /// Efface le message d'erreur et remet le status à unauthenticated
  /// ✅ IMPORTANT: Doit changer le status pour éviter les états incohérents
  void clearError() {
    if (state.status == AuthStatus.error) {
      _safeSetState(AuthState(
        status: AuthStatus.unauthenticated,
        user: state.user,
        // Clear all error fields
        errorMessage: null,
        fieldErrors: null,
        originalError: null,
      ));
    } else if (state.errorMessage != null || state.fieldErrors != null) {
      _safeSetState(state.copyWith(
        errorMessage: null,
        fieldErrors: null,
      ));
    }
  }
  
  /// Clear only field errors (useful when user starts typing)
  void clearFieldError(String fieldName) {
    if (state.fieldErrors != null && state.fieldErrors!.containsKey(fieldName)) {
      final newErrors = Map<String, String>.from(state.fieldErrors!);
      newErrors.remove(fieldName);
      _safeSetState(state.copyWith(
        fieldErrors: newErrors.isEmpty ? null : newErrors,
      ));
    }
  }

  Future<void> logout() async {
    _safeSetState(state.copyWith(status: AuthStatus.loading));
    await _repository.logout();
    if (!mounted) return;
    _safeSetState(state.copyWith(status: AuthStatus.unauthenticated, user: null));
  }

  Future<void> forgotPassword(String email) async {
    await _repository.forgotPassword(email: email);
  }

  Future<void> updateProfile({
    String? name,
    String? email,
    String? phone,
  }) async {
    _safeSetState(state.copyWith(status: AuthStatus.loading));
    try {
      await _repository.updateProfile(
        name: name,
        email: email,
        phone: phone,
      );
      // Refresh user data
      await checkAuthStatus();
    } catch (e) {
      if (!mounted) return;
      _safeSetState(state.copyWith(
        status: AuthStatus.error,
        errorMessage: e.toString(),
      ));
      rethrow;
    }
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.watch(authRepositoryProvider));
});
