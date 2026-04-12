import 'package:flutter/material.dart';

/// Couleurs de l'application centralisées.
///
/// Utiliser ces constantes au lieu de hardcoder les couleurs directement.
/// Exemple:
/// ```dart
/// color: context.isDark ? AppColors.darkBackground : AppColors.lightBackground,
/// ```
abstract final class AppColors {
  // === Arrière-plans ===
  /// Fond principal en mode clair
  static const lightBackground = Color(0xFFF8F9FD);

  /// Fond principal en mode sombre
  static const darkBackground = Color(0xFF121212);

  /// Fond des cartes en mode clair
  static const lightCard = Colors.white;

  /// Fond des cartes en mode sombre
  static const darkCard = Color(0xFF1E1E1E);

  /// Fond secondaire en mode sombre
  static const darkSurface = Color(0xFF2A2A2A);

  /// Fond tertiaire en mode sombre
  static const darkSurfaceVariant = Color(0xFF2C2C2C);

  // === Couleurs de la marque ===
  /// Vert principal Dr Pharma
  static const brandPrimary = Color(0xFF54AB70);

  /// Vert foncé (pour les gradients)
  static const brandPrimaryDark = Color(0xFF3D8C57);

  /// Vert accent (boutons, CTA)
  static const brandAccent = Color(0xFF2E7D32);

  /// Vert très foncé (gradients, headers)
  static const brandDark = Color(0xFF1B5E20);

  /// Vert moyen (variations)
  static const brandMedium = Color(0xFF43A047);

  // === Statuts ===
  /// Succès
  static const success = Color(0xFF4CAF50);

  /// Erreur
  static const error = Color(0xFFE53935);

  /// Avertissement
  static const warning = Color(0xFFFF9800);

  /// Information
  static const info = Color(0xFF2196F3);

  // === Texte ===
  /// Texte principal (dark mode)
  static const textDark = Colors.white;

  /// Texte secondaire (dark mode)
  static const textDarkSecondary = Color(0xB3FFFFFF); // white70

  /// Texte principal (light mode)
  static const textLight = Color(0xFF212121);

  /// Texte secondaire (light mode)
  static const textLightSecondary = Color(0xFF757575);

  // === Élégance ===
  /// Fond élégant sombre
  static const elegantDark = Color(0xFF2C3E50);

  // === Helpers ===
  /// Obtient la couleur d'arrière-plan selon le mode
  static Color background(bool isDark) =>
      isDark ? darkBackground : lightBackground;

  /// Obtient la couleur de carte selon le mode
  static Color card(bool isDark) => isDark ? darkCard : lightCard;

  /// Obtient la couleur de surface selon le mode
  static Color surface(bool isDark) =>
      isDark ? darkSurface : Colors.grey.shade50;
}

/// Extension pour accéder aux couleurs depuis le BuildContext
extension AppColorsExtension on BuildContext {
  /// Vérifie si le thème courant est sombre (version privée pour éviter le conflit)
  bool get _isDarkMode => Theme.of(this).brightness == Brightness.dark;

  /// Couleur d'arrière-plan adaptée au thème
  Color get appBackground =>
      _isDarkMode ? AppColors.darkBackground : AppColors.lightBackground;

  /// Couleur de carte adaptée au thème
  Color get appCard => _isDarkMode ? AppColors.darkCard : AppColors.lightCard;

  /// Couleur de surface adaptée au thème
  Color get appSurface =>
      _isDarkMode ? AppColors.darkSurface : Colors.grey.shade50;

  /// Couleur de texte principal adaptée au thème
  Color get appTextPrimary =>
      _isDarkMode ? AppColors.textDark : AppColors.textLight;

  /// Couleur de texte secondaire adaptée au thème
  Color get appTextSecondary =>
      _isDarkMode ? AppColors.textDarkSecondary : AppColors.textLightSecondary;
}
