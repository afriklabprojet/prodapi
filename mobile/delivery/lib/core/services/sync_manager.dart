import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod/legacy.dart';
import 'connectivity_service.dart';
import 'offline_service.dart';
import '../network/api_client.dart';
import '../../data/repositories/delivery_repository.dart';

/// État de la synchronisation
class SyncState {
  final bool isSyncing;
  final int totalPending;
  final int synced;
  final String? currentAction;
  final List<SyncResult> results;
  final DateTime? lastSyncTime;

  const SyncState({
    this.isSyncing = false,
    this.totalPending = 0,
    this.synced = 0,
    this.currentAction,
    this.results = const [],
    this.lastSyncTime,
  });

  SyncState copyWith({
    bool? isSyncing,
    int? totalPending,
    int? synced,
    String? currentAction,
    List<SyncResult>? results,
    DateTime? lastSyncTime,
  }) {
    return SyncState(
      isSyncing: isSyncing ?? this.isSyncing,
      totalPending: totalPending ?? this.totalPending,
      synced: synced ?? this.synced,
      currentAction: currentAction ?? this.currentAction,
      results: results ?? this.results,
      lastSyncTime: lastSyncTime ?? this.lastSyncTime,
    );
  }

  double get progress => totalPending > 0 ? synced / totalPending : 0;
  bool get hasFailures => results.any((r) => !r.success);
  int get failureCount => results.where((r) => !r.success).length;
  int get successCount => results.where((r) => r.success).length;
}

/// Résultat d'une synchronisation d'élément
class SyncResult {
  final String type;
  final int itemId;
  final bool success;
  final String? errorMessage;
  final DateTime timestamp;

  SyncResult({
    required this.type,
    required this.itemId,
    required this.success,
    this.errorMessage,
  }) : timestamp = DateTime.now();
}

/// Gestionnaire de synchronisation automatique
///
/// - Surveille les changements de connectivité
/// - Synchronise automatiquement les données en attente quand la connexion revient
/// - Gère les preuves de livraison, les actions, et les mises à jour de position
class SyncManager extends StateNotifier<SyncState> {
  final Ref _ref;
  bool _wasOffline = false;
  bool _disposed = false;

  SyncManager(this._ref) : super(const SyncState()) {
    _init();
  }

  void _init() {
    // Écouter les changements de connectivité via provider subscription
    _ref.listen<ConnectivityState>(
      connectivityProvider,
      (previous, next) {
        _onConnectivityChanged(previous, next);
      },
    );
    
    // Mettre à jour le compteur initial
    _updatePendingCount();
  }

  void _onConnectivityChanged(ConnectivityState? previous, ConnectivityState next) {
    // Si on était hors-ligne et qu'on revient en ligne
    if (_wasOffline && next.isOnline) {
      if (kDebugMode) debugPrint('🔄 [SyncManager] Reconnexion détectée, lancement de la synchronisation...');
      syncAll();
    }
    
    _wasOffline = next.isOffline;
    
    // Mettre à jour le provider de connectivité avec le compteur
    if (next.isOnline) {
      _updatePendingCount();
    }
  }

  /// Met à jour le compteur d'éléments en attente
  Future<void> _updatePendingCount() async {
    final actionsCount = await OfflineService.instance.getPendingActionsCount();
    final proofsCount = await OfflineService.instance.getPendingProofsCount();
    final total = actionsCount + proofsCount;
    
    if (_disposed) return;
    state = state.copyWith(totalPending: total);
    
    // Mettre à jour aussi le provider de connectivité
    try {
      _ref.read(connectivityProvider.notifier).updatePendingSyncCount(total);
    } catch (_) {
      // Provider peut être en cours de destruction
    }
  }

  /// Synchronise toutes les données en attente
  Future<void> syncAll() async {
    if (state.isSyncing) {
      if (kDebugMode) debugPrint('⏳ [SyncManager] Sync déjà en cours, ignoré');
      return;
    }

    // Vérifier qu'on est en ligne
    final connectivity = _ref.read(connectivityProvider);
    if (!connectivity.isOnline) {
      if (kDebugMode) debugPrint('📴 [SyncManager] Pas de connexion, sync annulée');
      return;
    }

    await _updatePendingCount();
    
    if (state.totalPending == 0) {
      if (kDebugMode) debugPrint('✅ [SyncManager] Rien à synchroniser');
      return;
    }

    if (_disposed) return;
    state = state.copyWith(
      isSyncing: true,
      synced: 0,
      results: [],
    );
    try {
      _ref.read(connectivityProvider.notifier).setSyncing(true);
    } catch (_) {
      // Provider peut être en cours de destruction
    }

    if (kDebugMode) debugPrint('🔄 [SyncManager] Début de la synchronisation (${state.totalPending} éléments)...');

    final results = <SyncResult>[];

    try {
      // 1. Synchroniser les preuves de livraison
      results.addAll(await _syncPendingProofs());
      
      // 2. Synchroniser les actions en attente
      results.addAll(await _syncPendingActions());
      
      // 3. Rafraîchir les données depuis le serveur
      await _refreshData();
      
    } catch (e) {
      if (kDebugMode) debugPrint('❌ [SyncManager] Erreur générale: $e');
    } finally {
      if (!_disposed) {
        state = state.copyWith(
          isSyncing: false,
          results: results,
          lastSyncTime: DateTime.now(),
        );
        try {
          _ref.read(connectivityProvider.notifier).setSyncing(false);
        } catch (_) {
          // Provider peut être disposed pendant le sync
        }
      }
      await _updatePendingCount();

      if (kDebugMode) {
        final successes = results.where((r) => r.success).length;
        final failures = results.where((r) => !r.success).length;
        debugPrint('✅ [SyncManager] Sync terminée: $successes succès, $failures échecs');
      }
    }
  }

  /// Synchronise les preuves de livraison en attente
  Future<List<SyncResult>> _syncPendingProofs() async {
    final results = <SyncResult>[];
    final proofs = await OfflineService.instance.getPendingProofsAndClear();
    
    if (proofs.isEmpty) return results;

    if (kDebugMode) debugPrint('📸 [SyncManager] Sync ${proofs.length} preuves...');

    if (!_disposed) state = state.copyWith(currentAction: 'Envoi des preuves de livraison...');

    for (final proof in proofs) {
      try {
        final deliveryId = proof['delivery_id'] as int;
        
        // Envoyer la preuve au serveur
        await _uploadProof(proof);
        
        results.add(SyncResult(
          type: 'proof',
          itemId: deliveryId,
          success: true,
        ));
        
        if (!_disposed) state = state.copyWith(synced: state.synced + 1);
        
      } catch (e) {
        if (kDebugMode) debugPrint('❌ [SyncManager] Erreur upload preuve: $e');
        
        // Remettre la preuve en attente pour réessayer plus tard
        await OfflineService.instance.addPendingProof(
          deliveryId: proof['delivery_id'] as int,
          photoBase64: proof['photo_base64'] as String?,
          signatureBase64: proof['signature_base64'] as String?,
          notes: proof['notes'] as String?,
          latitude: proof['latitude'] as double?,
          longitude: proof['longitude'] as double?,
        );
        
        results.add(SyncResult(
          type: 'proof',
          itemId: proof['delivery_id'] as int,
          success: false,
          errorMessage: e.toString(),
        ));
      }
    }

    return results;
  }

  Future<void> _uploadProof(Map<String, dynamic> proof) async {
    final dio = _ref.read(dioProvider);
    final deliveryId = proof['delivery_id'] as int;
    
    await dio.post(
      '/courier/deliveries/$deliveryId/proof',
      data: {
        'photo': proof['photo_base64'],
        'signature': proof['signature_base64'],
        'notes': proof['notes'],
        'latitude': proof['latitude'],
        'longitude': proof['longitude'],
      },
    );
  }

  /// Synchronise les actions en attente (pickup, deliver, etc.)
  Future<List<SyncResult>> _syncPendingActions() async {
    final results = <SyncResult>[];
    final actions = await OfflineService.instance.getPendingActionsAndClear();
    
    if (actions.isEmpty) return results;

    if (kDebugMode) debugPrint('🎯 [SyncManager] Sync ${actions.length} actions...');

    if (!_disposed) state = state.copyWith(currentAction: 'Synchronisation des actions...');

    final dio = _ref.read(dioProvider);

    for (final action in actions) {
      try {
        final type = action['type'] as String;
        final deliveryId = action['delivery_id'] as int;
        final data = action['data'] as Map<String, dynamic>?;
        
        switch (type) {
          case 'pickup':
            await dio.post('/courier/deliveries/$deliveryId/pickup');
            break;
          case 'deliver':
            await dio.post('/courier/deliveries/$deliveryId/complete', data: data);
            break;
          case 'location_update':
            if (data != null) {
              await dio.post('/courier/location', data: data);
            }
            break;
          default:
            if (kDebugMode) debugPrint('⚠️ [SyncManager] Action inconnue: $type');
        }
        
        results.add(SyncResult(
          type: type,
          itemId: deliveryId,
          success: true,
        ));
        
        if (!_disposed) state = state.copyWith(synced: state.synced + 1);
        
      } catch (e) {
        if (kDebugMode) debugPrint('❌ [SyncManager] Erreur action: $e');
        
        // Remettre l'action en attente pour réessayer
        await OfflineService.instance.addPendingAction(
          type: action['type'] as String,
          deliveryId: action['delivery_id'] as int,
          data: action['data'] as Map<String, dynamic>?,
        );
        
        results.add(SyncResult(
          type: action['type'] as String,
          itemId: action['delivery_id'] as int,
          success: false,
          errorMessage: e.toString(),
        ));
      }
    }

    return results;
  }

  /// Rafraîchit les données depuis le serveur après sync
  Future<void> _refreshData() async {
    if (_disposed) return;
    state = state.copyWith(currentAction: 'Actualisation des données...');
    
    try {
      final deliveryRepo = _ref.read(deliveryRepositoryProvider);
      
      // Rafraîchir les livraisons actives
      await deliveryRepo.getDeliveries(status: 'active');
      
      // Rafraîchir le profil
      await deliveryRepo.getProfile();
      
      if (kDebugMode) debugPrint('✅ [SyncManager] Données rafraîchies');
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ [SyncManager] Erreur rafraîchissement: $e');
    }
  }

  /// Force une synchronisation manuelle
  Future<void> forceSync() async {
    if (kDebugMode) debugPrint('🔄 [SyncManager] Sync forcée par l\'utilisateur');
    await syncAll();
  }

  /// Ajoute une action à synchroniser plus tard (quand hors-ligne)
  Future<void> queueAction({
    required String type,
    required int deliveryId,
    Map<String, dynamic>? data,
  }) async {
    await OfflineService.instance.addPendingAction(
      type: type,
      deliveryId: deliveryId,
      data: data,
    );
    await _updatePendingCount();
  }

  @override
  void dispose() {
    _disposed = true;
    // Provider subscription is automatically managed by Riverpod
    super.dispose();
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// PROVIDERS RIVERPOD
// ══════════════════════════════════════════════════════════════════════════════

/// Provider du gestionnaire de synchronisation
final syncManagerProvider = StateNotifierProvider<SyncManager, SyncState>((ref) {
  return SyncManager(ref);
});

/// Provider pour forcer une sync
final forceSyncProvider = Provider((ref) {
  return () => ref.read(syncManagerProvider.notifier).forceSync();
});

/// Provider booléen indiquant si une sync est en cours
final isSyncingProvider = Provider<bool>((ref) {
  return ref.watch(syncManagerProvider).isSyncing;
});
