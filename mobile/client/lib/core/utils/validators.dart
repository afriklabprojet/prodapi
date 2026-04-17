/// Validateurs utilitaires
class Validators {
  Validators._();

  /// Valide un email
  static bool isValidEmail(String email) {
    return RegExp(r'^[\w\-\.+]+@([\w\-]+\.)+[\w\-]{2,}$').hasMatch(email);
  }

  /// Valide un numéro de téléphone ivoirien
  static bool isValidPhone(String phone) {
    final cleaned = phone.replaceAll(RegExp(r'[\s\-\.\(\)]'), '');
    // +225XXXXXXXXXX or 0XXXXXXXXX
    return RegExp(r'^(\+225)?0?\d{9,10}$').hasMatch(cleaned);
  }

  /// Valide la force du mot de passe
  static bool isStrongPassword(String password) {
    return password.length >= 8;
  }

  /// Valide un code OTP (4 à 6 chiffres)
  static bool isValidOtp(String otp) {
    return RegExp(r'^\d{4,6}$').hasMatch(otp);
  }
}
