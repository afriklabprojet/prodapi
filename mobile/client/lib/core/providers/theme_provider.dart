import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../config/providers.dart';

/// Mode de thème de l'application
enum AppThemeMode {
  system, // Suit le thème du système
  light, // Toujours clair
  dark, // Toujours sombre
}

/// État du thème
class ThemeState {
  final AppThemeMode appThemeMode;
  final ThemeMode themeMode;

  const ThemeState({
    this.appThemeMode = AppThemeMode.system,
    this.themeMode = ThemeMode.system,
  });

  bool get isDarkMode {
    if (appThemeMode == AppThemeMode.system) {
      final brightness =
          SchedulerBinding.instance.platformDispatcher.platformBrightness;
      return brightness == Brightness.dark;
    }
    return themeMode == ThemeMode.dark;
  }

  bool get isLightMode => !isDarkMode;
  bool get isSystemMode => appThemeMode == AppThemeMode.system;

  ThemeState copyWith({AppThemeMode? appThemeMode, ThemeMode? themeMode}) {
    return ThemeState(
      appThemeMode: appThemeMode ?? this.appThemeMode,
      themeMode: themeMode ?? this.themeMode,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ThemeState &&
        other.appThemeMode == appThemeMode &&
        other.themeMode == themeMode;
  }

  @override
  int get hashCode => appThemeMode.hashCode ^ themeMode.hashCode;
}

/// Notifier pour gérer le thème
class ThemeNotifier extends StateNotifier<ThemeState> {
  static const String _themeKey = 'theme_mode';
  final SharedPreferences _prefs;

  ThemeNotifier(this._prefs) : super(const ThemeState()) {
    _loadTheme();
  }

  /// Charger le thème sauvegardé
  Future<void> _loadTheme() async {
    final savedMode = _prefs.getString(_themeKey);
    final appMode = _parseAppThemeMode(savedMode);
    state = ThemeState(
      appThemeMode: appMode,
      themeMode: _toThemeMode(appMode),
    );
  }

  AppThemeMode _parseAppThemeMode(String? value) {
    switch (value) {
      case 'light':
        return AppThemeMode.light;
      case 'dark':
        return AppThemeMode.dark;
      case 'system':
      default:
        return AppThemeMode.system;
    }
  }

  ThemeMode _toThemeMode(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.light:
        return ThemeMode.light;
      case AppThemeMode.dark:
        return ThemeMode.dark;
      case AppThemeMode.system:
        return ThemeMode.system;
    }
  }

  /// Toggle entre dark et light mode
  Future<void> toggleTheme() async {
    final newMode = state.isDarkMode ? AppThemeMode.light : AppThemeMode.dark;
    await setAppThemeMode(newMode);
  }

  /// Définir le mode de thème
  Future<void> setAppThemeMode(AppThemeMode mode) async {
    await _prefs.setString(_themeKey, mode.name);
    state = ThemeState(
      appThemeMode: mode,
      themeMode: _toThemeMode(mode),
    );
  }

  /// Définir le thème explicitement (legacy)
  Future<void> setTheme(ThemeMode mode) async {
    final appMode = mode == ThemeMode.dark
        ? AppThemeMode.dark
        : mode == ThemeMode.light
            ? AppThemeMode.light
            : AppThemeMode.system;
    await setAppThemeMode(appMode);
  }

  /// Active le mode clair
  Future<void> setLightMode() => setAppThemeMode(AppThemeMode.light);

  /// Active le mode sombre
  Future<void> setDarkMode() => setAppThemeMode(AppThemeMode.dark);

  /// Active le mode système
  Future<void> setSystemMode() => setAppThemeMode(AppThemeMode.system);
}

/// Provider pour le thème
final themeProvider = StateNotifierProvider<ThemeNotifier, ThemeState>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return ThemeNotifier(prefs);
});

/// Provider simplifié pour le ThemeMode de MaterialApp
final themeModeProvider = Provider<ThemeMode>((ref) {
  return ref.watch(themeProvider).themeMode;
});

/// Provider pour vérifier si le mode sombre est actif
final isDarkModeProvider = Provider<bool>((ref) {
  return ref.watch(themeProvider).isDarkMode;
});

/// Extension pour accéder facilement aux couleurs adaptatives du thème
extension ThemeContextExtension on BuildContext {
  /// Vérifie si le mode sombre est actif
  bool get isDark => Theme.of(this).brightness == Brightness.dark;

  /// Couleur de fond du scaffold
  Color get scaffoldBackground => Theme.of(this).scaffoldBackgroundColor;

  /// Couleur de surface (cards, conteneurs)
  Color get surfaceColor => Theme.of(this).colorScheme.surface;

  /// Couleur de fond des cartes
  Color get cardBackground =>
      isDark ? const Color(0xFF1E1E1E) : Colors.white;

  /// Texte principal
  Color get primaryText =>
      isDark ? Colors.white : const Color(0xFF212121);

  /// Texte secondaire
  Color get secondaryText =>
      isDark ? Colors.grey.shade400 : Colors.grey.shade600;

  /// Texte tertiaire (hints, placeholders)
  Color get tertiaryText =>
      isDark ? Colors.grey.shade500 : Colors.grey.shade500;

  /// Couleur des bordures
  Color get borderColor =>
      isDark ? const Color(0xFF3C3C3C) : Colors.grey.shade300;

  /// Couleur des dividers
  Color get dividerColor =>
      isDark ? Colors.white12 : Colors.grey.shade200;

  /// Couleur des icônes
  Color get iconColor =>
      isDark ? Colors.white : const Color(0xFF212121);

  /// Couleur de fond des inputs
  Color get inputFillColor =>
      isDark ? const Color(0xFF2C2C2C) : Colors.grey.shade50;

  /// Couleur d'ombre
  Color get shadowColor =>
      isDark ? Colors.black.withValues(alpha: 0.3) : Colors.black.withValues(alpha: 0.1);

  /// Couleur de hint
  Color get hintColor =>
      isDark ? Colors.white38 : Colors.grey.shade400;

  /// Couleur de fond surélevée (légèrement plus claire/foncée que surface)
  Color get elevatedBackground =>
      isDark ? const Color(0xFF2C2C2C) : Colors.grey.shade100;
}

