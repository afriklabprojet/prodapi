import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auto_theme_service.dart';

// Re-export isDarkModeProvider from theme_service
export '../services/theme_service.dart' show isDarkModeProvider;

/// Mode de thème étendu avec option Auto (intelligent)
enum AppThemeMode {
  light,    // Toujours clair
  dark,     // Toujours sombre
  system,   // Suit le système
  auto,     // Intelligent (basé sur l'heure) ⭐ NOUVEAU
}

/// Provider pour le mode thème (clair/sombre/auto)
final themeProvider = NotifierProvider<ThemeNotifier, ThemeMode>(
  ThemeNotifier.new,
);

/// Provider pour le mode de thème de l'app
final appThemeModeProvider = NotifierProvider<AppThemeModeNotifier, AppThemeMode>(
  AppThemeModeNotifier.new,
);

class AppThemeModeNotifier extends Notifier<AppThemeMode> {
  static const String _themeModeKey = 'app_theme_mode';

  @override
  AppThemeMode build() {
    // Charger le mode de façon asynchrone (non bloquante)
    Future.microtask(() => _loadMode());
    return AppThemeMode.light;
  }

  Future<void> _loadMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final modeString = prefs.getString(_themeModeKey);
      
      if (modeString != null) {
        state = AppThemeMode.values.firstWhere(
          (e) => e.name == modeString,
          orElse: () => AppThemeMode.light,
        );
      }
      
      // Si mode auto, initialiser le service
      if (state == AppThemeMode.auto) {
        _initAutoTheme();
      }
    } catch (e) {
      // En cas d'erreur, garder le thème par défaut
      debugPrint('⚠️ Erreur chargement thème: $e');
    }
  }

  Future<void> _initAutoTheme() async {
    final autoService = AutoThemeService.instance;
    await autoService.init();
    
    // Configurer le callback
    autoService.onThemeChange = (isDark) {
      // Notifier le theme provider du changement
      ref.read(themeProvider.notifier).setTheme(
        isDark ? ThemeMode.dark : ThemeMode.light,
      );
    };
    
    await autoService.setEnabled(true);
    
    // Appliquer immédiatement
    if (autoService.isNightTime()) {
      ref.read(themeProvider.notifier).setTheme(ThemeMode.dark);
    } else {
      ref.read(themeProvider.notifier).setTheme(ThemeMode.light);
    }
  }

  Future<void> setMode(AppThemeMode mode) async {
    state = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeModeKey, mode.name);
    
    final autoService = AutoThemeService.instance;
    
    switch (mode) {
      case AppThemeMode.light:
        await autoService.setEnabled(false);
        ref.read(themeProvider.notifier).setTheme(ThemeMode.light);
        break;
      case AppThemeMode.dark:
        await autoService.setEnabled(false);
        ref.read(themeProvider.notifier).setTheme(ThemeMode.dark);
        break;
      case AppThemeMode.system:
        await autoService.setEnabled(false);
        ref.read(themeProvider.notifier).setTheme(ThemeMode.system);
        break;
      case AppThemeMode.auto:
        _initAutoTheme();
        break;
    }
  }

  String get modeLabel {
    switch (state) {
      case AppThemeMode.light: return 'Clair';
      case AppThemeMode.dark: return 'Sombre';
      case AppThemeMode.system: return 'Système';
      case AppThemeMode.auto: return 'Intelligent';
    }
  }

  String get modeDescription {
    switch (state) {
      case AppThemeMode.light: return 'Toujours en mode clair';
      case AppThemeMode.dark: return 'Toujours en mode sombre';
      case AppThemeMode.system: return 'Suit les paramètres de l\'appareil';
      case AppThemeMode.auto:
        final autoService = AutoThemeService.instance;
        return autoService.getStatusDescription();
    }
  }

  IconData get modeIcon {
    switch (state) {
      case AppThemeMode.light: return Icons.light_mode;
      case AppThemeMode.dark: return Icons.dark_mode;
      case AppThemeMode.system: return Icons.brightness_auto;
      case AppThemeMode.auto: return Icons.schedule;
    }
  }
}

class ThemeNotifier extends Notifier<ThemeMode> {
  static const String _themeKey = 'theme_mode';

  @override
  ThemeMode build() {
    // Charger le thème de façon asynchrone (non bloquante)
    Future.microtask(() => _loadTheme());
    // Par défaut, utiliser le thème clair
    return ThemeMode.light;
  }

  Future<void> _loadTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (!ref.mounted) return; // Provider may have been disposed during await
      final themeString = prefs.getString(_themeKey);
      
      if (themeString != null) {
        state = ThemeMode.values.firstWhere(
          (e) => e.name == themeString,
          orElse: () => ThemeMode.light,
        );
      }
    } catch (e) {
      debugPrint('⚠️ Erreur chargement ThemeMode: $e');
    }
  }

  Future<void> setTheme(ThemeMode mode) async {
    state = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeKey, mode.name);
  }

  Future<void> toggleTheme() async {
    final newMode = state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    await setTheme(newMode);
  }

  bool get isDark => state == ThemeMode.dark;
  bool get isLight => state == ThemeMode.light;
  bool get isSystem => state == ThemeMode.system;
}

/// Couleur principale basée sur le logo DR-PHARMA
const Color kPrimaryGreen = Color(0xFF54AB70);
const Color kPrimaryGreenDark = Color(0xFF3D8C57);
const Color kPrimaryGreenLight = Color(0xFF6EC889);

/// Thème clair personnalisé
ThemeData get lightTheme => ThemeData(
  useMaterial3: true,
  brightness: Brightness.light,
  colorScheme: ColorScheme.fromSeed(
    seedColor: kPrimaryGreen,
    brightness: Brightness.light,
  ),
  scaffoldBackgroundColor: const Color(0xFFF8F9FD),
  appBarTheme: const AppBarTheme(
    backgroundColor: Colors.white,
    foregroundColor: Colors.black,
    elevation: 0,
    centerTitle: true,
  ),
  cardTheme: CardThemeData(
    color: Colors.white,
    elevation: 2,
    shadowColor: Colors.black.withValues(alpha: 0.1),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: kPrimaryGreen,
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: Colors.grey.shade100,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide.none,
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide.none,
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: kPrimaryGreen, width: 2),
    ),
  ),
  bottomNavigationBarTheme: const BottomNavigationBarThemeData(
    backgroundColor: Colors.white,
    selectedItemColor: kPrimaryGreen,
    unselectedItemColor: Colors.grey,
  ),
  dialogTheme: DialogThemeData(
    backgroundColor: Colors.white,
    surfaceTintColor: Colors.transparent,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
  ),
  dividerTheme: DividerThemeData(
    color: Colors.grey.shade200,
    thickness: 1,
  ),
);

/// Thème sombre personnalisé
ThemeData get darkTheme => ThemeData(
  useMaterial3: true,
  brightness: Brightness.dark,
  colorScheme: ColorScheme.fromSeed(
    seedColor: kPrimaryGreen,
    brightness: Brightness.dark,
  ),
  scaffoldBackgroundColor: const Color(0xFF121212),
  textTheme: const TextTheme(
    bodyLarge: TextStyle(color: Colors.white),
    bodyMedium: TextStyle(color: Colors.white),
    titleLarge: TextStyle(color: Colors.white),
    titleMedium: TextStyle(color: Colors.white),
    titleSmall: TextStyle(color: Colors.white70),
    labelLarge: TextStyle(color: Colors.white),
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: Color(0xFF1E1E1E),
    foregroundColor: Colors.white,
    elevation: 0,
    centerTitle: true,
  ),
  cardTheme: CardThemeData(
    color: const Color(0xFF1E1E1E),
    elevation: 4,
    shadowColor: Colors.black.withValues(alpha: 0.3),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: kPrimaryGreenDark,
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: const Color(0xFF2C2C2C),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide.none,
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide.none,
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: kPrimaryGreenLight, width: 2),
    ),
  ),
  bottomNavigationBarTheme: const BottomNavigationBarThemeData(
    backgroundColor: Color(0xFF1E1E1E),
    selectedItemColor: kPrimaryGreenLight,
    unselectedItemColor: Colors.grey,
  ),
  bottomSheetTheme: const BottomSheetThemeData(
    backgroundColor: Color(0xFF1E1E1E),
    modalBackgroundColor: Color(0xFF1E1E1E),
    surfaceTintColor: Colors.transparent,
  ),
  dialogTheme: DialogThemeData(
    backgroundColor: const Color(0xFF1E1E1E),
    surfaceTintColor: Colors.transparent,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    titleTextStyle: const TextStyle(
      color: Colors.white,
      fontSize: 20,
      fontWeight: FontWeight.bold,
    ),
    contentTextStyle: const TextStyle(
      color: Colors.white70,
      fontSize: 16,
    ),
  ),
  dividerTheme: const DividerThemeData(
    color: Color(0xFF2C2C2C),
    thickness: 1,
  ),
  listTileTheme: const ListTileThemeData(
    iconColor: Colors.white70,
    textColor: Colors.white,
  ),
  popupMenuTheme: PopupMenuThemeData(
    color: const Color(0xFF1E1E1E),
    surfaceTintColor: Colors.transparent,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    textStyle: const TextStyle(color: Colors.white),
  ),
  snackBarTheme: SnackBarThemeData(
    backgroundColor: const Color(0xFF2C2C2C),
    contentTextStyle: const TextStyle(color: Colors.white),
    actionTextColor: Colors.blue.shade300,
    behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
  ),
  switchTheme: SwitchThemeData(
    thumbColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) {
        return Colors.blue;
      }
      return Colors.grey;
    }),
    trackColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) {
        return Colors.blue.withValues(alpha: 0.5);
      }
      return Colors.grey.withValues(alpha: 0.3);
    }),
  ),
);

/// Extension pour accéder facilement aux couleurs du thème
extension ThemeExtension on BuildContext {
  bool get isDark => Theme.of(this).brightness == Brightness.dark;
  
  Color get scaffoldBackground => isDark 
      ? const Color(0xFF121212) 
      : const Color(0xFFF8F9FD);
  
  Color get cardBackground => isDark 
      ? const Color(0xFF1E1E1E) 
      : Colors.white;
  
  Color get surfaceColor => isDark 
      ? const Color(0xFF2C2C2C) 
      : Colors.grey.shade100;
  
  Color get primaryText => isDark 
      ? Colors.white 
      : Colors.black;
  
  Color get secondaryText => isDark 
      ? Colors.white70 
      : Colors.grey.shade600;
  
  Color get tertiaryText => isDark 
      ? Colors.white54 
      : Colors.grey.shade500;
  
  Color get dividerColor => isDark 
      ? const Color(0xFF2C2C2C) 
      : Colors.grey.shade200;
  
  Color get iconColor => isDark 
      ? Colors.white70 
      : Colors.grey.shade700;

  Color get inputFillColor => isDark
      ? const Color(0xFF2C2C2C)
      : Colors.grey.shade100;

  Color get shadowColor => isDark
      ? Colors.black.withValues(alpha: 0.3)
      : Colors.black.withValues(alpha: 0.1);

  Color get hintColor => isDark
      ? Colors.white38
      : Colors.grey.shade400;

  Color get borderColor => isDark
      ? Colors.white12
      : Colors.grey.shade300;
}
