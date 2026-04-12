import 'package:flutter/animation.dart';

/// Constantes d'animation partagées dans l'application.
///
/// Centralise les durées, courbes et délais pour garantir la cohérence
/// et faciliter les ajustements globaux.
abstract final class AnimationConstants {
  // ── Durées ──────────────────────────────────────────────────────────────

  /// Transition rapide (feedback de tap, micro-interaction).
  static const Duration fast = Duration(milliseconds: 100);

  /// Transition standard (changement d'état UI).
  static const Duration standard = Duration(milliseconds: 200);

  /// Transition moyenne (ouverture de panel, slide).
  static const Duration medium = Duration(milliseconds: 300);

  /// Transition d'entrée de page.
  static const Duration pageEnter = Duration(milliseconds: 250);

  /// Transition de sortie de page.
  static const Duration pageExit = Duration(milliseconds: 200);

  /// Durée d'affichage du feedback (succès/erreur dans un bouton).
  static const Duration feedbackDisplay = Duration(milliseconds: 1200);

  /// Durée de l'animation d'entrée (login, onboarding).
  static const Duration entranceAnimation = Duration(milliseconds: 1000);

  // ── Courbes ─────────────────────────────────────────────────────────────

  /// Courbe standard pour les éléments qui apparaissent.
  static final Curve enterCurve = Curves.easeOutCubic;

  /// Courbe pour les animations de rebond (logo, badge).
  static final Curve bounceCurve = Curves.easeOutBack;

  /// Courbe standard pour les disparitions.
  static final Curve exitCurve = Curves.easeIn;
}

/// Constantes d'espacement et de dimension UI.
abstract final class UIConstants {
  // ── Touch targets (Material 3 / HIG) ────────────────────────────────────

  /// Taille minimum d'une zone tactile (Material 3 = 48dp).
  static const double minTouchTarget = 48.0;

  /// Taille minimum d'une zone tactile iOS (HIG = 44pt).
  static const double minTouchTargetIOS = 44.0;

  /// Hauteur d'un bouton plein (CTA principal).
  static const double buttonHeight = 56.0;

  /// Rayon de bordure d'un bouton standard.
  static const double buttonRadius = 16.0;

  // ── Spacings ────────────────────────────────────────────────────────────

  /// Espacement minimal entre éléments interactifs.
  static const double spacingXS = 4.0;

  /// Petit espacement.
  static const double spacingSM = 8.0;

  /// Espacement standard.
  static const double spacingMD = 12.0;

  /// Espacement moyen.
  static const double spacingLG = 16.0;

  /// Grand espacement.
  static const double spacingXL = 24.0;

  /// Très grand espacement (entre sections).
  static const double spacingXXL = 32.0;

  // ── Paddings de page ────────────────────────────────────────────────────

  /// Padding horizontal standard d'une page.
  static const double pageHorizontalPadding = 20.0;

  /// Padding vertical standard d'une page.
  static const double pageVerticalPadding = 16.0;

  // ── Scroll ──────────────────────────────────────────────────────────────

  /// Seuil de pixels avant la fin de la liste pour déclencher le chargement.
  static const double infiniteScrollThreshold = 200.0;

  // ── Limites ─────────────────────────────────────────────────────────────

  /// Nombre max de scans récents conservés.
  static const int maxRecentScans = 10;
}
