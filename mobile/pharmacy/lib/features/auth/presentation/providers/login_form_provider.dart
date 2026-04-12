import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/providers/core_providers.dart';
import '../../domain/enums/password_strength.dart';
import 'state/login_form_state.dart';

/// Provider pour le formulaire de connexion.
final loginFormProvider =
    AutoDisposeNotifierProvider<LoginFormNotifier, LoginFormState>(
      LoginFormNotifier.new,
    );

/// Notifier pour gérer l'état du formulaire de connexion.
///
/// Sépare la logique métier de la page pour:
/// - Meilleure testabilité (tests unitaires sans UI)
/// - Code plus lisible et maintenable
/// - Réutilisation potentielle
class LoginFormNotifier extends AutoDisposeNotifier<LoginFormState> {
  // Clés de stockage
  static const _rememberMeKey = 'pharmacy_remember_me';
  static const _savedEmailKey = 'remember_me_email'; // Clé pour secure storage

  // Regex email RFC 5322
  static final _emailRegex = RegExp(
    r'^[a-zA-Z0-9.!#$%&*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)+$',
  );

  @override
  LoginFormState build() {
    // Différer l'initialisation asynchrone pour éviter les erreurs Riverpod
    // du type "Bad state: Tried to read the state of an uninitialized provider".
    Future.microtask(() async {
      await _loadSavedCredentials();
      await _checkBiometricCapability();
    });
    return const LoginFormState();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // CREDENTIALS PERSISTENCE (SECURE)
  // ═══════════════════════════════════════════════════════════════════════════

  /// Charge l'email sauvegardé si "Se souvenir de moi" était coché.
  /// Email stocké dans FlutterSecureStorage pour conformité RGPD.
  Future<void> _loadSavedCredentials() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final remember = prefs.getBool(_rememberMeKey) ?? false;

      if (remember) {
        // Email dans secure storage (chiffré)
        final securityService = ref.read(securityServiceProvider);
        final email = await securityService.getSecureData(_savedEmailKey) ?? '';

        if (email.isNotEmpty) {
          state = state.copyWith(
            email: email,
            rememberMe: true,
            isEmailValid: _emailRegex.hasMatch(email),
            hasPrefilledEmail: true,
          );
        }
      }
    } catch (e) {
      if (kDebugMode) debugPrint('❌ [LoginForm] Error loading credentials: $e');
    }
  }

  /// Sauvegarde les préférences de connexion.
  /// Email stocké de manière sécurisée (FlutterSecureStorage).
  Future<void> saveCredentials() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final securityService = ref.read(securityServiceProvider);

      if (state.rememberMe) {
        await prefs.setBool(_rememberMeKey, true);
        // Email dans secure storage (chiffré) au lieu de SharedPreferences
        await securityService.setSecureData(_savedEmailKey, state.email.trim());
      } else {
        await prefs.remove(_rememberMeKey);
        await securityService.removeSecureData(_savedEmailKey);
      }
    } catch (e) {
      if (kDebugMode) debugPrint('❌ [LoginForm] Error saving credentials: $e');
    }
  }

  /// Efface les credentials sauvegardés (appelé au logout).
  Future<void> clearSavedCredentials() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final securityService = ref.read(securityServiceProvider);
      await prefs.remove(_rememberMeKey);
      await securityService.removeSecureData(_savedEmailKey);
    } catch (e) {
      if (kDebugMode)
        debugPrint('❌ [LoginForm] Error clearing credentials: $e');
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // BIOMETRIC
  // ═══════════════════════════════════════════════════════════════════════════

  /// Vérifie la disponibilité de la biométrie.
  Future<void> _checkBiometricCapability() async {
    try {
      final securityService = ref.read(securityServiceProvider);
      final capability = await securityService.checkBiometricCapability();
      final isEnabled = securityService.isBiometricEnabled();

      String? label;
      if (capability.hasFaceId) {
        label = 'Face ID';
      } else if (capability.hasFingerprint) {
        label = 'Touch ID';
      } else {
        label = 'Biométrie';
      }

      state = state.copyWith(
        biometricAvailable: capability.isAvailable,
        biometricEnabled: isEnabled,
        biometricLabel: label,
      );
    } catch (e) {
      if (kDebugMode) debugPrint('❌ [LoginForm] Error checking biometric: $e');
    }
  }

  /// Démarre l'authentification biométrique.
  void startBiometricAuth() {
    state = state.copyWith(isBiometricAuthenticating: true);
  }

  /// Termine l'authentification biométrique.
  void endBiometricAuth() {
    state = state.copyWith(isBiometricAuthenticating: false);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // FORM UPDATES
  // ═══════════════════════════════════════════════════════════════════════════

  /// Met à jour l'email et valide le format.
  void updateEmail(String value) {
    final trimmed = value.trim();
    final isValid = _emailRegex.hasMatch(trimmed);
    state = state.copyWith(email: trimmed, isEmailValid: isValid);
  }

  /// Met à jour le mot de passe et calcule la force.
  void updatePassword(String value) {
    final strength = PasswordStrength.calculate(value);
    state = state.copyWith(password: value, passwordStrength: strength);
  }

  /// Bascule la visibilité du mot de passe.
  void togglePasswordVisibility() {
    state = state.copyWith(obscurePassword: !state.obscurePassword);
  }

  /// Bascule l'option "Se souvenir de moi".
  void toggleRememberMe() {
    state = state.copyWith(rememberMe: !state.rememberMe);
  }

  /// Active l'option "Se souvenir de moi".
  void setRememberMe(bool value) {
    state = state.copyWith(rememberMe: value);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SUBMISSION STATE
  // ═══════════════════════════════════════════════════════════════════════════

  /// Démarre la soumission du formulaire.
  void startSubmission() {
    state = state.copyWith(isSubmitting: true, showLoadingOverlay: true);
  }

  /// Termine la soumission du formulaire.
  void endSubmission() {
    state = state.copyWith(isSubmitting: false, showLoadingOverlay: false);
  }

  /// Active l'overlay de chargement.
  void showLoading() {
    state = state.copyWith(showLoadingOverlay: true);
  }

  /// Désactive l'overlay de chargement.
  void hideLoading() {
    state = state.copyWith(showLoadingOverlay: false);
  }

  /// Marque la navigation comme en cours.
  void startNavigation() {
    state = state.copyWith(isNavigating: true);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // VALIDATION
  // ═══════════════════════════════════════════════════════════════════════════

  /// Vérifie si l'email est valide.
  bool get isEmailValid => _emailRegex.hasMatch(state.email);

  /// Valide l'email et retourne un message d'erreur ou null.
  String? validateEmail(
    String? value, {
    required String emptyMessage,
    required String invalidMessage,
  }) {
    if (value == null || value.trim().isEmpty) {
      return emptyMessage;
    }
    if (!_emailRegex.hasMatch(value.trim())) {
      return invalidMessage;
    }
    return null;
  }

  /// Valide le mot de passe et retourne un message d'erreur ou null.
  String? validatePassword(
    String? value, {
    required String emptyMessage,
    required String Function(int) minLengthMessage,
  }) {
    if (value == null || value.isEmpty) {
      return emptyMessage;
    }
    if (value.length < PasswordStrength.minLength) {
      return minLengthMessage(PasswordStrength.minLength);
    }
    return null;
  }
}
