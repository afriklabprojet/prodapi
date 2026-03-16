import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:battery_plus/battery_plus.dart' as bp;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';

/// Seuils de batterie pour le mode économie
class BatteryThresholds {
  /// Seuil critique: réduire au minimum
  static const int critical = 10;
  
  /// Seuil bas: activer économie batterie
  static const int low = 20;
  
  /// Seuil normal: mode standard
  static const int normal = 50;
}

/// Mode d'économie de batterie actif
enum BatterySaverMode {
  /// Mode normal - GPS haute fréquence
  normal,
  
  /// Mode économie - GPS basse fréquence
  saver,
  
  /// Mode critique - GPS minimal, uniquement pour livraison
  critical,
  
  /// En charge - mode normal même si batterie basse
  charging,
}

/// État de la batterie avec niveau et mode
class BatteryStatus {
  final int level;
  final BatterySaverMode mode;
  final BatteryStatus? state;
  final bool isCharging;
  final DateTime lastUpdated;
  
  BatteryStatus({
    required this.level,
    required this.mode,
    this.state,
    required this.isCharging,
    required this.lastUpdated,
  });
  
  BatteryStatus copyWith({
    int? level,
    BatterySaverMode? mode,
    BatteryStatus? state,
    bool? isCharging,
    DateTime? lastUpdated,
  }) {
    return BatteryStatus(
      level: level ?? this.level,
      mode: mode ?? this.mode,
      state: state ?? this.state,
      isCharging: isCharging ?? this.isCharging,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
  
  /// Texte descriptif du mode
  String get modeDescription {
    switch (mode) {
      case BatterySaverMode.normal:
        return 'GPS précis';
      case BatterySaverMode.saver:
        return 'Économie activée';
      case BatterySaverMode.critical:
        return 'Mode minimal';
      case BatterySaverMode.charging:
        return 'En charge';
    }
  }
  
  /// Icône correspondant au mode
  String get modeIcon {
    switch (mode) {
      case BatterySaverMode.normal:
        return '🔋';
      case BatterySaverMode.saver:
        return '🔋';
      case BatterySaverMode.critical:
        return '🪫';
      case BatterySaverMode.charging:
        return '⚡';
    }
  }
  
  /// Intervalle de mise à jour GPS recommandé (en secondes)
  int get gpsUpdateIntervalSeconds {
    switch (mode) {
      case BatterySaverMode.normal:
        return 5;  // Mise à jour toutes les 5 secondes
      case BatterySaverMode.saver:
        return 15; // Mise à jour toutes les 15 secondes
      case BatterySaverMode.critical:
        return 30; // Mise à jour toutes les 30 secondes
      case BatterySaverMode.charging:
        return 5;  // Mode normal quand en charge
    }
  }
  
  /// Précision GPS recommandée
  LocationAccuracy get gpsAccuracy {
    switch (mode) {
      case BatterySaverMode.normal:
        return LocationAccuracy.high;
      case BatterySaverMode.saver:
        return LocationAccuracy.medium;
      case BatterySaverMode.critical:
        return LocationAccuracy.low;
      case BatterySaverMode.charging:
        return LocationAccuracy.high;
    }
  }
  
  /// Distance minimale avant mise à jour (en mètres)
  int get gpsDistanceFilter {
    switch (mode) {
      case BatterySaverMode.normal:
        return 10;  // 10 mètres
      case BatterySaverMode.saver:
        return 30;  // 30 mètres
      case BatterySaverMode.critical:
        return 50;  // 50 mètres
      case BatterySaverMode.charging:
        return 10;
    }
  }
}

/// Service de gestion de la batterie et économie d'énergie
class BatterySaverService {
  final bp.Battery _battery = bp.Battery();
  StreamSubscription<BatteryStatus>? _batterySubscription;
  
  // ignore: unused_field
  int _lastKnownLevel = 100;
  bool _isCharging = false;
  bool _batterySaverEnabled = true;
  
  /// Vérifier l'état initial de la batterie
  Future<BatteryStatus> checkBattery() async {
    try {
      final level = await _battery.batteryLevel;
      final state = await _battery.batteryState;
      _lastKnownLevel = level;
      _isCharging = state == bp.BatteryState.charging || state == bp.BatteryState.full;
      
      return BatteryStatus(
        level: level,
        mode: _calculateMode(level, _isCharging),
        isCharging: _isCharging,
        lastUpdated: DateTime.now(),
      );
    } catch (e) {
      if (kDebugMode) debugPrint('Erreur vérification batterie: $e');
      return BatteryStatus(
        level: 100,
        mode: BatterySaverMode.normal,
        isCharging: false,
        lastUpdated: DateTime.now(),
      );
    }
  }
  
  /// Calculer le mode selon le niveau et l'état de charge
  BatterySaverMode _calculateMode(int level, bool isCharging) {
    if (!_batterySaverEnabled) return BatterySaverMode.normal;
    if (isCharging) return BatterySaverMode.charging;
    if (level <= BatteryThresholds.critical) return BatterySaverMode.critical;
    if (level <= BatteryThresholds.low) return BatterySaverMode.saver;
    return BatterySaverMode.normal;
  }
  
  /// Écouter les changements de batterie
  Stream<BatteryStatus> watchBattery() {
    return _battery.onBatteryStateChanged.asyncMap((state) async {
      _isCharging = state == bp.BatteryState.charging || state == bp.BatteryState.full;
      final level = await _battery.batteryLevel;
      _lastKnownLevel = level;
      
      return BatteryStatus(
        level: level,
        mode: _calculateMode(level, _isCharging),
        isCharging: _isCharging,
        lastUpdated: DateTime.now(),
      );
    });
  }
  
  /// Activer/désactiver le mode économie batterie
  Future<void> setBatterySaverEnabled(bool enabled) async {
    _batterySaverEnabled = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('battery_saver_enabled', enabled);
  }
  
  /// Vérifier si le mode économie est activé
  Future<bool> isBatterySaverEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    _batterySaverEnabled = prefs.getBool('battery_saver_enabled') ?? true;
    return _batterySaverEnabled;
  }
  
  /// Obtenir les paramètres GPS optimisés selon la batterie
  LocationSettings getOptimizedLocationSettings(BatteryStatus state) {
    return LocationSettings(
      accuracy: state.gpsAccuracy,
      distanceFilter: state.gpsDistanceFilter,
    );
  }
  
  /// Nettoyer les ressources
  void dispose() {
    _batterySubscription?.cancel();
  }
}

/// Provider pour le service de batterie
final batterySaverServiceProvider = Provider<BatterySaverService>((ref) {
  final service = BatterySaverService();
  ref.onDispose(() => service.dispose());
  return service;
});

/// Provider pour l'état actuel de la batterie
final batteryStateProvider = StreamProvider<BatteryStatus>((ref) async* {
  final service = ref.watch(batterySaverServiceProvider);
  
  // État initial
  yield await service.checkBattery();
  
  // Écouter les changements
  await for (final state in service.watchBattery()) {
    yield state;
  }
});

/// Provider pour savoir si le mode économie est activé
final batterySaverEnabledProvider = FutureProvider<bool>((ref) async {
  final service = ref.watch(batterySaverServiceProvider);
  return service.isBatterySaverEnabled();
});
