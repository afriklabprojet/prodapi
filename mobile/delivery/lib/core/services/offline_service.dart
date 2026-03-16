import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../data/models/delivery.dart';
import '../../data/models/courier_profile.dart';
import 'encrypted_storage_service.dart';

/// Service de cache hors-ligne pour les données critiques
///
/// Utilise Hive chiffré (AES-256) pour stocker les données sensibles :
/// - Voir les livraisons actives
/// - Voir les infos de la commande en cours
/// - Conserver les preuves de livraison pour upload ultérieur
class OfflineService {
  OfflineService._();
  static final OfflineService instance = OfflineService._();

  Box<String>? _box;

  // ── Clés de cache ──────────────────────────────────
  static const String _keyActiveDeliveries = 'offline_active_deliveries';
  static const String _keyCurrentDelivery = 'offline_current_delivery';
  static const String _keyCourierProfile = 'offline_courier_profile';
  static const String _keyPendingProofs = 'offline_pending_proofs';
  static const String _keyWalletBalance = 'offline_wallet_balance';
  static const String _keyLastSyncTime = 'offline_last_sync';
  static const String _keyPendingActions = 'offline_pending_actions';

  // ── Initialisation ─────────────────────────────────

  Future<void> init() async {
    if (_box != null && _box!.isOpen) return;
    _box = await EncryptedStorageService.instance.openEncryptedBox('offline_data');
    if (kDebugMode) debugPrint('💾 [Offline] Service initialisé (chiffré)');
  }

  Box<String> get _storage {
    assert(_box != null && _box!.isOpen, 'OfflineService.init() doit être appelé avant utilisation.');
    return _box!;
  }

  // ── Livraisons ─────────────────────────────────────

  /// Sauvegarde la liste des livraisons actives pour accès hors-ligne
  Future<void> cacheActiveDeliveries(List<Delivery> deliveries) async {
    await init();
    final jsonList = deliveries.map((d) => d.toJson()).toList();
    await _storage.put(_keyActiveDeliveries, jsonEncode(jsonList));
    await _updateSyncTime();
    if (kDebugMode) debugPrint('💾 [Offline] ${deliveries.length} livraisons mises en cache');
  }

  /// Récupère les livraisons actives depuis le cache
  Future<List<Delivery>> getCachedActiveDeliveries() async {
    await init();
    final raw = _storage.get(_keyActiveDeliveries);
    if (raw == null) return [];

    try {
      final jsonList = jsonDecode(raw) as List;
      return jsonList.map((e) => Delivery.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ [Offline] Erreur lecture livraisons cache: $e');
      return [];
    }
  }

  /// Sauvegarde la livraison en cours
  Future<void> cacheCurrentDelivery(Delivery? delivery) async {
    await init();
    if (delivery == null) {
      await _storage.delete(_keyCurrentDelivery);
    } else {
      await _storage.put(_keyCurrentDelivery, jsonEncode(delivery.toJson()));
    }
    if (kDebugMode) debugPrint('💾 [Offline] Livraison courante ${delivery != null ? "sauvegardée" : "effacée"}');
  }

  /// Récupère la livraison en cours
  Future<Delivery?> getCachedCurrentDelivery() async {
    await init();
    final raw = _storage.get(_keyCurrentDelivery);
    if (raw == null) return null;

    try {
      return Delivery.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (e) {
      return null;
    }
  }

  // ── Profil Livreur ─────────────────────────────────

  /// Sauvegarde le profil livreur
  Future<void> cacheCourierProfile(CourierProfile profile) async {
    await init();
    await _storage.put(_keyCourierProfile, jsonEncode(profile.toJson()));
  }

  /// Récupère le profil livreur
  Future<CourierProfile?> getCachedCourierProfile() async {
    await init();
    final raw = _storage.get(_keyCourierProfile);
    if (raw == null) return null;

    try {
      return CourierProfile.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (e) {
      return null;
    }
  }

  // ── Wallet ─────────────────────────────────────────

  /// Sauvegarde le solde du wallet
  Future<void> cacheWalletBalance(double balance, double pendingEarnings) async {
    await init();
    await _storage.put(_keyWalletBalance, jsonEncode({
      'balance': balance,
      'pending_earnings': pendingEarnings,
      'cached_at': DateTime.now().toIso8601String(),
    }));
  }

  /// Récupère le solde du wallet
  Future<Map<String, double>?> getCachedWalletBalance() async {
    await init();
    final raw = _storage.get(_keyWalletBalance);
    if (raw == null) return null;

    try {
      final data = jsonDecode(raw) as Map<String, dynamic>;
      return {
        'balance': (data['balance'] as num).toDouble(),
        'pending_earnings': (data['pending_earnings'] as num).toDouble(),
      };
    } catch (e) {
      return null;
    }
  }

  // ── Preuves de livraison en attente ────────────────

  /// Ajoute une preuve de livraison en attente d'upload
  Future<void> addPendingProof({
    required int deliveryId,
    String? photoBase64,
    String? signatureBase64,
    String? notes,
    double? latitude,
    double? longitude,
  }) async {
    await init();
    final pendingList = await _getPendingProofs();
    
    pendingList.add({
      'delivery_id': deliveryId,
      'photo_base64': photoBase64,
      'signature_base64': signatureBase64,
      'notes': notes,
      'latitude': latitude,
      'longitude': longitude,
      'created_at': DateTime.now().toIso8601String(),
    });

    await _storage.put(_keyPendingProofs, jsonEncode(pendingList));
    if (kDebugMode) debugPrint('💾 [Offline] Preuve ajoutée en attente (total: ${pendingList.length})');
  }

  /// Récupère les preuves en attente
  Future<List<Map<String, dynamic>>> _getPendingProofs() async {
    final raw = _storage.get(_keyPendingProofs);
    if (raw == null) return [];

    try {
      return (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
    } catch (e) {
      return [];
    }
  }

  /// Récupère et supprime les preuves en attente (pour sync)
  Future<List<Map<String, dynamic>>> getPendingProofsAndClear() async {
    await init();
    final proofs = await _getPendingProofs();
    await _storage.delete(_keyPendingProofs);
    return proofs;
  }

  /// Vérifie s'il y a des preuves en attente
  Future<int> getPendingProofsCount() async {
    final proofs = await _getPendingProofs();
    return proofs.length;
  }

  // ── Actions en attente ─────────────────────────────

  /// Ajoute une action en attente (pour sync quand online)
  Future<void> addPendingAction({
    required String type, // 'pickup', 'deliver', 'location_update'
    required int deliveryId,
    Map<String, dynamic>? data,
  }) async {
    await init();
    final pendingList = await _getPendingActions();
    
    pendingList.add({
      'type': type,
      'delivery_id': deliveryId,
      'data': data,
      'created_at': DateTime.now().toIso8601String(),
    });

    await _storage.put(_keyPendingActions, jsonEncode(pendingList));
    if (kDebugMode) debugPrint('💾 [Offline] Action "$type" mise en file (total: ${pendingList.length})');
  }

  Future<List<Map<String, dynamic>>> _getPendingActions() async {
    final raw = _storage.get(_keyPendingActions);
    if (raw == null) return [];

    try {
      return (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
    } catch (e) {
      return [];
    }
  }

  /// Récupère et supprime les actions en attente
  Future<List<Map<String, dynamic>>> getPendingActionsAndClear() async {
    await init();
    final actions = await _getPendingActions();
    await _storage.delete(_keyPendingActions);
    return actions;
  }

  /// Vérifie s'il y a des actions en attente
  Future<int> getPendingActionsCount() async {
    final actions = await _getPendingActions();
    return actions.length;
  }

  // ── Synchronisation ────────────────────────────────

  Future<void> _updateSyncTime() async {
    await _storage.put(_keyLastSyncTime, DateTime.now().toIso8601String());
  }

  /// Récupère la dernière date de synchronisation
  Future<DateTime?> getLastSyncTime() async {
    await init();
    final raw = _storage.get(_keyLastSyncTime);
    if (raw == null) return null;
    return DateTime.tryParse(raw);
  }

  /// Vérifie si les données sont périmées (> 1 heure)
  Future<bool> isDataStale() async {
    final lastSync = await getLastSyncTime();
    if (lastSync == null) return true;
    return DateTime.now().difference(lastSync) > const Duration(hours: 1);
  }

  // ── Nettoyage ──────────────────────────────────────

  /// Efface tout le cache hors-ligne
  Future<void> clearAll() async {
    await init();
    final keys = [
      _keyActiveDeliveries,
      _keyCurrentDelivery,
      _keyCourierProfile,
      _keyWalletBalance,
      _keyLastSyncTime,
      // Ne pas effacer _keyPendingProofs et _keyPendingActions !
    ];
    for (final key in keys) {
      await _storage.delete(key);
    }
    if (kDebugMode) debugPrint('🗑️ [Offline] Cache nettoyé');
  }
}
