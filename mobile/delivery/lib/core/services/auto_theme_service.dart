import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service de gestion du thème intelligent (Mode Sombre Automatique)
///
/// Fonctionnalités :
/// - Détection automatique jour/nuit basée sur l'heure
/// - Heures personnalisables pour le passage en mode sombre
/// - Option de suivre la luminosité ambiante (si disponible)
/// - Économie de batterie du coursier la nuit
class AutoThemeService {
  AutoThemeService._();
  static final AutoThemeService instance = AutoThemeService._();

  // Clés de préférences
  static const String _keyAutoThemeEnabled = 'auto_theme_enabled';
  static const String _keyNightStartHour = 'night_start_hour';
  static const String _keyNightEndHour = 'night_end_hour';
  static const String _keyUseSunriseSunset = 'use_sunrise_sunset';

  SharedPreferences? _prefs;
  Timer? _checkTimer;
  
  // Callback pour notifier le changement de thème
  void Function(bool isDark)? onThemeChange;

  // Configuration par défaut
  int _nightStartHour = 19;  // 19h00 - début mode sombre
  int _nightEndHour = 6;      // 6h00 - fin mode sombre
  bool _isEnabled = false;
  // ignore: unused_field
  bool _useSunriseSunset = false;

  // État actuel
  bool _currentlyDark = false;
  bool get isCurrentlyDark => _currentlyDark;
  bool get isEnabled => _isEnabled;
  int get nightStartHour => _nightStartHour;
  int get nightEndHour => _nightEndHour;

  /// Initialiser le service
  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
    await _loadSettings();
    
    if (_isEnabled) {
      _startAutoCheck();
    }
    
    if (kDebugMode) {
      debugPrint('🌙 [AutoTheme] Initialisé - Activé: $_isEnabled');
      debugPrint('🌙 [AutoTheme] Heures sombres: ${_nightStartHour}h - ${_nightEndHour}h');
    }
  }

  /// Charger les paramètres
  Future<void> _loadSettings() async {
    _isEnabled = _prefs?.getBool(_keyAutoThemeEnabled) ?? false;
    _nightStartHour = _prefs?.getInt(_keyNightStartHour) ?? 19;
    _nightEndHour = _prefs?.getInt(_keyNightEndHour) ?? 6;
    _useSunriseSunset = _prefs?.getBool(_keyUseSunriseSunset) ?? false;
  }

  /// Activer/désactiver le mode automatique
  Future<void> setEnabled(bool enabled) async {
    _isEnabled = enabled;
    await _prefs?.setBool(_keyAutoThemeEnabled, enabled);
    
    if (enabled) {
      _startAutoCheck();
      _checkAndNotify();
    } else {
      _stopAutoCheck();
    }
    
    if (kDebugMode) {
      debugPrint('🌙 [AutoTheme] Mode auto ${enabled ? "activé" : "désactivé"}');
    }
  }

  /// Définir l'heure de début du mode sombre
  Future<void> setNightStartHour(int hour) async {
    _nightStartHour = hour.clamp(0, 23);
    await _prefs?.setInt(_keyNightStartHour, _nightStartHour);
    _checkAndNotify();
  }

  /// Définir l'heure de fin du mode sombre
  Future<void> setNightEndHour(int hour) async {
    _nightEndHour = hour.clamp(0, 23);
    await _prefs?.setInt(_keyNightEndHour, _nightEndHour);
    _checkAndNotify();
  }

  /// Vérifier si c'est l'heure du mode sombre
  bool isNightTime() {
    final now = DateTime.now();
    final currentHour = now.hour;
    
    // Cas où la période de nuit traverse minuit
    if (_nightStartHour > _nightEndHour) {
      // Ex: 19h -> 6h : sombre si heure >= 19 OU heure < 6
      return currentHour >= _nightStartHour || currentHour < _nightEndHour;
    } else {
      // Cas normal (ne traverse pas minuit)
      return currentHour >= _nightStartHour && currentHour < _nightEndHour;
    }
  }

  /// Obtenir le temps restant avant le prochain changement
  Duration getTimeUntilNextChange() {
    final now = DateTime.now();
    final isDark = isNightTime();
    
    int targetHour = isDark ? _nightEndHour : _nightStartHour;
    
    // Calculer le prochain changement
    var nextChange = DateTime(now.year, now.month, now.day, targetHour, 0);
    
    if (nextChange.isBefore(now)) {
      nextChange = nextChange.add(const Duration(days: 1));
    }
    
    return nextChange.difference(now);
  }

  /// Obtenir une description de l'état actuel
  String getStatusDescription() {
    if (!_isEnabled) {
      return 'Mode automatique désactivé';
    }
    
    final isDark = isNightTime();
    final timeUntil = getTimeUntilNextChange();
    final hours = timeUntil.inHours;
    final minutes = timeUntil.inMinutes % 60;
    
    if (isDark) {
      return 'Mode sombre actif • Passage au clair dans ${hours}h${minutes.toString().padLeft(2, '0')}';
    } else {
      return 'Mode clair actif • Passage au sombre dans ${hours}h${minutes.toString().padLeft(2, '0')}';
    }
  }

  /// Démarrer la vérification automatique
  void _startAutoCheck() {
    _stopAutoCheck();
    
    // Vérifier toutes les minutes
    _checkTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      _checkAndNotify();
    });
    
    // Vérification immédiate
    _checkAndNotify();
  }

  /// Arrêter la vérification automatique
  void _stopAutoCheck() {
    _checkTimer?.cancel();
    _checkTimer = null;
  }

  /// Vérifier et notifier si changement nécessaire
  void _checkAndNotify() {
    if (!_isEnabled) return;
    
    final shouldBeDark = isNightTime();
    
    if (shouldBeDark != _currentlyDark) {
      _currentlyDark = shouldBeDark;
      onThemeChange?.call(shouldBeDark);
      
      if (kDebugMode) {
        debugPrint('🌙 [AutoTheme] Changement de thème: ${shouldBeDark ? "SOMBRE" : "CLAIR"}');
      }
    }
  }

  /// Forcer une vérification du thème
  void checkNow() {
    _checkAndNotify();
  }

  /// Libérer les ressources
  void dispose() {
    _stopAutoCheck();
    onThemeChange = null;
  }

  /// Obtenir l'icône appropriée pour l'état actuel
  String getIcon() {
    if (!_isEnabled) return '🔆';
    return isNightTime() ? '🌙' : '☀️';
  }

  /// Créer un résumé pour l'affichage
  Map<String, dynamic> getSummary() {
    return {
      'enabled': _isEnabled,
      'is_night': isNightTime(),
      'night_start': _nightStartHour,
      'night_end': _nightEndHour,
      'status': getStatusDescription(),
      'icon': getIcon(),
    };
  }
}

/// Extension pour faciliter l'utilisation dans les widgets
extension AutoThemeExtension on AutoThemeService {
  /// Format lisible de l'heure
  String formatHour(int hour) {
    return '${hour.toString().padLeft(2, '0')}:00';
  }

  /// Description du créneau de nuit
  String get nightScheduleDescription {
    return 'Mode sombre de ${formatHour(_nightStartHour)} à ${formatHour(_nightEndHour)}';
  }
}
