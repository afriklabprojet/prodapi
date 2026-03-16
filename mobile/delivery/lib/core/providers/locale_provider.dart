import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Clé pour la persistance de la langue
const String _localeKey = 'app_locale';

/// Provider pour la locale de l'application
final localeProvider = NotifierProvider<LocaleNotifier, Locale>(LocaleNotifier.new);

/// Notifier pour gérer la locale avec persistance
class LocaleNotifier extends Notifier<Locale> {
  @override
  Locale build() {
    _loadSavedLocale();
    return const Locale('fr');
  }

  /// Langues supportées
  static const List<Locale> supportedLocales = [
    Locale('fr'),
    Locale('en'),
  ];

  /// Noms des langues pour l'affichage
  static const Map<String, String> localeNames = {
    'fr': 'Français',
    'en': 'English',
  };

  /// Charge la locale sauvegardée
  Future<void> _loadSavedLocale() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedLocale = prefs.getString(_localeKey);
      if (savedLocale != null && _isSupported(savedLocale)) {
        state = Locale(savedLocale);
      }
    } catch (e) {
      debugPrint('Error loading saved locale: $e');
    }
  }

  /// Vérifie si la locale est supportée
  bool _isSupported(String languageCode) {
    return supportedLocales.any((locale) => locale.languageCode == languageCode);
  }

  /// Change la locale de l'application
  Future<void> setLocale(Locale locale) async {
    if (!_isSupported(locale.languageCode)) {
      debugPrint('Locale ${locale.languageCode} is not supported');
      return;
    }

    state = locale;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_localeKey, locale.languageCode);
    } catch (e) {
      debugPrint('Error saving locale: $e');
    }
  }

  /// Change la langue par code
  Future<void> setLanguageCode(String languageCode) async {
    await setLocale(Locale(languageCode));
  }

  /// Bascule entre français et anglais
  Future<void> toggleLocale() async {
    final newLocale = state.languageCode == 'fr' 
        ? const Locale('en') 
        : const Locale('fr');
    await setLocale(newLocale);
  }

  /// Obtient le nom de la langue actuelle
  String get currentLanguageName => localeNames[state.languageCode] ?? 'Unknown';

  /// Obtient le code de la langue actuelle
  String get currentLanguageCode => state.languageCode;
}

/// Extension pour faciliter l'accès aux traductions
extension LocaleExtension on BuildContext {
  /// Obtient le nom de la langue pour un code donné
  String getLanguageName(String code) {
    return LocaleNotifier.localeNames[code] ?? code;
  }
}
