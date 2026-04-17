import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../../data/repositories/delivery_repository.dart';
import 'firestore_tracking_service.dart';

/// Provider pour le service Firestore de tracking
final firestoreTrackingServiceProvider = Provider<FirestoreTrackingService>((
  ref,
) {
  return FirestoreTrackingService();
});

final locationServiceProvider = Provider<LocationService>((ref) {
  final service = LocationService(
    ref.read(deliveryRepositoryProvider),
    ref.read(firestoreTrackingServiceProvider),
  );
  ref.onDispose(() => service.dispose());
  return service;
});

class LocationService {
  final DeliveryRepository _repository;
  final FirestoreTrackingService _firestoreTracking;
  StreamSubscription<Position>? _positionStreamSubscription;
  final StreamController<Position> _locationController =
      StreamController<Position>.broadcast();
  bool _isTracking = false;

  /// ID de la commande en cours de livraison (pour Firestore)
  int? currentOrderId;

  LocationService(this._repository, this._firestoreTracking);

  Stream<Position> get locationStream => _locationController.stream;

  /// Initialiser le tracking Firestore avec l'ID du livreur
  void initializeFirestore(int courierId) {
    _firestoreTracking.initialize(courierId);
  }

  /// Signaler le livreur comme en ligne dans Firestore
  Future<void> goOnline() => _firestoreTracking.goOnline();

  /// Signaler le livreur comme hors ligne dans Firestore
  Future<void> goOffline() => _firestoreTracking.goOffline();

  /// Mettre à jour le statut de livraison dans Firestore
  Future<void> updateDeliveryStatus({
    required int deliveryId,
    required String status,
    DateTime? estimatedArrival,
  }) {
    return _firestoreTracking.updateDeliveryStatus(
      deliveryId: deliveryId,
      status: status,
      estimatedArrival: estimatedArrival,
    );
  }

  /// Définir la destination pour le calcul d'ETA
  void setDestination({required double lat, required double lng}) {
    _firestoreTracking.setDestination(lat: lat, lng: lng);
  }

  /// Effacer la destination (livraison terminée)
  void clearDestination() {
    _firestoreTracking.clearDestination();
  }

  Future<void> requestPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error(
        'Location permissions are permanently denied, we cannot request permissions.',
      );
    }
  }

  Future<void> startTracking() async {
    if (_isTracking) return;

    try {
      await requestPermission();

      _isTracking = true;
      final locationSettings = LocationSettings(
        accuracy: LocationAccuracy.best, // Meilleure précision GPS possible
        distanceFilter:
            5, // Mise à jour tous les 5 mètres pour plus de précision
      );

      _positionStreamSubscription =
          Geolocator.getPositionStream(
            locationSettings: locationSettings,
          ).listen(
            (Position position) {
              // Envoyer la position à l'API backend
              _repository.updateLocation(position.latitude, position.longitude);

              // Envoyer la position à Firestore en temps réel
              _firestoreTracking.updateLocation(
                position,
                currentOrderId: currentOrderId,
              );

              if (!_locationController.isClosed) {
                _locationController.add(position);
              }
              if (kDebugMode) {
                debugPrint(
                  '📍 Location updated: ${position.latitude}, ${position.longitude}',
                );
              }
            },
            onError: (error) {
              if (kDebugMode) debugPrint('📍 Location stream error: $error');
              if (!_locationController.isClosed) {
                _locationController.addError(error);
              }
            },
            onDone: () {
              _isTracking = false;
            },
          );
    } catch (e) {
      if (kDebugMode) debugPrint('Error starting location tracking: $e');
      _isTracking = false;
    }
  }

  void stopTracking() {
    _positionStreamSubscription?.cancel();
    _positionStreamSubscription = null;
    _isTracking = false;
  }

  void dispose() {
    stopTracking();
    _locationController.close();
    _firestoreTracking.dispose();
  }
}
