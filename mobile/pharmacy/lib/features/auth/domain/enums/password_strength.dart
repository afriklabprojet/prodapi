import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

/// Niveaux de robustesse du mot de passe.
enum PasswordStrength {
  empty,
  tooShort,
  weak,
  medium,
  strong;

  Color get color => switch (this) {
        PasswordStrength.empty => Colors.grey.shade300,
        PasswordStrength.tooShort => Colors.red.shade400,
        PasswordStrength.weak => Colors.orange.shade400,
        PasswordStrength.medium => Colors.amber.shade600,
        PasswordStrength.strong => AppColors.primary,
      };

  Color get borderColor => switch (this) {
        PasswordStrength.empty => Colors.grey.shade200,
        PasswordStrength.tooShort => Colors.red.shade300,
        PasswordStrength.weak => Colors.orange.shade300,
        PasswordStrength.medium => Colors.amber.shade400,
        PasswordStrength.strong => AppColors.primary,
      };

  String get label => switch (this) {
        PasswordStrength.empty => '',
        PasswordStrength.tooShort => 'Trop court',
        PasswordStrength.weak => 'Faible',
        PasswordStrength.medium => 'Moyen',
        PasswordStrength.strong => 'Fort',
      };

  IconData? get icon => switch (this) {
        PasswordStrength.empty => null,
        PasswordStrength.tooShort => Icons.error_outline,
        PasswordStrength.weak => Icons.warning_amber_rounded,
        PasswordStrength.medium => Icons.info_outline,
        PasswordStrength.strong => Icons.check_circle,
      };

  double get progress => switch (this) {
        PasswordStrength.empty => 0.0,
        PasswordStrength.tooShort => 0.15,
        PasswordStrength.weak => 0.35,
        PasswordStrength.medium => 0.65,
        PasswordStrength.strong => 1.0,
      };

  static const int minLength = 6;

  /// Calcule la force d'un mot de passe.
  static PasswordStrength calculate(String password) {
    if (password.isEmpty) return PasswordStrength.empty;
    if (password.length < minLength) return PasswordStrength.tooShort;

    int score = 0;
    if (password.length >= 8) score++;
    if (password.length >= 12) score++;
    if (RegExp(r'[a-z]').hasMatch(password)) score++;
    if (RegExp(r'[A-Z]').hasMatch(password)) score++;
    if (RegExp(r'[0-9]').hasMatch(password)) score++;
    if (RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password)) score++;

    if (score <= 2) return PasswordStrength.weak;
    if (score <= 4) return PasswordStrength.medium;
    return PasswordStrength.strong;
  }
}
