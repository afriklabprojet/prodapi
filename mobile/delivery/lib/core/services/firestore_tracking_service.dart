import 'dart:async';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

/// Service Firestore pour le tracking en temps réel du livreur.
///
/// Structure Firestore :
/// ```
/// couriers/{courierId}
///   ├── latitude: double
///   ├── longitude: double
///   ├── accuracy: double
///   ├── speed: double
///   ├── heading: double
///   ├── isOnline: bool
///   ├── isDelivering: bool
///   ├── currentOrderId: int?
///   ├── updatedAt: Timestamp
///   └── batteryLevel: int?
///
/// deliveries/{deliveryId}/tracking
///   ├── courierId: int
///   ├── latitude: double
///   ├── longitude: double
///   ├── status: String (picked_up, in_transit, arriving, delivered)
///   ├── estimatedArrival: Timestamp?
///   └── updatedAt: Timestamp
/// ```
class FirestoreTrackingService {
  final FirebaseFirestore _firestore;

  /// ID du livreur connecté (sera défini après login)
  int? _courierId;

  /// Coordonnées de destination pour le calcul d'ETA
  double? _destinationLat;
  double? _destinationLng;

  /// Timer pour le heartbeat (mettre à jour "isOnline")
  Timer? _heartbeatTimer;

  FirestoreTrackingService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Référence à la collection des livreurs
  CollectionReference get _couriersRef => _firestore.collection('couriers');

  /// UID Firebase au format attendu par les security rules
  /// Le backend génère des custom tokens avec uid = "user_{userId}"
  String? get _firebaseUid => _courierId != null ? 'user_$_courierId' : null;

  /// Référence à la collection des livraisons
  CollectionReference get _deliveriesRef => _firestore.collection('deliveries');

  /// Initialiser le service avec l'ID du livreur
  void initialize(int courierId) {
    _courierId = courierId;
    _startHeartbeat();
    if (kDebugMode) {
      debugPrint('🔥 [Firestore] Tracking initialisé pour livreur #$courierId');
    }
  }

  /// Mettre à jour la position en temps réel dans Firestore
  Future<void> updateLocation(Position position, {int? currentOrderId}) async {
    if (_courierId == null) {
      if (kDebugMode) debugPrint('⚠️ [Firestore] courierId non défini, ignoré');
      return;
    }

    try {
      final data = {
        'latitude': position.latitude,
        'longitude': position.longitude,
        'accuracy': position.accuracy,
        'speed': position.speed,
        'heading': position.heading,
        'isOnline': true,
        'isDelivering': currentOrderId != null,
        'currentOrderId': currentOrderId,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await _couriersRef.doc(_firebaseUid).set(data, SetOptions(merge: true));

      // Si une livraison est en cours, mettre à jour aussi le doc de la livraison
      if (currentOrderId != null) {
        await _updateDeliveryTracking(
          deliveryId: currentOrderId,
          position: position,
        );
      }
    } catch (e) {
      if (kDebugMode) debugPrint('❌ [Firestore] Erreur updateLocation: $e');
    }
  }

  /// Définir la destination pour le calcul d'ETA
  void setDestination({required double lat, required double lng}) {
    _destinationLat = lat;
    _destinationLng = lng;
    if (kDebugMode) {
      debugPrint('📍 [Firestore] Destination définie: $lat, $lng');
    }
  }

  /// Effacer la destination (livraison terminée)
  void clearDestination() {
    _destinationLat = null;
    _destinationLng = null;
  }

  /// Calcule l'ETA en se basant sur la distance restante et la vitesse courante
  /// Retourne null si les données sont insuffisantes
  DateTime? _computeEta(Position position) {
    if (_destinationLat == null || _destinationLng == null) return null;

    final distanceMeters = Geolocator.distanceBetween(
      position.latitude,
      position.longitude,
      _destinationLat!,
      _destinationLng!,
    );

    // Vitesse minimum 2 m/s (~7 km/h) pour éviter des ETA absurdes à l'arrêt
    // Vitesse réaliste en ville : entre 5 et 15 m/s (18-54 km/h)
    double speedMs = max(2.0, position.speed);
    // Cap à 20 m/s (72 km/h) pour le réalisme urbain
    speedMs = min(speedMs, 20.0);

    final etaSeconds = distanceMeters / speedMs;
    // Cap à 2h max pour éviter des valeurs absurdes
    if (etaSeconds > 7200) return null;

    return DateTime.now().add(Duration(seconds: etaSeconds.round()));
  }

  /// Mettre à jour le tracking d'une livraison spécifique
  Future<void> _updateDeliveryTracking({
    required int deliveryId,
    required Position position,
  }) async {
    try {
      final data = <String, dynamic>{
        'courierId': _courierId,
        'latitude': position.latitude,
        'longitude': position.longitude,
        'speed': position.speed,
        'heading': position.heading,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // Calculer et ajouter l'ETA si possible
      final eta = _computeEta(position);
      if (eta != null) {
        data['estimatedArrival'] = Timestamp.fromDate(eta);
      }

      await _deliveriesRef
          .doc(deliveryId.toString())
          .set(data, SetOptions(merge: true));
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ [Firestore] Erreur updateDeliveryTracking: $e');
      }
    }
  }

  /// Mettre à jour le statut de la livraison
  /// [status] : picked_up, in_transit, arriving, delivered
  Future<void> updateDeliveryStatus({
    required int deliveryId,
    required String status,
    DateTime? estimatedArrival,
  }) async {
    if (_courierId == null) return;

    try {
      final data = <String, dynamic>{
        'courierId': _courierId,
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (estimatedArrival != null) {
        data['estimatedArrival'] = Timestamp.fromDate(estimatedArrival);
      }

      await _deliveriesRef
          .doc(deliveryId.toString())
          .set(data, SetOptions(merge: true));

      if (kDebugMode) {
        debugPrint('🔥 [Firestore] Statut livraison #$deliveryId → $status');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ [Firestore] Erreur updateDeliveryStatus: $e');
      }
    }
  }

  /// Signaler le livreur comme en ligne
  Future<void> goOnline() async {
    if (_firebaseUid == null) return;

    await _couriersRef.doc(_firebaseUid).set({
      'isOnline': true,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    _startHeartbeat();
    if (kDebugMode) debugPrint('🟢 [Firestore] Livreur en ligne');
  }

  /// Signaler le livreur comme hors ligne
  Future<void> goOffline() async {
    if (_firebaseUid == null) return;

    _heartbeatTimer?.cancel();

    await _couriersRef.doc(_firebaseUid).set({
      'isOnline': false,
      'isDelivering': false,
      'currentOrderId': null,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    if (kDebugMode) debugPrint('🔴 [Firestore] Livreur hors ligne');
  }

  /// Heartbeat toutes les 60 secondes pour confirmer que le livreur est en ligne
  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 60), (_) async {
      if (_firebaseUid == null) return;
      try {
        await _couriersRef.doc(_firebaseUid).update({
          'updatedAt': FieldValue.serverTimestamp(),
          'isOnline': true,
        });
      } catch (e) {
        if (kDebugMode) debugPrint('⚠️ [Firestore] Heartbeat failed: $e');
      }
    });
  }

  /// Nettoyer à la déconnexion
  void dispose() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
    // Fire-and-forget goOffline avec logging des erreurs
    goOffline().catchError((e) {
      if (kDebugMode) {
        debugPrint('⚠️ [Firestore] Error going offline on dispose: $e');
      }
    });
  }
}
