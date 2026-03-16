import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';
import 'package:dio/dio.dart';
import '../constants/api_constants.dart';
import 'secure_token_service.dart';

/// Mode de tracking selon l'activité
enum TrackingMode {
  idle,       // Pas de livraison en cours -> basse fréquence
  delivering, // Livraison en cours -> haute fréquence
  navigation, // Navigation active -> très haute fréquence
}

/// Vérifie si la plateforme supporte le background location
bool get _isSupported => !kIsWeb;

/// Service pour la gestion optimisée de la localisation en arrière-plan
/// Utilise Workmanager pour économiser la batterie
class BackgroundLocationService {
  static const String taskName = 'backgroundLocationUpdate';
  static const String uniqueTaskName = 'com.drpharma.courier.locationUpdate';
  
  /// Initialiser le service de localisation en arrière-plan
  static Future<void> initialize() async {
    if (!_isSupported) {
      if (kDebugMode) debugPrint('⚠️ Background location not supported on this platform');
      return;
    }
    await Workmanager().initialize(
      callbackDispatcher,
    );
  }
  
  /// Démarrer les mises à jour de position en arrière-plan
  /// [intervalMinutes] - Intervalle entre chaque mise à jour (min 15 minutes sur Android)
  static Future<void> startBackgroundUpdates({int intervalMinutes = 15}) async {
    if (!_isSupported) return;
    
    await Workmanager().registerPeriodicTask(
      uniqueTaskName,
      taskName,
      frequency: Duration(minutes: intervalMinutes),
      constraints: Constraints(
        networkType: NetworkType.connected,
        requiresBatteryNotLow: false,
        requiresCharging: false,
        requiresDeviceIdle: false,
        requiresStorageNotLow: false,
      ),
      existingWorkPolicy: ExistingPeriodicWorkPolicy.replace,
      backoffPolicy: BackoffPolicy.linear,
      backoffPolicyDelay: const Duration(minutes: 5),
    );
    
    // Sauvegarder l'état
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('background_location_enabled', true);
  }
  
  /// Arrêter les mises à jour en arrière-plan
  static Future<void> stopBackgroundUpdates() async {
    if (!_isSupported) return;
    
    await Workmanager().cancelByUniqueName(uniqueTaskName);
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('background_location_enabled', false);
  }
  
  /// Vérifier si le service est actif
  static Future<bool> isEnabled() async {
    if (!_isSupported) return false;
    
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('background_location_enabled') ?? false;
  }
}

/// Callback principal pour Workmanager (doit être une fonction top-level)
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((taskName, inputData) async {
    try {
      if (taskName == BackgroundLocationService.taskName) {
        await _updateLocationInBackground();
        return true;
      }
      return false;
    } catch (e) {
      if (kDebugMode) debugPrint('Background task error: $e');
      return false;
    }
  });
}

/// Effectuer la mise à jour de position en arrière-plan
Future<void> _updateLocationInBackground() async {
  try {
    // Vérifier les permissions
    final permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return;
    }
    
    // Récupérer le token d'authentification
    final token = await SecureTokenService.instance.getToken();
    if (token == null) return;
    
    // Obtenir la position actuelle avec précision optimisée pour la batterie
    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.medium, // Précision moyenne = meilleure batterie
        distanceFilter: 50, // Mettre à jour seulement si déplacé de 50m
      ),
    );
    
    // Envoyer la position au serveur
    final dio = Dio(BaseOptions(
      baseUrl: ApiConstants.baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    ));
    
    await dio.post(
      ApiConstants.location,
      data: {
        'latitude': position.latitude,
        'longitude': position.longitude,
        'accuracy': position.accuracy,
        'speed': position.speed,
        'heading': position.heading,
        'timestamp': position.timestamp.toIso8601String(),
        'source': 'background',
      },
    );
    
    // Sauvegarder la dernière position connue localement
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('last_latitude', position.latitude);
    await prefs.setDouble('last_longitude', position.longitude);
    await prefs.setString('last_location_time', DateTime.now().toIso8601String());
    
  } catch (e) {
    if (kDebugMode) debugPrint('Background location update failed: $e');
  }
}

/// Service pour la gestion intelligente de la localisation en temps réel
class SmartLocationService {
  
  /// Démarrer le tracking avec le mode approprié
  static Future<void> startTracking(TrackingMode mode) async {
    // Settings are applied when getting location stream
    _getSettingsForMode(mode);
  }
  
  /// Arrêter le tracking
  static void stopTracking() {
    // Cleanup if needed
  }
  
  /// Obtenir les paramètres de localisation selon le mode
  static LocationSettings _getSettingsForMode(TrackingMode mode) {
    switch (mode) {
      case TrackingMode.idle:
        return const LocationSettings(
          accuracy: LocationAccuracy.low,
          distanceFilter: 200, // Update tous les 200m
        );
      case TrackingMode.delivering:
        return const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 20, // Update tous les 20m
        );
      case TrackingMode.navigation:
        return const LocationSettings(
          accuracy: LocationAccuracy.bestForNavigation,
          distanceFilter: 5, // Update tous les 5m
        );
    }
  }
  
  /// Stream de position avec paramètres adaptatifs
  static Stream<Position> getPositionStream(TrackingMode mode) {
    return Geolocator.getPositionStream(
      locationSettings: _getSettingsForMode(mode),
    );
  }
  
  /// Obtenir la dernière position connue (moins de consommation batterie)
  static Future<Position?> getLastKnownPosition() async {
    return await Geolocator.getLastKnownPosition();
  }
  
  /// Calculer la distance entre deux points
  static double calculateDistance(
    double startLat, double startLng,
    double endLat, double endLng,
  ) {
    return Geolocator.distanceBetween(startLat, startLng, endLat, endLng);
  }
}

/// Provider pour gérer l'état du service de localisation
class LocationBatteryManager {
  static const int _highBatteryThreshold = 50; // 50%
  static const int _lowBatteryThreshold = 20;  // 20%
  
  /// Obtenir les paramètres de localisation adaptés au niveau de batterie
  static Future<LocationSettings> getOptimalSettings({
    required bool isDelivering,
    required int batteryLevel,
  }) async {
    // Si batterie très basse, réduire la précision
    if (batteryLevel < _lowBatteryThreshold) {
      return const LocationSettings(
        accuracy: LocationAccuracy.low,
        distanceFilter: 100,
      );
    }
    
    // Si en livraison et batterie correcte
    if (isDelivering) {
      if (batteryLevel > _highBatteryThreshold) {
        return const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10,
        );
      } else {
        return const LocationSettings(
          accuracy: LocationAccuracy.medium,
          distanceFilter: 25,
        );
      }
    }
    
    // Mode idle
    return const LocationSettings(
      accuracy: LocationAccuracy.low,
      distanceFilter: 100,
    );
  }
}
