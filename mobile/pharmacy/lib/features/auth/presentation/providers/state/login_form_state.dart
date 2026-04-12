import '../../../domain/enums/password_strength.dart';

/// État du formulaire de connexion.
///
/// Sépare la logique de présentation de la page de login
/// pour une meilleure testabilité et maintenabilité.
class LoginFormState {
  /// Email saisi
  final String email;

  /// Mot de passe saisi
  final String password;

  /// Email valide selon regex RFC 5322
  final bool isEmailValid;

  /// Mot de passe visible/masqué
  final bool obscurePassword;

  /// Option "Se souvenir de moi"
  final bool rememberMe;

  /// Force du mot de passe
  final PasswordStrength passwordStrength;

  /// Formulaire en cours de soumission
  final bool isSubmitting;

  /// Overlay de chargement visible
  final bool showLoadingOverlay;

  /// Navigation en cours (évite double navigation)
  final bool isNavigating;

  /// Biométrie disponible sur l'appareil
  final bool biometricAvailable;

  /// Biométrie activée par l'utilisateur
  final bool biometricEnabled;

  /// Authentification biométrique en cours
  final bool isBiometricAuthenticating;

  /// Label biométrique ("Face ID", "Touch ID", "Biométrie")
  final String? biometricLabel;

  /// Email pré-rempli (désactive autofocus email)
  final bool hasPrefilledEmail;

  const LoginFormState({
    this.email = '',
    this.password = '',
    this.isEmailValid = false,
    this.obscurePassword = true,
    this.rememberMe = false,
    this.passwordStrength = PasswordStrength.empty,
    this.isSubmitting = false,
    this.showLoadingOverlay = false,
    this.isNavigating = false,
    this.biometricAvailable = false,
    this.biometricEnabled = false,
    this.isBiometricAuthenticating = false,
    this.biometricLabel,
    this.hasPrefilledEmail = false,
  });

  /// Crée une copie avec les champs modifiés.
  LoginFormState copyWith({
    String? email,
    String? password,
    bool? isEmailValid,
    bool? obscurePassword,
    bool? rememberMe,
    PasswordStrength? passwordStrength,
    bool? isSubmitting,
    bool? showLoadingOverlay,
    bool? isNavigating,
    bool? biometricAvailable,
    bool? biometricEnabled,
    bool? isBiometricAuthenticating,
    String? biometricLabel,
    bool? hasPrefilledEmail,
  }) {
    return LoginFormState(
      email: email ?? this.email,
      password: password ?? this.password,
      isEmailValid: isEmailValid ?? this.isEmailValid,
      obscurePassword: obscurePassword ?? this.obscurePassword,
      rememberMe: rememberMe ?? this.rememberMe,
      passwordStrength: passwordStrength ?? this.passwordStrength,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      showLoadingOverlay: showLoadingOverlay ?? this.showLoadingOverlay,
      isNavigating: isNavigating ?? this.isNavigating,
      biometricAvailable: biometricAvailable ?? this.biometricAvailable,
      biometricEnabled: biometricEnabled ?? this.biometricEnabled,
      isBiometricAuthenticating:
          isBiometricAuthenticating ?? this.isBiometricAuthenticating,
      biometricLabel: biometricLabel ?? this.biometricLabel,
      hasPrefilledEmail: hasPrefilledEmail ?? this.hasPrefilledEmail,
    );
  }

  /// Indique si le bouton de connexion doit être désactivé.
  bool get isLoginDisabled => isSubmitting || showLoadingOverlay;

  /// Indique si la biométrie peut être utilisée.
  bool get canUseBiometric =>
      biometricAvailable && biometricEnabled && !isLoginDisabled;
}
