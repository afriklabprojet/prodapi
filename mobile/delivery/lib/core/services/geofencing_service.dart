import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'location_service.dart';
import 'firestore_tracking_service.dart';

/// Seuils de distance pour le geofencing (en mètres)
class GeofenceThresholds {
  /// Distance pour déclencher le statut "arriving" (approche)
  static const double approaching = 300.0;

  /// Distance pour déclencher le statut "arrived" (arrivé)
  static const double arrived = 50.0;

  /// Distance minimum pour considérer que le livreur a quitté la zone
  static const double departed = 500.0;
}

/// État d'une zone geofencée
enum GeofenceState {
  /// En dehors de toutes les zones
  outside,

  /// À proximité (300m) — statut "arriving"
  approaching,

  /// Arrivé sur place (50m) — statut "arrived"
  arrived,
}

/// Représente une zone de geofence surveillée
class GeofenceZone {
  final int deliveryId;
  final String type; // 'pickup' ou 'dropoff'
  final double latitude;
  final double longitude;
  final String? name;
  GeofenceState state;

  GeofenceZone({
    required this.deliveryId,
    required this.type,
    required this.latitude,
    required this.longitude,
    this.name,
    this.state = GeofenceState.outside,
  });

  double distanceTo(double lat, double lng) {
    return Geolocator.distanceBetween(latitude, longitude, lat, lng);
  }
}

/// Événement déclenché par le geofencing
class GeofenceEvent {
  final GeofenceZone zone;
  final GeofenceState previousState;
  final GeofenceState newState;
  final double distance;
  final DateTime timestamp;

  GeofenceEvent({
    required this.zone,
    required this.previousState,
    required this.newState,
    required this.distance,
  }) : timestamp = DateTime.now();

  bool get isArriving =>
      previousState == GeofenceState.outside &&
      newState == GeofenceState.approaching;

  bool get isArrived => newState == GeofenceState.arrived;

  bool get isDeparted =>
      previousState != GeofenceState.outside &&
      newState == GeofenceState.outside;
}

/// Service de geofencing pour la détection automatique d'arrivée
///
/// Surveille la position du livreur et déclenche automatiquement :
/// - "approaching" quand le livreur est à moins de 300m de la destination
/// - "arrived" quand le livreur est à moins de 50m de la destination
///
/// Intégration :
/// - Met à jour le statut Firestore via FirestoreTrackingService
/// - Émet des événements via le stream [events] pour l'UI (vibration, notification)
class GeofencingService {
  final LocationService _locationService;
  final FirestoreTrackingService _firestoreTracking;

  /// Zones surveillées
  final List<GeofenceZone> _zones = [];

  /// Stream d'événements de geofencing
  final StreamController<GeofenceEvent> _eventController =
      StreamController<GeofenceEvent>.broadcast();

  StreamSubscription<Position>? _locationSubscription;
  bool _isEnabled = true;
  bool _isMonitoring = false;

  /// IDs de livraisons déjà marquées "arrived" (éviter les doublons)
  final Set<String> _arrivedKeys = {};

  GeofencingService(this._locationService, this._firestoreTracking);

  /// Stream d'événements (pour l'UI)
  Stream<GeofenceEvent> get events => _eventController.stream;

  /// Active/désactive le geofencing
  bool get isEnabled => _isEnabled;
  set isEnabled(bool value) {
    _isEnabled = value;
    _savePreference(value);
    if (!value) {
      stopMonitoring();
    }
  }

  /// Nombre de zones surveillées
  int get zoneCount => _zones.length;

  /// Charger la préférence utilisateur
  Future<void> loadPreference() async {
    final prefs = await SharedPreferences.getInstance();
    _isEnabled = prefs.getBool('geofencing_enabled') ?? true;
  }

  Future<void> _savePreference(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('geofencing_enabled', enabled);
  }

  /// Ajouter une zone de geofence à surveiller
  void addZone(GeofenceZone zone) {
    // Éviter les doublons
    _zones.removeWhere(
        (z) => z.deliveryId == zone.deliveryId && z.type == zone.type);
    _zones.add(zone);
    if (kDebugMode) {
      debugPrint(
          '🎯 [Geofence] Zone ajoutée: ${zone.type} livraison #${zone.deliveryId} (${zone.latitude}, ${zone.longitude})');
    }
  }

  /// Supprimer les zones d'une livraison
  void removeZonesForDelivery(int deliveryId) {
    _zones.removeWhere((z) => z.deliveryId == deliveryId);
    _arrivedKeys.removeWhere((k) => k.startsWith('$deliveryId:'));
    if (kDebugMode) {
      debugPrint(
          '🎯 [Geofence] Zones supprimées pour livraison #$deliveryId');
    }
  }

  /// Supprimer toutes les zones
  void clearAllZones() {
    _zones.clear();
    _arrivedKeys.clear();
  }

  /// Démarrer la surveillance GPS
  void startMonitoring() {
    if (_isMonitoring || !_isEnabled) return;
    _isMonitoring = true;

    _locationSubscription = _locationService.locationStream.listen(
      _onPositionUpdate,
      onError: (e) {
        if (kDebugMode) debugPrint('❌ [Geofence] Erreur position: $e');
      },
    );

    if (kDebugMode) {
      debugPrint(
          '🎯 [Geofence] Surveillance démarrée (${_zones.length} zones)');
    }
  }

  /// Arrêter la surveillance
  void stopMonitoring() {
    _locationSubscription?.cancel();
    _locationSubscription = null;
    _isMonitoring = false;
    if (kDebugMode) debugPrint('🎯 [Geofence] Surveillance arrêtée');
  }

  /// Traiter une mise à jour de position
  void _onPositionUpdate(Position position) {
    if (!_isEnabled || _zones.isEmpty) return;

    for (final zone in _zones) {
      final distance = zone.distanceTo(position.latitude, position.longitude);
      final previousState = zone.state;
      GeofenceState newState;

      if (distance <= GeofenceThresholds.arrived) {
        newState = GeofenceState.arrived;
      } else if (distance <= GeofenceThresholds.approaching) {
        newState = GeofenceState.approaching;
      } else if (distance > GeofenceThresholds.departed) {
        newState = GeofenceState.outside;
      } else {
        // Dans la zone intermédiaire, garder l'état actuel
        continue;
      }

      if (newState != previousState) {
        zone.state = newState;

        final event = GeofenceEvent(
          zone: zone,
          previousState: previousState,
          newState: newState,
          distance: distance,
        );

        // Émettre l'événement
        _eventController.add(event);

        // Actions automatiques
        _handleStateChange(event);
      }
    }
  }

  /// Gérer les changements d'état automatiquement
  void _handleStateChange(GeofenceEvent event) {
    final key = '${event.zone.deliveryId}:${event.zone.type}';

    if (event.isArriving) {
      if (kDebugMode) {
        debugPrint(
            '🎯 [Geofence] APPROCHE: ${event.zone.type} livraison #${event.zone.deliveryId} (${event.distance.toInt()}m)');
      }

      // Mettre à jour le statut Firestore → "arriving"
      _firestoreTracking.updateDeliveryStatus(
        deliveryId: event.zone.deliveryId,
        status: 'arriving',
      );
    }

    if (event.isArrived && !_arrivedKeys.contains(key)) {
      _arrivedKeys.add(key);

      if (kDebugMode) {
        debugPrint(
            '🎯 [Geofence] ARRIVÉ: ${event.zone.type} livraison #${event.zone.deliveryId} (${event.distance.toInt()}m)');
      }

      // Mettre à jour le statut Firestore → type-specific status
      final status =
          event.zone.type == 'pickup' ? 'arrived_pharmacy' : 'arrived_client';
      _firestoreTracking.updateDeliveryStatus(
        deliveryId: event.zone.deliveryId,
        status: status,
      );
    }
  }

  /// Vérifier la position actuelle par rapport à toutes les zones (ponctuel)
  Future<void> checkCurrentPosition() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      _onPositionUpdate(position);
    } catch (e) {
      if (kDebugMode) debugPrint('❌ [Geofence] Erreur position actuelle: $e');
    }
  }

  void dispose() {
    stopMonitoring();
    _eventController.close();
  }
}

/// Provider pour le service de geofencing
final geofencingServiceProvider = Provider<GeofencingService>((ref) {
  final locationService = ref.read(locationServiceProvider);
  final firestoreTracking = ref.read(firestoreTrackingServiceProvider);
  final service = GeofencingService(locationService, firestoreTracking);
  service.loadPreference();
  ref.onDispose(() => service.dispose());
  return service;
});
