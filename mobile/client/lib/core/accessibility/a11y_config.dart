import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

/// Configuration d'accessibilité pour l'application DR-PHARMA
/// Gère les paramètres d'accessibilité comme le scaling du texte,
/// les contrastes élevés et les animations réduites
class A11yConfig {
  A11yConfig._();

  /// Taille de texte minimale pour la lisibilité
  static const double minTextScaleFactor = 0.8;

  /// Taille de texte maximale supportée
  static const double maxTextScaleFactor = 2.0;

  /// Taille de cible tactile minimale (recommandation WCAG)
  static const double minTapTargetSize = 48.0;

  /// Espacement minimum entre les éléments interactifs
  static const double minInteractiveSpacing = 8.0;

  /// Durée minimale d'affichage des messages (snackbars, toasts)
  static const Duration minMessageDuration = Duration(seconds: 4);

  /// Vérifier si les animations réduites sont activées
  static bool shouldReduceMotion(BuildContext context) {
    return MediaQuery.of(context).disableAnimations;
  }

  /// Vérifier si le mode contraste élevé est activé
  static bool isHighContrast(BuildContext context) {
    return MediaQuery.of(context).highContrast;
  }

  /// Vérifier si le texte en gras est activé
  static bool isBoldTextEnabled(BuildContext context) {
    return MediaQuery.of(context).boldText;
  }

  /// Obtenir le facteur d'échelle du texte (clampé aux limites)
  static double getTextScaleFactor(BuildContext context) {
    final factor = MediaQuery.of(context).textScaler.scale(1.0);
    return factor.clamp(minTextScaleFactor, maxTextScaleFactor);
  }

  /// Vérifier si l'utilisateur préfère les sous-titres
  static bool prefersClosedCaptions(BuildContext context) {
    return MediaQuery.of(context).accessibleNavigation;
  }

  /// Obtenir la durée d'animation appropriée
  static Duration getAnimationDuration(BuildContext context, Duration normal) {
    if (shouldReduceMotion(context)) {
      return Duration.zero;
    }
    return normal;
  }

  /// Obtenir la durée d'affichage des messages
  static Duration getMessageDuration(BuildContext context) {
    // Plus long si l'utilisateur utilise un lecteur d'écran
    if (MediaQuery.of(context).accessibleNavigation) {
      return const Duration(seconds: 8);
    }
    return minMessageDuration;
  }
}

/// Thème d'accessibilité avec contrastes améliorés
class A11yTheme {
  A11yTheme._();

  /// Couleurs avec contraste élevé pour le mode accessibilité
  static const Color highContrastPrimary = Color(0xFF005829);
  static const Color highContrastOnPrimary = Colors.white;
  static const Color highContrastError = Color(0xFFB00020);
  static const Color highContrastOnError = Colors.white;
  static const Color highContrastBackground = Colors.white;
  static const Color highContrastOnBackground = Colors.black;
  static const Color highContrastSurface = Color(0xFFF5F5F5);
  static const Color highContrastOnSurface = Colors.black;

  /// Obtenir le thème adapté à l'accessibilité
  static ThemeData getAccessibleTheme(
    BuildContext context,
    ThemeData baseTheme,
  ) {
    if (!A11yConfig.isHighContrast(context)) {
      return baseTheme;
    }

    return baseTheme.copyWith(
      colorScheme: baseTheme.colorScheme.copyWith(
        primary: highContrastPrimary,
        onPrimary: highContrastOnPrimary,
        error: highContrastError,
        onError: highContrastOnError,
        surface: highContrastSurface,
        onSurface: highContrastOnSurface,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(
            A11yConfig.minTapTargetSize,
            A11yConfig.minTapTargetSize,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(
            A11yConfig.minTapTargetSize,
            A11yConfig.minTapTargetSize,
          ),
          side: const BorderSide(width: 2, color: highContrastPrimary),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(
            A11yConfig.minTapTargetSize,
            A11yConfig.minTapTargetSize,
          ),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          minimumSize: const Size(
            A11yConfig.minTapTargetSize,
            A11yConfig.minTapTargetSize,
          ),
        ),
      ),
    );
  }
}

/// Helper pour annoncer des changements aux lecteurs d'écran
class A11yAnnouncer {
  A11yAnnouncer._();

  /// Annonce un message de manière polie (attend la fin du message en cours)
  static void announcePolitely(BuildContext context, String message) {
    // ignore: deprecated_member_use
    SemanticsService.announce(message, TextDirection.ltr);
  }

  /// Annonce un message de manière assertive (interrompt le message en cours)
  static void announceAssertively(BuildContext context, String message) {
    // ignore: deprecated_member_use
    SemanticsService.announce(
      message,
      TextDirection.ltr,
      assertiveness: Assertiveness.assertive,
    );
  }

  /// Annonce le résultat d'une action
  static void announceResult(
    BuildContext context,
    bool success, {
    String? customMessage,
  }) {
    final message =
        customMessage ??
        (success ? 'Opération réussie' : 'Échec de l\'opération');
    announcePolitely(context, message);
  }

  /// Annonce un changement de page
  static void announcePage(BuildContext context, String pageName) {
    announcePolitely(context, 'Page $pageName');
  }

  /// Annonce le chargement
  static void announceLoading(BuildContext context, [String? item]) {
    final message = item != null
        ? 'Chargement de $item en cours'
        : 'Chargement en cours';
    announcePolitely(context, message);
  }

  /// Annonce une erreur
  static void announceError(BuildContext context, String error) {
    announceAssertively(context, 'Erreur: $error');
  }
}
