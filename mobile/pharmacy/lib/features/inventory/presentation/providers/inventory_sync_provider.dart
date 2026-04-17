import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/providers/core_providers.dart';
import 'inventory_di_providers.dart';

/// Métadonnées de synchronisation pour l'inventaire.
class InventorySyncMeta {
  /// Dernière synchronisation réussie avec le serveur.
  final DateTime? lastServerSync;

  /// Nombre de modifications en attente de synchronisation.
  final int pendingChangesCount;

  /// Actuellement en mode offline.
  final bool isOffline;

  /// Données proviennent du cache (pas du serveur).
  final bool isFromCache;

  /// Âge des données en minutes.
  final int? dataAgeMinutes;

  const InventorySyncMeta({
    this.lastServerSync,
    this.pendingChangesCount = 0,
    this.isOffline = false,
    this.isFromCache = false,
    this.dataAgeMinutes,
  });

  InventorySyncMeta copyWith({
    DateTime? lastServerSync,
    int? pendingChangesCount,
    bool? isOffline,
    bool? isFromCache,
    int? dataAgeMinutes,
  }) {
    return InventorySyncMeta(
      lastServerSync: lastServerSync ?? this.lastServerSync,
      pendingChangesCount: pendingChangesCount ?? this.pendingChangesCount,
      isOffline: isOffline ?? this.isOffline,
      isFromCache: isFromCache ?? this.isFromCache,
      dataAgeMinutes: dataAgeMinutes ?? this.dataAgeMinutes,
    );
  }

  /// Indique si les données sont périmées (> 30 minutes).
  bool get isStale => dataAgeMinutes != null && dataAgeMinutes! > 30;

  /// Message descriptif de l'état de synchronisation.
  String get statusMessage {
    if (pendingChangesCount > 0) {
      return '$pendingChangesCount modification${pendingChangesCount > 1 ? 's' : ''} en attente';
    }
    if (isOffline && isFromCache) {
      return 'Mode hors-ligne';
    }
    if (isFromCache && lastServerSync != null) {
      final age = DateTime.now().difference(lastServerSync!);
      if (age.inMinutes < 1) return 'Synchro: à l\'instant';
      if (age.inMinutes < 60) return 'Synchro: il y a ${age.inMinutes} min';
      if (age.inHours < 24) return 'Synchro: il y a ${age.inHours}h';
      return 'Synchro: il y a ${age.inDays} jour${age.inDays > 1 ? 's' : ''}';
    }
    return '';
  }
}

/// Clé pour stocker le timestamp de dernière synchro inventaire.
const _inventoryLastSyncKey = 'inventory_last_sync';

/// Provider pour les métadonnées de synchronisation de l'inventaire.
final inventorySyncMetaProvider =
    StateNotifierProvider<InventorySyncMetaNotifier, InventorySyncMeta>(
      (ref) => InventorySyncMetaNotifier(ref),
    );

class InventorySyncMetaNotifier extends StateNotifier<InventorySyncMeta> {
  final Ref _ref;

  InventorySyncMetaNotifier(this._ref) : super(const InventorySyncMeta()) {
    _init();
  }

  Future<void> _init() async {
    await _loadLastSync();
    _watchConnectivity();
    _checkPendingChanges();
  }

  Future<void> _loadLastSync() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timestamp = prefs.getInt(_inventoryLastSyncKey);
      if (timestamp != null) {
        final lastSync = DateTime.fromMillisecondsSinceEpoch(timestamp);
        final age = DateTime.now().difference(lastSync).inMinutes;
        state = state.copyWith(lastServerSync: lastSync, dataAgeMinutes: age);
      }
    } catch (e) {
      if (kDebugMode)
        debugPrint('❌ [InventorySyncMeta] Error loading last sync: $e');
    }
  }

  void _watchConnectivity() {
    _ref.listen<AsyncValue<bool>>(inventoryConnectivityProvider, (prev, next) {
      next.whenData((isConnected) {
        state = state.copyWith(isOffline: !isConnected);

        // Si on revient online, tenter une synchro
        if (isConnected && (prev?.value == false)) {
          _syncPendingChanges();
        }
      });
    });
  }

  Future<void> _checkPendingChanges() async {
    try {
      final offlineStorage = _ref.read(offlineStorageProvider);
      final pendingActions = offlineStorage.getPendingActions();
      final inventoryActions = pendingActions
          .where((a) => a.collection == 'products')
          .length;

      state = state.copyWith(pendingChangesCount: inventoryActions);
    } catch (e) {
      if (kDebugMode)
        debugPrint('❌ [InventorySyncMeta] Error checking pending: $e');
    }
  }

  /// Appelé après une synchronisation réussie avec le serveur.
  Future<void> markSynced() async {
    final now = DateTime.now();
    state = state.copyWith(
      lastServerSync: now,
      isFromCache: false,
      dataAgeMinutes: 0,
      pendingChangesCount: 0,
    );

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_inventoryLastSyncKey, now.millisecondsSinceEpoch);
    } catch (e) {
      if (kDebugMode)
        debugPrint('❌ [InventorySyncMeta] Error saving sync time: $e');
    }
  }

  /// Appelé quand on utilise les données du cache.
  void markFromCache() {
    final age = state.lastServerSync != null
        ? DateTime.now().difference(state.lastServerSync!).inMinutes
        : null;

    state = state.copyWith(isFromCache: true, dataAgeMinutes: age);
  }

  /// Incrémente le compteur de modifications en attente.
  void addPendingChange() {
    state = state.copyWith(pendingChangesCount: state.pendingChangesCount + 1);
  }

  /// Synchronise les modifications en attente.
  Future<void> _syncPendingChanges() async {
    if (state.pendingChangesCount == 0) return;

    try {
      // Note: La synchronisation réelle est gérée par le SyncService
      // Ici on met simplement à jour l'état après vérification
      await _checkPendingChanges();

      // Rafraîchir l'inventaire depuis le serveur
      _ref.invalidate(inventoryRepositoryProvider);
    } catch (e) {
      if (kDebugMode)
        debugPrint('❌ [InventorySyncMeta] Error syncing pending: $e');
    }
  }

  /// Force une synchronisation manuelle.
  Future<bool> forceSync() async {
    if (state.isOffline) return false;

    try {
      await _syncPendingChanges();
      _ref.invalidate(inventoryRepositoryProvider);
      await markSynced();
      return true;
    } catch (e) {
      if (kDebugMode) debugPrint('❌ [InventorySyncMeta] Force sync failed: $e');
      return false;
    }
  }
}

/// Provider de connectivité simplifié pour l'inventaire.
final inventoryConnectivityProvider = StreamProvider<bool>((ref) async* {
  final networkInfo = ref.watch(networkInfoProvider);

  // Vérification initiale
  yield await networkInfo.isConnected;

  // Écouter les changements
  await for (final isConnected in networkInfo.connectivityStream) {
    yield isConnected;
  }
});
