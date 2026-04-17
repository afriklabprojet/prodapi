/// Force du mot de passe
enum PasswordStrength { weak, medium, strong }

/// Validateurs pour les champs de formulaire Flutter
class FormValidators {
  FormValidators._();

  /// Validate required field
  static String? required(String? value, {String fieldName = 'Ce champ'}) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName est requis';
    }
    return null;
  }

  /// Validate email
  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'L\'email est requis';
    }
    if (!RegExp(r'^[\w\-\.]+@([\w\-]+\.)+[\w\-]{2,}$').hasMatch(value.trim())) {
      return 'Format d\'email invalide';
    }
    return null;
  }

  /// Alias for email validator
  static String? validateEmail(String? value) => email(value);

  /// Validate phone number
  static String? phone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Le numéro de téléphone est requis';
    }
    final cleaned = value.replaceAll(RegExp(r'[\s\-\.\(\)]'), '');
    if (cleaned.length < 8 || cleaned.length > 15) {
      return 'Numéro de téléphone invalide';
    }
    return null;
  }

  /// Alias for phone validator
  static String? validatePhone(String? value) => phone(value);

  /// Validate password
  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return 'Le mot de passe est requis';
    }
    if (value.length < 8) {
      return 'Le mot de passe doit contenir au moins 8 caractères';
    }
    return null;
  }

  /// Validate password with strength requirement
  static String? validatePassword(String? value, {PasswordStrength? strength}) {
    if (value == null || value.isEmpty) {
      return 'Le mot de passe est requis';
    }
    if (value.length < 8) {
      return 'Le mot de passe doit contenir au moins 8 caractères';
    }
    if (strength == PasswordStrength.strong) {
      if (!RegExp(r'[A-Z]').hasMatch(value)) {
        return 'Le mot de passe doit contenir au moins une majuscule';
      }
      if (!RegExp(r'[0-9]').hasMatch(value)) {
        return 'Le mot de passe doit contenir au moins un chiffre';
      }
    }
    return null;
  }

  /// Validate password confirmation
  static String? confirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) {
      return 'La confirmation du mot de passe est requise';
    }
    if (value != password) {
      return 'Les mots de passe ne correspondent pas';
    }
    return null;
  }

  /// Alias for password confirmation
  static String? validatePasswordConfirmation(String? value, String password) =>
      confirmPassword(value, password);

  /// Validate name
  static String? name(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Le nom est requis';
    }
    if (value.trim().length < 2) {
      return 'Le nom doit contenir au moins 2 caractères';
    }
    return null;
  }

  /// Validate name with options
  static String? validateName(String? value, {String? fieldName, int? minLength}) {
    final field = fieldName ?? 'Le nom';
    final min = minLength ?? 2;
    if (value == null || value.trim().isEmpty) {
      return '$field est requis';
    }
    if (value.trim().length < min) {
      return '$field doit contenir au moins $min caractères';
    }
    return null;
  }

  /// Validate address
  static String? validateAddress(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'L\'adresse est requise';
    }
    if (value.trim().length < 5) {
      return 'L\'adresse doit contenir au moins 5 caractères';
    }
    return null;
  }

  /// Validate minimum length
  static String? minLength(String? value, int min, {String fieldName = 'Ce champ'}) {
    if (value == null || value.length < min) {
      return '$fieldName doit contenir au moins $min caractères';
    }
    return null;
  }

  /// Validate OTP code
  static String? otp(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Le code est requis';
    }
    if (!RegExp(r'^\d{4,6}$').hasMatch(value.trim())) {
      return 'Code invalide (4 à 6 chiffres)';
    }
    return null;
  }
}
