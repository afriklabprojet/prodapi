import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'location_service.dart';
import 'firestore_tracking_service.dart';

/// Mode de zone pour les seuils adaptatifs
enum GeofenceMode {
  /// Zone urbaine dense (seuils serrés)
  urban,

  /// Zone suburbaine
  suburban,

  /// Zone rurale (seuils larges)
  rural,
}

/// Configuration des seuils de distance pour le geofencing (en mètres)
class GeofenceThresholds {
  /// Mode actuel (ajusté automatiquement ou manuellement)
  static GeofenceMode mode = GeofenceMode.urban;

  /// Distance pour déclencher le statut "arriving" (approche)
  static double get approaching => switch (mode) {
    GeofenceMode.urban => 200.0,
    GeofenceMode.suburban => 300.0,
    GeofenceMode.rural => 500.0,
  };

  /// Distance pour déclencher le statut "arrived" (arrivé)
  static double get arrived => switch (mode) {
    GeofenceMode.urban => 30.0,
    GeofenceMode.suburban => 50.0,
    GeofenceMode.rural => 80.0,
  };

  /// Distance minimum pour considérer que le livreur a quitté la zone
  static double get departed => switch (mode) {
    GeofenceMode.urban => 350.0,
    GeofenceMode.suburban => 500.0,
    GeofenceMode.rural => 700.0,
  };

  /// Précision GPS maximale acceptée (en mètres)
  /// Réduit de 100m à 50m pour une meilleure précision
  static double get maxAccuracy => switch (mode) {
    GeofenceMode.urban => 30.0,
    GeofenceMode.suburban => 50.0,
    GeofenceMode.rural => 80.0,
  };

  /// Vitesse maximale plausible (m/s) — 120 km/h = 33.3 m/s
  /// Utilisé pour filtrer les positions GPS aberrantes
  static const double maxSpeedMs = 33.3;

  /// Nombre d'échantillons consécutifs requis pour confirmer un changement d'état
  static const int requiredConsecutiveSamples = 3;

  /// Délai minimum entre deux mises à jour (ms) pour économiser la batterie
  static int get minUpdateIntervalMs => switch (mode) {
    GeofenceMode.urban => 2000,
    GeofenceMode.suburban => 3000,
    GeofenceMode.rural => 5000,
  };
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

/// Direction de mouvement par rapport à une zone
enum MovementDirection {
  /// Se rapproche de la zone
  approaching,

  /// S'éloigne de la zone
  departing,

  /// Stationnaire ou indéterminé
  stationary,
}

/// Représente une zone de geofence surveillée
class GeofenceZone {
  final int deliveryId;
  final String type; // 'pickup' ou 'dropoff'
  final double latitude;
  final double longitude;
  final String? name;
  GeofenceState state;

  /// Dernière distance connue
  double? lastDistance;

  /// Direction de mouvement actuelle
  MovementDirection direction = MovementDirection.stationary;

  /// ETA estimé en secondes (null si indisponible)
  int? etaSeconds;

  /// Vitesse moyenne vers la zone (m/s)
  double? approachSpeed;

  /// Historique des distances pour calcul de direction (5 dernières)
  final List<_DistanceSample> _distanceHistory = [];

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

  /// Met à jour les statistiques de direction et ETA
  void updateDirectionAndEta(double currentDistance, double? speedMs) {
    final now = DateTime.now();
    lastDistance = currentDistance;

    // Ajouter à l'historique
    _distanceHistory.add(
      _DistanceSample(distance: currentDistance, timestamp: now),
    );

    // Garder seulement les 5 derniers échantillons
    while (_distanceHistory.length > 5) {
      _distanceHistory.removeAt(0);
    }

    // Calculer la direction si on a assez d'échantillons
    if (_distanceHistory.length >= 2) {
      final first = _distanceHistory.first;
      final last = _distanceHistory.last;
      final distanceDelta = first.distance - last.distance;
      final timeDeltaMs = last.timestamp
          .difference(first.timestamp)
          .inMilliseconds;

      if (timeDeltaMs > 0) {
        // Vitesse d'approche positive = se rapproche
        approachSpeed = (distanceDelta / timeDeltaMs) * 1000; // m/s

        if (approachSpeed! > 0.5) {
          direction = MovementDirection.approaching;
        } else if (approachSpeed! < -0.5) {
          direction = MovementDirection.departing;
        } else {
          direction = MovementDirection.stationary;
        }

        // Calculer l'ETA si on se rapproche
        if (direction == MovementDirection.approaching && approachSpeed! > 0) {
          etaSeconds = (currentDistance / approachSpeed!).round();
          // Limiter ETA à 2 heures max
          if (etaSeconds! > 7200) etaSeconds = null;
        } else {
          etaSeconds = null;
        }
      }
    }
  }

  /// Réinitialiser l'historique (après un changement d'état)
  void resetHistory() {
    _distanceHistory.clear();
    direction = MovementDirection.stationary;
    etaSeconds = null;
    approachSpeed = null;
  }
}

/// Échantillon de distance pour l'historique
class _DistanceSample {
  final double distance;
  final DateTime timestamp;

  _DistanceSample({required this.distance, required this.timestamp});
}

/// Événement déclenché par le geofencing
class GeofenceEvent {
  final GeofenceZone zone;
  final GeofenceState previousState;
  final GeofenceState newState;
  final double distance;
  final DateTime timestamp;
  final MovementDirection direction;
  final int? etaSeconds;
  final double? speed;

  GeofenceEvent({
    required this.zone,
    required this.previousState,
    required this.newState,
    required this.distance,
    this.direction = MovementDirection.stationary,
    this.etaSeconds,
    this.speed,
  }) : timestamp = DateTime.now();

  bool get isArriving =>
      previousState == GeofenceState.outside &&
      newState == GeofenceState.approaching;

  bool get isArrived => newState == GeofenceState.arrived;

  bool get isDeparted =>
      previousState != GeofenceState.outside &&
      newState == GeofenceState.outside;

  /// ETA formaté (ex: "2 min" ou "45 sec")
  String? get etaFormatted {
    if (etaSeconds == null) return null;
    if (etaSeconds! < 60) return '${etaSeconds}s';
    final minutes = (etaSeconds! / 60).round();
    return '${minutes}min';
  }
}

/// Service de geofencing pour la détection automatique d'arrivée
///
/// Surveille la position du livreur et déclenche automatiquement :
/// - "approaching" quand le livreur est à moins de 200-500m de la destination (selon mode)
/// - "arrived" quand le livreur est à moins de 30-80m de la destination (selon mode)
///
/// Améliorations v2:
/// - Seuils adaptatifs (urbain/suburban/rural)
/// - Filtre de vitesse pour positions aberrantes
/// - Calcul de direction (vers/s'éloigne)
/// - ETA prédictif basé sur la vitesse
/// - Optimisation batterie selon distance
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

  /// Compteurs d'échantillons consécutifs par zone pour le debounce
  /// Clé: "deliveryId:type", Valeur: {state: GeofenceState, count: int}
  final Map<String, _PendingStateChange> _pendingChanges = {};

  /// Dernière position valide (pour le filtre de vitesse)
  Position? _lastValidPosition;

  /// Timestamp de la dernière mise à jour traitée
  DateTime? _lastUpdateTime;

  GeofencingService(this._locationService, this._firestoreTracking);

  /// Stream d'événements (pour l'UI)
  Stream<GeofenceEvent> get events => _eventController.stream;

  /// Mode de geofencing actuel
  GeofenceMode get mode => GeofenceThresholds.mode;

  /// Changer le mode de geofencing (urbain/suburban/rural)
  void setMode(GeofenceMode newMode) {
    GeofenceThresholds.mode = newMode;
    if (kDebugMode) {
      debugPrint('🎯 [Geofence] Mode changé: $newMode');
    }
  }

  /// Détecte automatiquement le mode en fonction de la densité des zones
  void autoDetectMode() {
    // Si on a des zones avec de petites distances, on est en urbain
    // Sinon, on calcule selon l'espacement des zones
    if (_zones.isEmpty) return;

    // Vérifier si les zones sont proches (indicateur urbain)
    double minDistanceBetweenZones = double.infinity;
    for (int i = 0; i < _zones.length; i++) {
      for (int j = i + 1; j < _zones.length; j++) {
        final dist = _zones[i].distanceTo(
          _zones[j].latitude,
          _zones[j].longitude,
        );
        if (dist < minDistanceBetweenZones) minDistanceBetweenZones = dist;
      }
    }

    if (minDistanceBetweenZones < 500) {
      setMode(GeofenceMode.urban);
    } else if (minDistanceBetweenZones < 2000) {
      setMode(GeofenceMode.suburban);
    } else {
      setMode(GeofenceMode.rural);
    }
  }

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
    final savedMode = prefs.getString('geofencing_mode');
    if (savedMode != null) {
      GeofenceThresholds.mode = GeofenceMode.values.firstWhere(
        (m) => m.name == savedMode,
        orElse: () => GeofenceMode.urban,
      );
    }
  }

  Future<void> _savePreference(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('geofencing_enabled', enabled);
    await prefs.setString('geofencing_mode', GeofenceThresholds.mode.name);
  }

  /// Ajouter une zone de geofence à surveiller
  void addZone(GeofenceZone zone) {
    // Éviter les doublons
    _zones.removeWhere(
      (z) => z.deliveryId == zone.deliveryId && z.type == zone.type,
    );
    _zones.add(zone);

    // Auto-détecter le mode après ajout
    autoDetectMode();

    if (kDebugMode) {
      debugPrint(
        '🎯 [Geofence] Zone ajoutée: ${zone.type} livraison #${zone.deliveryId} '
        '(${zone.latitude}, ${zone.longitude}) - Mode: ${GeofenceThresholds.mode.name}',
      );
    }
  }

  /// Supprimer les zones d'une livraison
  void removeZonesForDelivery(int deliveryId) {
    _zones.removeWhere((z) => z.deliveryId == deliveryId);
    _arrivedKeys.removeWhere((k) => k.startsWith('$deliveryId:'));
    if (kDebugMode) {
      debugPrint('🎯 [Geofence] Zones supprimées pour livraison #$deliveryId');
    }
  }

  /// Supprimer toutes les zones
  void clearAllZones() {
    _zones.clear();
    _arrivedKeys.clear();
    _pendingChanges.clear();
    _lastValidPosition = null;
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
        '🎯 [Geofence] Surveillance démarrée (${_zones.length} zones)',
      );
    }
  }

  /// Arrêter la surveillance
  void stopMonitoring() {
    _locationSubscription?.cancel();
    _locationSubscription = null;
    _isMonitoring = false;
    _lastValidPosition = null;
    _lastUpdateTime = null;
    if (kDebugMode) debugPrint('🎯 [Geofence] Surveillance arrêtée');
  }

  /// Calculer la vitesse entre deux positions (m/s)
  double _calculateSpeed(Position current, Position previous) {
    final distance = Geolocator.distanceBetween(
      previous.latitude,
      previous.longitude,
      current.latitude,
      current.longitude,
    );
    final timeDiff =
        current.timestamp.difference(previous.timestamp).inMilliseconds / 1000;
    if (timeDiff <= 0) return 0;
    return distance / timeDiff;
  }

  /// Traiter une mise à jour de position
  void _onPositionUpdate(Position position) {
    if (!_isEnabled || _zones.isEmpty) return;

    final now = DateTime.now();

    // Throttling: ne pas traiter trop souvent pour économiser la batterie
    if (_lastUpdateTime != null) {
      final elapsed = now.difference(_lastUpdateTime!).inMilliseconds;
      if (elapsed < GeofenceThresholds.minUpdateIntervalMs) {
        return;
      }
    }

    // Filtre de précision GPS : rejeter les positions imprécises
    if (position.accuracy > GeofenceThresholds.maxAccuracy) {
      if (kDebugMode) {
        debugPrint(
          '📡 [Geofence] Position ignorée: précision ${position.accuracy.toInt()}m > seuil ${GeofenceThresholds.maxAccuracy.toInt()}m',
        );
      }
      return;
    }

    // Filtre de vitesse : rejeter les positions aberrantes (téléportation GPS)
    if (_lastValidPosition != null) {
      final calculatedSpeed = _calculateSpeed(position, _lastValidPosition!);
      if (calculatedSpeed > GeofenceThresholds.maxSpeedMs) {
        if (kDebugMode) {
          debugPrint(
            '📡 [Geofence] Position ignorée: vitesse ${(calculatedSpeed * 3.6).toInt()} km/h > ${(GeofenceThresholds.maxSpeedMs * 3.6).toInt()} km/h',
          );
        }
        return;
      }
    }

    // Position valide, mettre à jour les références
    _lastValidPosition = position;
    _lastUpdateTime = now;

    // Vitesse actuelle (du GPS ou calculée)
    final currentSpeed = position.speed >= 0 ? position.speed : null;

    for (final zone in _zones) {
      final distance = zone.distanceTo(position.latitude, position.longitude);

      // Mettre à jour les statistiques de direction et ETA pour cette zone
      zone.updateDirectionAndEta(distance, currentSpeed);

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
        // Mais émettre un event de progression si direction change
        _emitProgressEvent(zone, distance, currentSpeed);
        continue;
      }

      if (newState != previousState) {
        final key = '${zone.deliveryId}:${zone.type}';

        // Debounce : exiger N échantillons consécutifs dans le même état
        final pending = _pendingChanges[key];
        if (pending != null && pending.targetState == newState) {
          pending.count++;
        } else {
          _pendingChanges[key] = _PendingStateChange(
            targetState: newState,
            count: 1,
          );
        }

        final currentPending = _pendingChanges[key]!;
        if (currentPending.count <
            GeofenceThresholds.requiredConsecutiveSamples) {
          if (kDebugMode) {
            final directionStr = zone.direction == MovementDirection.approaching
                ? '→'
                : zone.direction == MovementDirection.departing
                ? '←'
                : '•';
            final etaStr = zone.etaSeconds != null
                ? ' ETA: ${_formatEta(zone.etaSeconds!)}'
                : '';
            debugPrint(
              '📡 [Geofence] Debounce ${zone.type} #${zone.deliveryId}: '
              '${currentPending.count}/${GeofenceThresholds.requiredConsecutiveSamples} '
              'pour $newState (${distance.toInt()}m $directionStr$etaStr)',
            );
          }
          continue;
        }

        // Seuil atteint : confirmer le changement d'état
        _pendingChanges.remove(key);
        zone.state = newState;
        zone.resetHistory(); // Réinitialiser l'historique après changement d'état

        final event = GeofenceEvent(
          zone: zone,
          previousState: previousState,
          newState: newState,
          distance: distance,
          direction: zone.direction,
          etaSeconds: zone.etaSeconds,
          speed: currentSpeed,
        );

        // Émettre l'événement
        _eventController.add(event);

        // Actions automatiques
        _handleStateChange(event);
      } else {
        // Même état : réinitialiser le compteur de debounce
        final key = '${zone.deliveryId}:${zone.type}';
        _pendingChanges.remove(key);
      }
    }
  }

  /// Émettre un événement de progression (sans changement d'état)
  void _emitProgressEvent(GeofenceZone zone, double distance, double? speed) {
    // Émettre uniquement si on a un ETA et qu'on se rapproche
    if (zone.direction == MovementDirection.approaching &&
        zone.etaSeconds != null) {
      final event = GeofenceEvent(
        zone: zone,
        previousState: zone.state,
        newState: zone.state,
        distance: distance,
        direction: zone.direction,
        etaSeconds: zone.etaSeconds,
        speed: speed,
      );
      _eventController.add(event);
    }
  }

  /// Formater l'ETA pour le debug
  String _formatEta(int seconds) {
    if (seconds < 60) return '${seconds}s';
    return '${(seconds / 60).round()}min';
  }

  /// Gérer les changements d'état automatiquement
  void _handleStateChange(GeofenceEvent event) {
    final key = '${event.zone.deliveryId}:${event.zone.type}';

    if (event.isArriving) {
      final etaStr = event.etaFormatted != null
          ? ' - ETA: ${event.etaFormatted}'
          : '';
      if (kDebugMode) {
        debugPrint(
          '🎯 [Geofence] APPROCHE: ${event.zone.type} livraison #${event.zone.deliveryId} '
          '(${event.distance.toInt()}m$etaStr)',
        );
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
          '🎯 [Geofence] ARRIVÉ: ${event.zone.type} livraison #${event.zone.deliveryId} (${event.distance.toInt()}m)',
        );
      }

      // Mettre à jour le statut Firestore → type-specific status
      final status = event.zone.type == 'pickup'
          ? 'arrived_pharmacy'
          : 'arrived_client';
      _firestoreTracking.updateDeliveryStatus(
        deliveryId: event.zone.deliveryId,
        status: status,
      );
    }

    if (event.isDeparted) {
      if (kDebugMode) {
        debugPrint(
          '🎯 [Geofence] DÉPART: ${event.zone.type} livraison #${event.zone.deliveryId} (${event.distance.toInt()}m)',
        );
      }
    }
  }

  /// Vérifier la position actuelle par rapport à toutes les zones (ponctuel)
  Future<void> checkCurrentPosition() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.best,
        ),
      );
      _onPositionUpdate(position);
    } catch (e) {
      if (kDebugMode) debugPrint('❌ [Geofence] Erreur position actuelle: $e');
    }
  }

  /// Obtenir l'ETA pour une zone spécifique
  int? getEtaForZone(int deliveryId, String type) {
    final zone = _zones.firstWhere(
      (z) => z.deliveryId == deliveryId && z.type == type,
      orElse: () =>
          GeofenceZone(deliveryId: -1, type: '', latitude: 0, longitude: 0),
    );
    return zone.deliveryId != -1 ? zone.etaSeconds : null;
  }

  /// Obtenir la direction de mouvement pour une zone
  MovementDirection getDirectionForZone(int deliveryId, String type) {
    final zone = _zones.firstWhere(
      (z) => z.deliveryId == deliveryId && z.type == type,
      orElse: () =>
          GeofenceZone(deliveryId: -1, type: '', latitude: 0, longitude: 0),
    );
    return zone.deliveryId != -1
        ? zone.direction
        : MovementDirection.stationary;
  }

  /// Obtenir la distance actuelle pour une zone
  double? getDistanceForZone(int deliveryId, String type) {
    final zone = _zones.firstWhere(
      (z) => z.deliveryId == deliveryId && z.type == type,
      orElse: () =>
          GeofenceZone(deliveryId: -1, type: '', latitude: 0, longitude: 0),
    );
    return zone.deliveryId != -1 ? zone.lastDistance : null;
  }

  void dispose() {
    stopMonitoring();
    _eventController.close();
  }
}

/// Classe interne pour suivre les changements d'état en attente de confirmation (debounce)
class _PendingStateChange {
  final GeofenceState targetState;
  int count;

  _PendingStateChange({required this.targetState, this.count = 0});
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
