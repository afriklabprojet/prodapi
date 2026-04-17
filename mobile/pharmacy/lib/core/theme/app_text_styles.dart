import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Styles de texte centralisés pour l'application.
/// Utilisez les méthodes `of(context)` pour obtenir des styles accessibles
/// qui respectent le textScaleFactor de l'utilisateur.
class AppTextStyles {
  AppTextStyles._();

  // Titres
  static const TextStyle h1 = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    height: 1.3,
  );

  static const TextStyle h2 = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.bold,
    height: 1.3,
  );

  static const TextStyle h3 = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    height: 1.3,
  );

  // Corps de texte
  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    height: 1.5,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    height: 1.5,
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    height: 1.4,
  );

  // Labels
  static const TextStyle label = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.5,
  );

  static const TextStyle labelLarge = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.3,
  );

  // Boutons
  static const TextStyle button = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.5,
  );

  // Caption
  static const TextStyle caption = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.normal,
    color: Colors.grey,
  );

  /// Styles accessibles qui respectent le textScaleFactor
  /// Limite max de 1.5x pour éviter les débordements
  static AppTextStylesAccessible of(
    BuildContext context, {
    double maxScale = 1.5,
  }) {
    return AppTextStylesAccessible._(context, maxScale);
  }
}

/// Version accessible des styles de texte
/// Applique automatiquement le textScaleFactor avec une limite max
class AppTextStylesAccessible {
  final BuildContext _context;
  final double _maxScale;

  AppTextStylesAccessible._(this._context, this._maxScale);

  double get _scaleFactor {
    final mediaQuery = MediaQuery.of(_context);
    return math.min(mediaQuery.textScaler.scale(1.0), _maxScale);
  }

  TextStyle _scale(TextStyle base) {
    final baseFontSize = base.fontSize ?? 14.0;
    return base.copyWith(fontSize: baseFontSize * _scaleFactor);
  }

  TextStyle get h1 => _scale(AppTextStyles.h1);
  TextStyle get h2 => _scale(AppTextStyles.h2);
  TextStyle get h3 => _scale(AppTextStyles.h3);
  TextStyle get bodyLarge => _scale(AppTextStyles.bodyLarge);
  TextStyle get bodyMedium => _scale(AppTextStyles.bodyMedium);
  TextStyle get bodySmall => _scale(AppTextStyles.bodySmall);
  TextStyle get label => _scale(AppTextStyles.label);
  TextStyle get labelLarge => _scale(AppTextStyles.labelLarge);
  TextStyle get button => _scale(AppTextStyles.button);
  TextStyle get caption => _scale(AppTextStyles.caption);
}
