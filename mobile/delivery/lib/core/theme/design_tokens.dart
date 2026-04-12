import 'package:flutter/material.dart';

/// Design tokens centralisés pour l'application DR-PHARMA.
///
/// Utilisez ces constantes pour maintenir la cohérence visuelle
/// entre tous les écrans de l'application.
abstract final class DesignTokens {
  // ============================================================
  // COULEURS - Marque
  // ============================================================

  /// Vert principal DR-PHARMA (utilisé partout : boutons, liens, accents)
  static const Color primary = Color(0xFF0D6644);

  /// Vert principal clair (pour backgrounds, hover states)
  static const Color primaryLight = Color(0xFF54AB70);

  /// Vert foncé (pour gradients, headers)
  static const Color primaryDark = Color(0xFF0A5236);

  // ============================================================
  // COULEURS - Texte (Light Mode)
  // ============================================================

  /// Texte principal (titres, labels importants)
  static const Color textDark = Color(0xFF0F1F18);

  /// Texte secondaire (descriptions, placeholders)
  static const Color textMuted = Color(0xFF8A9E96);

  /// Labels de champs
  static const Color labelColor = Color(0xFF4A6358);

  /// Icônes dans les champs
  static const Color iconColor = Color(0xFF9BB8AC);

  // ============================================================
  // COULEURS - Texte (Dark Mode)
  // ============================================================

  /// Texte principal dark mode
  static const Color textDarkMode = Color(0xFFFFFFFF);

  /// Texte secondaire dark mode
  static const Color textMutedDarkMode = Color(0xFFB0BEC5);

  /// Labels dark mode
  static const Color labelColorDarkMode = Color(0xFFCFD8DC);

  /// Icônes dark mode
  static const Color iconColorDarkMode = Color(0xFF90A4AE);

  // ============================================================
  // COULEURS - Surfaces (Light Mode)
  // ============================================================

  /// Fond de page
  static const Color backgroundLight = Color(0xFFF7FBF9);

  /// Fond des champs de saisie
  static const Color fieldBgLight = Color(0xFFF7FBF9);

  /// Bordure des champs
  static const Color fieldBorderLight = Color(0xFFDDE6E1);

  /// Fond des segments/tabs
  static const Color segmentBgLight = Color(0xFFF2F5F3);

  /// Fond des cartes
  static const Color cardBgLight = Colors.white;

  // ============================================================
  // COULEURS - Surfaces (Dark Mode)
  // ============================================================

  /// Fond de page dark mode
  static const Color backgroundDark = Color(0xFF0D1B2A);

  /// Fond des champs dark mode
  static const Color fieldBgDark = Color(0xFF1A2A3A);

  /// Bordure des champs dark mode
  static const Color fieldBorderDark = Color(0xFF2D3E4E);

  /// Fond des segments dark mode
  static const Color segmentBgDark = Color(0xFF1A2A3A);

  /// Fond des cartes dark mode
  static const Color cardBgDark = Color(0xFF152030);

  // ============================================================
  // COULEURS - États
  // ============================================================

  /// Succès
  static const Color success = Color(0xFF4CAF50);

  /// Erreur
  static const Color error = Color(0xFFE53935);

  /// Avertissement
  static const Color warning = Color(0xFFFF9800);

  /// Information
  static const Color info = Color(0xFF2196F3);

  // ============================================================
  // ESPACEMENTS
  // ============================================================

  /// Espacement extra small (4px)
  static const double spaceXs = 4.0;

  /// Espacement small (8px)
  static const double spaceSm = 8.0;

  /// Espacement medium (16px)
  static const double spaceMd = 16.0;

  /// Espacement large (24px)
  static const double spaceLg = 24.0;

  /// Espacement extra large (32px)
  static const double spaceXl = 32.0;

  /// Espacement 2x large (48px)
  static const double space2xl = 48.0;

  // ============================================================
  // RAYONS DE BORDURE
  // ============================================================

  /// Rayon small (8px) — chips, badges
  static const double radiusSm = 8.0;

  /// Rayon medium (12px) — boutons, champs
  static const double radiusMd = 12.0;

  /// Rayon large (16px) — cartes, modals
  static const double radiusLg = 16.0;

  /// Rayon extra large (24px) — bottom sheets
  static const double radiusXl = 24.0;

  /// Rayon circulaire
  static const double radiusFull = 999.0;

  // ============================================================
  // TAILLES DE TEXTE
  // ============================================================

  /// Caption (11px)
  static const double fontSizeCaption = 11.0;

  /// Small (13px)
  static const double fontSizeSm = 13.0;

  /// Body (15px)
  static const double fontSizeBody = 15.0;

  /// Subtitle (16px)
  static const double fontSizeSubtitle = 16.0;

  /// Title (20px)
  static const double fontSizeTitle = 20.0;

  /// Headline (26px)
  static const double fontSizeHeadline = 26.0;

  // ============================================================
  // HAUTEURS DE COMPOSANTS
  // ============================================================

  /// Hauteur des boutons standard
  static const double buttonHeight = 56.0;

  /// Hauteur des boutons secondaires
  static const double buttonHeightSmall = 50.0;

  /// Hauteur des champs de saisie
  static const double fieldHeight = 56.0;

  /// Hauteur des icônes dans les champs
  static const double fieldIconSize = 20.0;

  // ============================================================
  // OMBRES
  // ============================================================

  /// Ombre légère pour les cartes
  static List<BoxShadow> get shadowLight => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.04),
          blurRadius: 6,
          offset: const Offset(0, 2),
        ),
      ];

  /// Ombre moyenne pour les modals
  static List<BoxShadow> get shadowMedium => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.08),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ];

  /// Ombre forte pour les bottom sheets
  static List<BoxShadow> get shadowStrong => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.12),
          blurRadius: 20,
          offset: const Offset(0, -4),
        ),
      ];
}

/// Extension pour accéder aux tokens adaptés au thème depuis le BuildContext.
extension DesignTokensExtension on BuildContext {
  bool get _isDark => Theme.of(this).brightness == Brightness.dark;

  // Texte
  Color get tokenTextPrimary =>
      _isDark ? DesignTokens.textDarkMode : DesignTokens.textDark;
  Color get tokenTextMuted =>
      _isDark ? DesignTokens.textMutedDarkMode : DesignTokens.textMuted;
  Color get tokenLabelColor =>
      _isDark ? DesignTokens.labelColorDarkMode : DesignTokens.labelColor;
  Color get tokenIconColor =>
      _isDark ? DesignTokens.iconColorDarkMode : DesignTokens.iconColor;

  // Surfaces
  Color get tokenBackground =>
      _isDark ? DesignTokens.backgroundDark : DesignTokens.backgroundLight;
  Color get tokenFieldBg =>
      _isDark ? DesignTokens.fieldBgDark : DesignTokens.fieldBgLight;
  Color get tokenFieldBorder =>
      _isDark ? DesignTokens.fieldBorderDark : DesignTokens.fieldBorderLight;
  Color get tokenSegmentBg =>
      _isDark ? DesignTokens.segmentBgDark : DesignTokens.segmentBgLight;
  Color get tokenCardBg =>
      _isDark ? DesignTokens.cardBgDark : DesignTokens.cardBgLight;
}
