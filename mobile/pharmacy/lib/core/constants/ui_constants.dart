import 'package:flutter/widgets.dart';

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
/// 
/// ## Guide d'utilisation des spacings :
/// - **spacingXS (4)** : Entre icône et texte, entre badges
/// - **spacingSM (8)** : Entre éléments de même groupe, gap de chips
/// - **spacingMD (12)** : Entre lignes de texte, padding de chips
/// - **spacingLG (16)** : Entre sections dans une carte, padding de cartes
/// - **spacingXL (24)** : Entre cartes, après titres de section
/// - **spacingXXL (32)** : Entre sections majeures, avant/après headers
/// 
/// ## Règle des 4dp :
/// Tous les espacements sont des multiples de 4dp pour garantir
/// un rythme visuel cohérent (4, 8, 12, 16, 24, 32).
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

  // ── Spacings (basés sur une grille de 4dp) ──────────────────────────────

  /// 4dp - Espacement minimal (icône-texte, badges adjacents).
  static const double spacingXS = 4.0;

  /// 8dp - Petit espacement (éléments du même groupe).
  static const double spacingSM = 8.0;

  /// 12dp - Espacement standard (lignes de texte, padding de chips).
  static const double spacingMD = 12.0;

  /// 16dp - Espacement moyen (sections dans carte, padding cartes).
  static const double spacingLG = 16.0;

  /// 24dp - Grand espacement (entre cartes, après titres).
  static const double spacingXL = 24.0;

  /// 32dp - Très grand espacement (sections majeures, headers).
  static const double spacingXXL = 32.0;

  // ── Paddings de page ────────────────────────────────────────────────────

  /// Padding horizontal standard d'une page.
  static const double pageHorizontalPadding = 20.0;

  /// Padding vertical standard d'une page.
  static const double pageVerticalPadding = 16.0;

  // ── EdgeInsets pré-définis ──────────────────────────────────────────────

  /// Padding de page standard.
  static const EdgeInsets pagePadding = EdgeInsets.symmetric(
    horizontal: pageHorizontalPadding,
    vertical: pageVerticalPadding,
  );

  /// Padding de carte standard.
  static const EdgeInsets cardPadding = EdgeInsets.all(spacingLG);

  /// Padding de bottom sheet.
  static const EdgeInsets sheetPadding = EdgeInsets.all(spacingXL);

  /// Padding dense pour les chips/badges.
  static const EdgeInsets chipPadding = EdgeInsets.symmetric(
    horizontal: spacingMD,
    vertical: spacingSM,
  );

  /// Margin entre cartes dans une liste.
  static const EdgeInsets cardMargin = EdgeInsets.only(bottom: spacingMD);

  /// Padding d'item de liste.
  static const EdgeInsets listItemPadding = EdgeInsets.symmetric(
    horizontal: pageHorizontalPadding,
    vertical: spacingMD,
  );

  // ── Border Radius ───────────────────────────────────────────────────────

  /// Radius de carte standard.
  static const double cardRadius = 16.0;

  /// Radius de chip/badge.
  static const double chipRadius = 8.0;

  /// Radius de bouton.
  static const double radiusButton = 16.0;

  /// Radius de bottom sheet.
  static const double sheetRadius = 24.0;

  // ── Scroll ──────────────────────────────────────────────────────────────

  /// Seuil de pixels avant la fin de la liste pour déclencher le chargement.
  static const double infiniteScrollThreshold = 200.0;

  // ── Limites ─────────────────────────────────────────────────────────────

  /// Nombre max de scans récents conservés.
  static const int maxRecentScans = 10;

  // ── Icon Sizes ──────────────────────────────────────────────────────────

  /// Taille d'icône petite (badges, indicateurs).
  static const double iconSM = 16.0;

  /// Taille d'icône standard (boutons, listes).
  static const double iconMD = 20.0;

  /// Taille d'icône grande (actions principales).
  static const double iconLG = 24.0;

  /// Taille d'icône très grande (empty states).
  static const double iconXL = 48.0;
}
