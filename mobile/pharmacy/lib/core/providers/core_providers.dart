import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';
import '../network/api_client.dart';
import '../network/auth_interceptor.dart';
import '../network/network_info.dart';
import '../services/notification_service.dart';
import '../services/cache_service.dart';
import '../services/security_service.dart';
import '../services/offline_storage_service.dart';
import '../services/sync_service.dart';
import '../services/order_queue_service.dart';
import '../../features/auth/data/datasources/auth_local_datasource.dart';

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('SharedPreferences not initialized');
});

// ==================== SESSION EXPIRED ====================
/// Provider qui signale quand une session a expiré (401 global).
/// Mis à `true` par l'AuthInterceptor quand un 401 est reçu sur une route protégée.
final sessionExpiredProvider = StateProvider<bool>((ref) => false);

final apiClientProvider = Provider<ApiClient>((ref) {
  final authLocalDataSource = AuthLocalDataSourceImpl();
  final authInterceptor = AuthInterceptor(
    localDataSource: authLocalDataSource,
    baseUrl: AppConstants.apiBaseUrl,
    onUnauthorized: () {
      // Signal session expiry — listened in main.dart
      ref.read(sessionExpiredProvider.notifier).state = true;
    },
  );
  final client = ApiClient(authInterceptor: authInterceptor);
  // Attacher le Dio principal pour permettre le replay des requêtes après refresh
  authInterceptor.attachDio(client.dio);
  return client;
});

final networkInfoProvider = Provider<NetworkInfo>((ref) {
  return NetworkInfoImpl();
});

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});

// ==================== CACHE SERVICE ====================
final cacheServiceProvider = Provider<CacheService>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return CacheService(prefs);
});

// ==================== SECURITY SERVICE ====================
final securityServiceProvider = Provider<SecurityService>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  final service = SecurityService(prefs);
  ref.onDispose(() => service.dispose());
  return service;
});

// ==================== OFFLINE STORAGE SERVICE ====================
final offlineStorageProvider = Provider<OfflineStorageService>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return OfflineStorageService(prefs);
});

// ==================== SYNC SERVICE ====================
final syncServiceProvider = Provider<SyncService>((ref) {
  final service = SyncService(
    offlineStorage: ref.watch(offlineStorageProvider),
    apiClient: ref.watch(apiClientProvider),
    networkInfo: ref.watch(networkInfoProvider),
  );
  ref.onDispose(() => service.dispose());
  return service;
});

// ==================== ORDER QUEUE SERVICE ====================
final orderQueueServiceProvider = Provider<OrderQueueService>((ref) {
  return OrderQueueService(
    offlineStorage: ref.watch(offlineStorageProvider),
    networkInfo: ref.watch(networkInfoProvider),
  );
});

// ==================== CONNECTIVITY STATE ====================
final connectivityProvider =
    StateNotifierProvider<ConnectivityNotifier, ConnectivityState>((ref) {
      return ConnectivityNotifier(ref.watch(networkInfoProvider));
    });

class ConnectivityState {
  final bool isConnected;
  final bool hasPendingSync;
  final int pendingActionsCount;

  ConnectivityState({
    required this.isConnected,
    this.hasPendingSync = false,
    this.pendingActionsCount = 0,
  });

  ConnectivityState copyWith({
    bool? isConnected,
    bool? hasPendingSync,
    int? pendingActionsCount,
  }) {
    return ConnectivityState(
      isConnected: isConnected ?? this.isConnected,
      hasPendingSync: hasPendingSync ?? this.hasPendingSync,
      pendingActionsCount: pendingActionsCount ?? this.pendingActionsCount,
    );
  }
}

class ConnectivityNotifier extends StateNotifier<ConnectivityState> {
  final NetworkInfo _networkInfo;
  bool _wasConnected = true;

  ConnectivityNotifier(this._networkInfo)
    : super(ConnectivityState(isConnected: true)) {
    _checkConnectivity();
  }

  Future<void> _checkConnectivity() async {
    final isConnected = await _networkInfo.isConnected;
    _wasConnected = state.isConnected;
    state = state.copyWith(isConnected: isConnected);
  }

  Future<void> checkConnectivity() async {
    await _checkConnectivity();
  }

  /// Vérifie si on vient de retrouver la connexion
  bool get justReconnected => state.isConnected && !_wasConnected;

  void setPendingSync(bool hasPending, int count) {
    state = state.copyWith(
      hasPendingSync: hasPending,
      pendingActionsCount: count,
    );
  }
}

// ==================== AUTO-SYNC ON RECONNECT ====================
/// Provider qui surveille la connectivité et synchronise automatiquement
/// les actions en attente quand la connexion revient
final autoSyncProvider = Provider<void>((ref) {
  ref.listen<ConnectivityState>(connectivityProvider, (previous, next) async {
    // Si on vient de retrouver la connexion et qu'il y a des actions en attente
    if (previous != null && !previous.isConnected && next.isConnected) {
      final syncService = ref.read(syncServiceProvider);
      final offlineStorage = ref.read(offlineStorageProvider);

      if (offlineStorage.hasPendingActions) {
        final result = await syncService.syncNow();

        // Mettre à jour l'état de sync
        final connectivityNotifier = ref.read(connectivityProvider.notifier);
        connectivityNotifier.setPendingSync(
          offlineStorage.hasPendingActions,
          offlineStorage.pendingActionsCount,
        );

        if (result.success && result.syncedCount > 0) {
          // Notifier qu'une sync a eu lieu (peut être écouté par l'UI)
          ref.read(_syncCompletedProvider.notifier).state++;
        }
      }
    }
  });
});

/// Compteur de syncs réussies (pour déclencher des rebuilds UI)
final _syncCompletedProvider = StateProvider<int>((ref) => 0);

/// Provider exposé pour l'UI - incrémenté après chaque sync réussie
final syncCompletedCountProvider = Provider<int>((ref) {
  return ref.watch(_syncCompletedProvider);
});
