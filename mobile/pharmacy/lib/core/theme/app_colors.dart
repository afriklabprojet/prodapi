import 'package:flutter/material.dart';

class AppColors {
  // Private constructor to prevent instantiation
  AppColors._();

  // Primary Palette
  static const Color primary = Color(0xFF2E7D32); // Medical Green
  static const Color primaryLight = Color(0xFFE8F5E9); // Light Green bg
  static const Color primaryDark = Color(0xFF1B5E20);

  // Secondary Palette
  static const Color secondary = Color(0xFF5C6BC0); // Soft Indigo
  static const Color secondaryLight = Color(0xFFE8EAF6);
  static const Color accent = Color(0xFF26A69A); // Teal

  // Status Colors
  static const Color success = Color(0xFF43A047);
  static const Color error = Color(0xFFE53935);
  static const Color warning = Color(0xFFFFA000);
  static const Color info = Color(0xFF1565C0); // Blue 800 - WCAG AA compliant (4.5:1+)
  static const Color urgent = Color(0xFFD32F2F);

  // Status Backgrounds (Soft)
  static const Color successBg = Color(0xFFF1F8E9); // Very light green
  static const Color errorBg = Color(0xFFFFEBEE); // Very light red
  static const Color warningBg = Color(0xFFFFF8E1); // Very light amber
  static const Color infoBg = Color(0xFFE3F2FD); // Very light blue

  // Neutral / Foundation
  static const Color background = Color(0xFFF8F9FA);
  static const Color surface = Colors.white;
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textDisabled = Color(0xFFBDBDBD);
  static const Color divider = Color(0xFFEEEEEE);
  static const Color border = Color(0xFFE0E0E0);

  // Shadows
  static Color shadow = const Color(0xFF8D8D8D).withValues(alpha: 0.08);

  // Dark Theme Colors
  static const Color darkBackground = Color(0xFF121212);
  static const Color darkSurface = Color(0xFF1E1E1E);
  static const Color darkCard = Color(0xFF2C2C2C);
  static const Color darkTextPrimary = Color(0xFFFFFFFF);
  static const Color darkTextSecondary = Color(0xFFB3B3B3);
  static const Color darkDivider = Color(0xFF3D3D3D);
  static const Color darkBorder = Color(0xFF4D4D4D);

  // ==================== ADAPTIVE COLORS ====================

  /// Couleur de fond de carte adaptative (light/dark)
  static Color cardColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? darkCard
        : Colors.white;
  }

  /// Couleur de fond de page adaptative
  static Color backgroundColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? darkBackground
        : background;
  }

  /// Couleur de surface adaptative
  static Color surfaceColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? darkSurface
        : surface;
  }

  /// Couleur de texte principale adaptative
  static Color textColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? darkTextPrimary
        : textPrimary;
  }

  /// Couleur de texte secondaire adaptative
  static Color textSecondaryColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? darkTextSecondary
        : textSecondary;
  }

  /// Couleur de texte légère (pour hints, placeholders)
  static Color textLightColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? Colors.grey.shade500
        : Colors.grey.shade600;
  }

  /// Couleur de bordure adaptative
  static Color borderColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? darkBorder
        : border;
  }

  /// Couleur de diviseur adaptative
  static Color dividerColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? darkDivider
        : divider;
  }

  /// Couleur de fond d'input adaptative
  static Color inputFillColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? darkCard
        : Colors.grey.shade100;
  }

  /// Couleur de fond hover/pressed adaptative
  static Color hoverColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? Colors.white.withValues(alpha: 0.05)
        : Colors.black.withValues(alpha: 0.05);
  }

  /// Vérifie si le mode sombre est actif
  static bool isDark(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark;
  }

  // ==================== MATERIAL 3 COLORSCHEME HELPERS ====================

  /// Accès rapide au ColorScheme du thème actuel
  static ColorScheme colorScheme(BuildContext context) {
    return Theme.of(context).colorScheme;
  }

  /// Couleur primaire du thème (préférer à AppColors.primary)
  static Color primaryColor(BuildContext context) {
    return Theme.of(context).colorScheme.primary;
  }

  /// Couleur primaire container (pour fonds colorés)
  static Color primaryContainerColor(BuildContext context) {
    return Theme.of(context).colorScheme.primaryContainer;
  }

  /// Couleur de surface du thème (cartes, dialogs)
  static Color surfaceTheme(BuildContext context) {
    return Theme.of(context).colorScheme.surface;
  }

  /// Couleur de surface container (variante de surface)
  static Color surfaceContainer(BuildContext context) {
    return Theme.of(context).colorScheme.surfaceContainerHighest;
  }

  /// Couleur d'erreur du thème
  static Color errorColor(BuildContext context) {
    return Theme.of(context).colorScheme.error;
  }

  /// Couleur outline (bordures)
  static Color outlineColor(BuildContext context) {
    return Theme.of(context).colorScheme.outline;
  }

  /// Couleur outline variante (bordures subtiles)
  static Color outlineVariantColor(BuildContext context) {
    return Theme.of(context).colorScheme.outlineVariant;
  }

  /// Texte sur surface
  static Color onSurface(BuildContext context) {
    return Theme.of(context).colorScheme.onSurface;
  }

  /// Texte sur surface (variante, pour texte secondaire)
  static Color onSurfaceVariant(BuildContext context) {
    return Theme.of(context).colorScheme.onSurfaceVariant;
  }
}
