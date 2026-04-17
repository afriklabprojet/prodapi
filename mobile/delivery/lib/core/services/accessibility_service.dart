import 'dart:math' as std;
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service d'accessibilité
/// =======================

/// État des paramètres d'accessibilité
class AccessibilityState {
  final bool highContrast;
  final bool largeText;
  final bool reduceMotion;
  final bool screenReaderEnabled;
  final double textScaleFactor;
  final bool boldText;
  final bool invertColors;

  const AccessibilityState({
    this.highContrast = false,
    this.largeText = false,
    this.reduceMotion = false,
    this.screenReaderEnabled = false,
    this.textScaleFactor = 1.0,
    this.boldText = false,
    this.invertColors = false,
  });

  AccessibilityState copyWith({
    bool? highContrast,
    bool? largeText,
    bool? reduceMotion,
    bool? screenReaderEnabled,
    double? textScaleFactor,
    bool? boldText,
    bool? invertColors,
  }) {
    return AccessibilityState(
      highContrast: highContrast ?? this.highContrast,
      largeText: largeText ?? this.largeText,
      reduceMotion: reduceMotion ?? this.reduceMotion,
      screenReaderEnabled: screenReaderEnabled ?? this.screenReaderEnabled,
      textScaleFactor: textScaleFactor ?? this.textScaleFactor,
      boldText: boldText ?? this.boldText,
      invertColors: invertColors ?? this.invertColors,
    );
  }
}

/// Notifier pour l'accessibilité
class AccessibilityNotifier extends Notifier<AccessibilityState> {
  static const _keyHighContrast = 'accessibility_high_contrast';
  static const _keyLargeText = 'accessibility_large_text';
  static const _keyReduceMotion = 'accessibility_reduce_motion';
  static const _keyTextScale = 'accessibility_text_scale';
  static const _keyBoldText = 'accessibility_bold_text';

  @override
  AccessibilityState build() {
    _loadSettings();
    return const AccessibilityState();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    state = AccessibilityState(
      highContrast: prefs.getBool(_keyHighContrast) ?? false,
      largeText: prefs.getBool(_keyLargeText) ?? false,
      reduceMotion: prefs.getBool(_keyReduceMotion) ?? false,
      textScaleFactor: prefs.getDouble(_keyTextScale) ?? 1.0,
      boldText: prefs.getBool(_keyBoldText) ?? false,
    );
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyHighContrast, state.highContrast);
    await prefs.setBool(_keyLargeText, state.largeText);
    await prefs.setBool(_keyReduceMotion, state.reduceMotion);
    await prefs.setDouble(_keyTextScale, state.textScaleFactor);
    await prefs.setBool(_keyBoldText, state.boldText);
  }

  Future<void> setHighContrast(bool enabled) async {
    state = state.copyWith(highContrast: enabled);
    await _saveSettings();
  }

  Future<void> setLargeText(bool enabled) async {
    state = state.copyWith(
      largeText: enabled,
      textScaleFactor: enabled ? 1.3 : 1.0,
    );
    await _saveSettings();
  }

  Future<void> setReduceMotion(bool enabled) async {
    state = state.copyWith(reduceMotion: enabled);
    await _saveSettings();
  }

  Future<void> setTextScaleFactor(double scale) async {
    state = state.copyWith(textScaleFactor: scale.clamp(0.8, 2.0));
    await _saveSettings();
  }

  Future<void> setBoldText(bool enabled) async {
    state = state.copyWith(boldText: enabled);
    await _saveSettings();
  }

  void updateScreenReaderStatus(bool enabled) {
    state = state.copyWith(screenReaderEnabled: enabled);
  }
}

/// Provider pour l'accessibilité
final accessibilityProvider =
    NotifierProvider<AccessibilityNotifier, AccessibilityState>(
  AccessibilityNotifier.new,
);

/// Provider pour savoir si les animations sont réduites
final reduceMotionProvider = Provider<bool>((ref) {
  return ref.watch(accessibilityProvider).reduceMotion;
});

/// Provider pour le facteur d'échelle du texte
final textScaleProvider = Provider<double>((ref) {
  return ref.watch(accessibilityProvider).textScaleFactor;
});

/// Thème haute contraste
class HighContrastTheme {
  static ThemeData light() {
    return ThemeData(
      brightness: Brightness.light,
      primaryColor: Colors.black,
      scaffoldBackgroundColor: Colors.white,
      colorScheme: const ColorScheme.light(
        primary: Colors.black,
        onPrimary: Colors.white,
        secondary: Color(0xFF0055FF),
        onSecondary: Colors.white,
        surface: Colors.white,
        onSurface: Colors.black,
        error: Color(0xFFCC0000),
        onError: Colors.white,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: Colors.black, width: 2),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.black,
          side: const BorderSide(color: Colors.black, width: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.black, width: 2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF0055FF), width: 3),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: Colors.black,
        thickness: 2,
      ),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: Colors.black, fontWeight: FontWeight.w500),
        bodyMedium: TextStyle(color: Colors.black, fontWeight: FontWeight.w500),
        titleLarge: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
      ),
    );
  }

  static ThemeData dark() {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: Colors.white,
      scaffoldBackgroundColor: Colors.black,
      colorScheme: const ColorScheme.dark(
        primary: Colors.white,
        onPrimary: Colors.black,
        secondary: Color(0xFF66B3FF),
        onSecondary: Colors.black,
        surface: Colors.black,
        onSurface: Colors.white,
        error: Color(0xFFFF6666),
        onError: Colors.black,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        color: Colors.black,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: Colors.white, width: 2),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.white,
          side: const BorderSide(color: Colors.white, width: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.white, width: 2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF66B3FF), width: 3),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: Colors.white,
        thickness: 2,
      ),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
        bodyMedium: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
        titleLarge: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
    );
  }
}

/// Widget avec sémantique améliorée pour les boutons
class AccessibleButton extends StatelessWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final String semanticLabel;
  final String? semanticHint;
  final bool isEnabled;

  const AccessibleButton({
    super.key,
    required this.child,
    required this.onPressed,
    required this.semanticLabel,
    this.semanticHint,
    this.isEnabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: isEnabled && onPressed != null,
      label: semanticLabel,
      hint: semanticHint,
      onTap: onPressed,
      child: MergeSemantics(
        child: ExcludeSemantics(
          child: child,
        ),
      ),
    );
  }
}

/// Widget avec focus visible pour les champs de saisie
class AccessibleTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String label;
  final String? hint;
  final String? errorText;
  final bool obscureText;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onChanged;
  final String? semanticLabel;

  const AccessibleTextField({
    super.key,
    this.controller,
    required this.label,
    this.hint,
    this.errorText,
    this.obscureText = false,
    this.keyboardType,
    this.onChanged,
    this.semanticLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      textField: true,
      label: semanticLabel ?? label,
      hint: hint,
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        onChanged: onChanged,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          errorText: errorText,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }
}

/// Widget de carte accessible
class AccessibleCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final String semanticLabel;
  final String? semanticHint;

  const AccessibleCard({
    super.key,
    required this.child,
    this.onTap,
    required this.semanticLabel,
    this.semanticHint,
  });

  @override
  Widget build(BuildContext context) {
    final card = Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: child,
      ),
    );

    return Semantics(
      container: true,
      label: semanticLabel,
      hint: semanticHint,
      button: onTap != null,
      child: card,
    );
  }
}

/// Widget d'image accessible
class AccessibleImage extends StatelessWidget {
  final ImageProvider image;
  final String semanticLabel;
  final double? width;
  final double? height;
  final BoxFit fit;
  final bool excludeFromSemantics;

  const AccessibleImage({
    super.key,
    required this.image,
    required this.semanticLabel,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.excludeFromSemantics = false,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      image: true,
      label: semanticLabel,
      excludeSemantics: excludeFromSemantics,
      child: Image(
        image: image,
        width: width,
        height: height,
        fit: fit,
        semanticLabel: excludeFromSemantics ? null : semanticLabel,
      ),
    );
  }
}

/// Widget d'icône accessible
class AccessibleIcon extends StatelessWidget {
  final IconData icon;
  final String semanticLabel;
  final double? size;
  final Color? color;

  const AccessibleIcon({
    super.key,
    required this.icon,
    required this.semanticLabel,
    this.size,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel,
      child: Icon(
        icon,
        size: size,
        color: color,
        semanticLabel: semanticLabel,
      ),
    );
  }
}

/// Widget pour les valeurs numériques accessibles
class AccessibleValue extends StatelessWidget {
  final String value;
  final String label;
  final String? unit;
  final TextStyle? valueStyle;
  final TextStyle? labelStyle;

  const AccessibleValue({
    super.key,
    required this.value,
    required this.label,
    this.unit,
    this.valueStyle,
    this.labelStyle,
  });

  @override
  Widget build(BuildContext context) {
    final semanticValue = unit != null ? '$value $unit' : value;
    
    return Semantics(
      label: '$label: $semanticValue',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            unit != null ? '$value $unit' : value,
            style: valueStyle ?? Theme.of(context).textTheme.headlineMedium,
          ),
          Text(
            label,
            style: labelStyle ?? Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

/// Widget de statut accessible
class AccessibleStatus extends StatelessWidget {
  final String status;
  final Color color;
  final IconData? icon;

  const AccessibleStatus({
    super.key,
    required this.status,
    required this.color,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Statut: $status',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
            ],
            Text(
              status,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Widget slider accessible
class AccessibleSlider extends StatelessWidget {
  final double value;
  final double min;
  final double max;
  final int? divisions;
  final String label;
  final ValueChanged<double>? onChanged;
  final String Function(double)? semanticFormatter;

  const AccessibleSlider({
    super.key,
    required this.value,
    this.min = 0,
    this.max = 1,
    this.divisions,
    required this.label,
    this.onChanged,
    this.semanticFormatter,
  });

  @override
  Widget build(BuildContext context) {
    final semanticValue = semanticFormatter?.call(value) ?? value.toStringAsFixed(1);
    
    return Semantics(
      slider: true,
      label: '$label: $semanticValue',
      value: semanticValue,
      increasedValue: semanticFormatter?.call((value + (max - min) / (divisions ?? 10)).clamp(min, max)),
      decreasedValue: semanticFormatter?.call((value - (max - min) / (divisions ?? 10)).clamp(min, max)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label),
              Text(semanticValue, style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
          Slider(
            value: value,
            min: min,
            max: max,
            divisions: divisions,
            label: semanticValue,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

/// Extension pour annoncer aux lecteurs d'écran
extension SemanticAnnouncements on BuildContext {
  void announceForAccessibility(String message, {bool assertive = false}) {
    SemanticsService.sendAnnouncement(
      View.of(this),
      message,
      TextDirection.ltr,
      assertiveness: assertive ? Assertiveness.assertive : Assertiveness.polite,
    );
  }
}

/// Vérificateur de contraste de couleurs
class ContrastChecker {
  /// Calcule le ratio de contraste entre deux couleurs (WCAG)
  static double getContrastRatio(Color foreground, Color background) {
    final l1 = _getRelativeLuminance(foreground);
    final l2 = _getRelativeLuminance(background);
    
    final lighter = l1 > l2 ? l1 : l2;
    final darker = l1 > l2 ? l2 : l1;
    
    return (lighter + 0.05) / (darker + 0.05);
  }

  static double _getRelativeLuminance(Color color) {
    double r = (color.r * 255.0).round().clamp(0, 255) / 255;
    double g = (color.g * 255.0).round().clamp(0, 255) / 255;
    double b = (color.b * 255.0).round().clamp(0, 255) / 255;

    r = r <= 0.03928 ? r / 12.92 : ((r + 0.055) / 1.055).pow(2.4);
    g = g <= 0.03928 ? g / 12.92 : ((g + 0.055) / 1.055).pow(2.4);
    b = b <= 0.03928 ? b / 12.92 : ((b + 0.055) / 1.055).pow(2.4);

    return 0.2126 * r + 0.7152 * g + 0.0722 * b;
  }

  /// Vérifie si le contraste est suffisant pour le texte normal (AA)
  static bool meetsAA(Color foreground, Color background) {
    return getContrastRatio(foreground, background) >= 4.5;
  }

  /// Vérifie si le contraste est suffisant pour le grand texte (AA)
  static bool meetsAALargeText(Color foreground, Color background) {
    return getContrastRatio(foreground, background) >= 3.0;
  }

  /// Vérifie si le contraste est suffisant (AAA)
  static bool meetsAAA(Color foreground, Color background) {
    return getContrastRatio(foreground, background) >= 7.0;
  }
}

extension on double {
  double pow(double exponent) {
    return std.pow(this, exponent).toDouble();
  }
}
