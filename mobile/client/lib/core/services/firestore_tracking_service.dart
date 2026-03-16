import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Données de position du livreur en temps réel
class CourierLocationData {
  final double latitude;
  final double longitude;
  final double? accuracy;
  final double? speed;
  final double? heading;
  final bool isOnline;
  final bool isDelivering;
  final int? currentOrderId;
  final DateTime? updatedAt;

  const CourierLocationData({
    required this.latitude,
    required this.longitude,
    this.accuracy,
    this.speed,
    this.heading,
    this.isOnline = false,
    this.isDelivering = false,
    this.currentOrderId,
    this.updatedAt,
  });

  factory CourierLocationData.fromFirestore(Map<String, dynamic> data) {
    return CourierLocationData(
      latitude: (data['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (data['longitude'] as num?)?.toDouble() ?? 0.0,
      accuracy: (data['accuracy'] as num?)?.toDouble(),
      speed: (data['speed'] as num?)?.toDouble(),
      heading: (data['heading'] as num?)?.toDouble(),
      isOnline: data['isOnline'] as bool? ?? false,
      isDelivering: data['isDelivering'] as bool? ?? false,
      currentOrderId: data['currentOrderId'] as int?,
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }
}

/// Données de tracking d'une livraison en temps réel
class DeliveryTrackingData {
  final int? courierId;
  final double latitude;
  final double longitude;
  final double? speed;
  final double? heading;
  final String? status;
  final DateTime? estimatedArrival;
  final DateTime? updatedAt;

  const DeliveryTrackingData({
    this.courierId,
    required this.latitude,
    required this.longitude,
    this.speed,
    this.heading,
    this.status,
    this.estimatedArrival,
    this.updatedAt,
  });

  factory DeliveryTrackingData.fromFirestore(Map<String, dynamic> data) {
    return DeliveryTrackingData(
      courierId: data['courierId'] as int?,
      latitude: (data['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (data['longitude'] as num?)?.toDouble() ?? 0.0,
      speed: (data['speed'] as num?)?.toDouble(),
      heading: (data['heading'] as num?)?.toDouble(),
      status: data['status'] as String?,
      estimatedArrival: (data['estimatedArrival'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  /// Status lisible pour l'UI
  String get statusLabel {
    switch (status) {
      case 'picked_up':
        return 'Commande récupérée';
      case 'in_transit':
        return 'En route';
      case 'arriving':
        return 'Arrivée imminente';
      case 'delivered':
        return 'Livré';
      default:
        return 'En préparation';
    }
  }
}

/// Service Firestore côté client pour écouter le tracking en temps réel.
///
/// Permet d'écouter :
/// - La position d'un livreur spécifique (via courierId)
/// - Le tracking d'une livraison spécifique (via deliveryId/orderId)
class FirestoreTrackingService {
  final FirebaseFirestore _firestore;

  FirestoreTrackingService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Référence à la collection des livreurs
  CollectionReference get _couriersRef => _firestore.collection('couriers');

  /// Référence à la collection des livraisons
  CollectionReference get _deliveriesRef => _firestore.collection('deliveries');

  /// Stream en temps réel de la position d'un livreur
  ///
  /// Utilisé par le client pour suivre le livreur sur la carte.
  /// Les mises à jour arrivent instantanément via Firestore.
  Stream<CourierLocationData?> watchCourierLocation(int courierId) {
    return _couriersRef
        .doc(courierId.toString())
        .snapshots()
        .map((snapshot) {
      if (!snapshot.exists || snapshot.data() == null) {
        return null;
      }
      return CourierLocationData.fromFirestore(
        snapshot.data()! as Map<String, dynamic>,
      );
    }).handleError((error) {
      debugPrint('❌ [Firestore] Erreur watchCourierLocation: $error');
    });
  }

  /// Stream en temps réel du tracking d'une livraison (par orderId)
  ///
  /// Écoute les mises à jour de position + statut pour une commande donnée.
  Stream<DeliveryTrackingData?> watchDeliveryTracking(int orderId) {
    return _deliveriesRef
        .doc(orderId.toString())
        .snapshots()
        .map((snapshot) {
      if (!snapshot.exists || snapshot.data() == null) {
        return null;
      }
      return DeliveryTrackingData.fromFirestore(
        snapshot.data()! as Map<String, dynamic>,
      );
    }).handleError((error) {
      debugPrint('❌ [Firestore] Erreur watchDeliveryTracking: $error');
    });
  }

  /// Vérifier si un livreur est actuellement en ligne
  Future<bool> isCourierOnline(int courierId) async {
    try {
      final doc = await _couriersRef.doc(courierId.toString()).get();
      if (!doc.exists) return false;
      final data = doc.data() as Map<String, dynamic>?;
      if (data == null) return false;

      final isOnline = data['isOnline'] as bool? ?? false;
      final updatedAt = (data['updatedAt'] as Timestamp?)?.toDate();

      // Considérer hors ligne si pas de mise à jour depuis 2 minutes
      if (updatedAt != null) {
        final diff = DateTime.now().difference(updatedAt);
        if (diff.inMinutes > 2) return false;
      }

      return isOnline;
    } catch (e) {
      debugPrint('❌ [Firestore] Erreur isCourierOnline: $e');
      return false;
    }
  }

  /// Obtenir la dernière position connue d'un livreur (one-shot)
  Future<CourierLocationData?> getLastCourierLocation(int courierId) async {
    try {
      final doc = await _couriersRef.doc(courierId.toString()).get();
      if (!doc.exists || doc.data() == null) return null;
      return CourierLocationData.fromFirestore(
        doc.data()! as Map<String, dynamic>,
      );
    } catch (e) {
      debugPrint('❌ [Firestore] Erreur getLastCourierLocation: $e');
      return null;
    }
  }

  /// Obtenir tous les livreurs en ligne (utile pour admin/pharmacie)
  Stream<List<CourierLocationData>> watchOnlineCouriers() {
    return _couriersRef
        .where('isOnline', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return CourierLocationData.fromFirestore(
          doc.data() as Map<String, dynamic>,
        );
      }).toList();
    });
  }
}
