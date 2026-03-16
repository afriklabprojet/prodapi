import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod/legacy.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// Mode de thème
enum ThemeMode {
  system,
  light,
  dark,
  oled,
  custom,
}

/// Variante de couleur
enum ColorVariant {
  blue,
  green,
  orange,
  purple,
  red,
  teal,
  pink,
  custom,
}

/// Préréglage de thème
class ThemePreset {
  final String id;
  final String name;
  final Color primaryColor;
  final Color secondaryColor;
  final Color backgroundColor;
  final Color surfaceColor;
  final Color errorColor;
  final bool isDark;

  const ThemePreset({
    required this.id,
    required this.name,
    required this.primaryColor,
    required this.secondaryColor,
    required this.backgroundColor,
    required this.surfaceColor,
    required this.errorColor,
    required this.isDark,
  });
}

/// Paramètres de thème personnalisé
class CustomThemeSettings {
  final Color primaryColor;
  final Color secondaryColor;
  final Color backgroundColor;
  final Color surfaceColor;
  final Color textColor;
  final Color errorColor;
  final double borderRadius;
  final bool useMaterial3;
  final String? fontFamily;

  const CustomThemeSettings({
    this.primaryColor = const Color(0xFF2196F3),
    this.secondaryColor = const Color(0xFF03DAC6),
    this.backgroundColor = const Color(0xFFFFFFFF),
    this.surfaceColor = const Color(0xFFF5F5F5),
    this.textColor = const Color(0xFF212121),
    this.errorColor = const Color(0xFFB00020),
    this.borderRadius = 12.0,
    this.useMaterial3 = true,
    this.fontFamily,
  });

  CustomThemeSettings copyWith({
    Color? primaryColor,
    Color? secondaryColor,
    Color? backgroundColor,
    Color? surfaceColor,
    Color? textColor,
    Color? errorColor,
    double? borderRadius,
    bool? useMaterial3,
    String? fontFamily,
  }) {
    return CustomThemeSettings(
      primaryColor: primaryColor ?? this.primaryColor,
      secondaryColor: secondaryColor ?? this.secondaryColor,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      surfaceColor: surfaceColor ?? this.surfaceColor,
      textColor: textColor ?? this.textColor,
      errorColor: errorColor ?? this.errorColor,
      borderRadius: borderRadius ?? this.borderRadius,
      useMaterial3: useMaterial3 ?? this.useMaterial3,
      fontFamily: fontFamily ?? this.fontFamily,
    );
  }
}

/// État du thème
class AppThemeState {
  final ThemeMode themeMode;
  final ColorVariant colorVariant;
  final CustomThemeSettings customSettings;
  final bool useOledBlack;
  final bool reducedMotion;
  final bool highContrast;
  final double textScale;
  final ThemeData lightTheme;
  final ThemeData darkTheme;

  const AppThemeState({
    this.themeMode = ThemeMode.system,
    this.colorVariant = ColorVariant.blue,
    this.customSettings = const CustomThemeSettings(),
    this.useOledBlack = false,
    this.reducedMotion = false,
    this.highContrast = false,
    this.textScale = 1.0,
    required this.lightTheme,
    required this.darkTheme,
  });

  AppThemeState copyWith({
    ThemeMode? themeMode,
    ColorVariant? colorVariant,
    CustomThemeSettings? customSettings,
    bool? useOledBlack,
    bool? reducedMotion,
    bool? highContrast,
    double? textScale,
    ThemeData? lightTheme,
    ThemeData? darkTheme,
  }) {
    return AppThemeState(
      themeMode: themeMode ?? this.themeMode,
      colorVariant: colorVariant ?? this.colorVariant,
      customSettings: customSettings ?? this.customSettings,
      useOledBlack: useOledBlack ?? this.useOledBlack,
      reducedMotion: reducedMotion ?? this.reducedMotion,
      highContrast: highContrast ?? this.highContrast,
      textScale: textScale ?? this.textScale,
      lightTheme: lightTheme ?? this.lightTheme,
      darkTheme: darkTheme ?? this.darkTheme,
    );
  }

  /// Retourne true si l'app doit utiliser le thème sombre
  bool get isDark {
    switch (themeMode) {
      case ThemeMode.light:
        return false;
      case ThemeMode.dark:
      case ThemeMode.oled:
        return true;
      case ThemeMode.system:
      case ThemeMode.custom:
        final brightness = SchedulerBinding.instance.platformDispatcher.platformBrightness;
        return brightness == Brightness.dark;
    }
  }

  /// Retourne le thème actif
  ThemeData get activeTheme => isDark ? darkTheme : lightTheme;
}

/// Préréglages de thèmes
const List<ThemePreset> themePresets = [
  ThemePreset(
    id: 'default_light',
    name: 'Clair par défaut',
    primaryColor: Color(0xFF2196F3),
    secondaryColor: Color(0xFF03DAC6),
    backgroundColor: Color(0xFFFFFFFF),
    surfaceColor: Color(0xFFF5F5F5),
    errorColor: Color(0xFFB00020),
    isDark: false,
  ),
  ThemePreset(
    id: 'default_dark',
    name: 'Sombre par défaut',
    primaryColor: Color(0xFF90CAF9),
    secondaryColor: Color(0xFF03DAC6),
    backgroundColor: Color(0xFF121212),
    surfaceColor: Color(0xFF1E1E1E),
    errorColor: Color(0xFFCF6679),
    isDark: true,
  ),
  ThemePreset(
    id: 'oled',
    name: 'OLED Noir pur',
    primaryColor: Color(0xFF2196F3),
    secondaryColor: Color(0xFF03DAC6),
    backgroundColor: Color(0xFF000000),
    surfaceColor: Color(0xFF0A0A0A),
    errorColor: Color(0xFFCF6679),
    isDark: true,
  ),
  ThemePreset(
    id: 'forest',
    name: 'Forêt',
    primaryColor: Color(0xFF4CAF50),
    secondaryColor: Color(0xFF8BC34A),
    backgroundColor: Color(0xFF0D1F0D),
    surfaceColor: Color(0xFF1A2F1A),
    errorColor: Color(0xFFFF5252),
    isDark: true,
  ),
  ThemePreset(
    id: 'ocean',
    name: 'Océan',
    primaryColor: Color(0xFF00BCD4),
    secondaryColor: Color(0xFF4DD0E1),
    backgroundColor: Color(0xFF0D1B1F),
    surfaceColor: Color(0xFF132830),
    errorColor: Color(0xFFFF5252),
    isDark: true,
  ),
  ThemePreset(
    id: 'sunset',
    name: 'Coucher de soleil',
    primaryColor: Color(0xFFFF5722),
    secondaryColor: Color(0xFFFF9800),
    backgroundColor: Color(0xFF1A0F0A),
    surfaceColor: Color(0xFF2D1A12),
    errorColor: Color(0xFFFF5252),
    isDark: true,
  ),
  ThemePreset(
    id: 'purple_night',
    name: 'Nuit violette',
    primaryColor: Color(0xFF9C27B0),
    secondaryColor: Color(0xFFE040FB),
    backgroundColor: Color(0xFF0F0A1A),
    surfaceColor: Color(0xFF1A132D),
    errorColor: Color(0xFFFF5252),
    isDark: true,
  ),
];

/// Service de thème avancé
class ThemeService extends StateNotifier<AppThemeState> {
  late Box _themeBox;

  ThemeService() : super(AppThemeState(
    lightTheme: _buildDefaultLightTheme(),
    darkTheme: _buildDefaultDarkTheme(),
  )) {
    _init();
  }

  Future<void> _init() async {
    _themeBox = await Hive.openBox('theme');
    await _loadSettings();
  }

  Future<void> _loadSettings() async {
    final mode = _themeBox.get('themeMode', defaultValue: 'system');
    final variant = _themeBox.get('colorVariant', defaultValue: 'blue');
    final oled = _themeBox.get('useOledBlack', defaultValue: false);
    final reducedMotion = _themeBox.get('reducedMotion', defaultValue: false);
    final highContrast = _themeBox.get('highContrast', defaultValue: false);
    final textScale = _themeBox.get('textScale', defaultValue: 1.0);

    // Charger les couleurs personnalisées
    final customPrimary = _themeBox.get('customPrimary');
    final customSecondary = _themeBox.get('customSecondary');
    final customBg = _themeBox.get('customBackground');
    final customRadius = _themeBox.get('borderRadius', defaultValue: 12.0);

    CustomThemeSettings customSettings = state.customSettings;
    if (customPrimary != null) {
      customSettings = customSettings.copyWith(
        primaryColor: Color(customPrimary),
        secondaryColor: customSecondary != null ? Color(customSecondary) : null,
        backgroundColor: customBg != null ? Color(customBg) : null,
        borderRadius: customRadius,
      );
    }

    final themeMode = ThemeMode.values.firstWhere(
      (m) => m.name == mode,
      orElse: () => ThemeMode.system,
    );

    final colorVariant = ColorVariant.values.firstWhere(
      (v) => v.name == variant,
      orElse: () => ColorVariant.blue,
    );

    _updateThemes(
      themeMode: themeMode,
      colorVariant: colorVariant,
      customSettings: customSettings,
      useOledBlack: oled,
      reducedMotion: reducedMotion,
      highContrast: highContrast,
      textScale: textScale,
    );
  }

  void _updateThemes({
    ThemeMode? themeMode,
    ColorVariant? colorVariant,
    CustomThemeSettings? customSettings,
    bool? useOledBlack,
    bool? reducedMotion,
    bool? highContrast,
    double? textScale,
  }) {
    final mode = themeMode ?? state.themeMode;
    final variant = colorVariant ?? state.colorVariant;
    final settings = customSettings ?? state.customSettings;
    final oled = useOledBlack ?? state.useOledBlack;
    final motion = reducedMotion ?? state.reducedMotion;
    final contrast = highContrast ?? state.highContrast;
    final scale = textScale ?? state.textScale;

    final primaryColor = _getPrimaryColor(variant, settings);
    
    final lightTheme = _buildLightTheme(
      primaryColor: primaryColor,
      customSettings: settings,
      highContrast: contrast,
      textScale: scale,
    );

    final darkTheme = _buildDarkTheme(
      primaryColor: primaryColor,
      customSettings: settings,
      useOledBlack: oled || mode == ThemeMode.oled,
      highContrast: contrast,
      textScale: scale,
    );

    state = state.copyWith(
      themeMode: mode,
      colorVariant: variant,
      customSettings: settings,
      useOledBlack: oled,
      reducedMotion: motion,
      highContrast: contrast,
      textScale: scale,
      lightTheme: lightTheme,
      darkTheme: darkTheme,
    );
  }

  Color _getPrimaryColor(ColorVariant variant, CustomThemeSettings settings) {
    switch (variant) {
      case ColorVariant.blue:
        return const Color(0xFF2196F3);
      case ColorVariant.green:
        return const Color(0xFF4CAF50);
      case ColorVariant.orange:
        return const Color(0xFFFF9800);
      case ColorVariant.purple:
        return const Color(0xFF9C27B0);
      case ColorVariant.red:
        return const Color(0xFFF44336);
      case ColorVariant.teal:
        return const Color(0xFF009688);
      case ColorVariant.pink:
        return const Color(0xFFE91E63);
      case ColorVariant.custom:
        return settings.primaryColor;
    }
  }

  ThemeData _buildLightTheme({
    required Color primaryColor,
    required CustomThemeSettings customSettings,
    required bool highContrast,
    required double textScale,
  }) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: primaryColor,
      brightness: Brightness.light,
    );

    return ThemeData(
      useMaterial3: customSettings.useMaterial3,
      colorScheme: highContrast 
          ? colorScheme.copyWith(
              onSurface: Colors.black,
            )
          : colorScheme,
      fontFamily: customSettings.fontFamily,
      cardTheme: CardThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(customSettings.borderRadius),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(customSettings.borderRadius),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(customSettings.borderRadius),
        ),
      ),
    );
  }

  ThemeData _buildDarkTheme({
    required Color primaryColor,
    required CustomThemeSettings customSettings,
    required bool useOledBlack,
    required bool highContrast,
    required double textScale,
  }) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: primaryColor,
      brightness: Brightness.dark,
    ).copyWith(
      surface: useOledBlack ? Colors.black : null,
    );

    return ThemeData(
      useMaterial3: customSettings.useMaterial3,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: useOledBlack ? Colors.black : null,
      fontFamily: customSettings.fontFamily,
      cardTheme: CardThemeData(
        color: useOledBlack ? const Color(0xFF0A0A0A) : null,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(customSettings.borderRadius),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: useOledBlack ? Colors.black : null,
        surfaceTintColor: useOledBlack ? Colors.transparent : null,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: useOledBlack ? Colors.black : null,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(customSettings.borderRadius),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(customSettings.borderRadius),
        ),
        filled: true,
        fillColor: useOledBlack ? const Color(0xFF0A0A0A) : null,
      ),
    );
  }

  /// Changer le mode de thème
  Future<void> setThemeMode(ThemeMode mode) async {
    await _themeBox.put('themeMode', mode.name);
    _updateThemes(themeMode: mode);
  }

  /// Changer la variante de couleur
  Future<void> setColorVariant(ColorVariant variant) async {
    await _themeBox.put('colorVariant', variant.name);
    _updateThemes(colorVariant: variant);
  }

  /// Activer/désactiver OLED noir
  Future<void> setOledBlack(bool enabled) async {
    await _themeBox.put('useOledBlack', enabled);
    _updateThemes(useOledBlack: enabled);
  }

  /// Activer/désactiver animations réduites
  Future<void> setReducedMotion(bool enabled) async {
    await _themeBox.put('reducedMotion', enabled);
    _updateThemes(reducedMotion: enabled);
  }

  /// Activer/désactiver contraste élevé
  Future<void> setHighContrast(bool enabled) async {
    await _themeBox.put('highContrast', enabled);
    _updateThemes(highContrast: enabled);
  }

  /// Changer l'échelle de texte
  Future<void> setTextScale(double scale) async {
    await _themeBox.put('textScale', scale.clamp(0.8, 1.5));
    _updateThemes(textScale: scale);
  }

  /// Définir une couleur primaire personnalisée
  Future<void> setCustomPrimaryColor(Color color) async {
    await _themeBox.put('customPrimary', color.toARGB32);
    final newSettings = state.customSettings.copyWith(primaryColor: color);
    _updateThemes(
      colorVariant: ColorVariant.custom,
      customSettings: newSettings,
    );
  }

  /// Définir le rayon de bordure
  Future<void> setBorderRadius(double radius) async {
    await _themeBox.put('borderRadius', radius);
    final newSettings = state.customSettings.copyWith(borderRadius: radius);
    _updateThemes(customSettings: newSettings);
  }

  /// Appliquer un préréglage
  Future<void> applyPreset(ThemePreset preset) async {
    final customSettings = CustomThemeSettings(
      primaryColor: preset.primaryColor,
      secondaryColor: preset.secondaryColor,
      backgroundColor: preset.backgroundColor,
      surfaceColor: preset.surfaceColor,
    );

    await _themeBox.put('customPrimary', preset.primaryColor.toARGB32);
    await _themeBox.put('customSecondary', preset.secondaryColor.toARGB32);
    await _themeBox.put('customBackground', preset.backgroundColor.toARGB32);

    _updateThemes(
      themeMode: preset.isDark ? ThemeMode.dark : ThemeMode.light,
      colorVariant: ColorVariant.custom,
      customSettings: customSettings,
      useOledBlack: preset.id == 'oled',
    );
  }

  /// Réinitialiser vers le thème par défaut
  Future<void> resetToDefault() async {
    await _themeBox.clear();
    
    state = AppThemeState(
      lightTheme: _buildDefaultLightTheme(),
      darkTheme: _buildDefaultDarkTheme(),
    );
  }

  static ThemeData _buildDefaultLightTheme() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF2196F3),
        brightness: Brightness.light,
      ),
    );
  }

  static ThemeData _buildDefaultDarkTheme() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF2196F3),
        brightness: Brightness.dark,
      ),
    );
  }
}

/// Provider pour le service de thème
final themeServiceProvider = StateNotifierProvider<ThemeService, AppThemeState>((ref) {
  return ThemeService();
});

/// Provider pour le thème actif
final activeThemeProvider = Provider<ThemeData>((ref) {
  return ref.watch(themeServiceProvider).activeTheme;
});

/// Provider pour le mode sombre
final isDarkModeProvider = Provider<bool>((ref) {
  return ref.watch(themeServiceProvider).isDark;
});

/// Provider pour l'échelle de texte
final textScaleProvider = Provider<double>((ref) {
  return ref.watch(themeServiceProvider).textScale;
});

/// Provider pour les animations réduites
final reducedMotionProvider = Provider<bool>((ref) {
  return ref.watch(themeServiceProvider).reducedMotion;
});
