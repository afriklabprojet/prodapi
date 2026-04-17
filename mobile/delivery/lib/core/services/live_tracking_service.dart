import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:share_plus/share_plus.dart';
import 'package:geolocator/geolocator.dart';
import '../config/app_config.dart';

/// Service pour partager la position du livreur en temps réel
/// Permet aux clients de suivre la livraison via une URL web
class LiveTrackingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  Timer? _updateTimer;
  String? _activeTrackingId;
  int? _activeDeliveryId;
  StreamSubscription<Position>? _positionSubscription;
  
  /// URL de base pour le tracking web
  static String get trackingBaseUrl => '${AppConfig.webBaseUrl}/track';
  
  /// Générer un lien de tracking pour une livraison
  Future<String> generateTrackingLink(int deliveryId, int courierId) async {
    // Créer un ID unique pour cette session de tracking
    final trackingId = '${deliveryId}_${DateTime.now().millisecondsSinceEpoch}';
    
    // Créer le document de tracking dans Firestore
    await _firestore.collection('live_tracking').doc(trackingId).set({
      'delivery_id': deliveryId,
      'courier_id': courierId,
      'created_at': FieldValue.serverTimestamp(),
      'expires_at': DateTime.now().add(const Duration(hours: 2)).toIso8601String(),
      'is_active': true,
      'last_position': null,
      'last_updated': null,
    });
    
    _activeTrackingId = trackingId;
    _activeDeliveryId = deliveryId;
    
    return '$trackingBaseUrl/$trackingId';
  }
  
  /// Démarrer la mise à jour de position en temps réel
  Future<void> startLiveTracking(int deliveryId, int courierId) async {
    // Générer le lien si pas encore fait
    if (_activeTrackingId == null || _activeDeliveryId != deliveryId) {
      await generateTrackingLink(deliveryId, courierId);
    }
    
    // Arrêter tout tracking précédent
    stopLiveTracking();
    
    // Écouter les mises à jour de position
    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 20, // Mise à jour tous les 20m
      ),
    ).listen(
      (Position position) {
        _updatePosition(position);
      },
      onError: (error) {
        if (kDebugMode) debugPrint('Live tracking position error: $error');
      },
      onDone: () {
        if (kDebugMode) debugPrint('Live tracking position stream done');
      },
    );
    
    // Heartbeat toutes les 60 secondes pour confirmer la présence
    // (pas de GPS query — utilise la dernière position connue)
    _updateTimer = Timer.periodic(const Duration(seconds: 60), (_) async {
      // Simplement mettre à jour le timestamp dans Firestore
      if (_activeTrackingId == null) return;
      try {
        await _firestore.collection('live_tracking').doc(_activeTrackingId).update({
          'last_updated': FieldValue.serverTimestamp(),
        });
      } catch (e) {
        if (kDebugMode) debugPrint('Live tracking heartbeat error: $e');
      }
    });
    
    if (kDebugMode) debugPrint('🔴 Live tracking started for delivery $_activeDeliveryId');
  }
  
  /// Mettre à jour la position dans Firestore
  Future<void> _updatePosition(Position position) async {
    if (_activeTrackingId == null) return;
    
    try {
      await _firestore.collection('live_tracking').doc(_activeTrackingId).update({
        'last_position': {
          'latitude': position.latitude,
          'longitude': position.longitude,
          'heading': position.heading,
          'speed': position.speed,
          'accuracy': position.accuracy,
        },
        'last_updated': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      if (kDebugMode) debugPrint('Live tracking update error: $e');
    }
  }
  
  /// Mettre à jour le statut de livraison (pour affichage sur la page web)
  Future<void> updateDeliveryStatus(String status, {String? etaMinutes}) async {
    if (_activeTrackingId == null) return;
    
    try {
      await _firestore.collection('live_tracking').doc(_activeTrackingId).update({
        'delivery_status': status,
        'eta_minutes': etaMinutes,
        'status_updated': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      if (kDebugMode) debugPrint('Live tracking status update error: $e');
    }
  }
  
  /// Arrêter le tracking
  void stopLiveTracking() {
    _positionSubscription?.cancel();
    _positionSubscription = null;
    _updateTimer?.cancel();
    _updateTimer = null;
    
    if (kDebugMode && _activeTrackingId != null) {
      debugPrint('🔴 Live tracking stopped');
    }
  }
  
  /// Marquer le tracking comme terminé (livraison complétée)
  Future<void> completeTracking() async {
    if (_activeTrackingId == null) return;
    
    try {
      await _firestore.collection('live_tracking').doc(_activeTrackingId).update({
        'is_active': false,
        'completed_at': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      if (kDebugMode) debugPrint('Live tracking complete error: $e');
    }
    
    stopLiveTracking();
    _activeTrackingId = null;
    _activeDeliveryId = null;
  }
  
  /// Partager le lien de tracking
  Future<void> shareTrackingLink(String trackingUrl) async {
    await Share.share(
      'Suivez votre livraison en temps réel ici: $trackingUrl',
      subject: 'Suivi de livraison DR-PHARMA',
    );
  }
  
  /// Obtenir le lien de tracking actif
  String? getActiveTrackingLink() {
    if (_activeTrackingId == null) return null;
    return '$trackingBaseUrl/$_activeTrackingId';
  }
  
  /// Vérifier si le tracking est actif
  bool get isTrackingActive => _activeTrackingId != null;
}

/// Provider pour le service de tracking
final liveTrackingServiceProvider = Provider<LiveTrackingService>((ref) {
  final service = LiveTrackingService();
  ref.onDispose(() => service.stopLiveTracking());
  return service;
});

/// Provider pour le lien de tracking actif
final activeTrackingLinkProvider = Provider<String?>((ref) {
  final service = ref.watch(liveTrackingServiceProvider);
  return service.getActiveTrackingLink();
});
