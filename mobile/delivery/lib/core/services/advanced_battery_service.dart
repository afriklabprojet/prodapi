import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:battery_plus/battery_plus.dart' as bp;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';

/// Configuration avancée des modes d'économie d'énergie
class PowerProfile {
  final String id;
  final String name;
  final String description;
  final int gpsIntervalSeconds;
  final int distanceFilterMeters;
  final LocationAccuracy accuracy;
  final bool enableAnimations;
  final bool enableVibration;
  final bool enableAutoSync;
  final int syncIntervalMinutes;
  final double brightnessMultiplier;

  const PowerProfile({
    required this.id,
    required this.name,
    required this.description,
    required this.gpsIntervalSeconds,
    required this.distanceFilterMeters,
    required this.accuracy,
    this.enableAnimations = true,
    this.enableVibration = true,
    this.enableAutoSync = true,
    this.syncIntervalMinutes = 5,
    this.brightnessMultiplier = 1.0,
  });

  /// Profil performances maximales
  static const performance = PowerProfile(
    id: 'performance',
    name: 'Performance',
    description: 'GPS haute précision, toutes les fonctionnalités activées',
    gpsIntervalSeconds: 3,
    distanceFilterMeters: 5,
    accuracy: LocationAccuracy.bestForNavigation,
    enableAnimations: true,
    enableVibration: true,
    enableAutoSync: true,
    syncIntervalMinutes: 2,
    brightnessMultiplier: 1.0,
  );

  /// Profil équilibré
  static const balanced = PowerProfile(
    id: 'balanced',
    name: 'Équilibré',
    description: 'Bon compromis entre précision et autonomie',
    gpsIntervalSeconds: 10,
    distanceFilterMeters: 15,
    accuracy: LocationAccuracy.high,
    enableAnimations: true,
    enableVibration: true,
    enableAutoSync: true,
    syncIntervalMinutes: 5,
    brightnessMultiplier: 0.9,
  );

  /// Profil économie d'énergie
  static const batterySaver = PowerProfile(
    id: 'battery_saver',
    name: 'Économie',
    description: 'Réduit la consommation, GPS moins fréquent',
    gpsIntervalSeconds: 20,
    distanceFilterMeters: 30,
    accuracy: LocationAccuracy.medium,
    enableAnimations: false,
    enableVibration: false,
    enableAutoSync: true,
    syncIntervalMinutes: 10,
    brightnessMultiplier: 0.7,
  );

  /// Profil ultra économie
  static const ultraSaver = PowerProfile(
    id: 'ultra_saver',
    name: 'Ultra économie',
    description: 'Économie maximale, GPS minimal',
    gpsIntervalSeconds: 45,
    distanceFilterMeters: 50,
    accuracy: LocationAccuracy.low,
    enableAnimations: false,
    enableVibration: false,
    enableAutoSync: false,
    syncIntervalMinutes: 30,
    brightnessMultiplier: 0.5,
  );

  /// Tous les profils disponibles
  static List<PowerProfile> get all => [
        performance,
        balanced,
        batterySaver,
        ultraSaver,
      ];

  /// Trouve un profil par ID
  static PowerProfile? findById(String id) {
    try {
      return all.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }
}

/// Statistiques d'utilisation de la batterie
class BatteryUsageStats {
  final double averageDrainPerHour;
  final int estimatedMinutesRemaining;
  final Map<String, double> usageByFeature;
  final DateTime lastFullCharge;
  final int cyclesSinceCharge;

  BatteryUsageStats({
    required this.averageDrainPerHour,
    required this.estimatedMinutesRemaining,
    this.usageByFeature = const {},
    required this.lastFullCharge,
    this.cyclesSinceCharge = 0,
  });

  String get remainingTimeFormatted {
    if (estimatedMinutesRemaining < 60) {
      return '$estimatedMinutesRemaining min';
    }
    final hours = estimatedMinutesRemaining ~/ 60;
    final minutes = estimatedMinutesRemaining % 60;
    return '${hours}h${minutes > 0 ? ' ${minutes}min' : ''}';
  }
}

/// État détaillé de la batterie
class AdvancedBatteryState {
  final int level;
  final bool isCharging;
  final PowerProfile activeProfile;
  final bool autoOptimizeEnabled;
  final BatteryUsageStats? stats;
  final DateTime lastUpdated;
  final List<int> levelHistory;

  AdvancedBatteryState({
    required this.level,
    required this.isCharging,
    required this.activeProfile,
    this.autoOptimizeEnabled = true,
    this.stats,
    required this.lastUpdated,
    this.levelHistory = const [],
  });

  AdvancedBatteryState copyWith({
    int? level,
    bool? isCharging,
    PowerProfile? activeProfile,
    bool? autoOptimizeEnabled,
    BatteryUsageStats? stats,
    DateTime? lastUpdated,
    List<int>? levelHistory,
  }) {
    return AdvancedBatteryState(
      level: level ?? this.level,
      isCharging: isCharging ?? this.isCharging,
      activeProfile: activeProfile ?? this.activeProfile,
      autoOptimizeEnabled: autoOptimizeEnabled ?? this.autoOptimizeEnabled,
      stats: stats ?? this.stats,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      levelHistory: levelHistory ?? this.levelHistory,
    );
  }

  /// Niveau de batterie critique
  bool get isCritical => level <= 10 && !isCharging;

  /// Niveau de batterie bas
  bool get isLow => level <= 20 && !isCharging;

  /// Couleur associée au niveau
  int get levelColorValue {
    if (isCharging) return 0xFF4CAF50; // Green
    if (level <= 10) return 0xFFF44336; // Red
    if (level <= 20) return 0xFFFF9800; // Orange
    if (level <= 50) return 0xFFFFEB3B; // Yellow
    return 0xFF4CAF50; // Green
  }
}

/// Recommandation d'optimisation
class OptimizationTip {
  final String id;
  final String title;
  final String description;
  final String icon;
  final int estimatedSavingsPercent;
  final VoidCallback? action;
  final bool isApplied;

  OptimizationTip({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.estimatedSavingsPercent,
    this.action,
    this.isApplied = false,
  });
}

/// Service avancé de gestion de batterie
class AdvancedBatteryService {
  final bp.Battery _battery = bp.Battery();
  final List<int> _levelHistory = [];
  DateTime? _lastFullCharge;
  int _cyclesSinceCharge = 0;

  PowerProfile _activeProfile = PowerProfile.balanced;
  bool _autoOptimizeEnabled = true;

  /// Initialiser le service
  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    
    final profileId = prefs.getString('power_profile') ?? 'balanced';
    _activeProfile = PowerProfile.findById(profileId) ?? PowerProfile.balanced;
    _autoOptimizeEnabled = prefs.getBool('auto_optimize') ?? true;

    // Charger l'historique
    final historyString = prefs.getString('battery_level_history') ?? '';
    if (historyString.isNotEmpty) {
      _levelHistory.addAll(
        historyString.split(',').map((s) => int.tryParse(s) ?? 0).toList(),
      );
    }

    final lastChargeStr = prefs.getString('last_full_charge');
    if (lastChargeStr != null) {
      _lastFullCharge = DateTime.tryParse(lastChargeStr);
    }
  }

  /// Vérifier l'état actuel de la batterie
  Future<AdvancedBatteryState> checkBattery() async {
    try {
      final level = await _battery.batteryLevel;
      final state = await _battery.batteryState;
      final isCharging = state == bp.BatteryState.charging || state == bp.BatteryState.full;

      // Mettre à jour l'historique
      _levelHistory.add(level);
      if (_levelHistory.length > 100) {
        _levelHistory.removeAt(0);
      }

      // Détecter charge complète
      if (state == bp.BatteryState.full) {
        _lastFullCharge = DateTime.now();
        _cyclesSinceCharge = 0;
      }

      // Auto-optimisation
      PowerProfile effectiveProfile = _activeProfile;
      if (_autoOptimizeEnabled && !isCharging) {
        effectiveProfile = _getOptimalProfile(level);
      } else if (isCharging) {
        effectiveProfile = PowerProfile.performance;
      }

      return AdvancedBatteryState(
        level: level,
        isCharging: isCharging,
        activeProfile: effectiveProfile,
        autoOptimizeEnabled: _autoOptimizeEnabled,
        stats: _calculateStats(level),
        lastUpdated: DateTime.now(),
        levelHistory: List.from(_levelHistory),
      );
    } catch (e) {
      if (kDebugMode) debugPrint('❌ [Battery] Erreur: $e');
      return AdvancedBatteryState(
        level: 100,
        isCharging: false,
        activeProfile: _activeProfile,
        lastUpdated: DateTime.now(),
      );
    }
  }

  /// Stream des changements de batterie
  Stream<AdvancedBatteryState> watchBattery() {
    return _battery.onBatteryStateChanged.asyncMap((_) async {
      return await checkBattery();
    });
  }

  /// Profil optimal selon le niveau
  PowerProfile _getOptimalProfile(int level) {
    if (level <= 10) return PowerProfile.ultraSaver;
    if (level <= 20) return PowerProfile.batterySaver;
    if (level <= 50) return PowerProfile.balanced;
    return _activeProfile;
  }

  /// Calcule les statistiques d'utilisation
  BatteryUsageStats _calculateStats(int currentLevel) {
    double drainPerHour = 0;
    int estimatedMinutes = 0;

    if (_levelHistory.length >= 2) {
      // Calcul basé sur les 10 dernières mesures
      final recentHistory = _levelHistory.length > 10
          ? _levelHistory.sublist(_levelHistory.length - 10)
          : _levelHistory;

      if (recentHistory.isNotEmpty) {
        final totalDrain = recentHistory.first - recentHistory.last;
        // Estimation: 1 mesure ≈ 5 minutes
        drainPerHour = (totalDrain / (recentHistory.length * 5)) * 60;
        drainPerHour = drainPerHour.clamp(0, 100);

        if (drainPerHour > 0) {
          estimatedMinutes = ((currentLevel / drainPerHour) * 60).round();
        } else {
          estimatedMinutes = currentLevel * 10; // Estimation par défaut
        }
      }
    } else {
      estimatedMinutes = currentLevel * 6; // ~10h pour 100%
    }

    return BatteryUsageStats(
      averageDrainPerHour: drainPerHour,
      estimatedMinutesRemaining: estimatedMinutes.clamp(0, 1440), // Max 24h
      lastFullCharge: _lastFullCharge ?? DateTime.now(),
      cyclesSinceCharge: _cyclesSinceCharge,
      usageByFeature: {
        'GPS': 35.0,
        'Écran': 30.0,
        'Réseau': 20.0,
        'Autres': 15.0,
      },
    );
  }

  /// Définir le profil d'énergie
  Future<void> setProfile(PowerProfile profile) async {
    _activeProfile = profile;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('power_profile', profile.id);
    if (kDebugMode) debugPrint('⚡ [Battery] Profil changé: ${profile.name}');
  }

  /// Activer/désactiver l'auto-optimisation
  Future<void> setAutoOptimize(bool enabled) async {
    _autoOptimizeEnabled = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('auto_optimize', enabled);
  }

  /// Obtenir les réglages GPS optimisés
  LocationSettings getOptimizedGpsSettings(AdvancedBatteryState state) {
    return LocationSettings(
      accuracy: state.activeProfile.accuracy,
      distanceFilter: state.activeProfile.distanceFilterMeters,
    );
  }

  /// Obtenir les conseils d'optimisation
  List<OptimizationTip> getOptimizationTips(AdvancedBatteryState state) {
    final tips = <OptimizationTip>[];

    if (state.activeProfile != PowerProfile.batterySaver &&
        state.activeProfile != PowerProfile.ultraSaver &&
        state.level <= 30) {
      tips.add(OptimizationTip(
        id: 'enable_saver',
        title: 'Activer le mode économie',
        description: 'Réduisez la fréquence GPS pour économiser la batterie',
        icon: '🔋',
        estimatedSavingsPercent: 20,
      ));
    }

    if (_autoOptimizeEnabled == false && state.level <= 50) {
      tips.add(OptimizationTip(
        id: 'enable_auto',
        title: 'Activer l\'optimisation auto',
        description: 'Laissez l\'application ajuster les réglages automatiquement',
        icon: '⚡',
        estimatedSavingsPercent: 15,
      ));
    }

    if (state.activeProfile.enableAnimations && state.level <= 20) {
      tips.add(OptimizationTip(
        id: 'disable_animations',
        title: 'Désactiver les animations',
        description: 'Économise de l\'énergie en désactivant les effets visuels',
        icon: '✨',
        estimatedSavingsPercent: 5,
      ));
    }

    return tips;
  }

  /// Sauvegarder l'état
  Future<void> saveState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'battery_level_history',
      _levelHistory.join(','),
    );
    if (_lastFullCharge != null) {
      await prefs.setString(
        'last_full_charge',
        _lastFullCharge!.toIso8601String(),
      );
    }
  }

  void dispose() {
    saveState();
  }
}

/// Provider pour le service avancé de batterie
final advancedBatteryServiceProvider = Provider<AdvancedBatteryService>((ref) {
  final service = AdvancedBatteryService();
  service.initialize();
  ref.onDispose(() => service.dispose());
  return service;
});

/// Provider pour l'état avancé de la batterie
final advancedBatteryStateProvider = StreamProvider<AdvancedBatteryState>((ref) async* {
  final service = ref.watch(advancedBatteryServiceProvider);

  // État initial
  yield await service.checkBattery();

  // Écouter les changements
  await for (final state in service.watchBattery()) {
    yield state;
  }
});

/// Provider pour le profil actif
final activePowerProfileProvider = Provider<PowerProfile>((ref) {
  final batteryState = ref.watch(advancedBatteryStateProvider);
  return batteryState.whenOrNull(data: (state) => state.activeProfile) ??
      PowerProfile.balanced;
});

/// Provider pour les conseils d'optimisation
final optimizationTipsProvider = Provider<List<OptimizationTip>>((ref) {
  final service = ref.watch(advancedBatteryServiceProvider);
  final batteryState = ref.watch(advancedBatteryStateProvider);

  return batteryState.whenOrNull(
        data: (state) => service.getOptimizationTips(state),
      ) ??
      [];
});
