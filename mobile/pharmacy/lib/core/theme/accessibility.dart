import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Extensions et utilitaires d'accessibilité pour l'app pharmacie
/// Implémente le support du textScaleFactor et des préférences d'accessibilité

/// Extension pour respecter le textScaleFactor avec des limites raisonnables
extension AccessibleTextStyle on TextStyle {
  /// Applique le textScaleFactor avec une limite max pour éviter les débordements
  /// [maxScale] : facteur max (défaut 1.5 = 150% du système)
  TextStyle withAccessibleScaling(
    BuildContext context, {
    double maxScale = 1.5,
  }) {
    final mediaQuery = MediaQuery.of(context);
    final scaleFactor = math.min(mediaQuery.textScaler.scale(1.0), maxScale);
    final baseFontSize = fontSize ?? 14.0;

    return copyWith(fontSize: baseFontSize * scaleFactor);
  }
}

/// Extension sur BuildContext pour accès rapide aux infos d'accessibilité
extension AccessibilityContext on BuildContext {
  /// Retourne le facteur d'échelle du texte (1.0 = normal)
  double get textScaleFactor => MediaQuery.of(this).textScaler.scale(1.0);

  /// Vérifie si l'utilisateur a activé un agrandissement significatif
  bool get isLargeText => textScaleFactor >= 1.3;

  /// Vérifie si l'utilisateur utilise du texte très grand
  bool get isExtraLargeText => textScaleFactor >= 1.5;

  /// Vérifie si les animations doivent être réduites
  bool get reduceMotion => MediaQuery.of(this).disableAnimations;

  /// Vérifie si le contraste élevé est activé
  bool get highContrast => MediaQuery.of(this).highContrast;

  /// Vérifie si le mode sombre est actif
  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;

  /// Taille de police accessible avec limite max
  double accessibleFontSize(double baseSize, {double maxScale = 1.5}) {
    return baseSize * math.min(textScaleFactor, maxScale);
  }
}

/// Widget wrapper pour adapter le layout en fonction de l'accessibilité
class AccessibleLayout extends StatelessWidget {
  final Widget defaultLayout;
  final Widget? largeTextLayout;
  final Widget? extraLargeTextLayout;

  const AccessibleLayout({
    super.key,
    required this.defaultLayout,
    this.largeTextLayout,
    this.extraLargeTextLayout,
  });

  @override
  Widget build(BuildContext context) {
    if (context.isExtraLargeText && extraLargeTextLayout != null) {
      return extraLargeTextLayout!;
    }
    if (context.isLargeText && largeTextLayout != null) {
      return largeTextLayout!;
    }
    return defaultLayout;
  }
}

/// Constantes d'accessibilité
class AccessibilityConstants {
  AccessibilityConstants._();

  /// Taille minimum de touch target recommandée (WCAG 2.5.5)
  static const double minTouchTarget = 48.0;

  /// Taille minimum de touch target sur iOS (Apple HIG)
  static const double minTouchTargetIOS = 44.0;

  /// Espacement minimum entre éléments tactiles
  static const double minTapSpacing = 8.0;

  /// Ratio de contraste minimum (WCAG AA)
  static const double minContrastRatioAA = 4.5;

  /// Ratio de contraste minimum pour texte large (WCAG AA)
  static const double minContrastRatioLargeAA = 3.0;

  /// Ratio de contraste minimum (WCAG AAA)
  static const double minContrastRatioAAA = 7.0;
}

/// Widget qui garantit une taille de touch target minimum
class MinTouchTarget extends StatelessWidget {
  final Widget child;
  final double minSize;
  final AlignmentGeometry alignment;

  const MinTouchTarget({
    super.key,
    required this.child,
    this.minSize = AccessibilityConstants.minTouchTarget,
    this.alignment = Alignment.center,
  });

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(minWidth: minSize, minHeight: minSize),
      child: Align(alignment: alignment, child: child),
    );
  }
}
