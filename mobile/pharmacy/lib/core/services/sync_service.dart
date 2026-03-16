import 'dart:async';
import 'package:flutter/foundation.dart';
import 'offline_storage_service.dart';
import '../network/api_client.dart';
import '../network/network_info.dart';

/// Service de synchronisation pour gérer le mode offline
/// Synchronise les données entre le stockage local et le serveur
class SyncService {
  final OfflineStorageService _offlineStorage;
  final ApiClient _apiClient;
  final NetworkInfo _networkInfo;
  
  Timer? _syncTimer;
  bool _isSyncing = false;
  
  // Callbacks
  VoidCallback? onSyncStarted;
  VoidCallback? onSyncCompleted;
  Function(String error)? onSyncError;
  Function(int remaining)? onActionSynced;

  SyncService({
    required OfflineStorageService offlineStorage,
    required ApiClient apiClient,
    required NetworkInfo networkInfo,
  })  : _offlineStorage = offlineStorage,
        _apiClient = apiClient,
        _networkInfo = networkInfo;

  /// Démarre la synchronisation automatique
  void startAutoSync({Duration interval = const Duration(minutes: 5)}) {
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(interval, (_) => syncIfNeeded());
    if (kDebugMode) debugPrint('🔄 [SyncService] Auto-sync started (interval: ${interval.inMinutes}min)');
  }

  /// Arrête la synchronisation automatique
  void stopAutoSync() {
    _syncTimer?.cancel();
    _syncTimer = null;
    if (kDebugMode) debugPrint('⏹️ [SyncService] Auto-sync stopped');
  }

  /// Synchronise si nécessaire et si connecté
  Future<SyncResult> syncIfNeeded() async {
    if (_isSyncing) {
      return SyncResult(
        success: false,
        message: 'Synchronisation déjà en cours',
      );
    }

    if (!_offlineStorage.hasPendingActions) {
      return SyncResult(
        success: true,
        message: 'Rien à synchroniser',
        syncedCount: 0,
      );
    }

    final isConnected = await _networkInfo.isConnected;
    if (!isConnected) {
      return SyncResult(
        success: false,
        message: 'Pas de connexion internet',
        pendingCount: _offlineStorage.pendingActionsCount,
      );
    }

    return await syncNow();
  }

  /// Force la synchronisation immédiate
  Future<SyncResult> syncNow() async {
    if (_isSyncing) {
      return SyncResult(
        success: false,
        message: 'Synchronisation déjà en cours',
      );
    }

    _isSyncing = true;
    onSyncStarted?.call();
    
    int syncedCount = 0;
    int failedCount = 0;
    final errors = <String>[];

    try {
      final actions = _offlineStorage.getPendingActions();
      if (kDebugMode) debugPrint('🔄 [SyncService] Starting sync of ${actions.length} actions');

      for (final action in actions) {
        try {
          final success = await _executeAction(action);
          if (success) {
            await _offlineStorage.removeAction(action.id);
            syncedCount++;
            onActionSynced?.call(actions.length - syncedCount - failedCount);
          } else {
            failedCount++;
          }
        } catch (e) {
          if (kDebugMode) debugPrint('❌ [SyncService] Error syncing action ${action.id}: $e');
          errors.add('${action.collection}/${action.entityId}: $e');
          
          // Incrémenter le compteur de retry
          if (action.retryCount < 3) {
            final updatedAction = action.copyWith(retryCount: action.retryCount + 1);
            await _offlineStorage.removeAction(action.id);
            await _offlineStorage.queueAction(updatedAction);
          } else {
            // Trop de tentatives, supprimer l'action
            await _offlineStorage.removeAction(action.id);
            failedCount++;
          }
        }
      }

      await _offlineStorage.updateLastSyncTime();
      
      if (kDebugMode) debugPrint('✅ [SyncService] Sync completed: $syncedCount synced, $failedCount failed');
      
      return SyncResult(
        success: failedCount == 0,
        message: failedCount == 0 
            ? 'Synchronisation réussie'
            : '$failedCount actions en échec',
        syncedCount: syncedCount,
        failedCount: failedCount,
        errors: errors,
      );
    } catch (e) {
      if (kDebugMode) debugPrint('❌ [SyncService] Sync error: $e');
      onSyncError?.call(e.toString());
      return SyncResult(
        success: false,
        message: 'Erreur de synchronisation: $e',
        errors: [e.toString()],
      );
    } finally {
      _isSyncing = false;
      onSyncCompleted?.call();
    }
  }

  /// Exécute une action en attente
  Future<bool> _executeAction(PendingAction action) async {
    switch (action.type) {
      case ActionType.create:
        return await _executeCreate(action);
      case ActionType.update:
        return await _executeUpdate(action);
      case ActionType.delete:
        return await _executeDelete(action);
    }
  }

  Future<bool> _executeCreate(PendingAction action) async {
    if (action.data == null) return false;

    final endpoint = _getEndpoint(action.collection);
    final response = await _apiClient.post(endpoint, data: action.data);
    return response.statusCode == 200 || response.statusCode == 201;
  }

  Future<bool> _executeUpdate(PendingAction action) async {
    if (action.entityId == null || action.data == null) return false;

    final endpoint = '${_getEndpoint(action.collection)}/${action.entityId}';
    final response = await _apiClient.put(endpoint, data: action.data);
    return response.statusCode == 200;
  }

  Future<bool> _executeDelete(PendingAction action) async {
    if (action.entityId == null) return false;

    final endpoint = '${_getEndpoint(action.collection)}/${action.entityId}';
    final response = await _apiClient.delete(endpoint);
    return response.statusCode == 200 || response.statusCode == 204;
  }

  String _getEndpoint(String collection) {
    switch (collection) {
      case OfflineCollections.orders:
        return '/pharmacy/orders';
      case OfflineCollections.products:
        return '/pharmacy/products';
      case OfflineCollections.notifications:
        return '/notifications';
      default:
        return '/$collection';
    }
  }

  /// Vérifie si une synchronisation est en cours
  bool get isSyncing => _isSyncing;

  /// Retourne le nombre d'actions en attente
  int get pendingActionsCount => _offlineStorage.pendingActionsCount;

  /// Nettoie les ressources
  void dispose() {
    stopAutoSync();
  }
}

/// Résultat de synchronisation
class SyncResult {
  final bool success;
  final String message;
  final int syncedCount;
  final int failedCount;
  final int pendingCount;
  final List<String> errors;

  SyncResult({
    required this.success,
    required this.message,
    this.syncedCount = 0,
    this.failedCount = 0,
    this.pendingCount = 0,
    this.errors = const [],
  });

  @override
  String toString() {
    return 'SyncResult(success: $success, synced: $syncedCount, failed: $failedCount, message: $message)';
  }
}
