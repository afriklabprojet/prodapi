import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod/legacy.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'encrypted_storage_service.dart';
import 'secure_token_service.dart';

/// État de la connexion réseau
enum NetworkStatus {
  online,
  offline,
  weak,
  unknown,
}

/// Priorité d'une action en queue
enum SyncPriority {
  critical,  // Doit être sync immédiatement (ex: livraison terminée)
  high,      // Important (ex: acceptation commande)
  normal,    // Standard
  low,       // Peut attendre (ex: mise à jour profil)
}

/// Action en attente de synchronisation
class PendingSyncAction {
  final String id;
  final String type;
  final String endpoint;
  final String method;
  final Map<String, dynamic>? body;
  final Map<String, String>? headers;
  final SyncPriority priority;
  final DateTime createdAt;
  final int retryCount;
  final int maxRetries;
  final DateTime? lastAttempt;
  final String? errorMessage;

  PendingSyncAction({
    required this.id,
    required this.type,
    required this.endpoint,
    required this.method,
    this.body,
    this.headers,
    this.priority = SyncPriority.normal,
    DateTime? createdAt,
    this.retryCount = 0,
    this.maxRetries = 3,
    this.lastAttempt,
    this.errorMessage,
  }) : createdAt = createdAt ?? DateTime.now();

  PendingSyncAction copyWith({
    String? id,
    String? type,
    String? endpoint,
    String? method,
    Map<String, dynamic>? body,
    Map<String, String>? headers,
    SyncPriority? priority,
    DateTime? createdAt,
    int? retryCount,
    int? maxRetries,
    DateTime? lastAttempt,
    String? errorMessage,
  }) {
    return PendingSyncAction(
      id: id ?? this.id,
      type: type ?? this.type,
      endpoint: endpoint ?? this.endpoint,
      method: method ?? this.method,
      body: body ?? this.body,
      headers: headers ?? this.headers,
      priority: priority ?? this.priority,
      createdAt: createdAt ?? this.createdAt,
      retryCount: retryCount ?? this.retryCount,
      maxRetries: maxRetries ?? this.maxRetries,
      lastAttempt: lastAttempt ?? this.lastAttempt,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type,
    'endpoint': endpoint,
    'method': method,
    'body': body,
    'headers': headers,
    'priority': priority.name,
    'createdAt': createdAt.toIso8601String(),
    'retryCount': retryCount,
    'maxRetries': maxRetries,
    'lastAttempt': lastAttempt?.toIso8601String(),
    'errorMessage': errorMessage,
  };

  factory PendingSyncAction.fromJson(Map<String, dynamic> json) {
    return PendingSyncAction(
      id: json['id'],
      type: json['type'],
      endpoint: json['endpoint'],
      method: json['method'],
      body: json['body'] != null ? Map<String, dynamic>.from(json['body']) : null,
      headers: json['headers'] != null ? Map<String, String>.from(json['headers']) : null,
      priority: SyncPriority.values.firstWhere(
        (p) => p.name == json['priority'],
        orElse: () => SyncPriority.normal,
      ),
      createdAt: DateTime.parse(json['createdAt']),
      retryCount: json['retryCount'] ?? 0,
      maxRetries: json['maxRetries'] ?? 3,
      lastAttempt: json['lastAttempt'] != null ? DateTime.parse(json['lastAttempt']) : null,
      errorMessage: json['errorMessage'],
    );
  }

  bool get canRetry => retryCount < maxRetries;
  
  Duration get retryDelay {
    // Backoff exponentiel: 1s, 2s, 4s, 8s...
    return Duration(seconds: (1 << retryCount).clamp(1, 60));
  }
}

/// Données en cache
class CachedData {
  final String key;
  final dynamic data;
  final DateTime cachedAt;
  final Duration? ttl;
  final String? etag;
  final bool isDirty;

  CachedData({
    required this.key,
    required this.data,
    DateTime? cachedAt,
    this.ttl,
    this.etag,
    this.isDirty = false,
  }) : cachedAt = cachedAt ?? DateTime.now();

  bool get isExpired {
    if (ttl == null) return false;
    return DateTime.now().difference(cachedAt) > ttl!;
  }

  Map<String, dynamic> toJson() => {
    'key': key,
    'data': data,
    'cachedAt': cachedAt.toIso8601String(),
    'ttl': ttl?.inSeconds,
    'etag': etag,
    'isDirty': isDirty,
  };

  factory CachedData.fromJson(Map<String, dynamic> json) {
    return CachedData(
      key: json['key'],
      data: json['data'],
      cachedAt: DateTime.parse(json['cachedAt']),
      ttl: json['ttl'] != null ? Duration(seconds: json['ttl']) : null,
      etag: json['etag'],
      isDirty: json['isDirty'] ?? false,
    );
  }
}

/// État du mode hors-ligne
class OfflineState {
  final NetworkStatus networkStatus;
  final int pendingActionsCount;
  final int cachedItemsCount;
  final DateTime? lastSyncAt;
  final bool isSyncing;
  final double syncProgress;
  final String? syncError;

  const OfflineState({
    this.networkStatus = NetworkStatus.unknown,
    this.pendingActionsCount = 0,
    this.cachedItemsCount = 0,
    this.lastSyncAt,
    this.isSyncing = false,
    this.syncProgress = 0,
    this.syncError,
  });

  OfflineState copyWith({
    NetworkStatus? networkStatus,
    int? pendingActionsCount,
    int? cachedItemsCount,
    DateTime? lastSyncAt,
    bool? isSyncing,
    double? syncProgress,
    String? syncError,
  }) {
    return OfflineState(
      networkStatus: networkStatus ?? this.networkStatus,
      pendingActionsCount: pendingActionsCount ?? this.pendingActionsCount,
      cachedItemsCount: cachedItemsCount ?? this.cachedItemsCount,
      lastSyncAt: lastSyncAt ?? this.lastSyncAt,
      isSyncing: isSyncing ?? this.isSyncing,
      syncProgress: syncProgress ?? this.syncProgress,
      syncError: syncError,
    );
  }

  bool get isOnline => networkStatus == NetworkStatus.online;
  bool get isOffline => networkStatus == NetworkStatus.offline;
  bool get hasPendingActions => pendingActionsCount > 0;
}

/// Service de mode hors-ligne
class OfflineModeService extends StateNotifier<OfflineState> {
  OfflineModeService() : super(const OfflineState());

  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  
  Box<String>? _syncQueueBox;
  Box<String>? _cacheBox;
  
  Timer? _syncTimer;
  Timer? _pingTimer;
  
  final List<Function(NetworkStatus)> _networkChangeListeners = [];

  /// Initialiser le service
  Future<void> initialize() async {
    // Initialiser Hive chiffré
    final encryptedStorage = EncryptedStorageService.instance;
    await encryptedStorage.initialize();
    _syncQueueBox = await encryptedStorage.openEncryptedBox('sync_queue');
    _cacheBox = await encryptedStorage.openEncryptedBox('offline_cache');
    
    // Charger l'état initial
    await _loadState();
    
    // Écouter les changements de connectivité
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(_onConnectivityChanged);
    
    // Vérifier la connectivité initiale
    final result = await _connectivity.checkConnectivity();
    await _onConnectivityChanged(result);
    
    // Timer de vérification périodique
    _pingTimer = Timer.periodic(const Duration(seconds: 30), (_) => _checkRealConnectivity());
    
    if (kDebugMode) debugPrint('📶 Offline Mode Service initialized');
  }

  /// Charger l'état depuis le stockage
  Future<void> _loadState() async {
    final pendingCount = _syncQueueBox?.length ?? 0;
    final cachedCount = _cacheBox?.length ?? 0;
    
    final prefs = await SharedPreferences.getInstance();
    final lastSyncStr = prefs.getString('last_sync_at');
    
    state = state.copyWith(
      pendingActionsCount: pendingCount,
      cachedItemsCount: cachedCount,
      lastSyncAt: lastSyncStr != null ? DateTime.parse(lastSyncStr) : null,
    );
  }

  /// Gérer les changements de connectivité
  Future<void> _onConnectivityChanged(List<ConnectivityResult> results) async {
    final result = results.isNotEmpty ? results.first : ConnectivityResult.none;
    
    NetworkStatus newStatus;
    switch (result) {
      case ConnectivityResult.wifi:
      case ConnectivityResult.ethernet:
        newStatus = NetworkStatus.online;
        break;
      case ConnectivityResult.mobile:
        // Vérifier la qualité de la connexion
        newStatus = await _checkRealConnectivity() ? NetworkStatus.online : NetworkStatus.weak;
        break;
      case ConnectivityResult.none:
        newStatus = NetworkStatus.offline;
        break;
      default:
        newStatus = NetworkStatus.unknown;
    }
    
    final previousStatus = state.networkStatus;
    state = state.copyWith(networkStatus: newStatus);
    
    // Notifier les listeners
    for (final listener in _networkChangeListeners) {
      listener(newStatus);
    }
    
    // Déclencher la synchronisation si on passe de offline à online
    if (previousStatus == NetworkStatus.offline && newStatus == NetworkStatus.online) {
      if (kDebugMode) debugPrint('📶 Back online! Starting sync...');
      await syncPendingActions();
    }
    
    if (kDebugMode) debugPrint('📶 Network status: $newStatus');
  }

  /// Vérifier la connectivité réelle avec un ping
  Future<bool> _checkRealConnectivity() async {
    try {
      final dio = Dio(BaseOptions(
        connectTimeout: const Duration(seconds: 5),
        receiveTimeout: const Duration(seconds: 5),
      ));
      final response = await dio.get('https://www.google.com/generate_204');
      return response.statusCode == 204 || response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Ajouter une action à la queue de synchronisation
  Future<void> queueAction(PendingSyncAction action) async {
    if (_syncQueueBox == null) return;
    
    await _syncQueueBox!.put(action.id, jsonEncode(action.toJson()));
    
    state = state.copyWith(
      pendingActionsCount: _syncQueueBox!.length,
    );
    
    if (kDebugMode) debugPrint('📤 Queued action: ${action.type} (${action.id})');
    
    // Si on est en ligne, essayer de sync immédiatement pour les actions critiques
    if (state.isOnline && action.priority == SyncPriority.critical) {
      await syncPendingActions();
    }
  }

  /// Supprimer une action de la queue
  Future<void> removeAction(String id) async {
    if (_syncQueueBox == null) return;
    
    await _syncQueueBox!.delete(id);
    
    state = state.copyWith(
      pendingActionsCount: _syncQueueBox!.length,
    );
  }

  /// Obtenir toutes les actions en attente
  List<PendingSyncAction> getPendingActions() {
    if (_syncQueueBox == null) return [];
    
    final actions = <PendingSyncAction>[];
    for (final key in _syncQueueBox!.keys) {
      final json = _syncQueueBox!.get(key);
      if (json != null) {
        actions.add(PendingSyncAction.fromJson(jsonDecode(json)));
      }
    }
    
    // Trier par priorité puis par date
    actions.sort((a, b) {
      final priorityCompare = a.priority.index.compareTo(b.priority.index);
      if (priorityCompare != 0) return priorityCompare;
      return a.createdAt.compareTo(b.createdAt);
    });
    
    return actions;
  }

  /// Synchroniser les actions en attente
  Future<void> syncPendingActions() async {
    if (!state.isOnline || state.isSyncing) return;
    
    final actions = getPendingActions();
    if (actions.isEmpty) return;
    
    state = state.copyWith(isSyncing: true, syncProgress: 0, syncError: null);
    
    if (kDebugMode) debugPrint('🔄 Starting sync of ${actions.length} actions...');
    
    int completed = 0;
    final errors = <String>[];
    
    for (final action in actions) {
      try {
        await _executeAction(action);
        await removeAction(action.id);
        completed++;
        
        state = state.copyWith(
          syncProgress: completed / actions.length,
        );
      } catch (e) {
        if (kDebugMode) debugPrint('❌ Sync error for ${action.id}: $e');
        
        if (action.canRetry) {
          // Mettre à jour avec retry count
          final updatedAction = action.copyWith(
            retryCount: action.retryCount + 1,
            lastAttempt: DateTime.now(),
            errorMessage: e.toString(),
          );
          await _syncQueueBox!.put(action.id, jsonEncode(updatedAction.toJson()));
        } else {
          errors.add('${action.type}: $e');
        }
      }
    }
    
    // Sauvegarder la date de dernière sync
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('last_sync_at', DateTime.now().toIso8601String());
    
    state = state.copyWith(
      isSyncing: false,
      syncProgress: 1.0,
      lastSyncAt: DateTime.now(),
      pendingActionsCount: _syncQueueBox?.length ?? 0,
      syncError: errors.isNotEmpty ? errors.join('\n') : null,
    );
    
    if (kDebugMode) debugPrint('✅ Sync completed: $completed/${actions.length}');
  }

  /// Exécuter une action en attente via l'API
  Future<void> _executeAction(PendingSyncAction action) async {
    final token = await SecureTokenService.instance.getToken();
    if (token == null || token.isEmpty) {
      throw Exception('Token d\'authentification manquant pour la sync offline');
    }

    final dio = Dio(BaseOptions(
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        if (action.headers != null) ...action.headers!,
      },
    ));

    Response response;
    switch (action.method.toUpperCase()) {
      case 'POST':
        response = await dio.post(action.endpoint, data: action.body);
        break;
      case 'PUT':
        response = await dio.put(action.endpoint, data: action.body);
        break;
      case 'PATCH':
        response = await dio.patch(action.endpoint, data: action.body);
        break;
      case 'DELETE':
        response = await dio.delete(action.endpoint, data: action.body);
        break;
      default:
        response = await dio.get(action.endpoint);
    }

    if (response.statusCode != null && response.statusCode! >= 400) {
      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        message: 'Erreur serveur: ${response.statusCode}',
      );
    }

    if (kDebugMode) debugPrint('✅ Executed action: ${action.type} ${action.method} ${action.endpoint}');
  }

  // ============ CACHE INTELLIGENT ============

  /// Mettre en cache des données
  Future<void> cacheData(String key, dynamic data, {Duration? ttl, String? etag}) async {
    if (_cacheBox == null) return;
    
    final cached = CachedData(
      key: key,
      data: data,
      ttl: ttl,
      etag: etag,
    );
    
    await _cacheBox!.put(key, jsonEncode(cached.toJson()));
    
    state = state.copyWith(
      cachedItemsCount: _cacheBox!.length,
    );
  }

  /// Récupérer des données du cache
  CachedData? getCachedData(String key, {bool ignoreExpiry = false}) {
    if (_cacheBox == null) return null;
    
    final json = _cacheBox!.get(key);
    if (json == null) return null;
    
    final cached = CachedData.fromJson(jsonDecode(json));
    
    if (!ignoreExpiry && cached.isExpired) {
      // Supprimer du cache si expiré
      _cacheBox!.delete(key);
      return null;
    }
    
    return cached;
  }

  /// Vérifier si des données sont en cache
  bool hasCachedData(String key) {
    final cached = getCachedData(key);
    return cached != null;
  }

  /// Marquer des données comme "dirty" (à re-sync)
  Future<void> markDirty(String key) async {
    if (_cacheBox == null) return;
    
    final json = _cacheBox!.get(key);
    if (json == null) return;
    
    final cached = CachedData.fromJson(jsonDecode(json));
    final dirtyCached = CachedData(
      key: cached.key,
      data: cached.data,
      cachedAt: cached.cachedAt,
      ttl: cached.ttl,
      etag: cached.etag,
      isDirty: true,
    );
    
    await _cacheBox!.put(key, jsonEncode(dirtyCached.toJson()));
  }

  /// Nettoyer le cache expiré
  Future<void> cleanExpiredCache() async {
    if (_cacheBox == null) return;
    
    final keysToDelete = <String>[];
    
    for (final key in _cacheBox!.keys) {
      final json = _cacheBox!.get(key);
      if (json != null) {
        final cached = CachedData.fromJson(jsonDecode(json));
        if (cached.isExpired) {
          keysToDelete.add(key as String);
        }
      }
    }
    
    for (final key in keysToDelete) {
      await _cacheBox!.delete(key);
    }
    
    state = state.copyWith(
      cachedItemsCount: _cacheBox!.length,
    );
    
    if (kDebugMode) debugPrint('🧹 Cleaned ${keysToDelete.length} expired cache entries');
  }

  /// Vider tout le cache
  Future<void> clearCache() async {
    await _cacheBox?.clear();
    state = state.copyWith(cachedItemsCount: 0);
  }

  /// Vider la queue de synchronisation
  Future<void> clearSyncQueue() async {
    await _syncQueueBox?.clear();
    state = state.copyWith(pendingActionsCount: 0);
  }

  // ============ LISTENERS ============

  /// Ajouter un listener pour les changements de réseau
  void addNetworkChangeListener(Function(NetworkStatus) listener) {
    _networkChangeListeners.add(listener);
  }

  /// Supprimer un listener
  void removeNetworkChangeListener(Function(NetworkStatus) listener) {
    _networkChangeListeners.remove(listener);
  }

  // ============ CACHE KEYS PRÉDÉFINIS ============
  
  static const String cacheKeyProfile = 'profile';
  static const String cacheKeyDeliveries = 'deliveries';
  static const String cacheKeyActiveDelivery = 'active_delivery';
  static const String cacheKeyEarnings = 'earnings';
  static const String cacheKeyStats = 'stats';
  static const String cacheKeyPharmacies = 'pharmacies';
  static const String cacheKeySettings = 'settings';

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    _syncTimer?.cancel();
    _pingTimer?.cancel();
    _syncQueueBox?.close();
    _cacheBox?.close();
    super.dispose();
  }
}

/// Provider
final offlineModeServiceProvider = StateNotifierProvider<OfflineModeService, OfflineState>((ref) {
  final service = OfflineModeService();
  return service;
});

/// Provider pour le statut réseau
final networkStatusProvider = Provider<NetworkStatus>((ref) {
  return ref.watch(offlineModeServiceProvider).networkStatus;
});

/// Provider pour savoir si on est en ligne (offline_mode)
final offlineModeIsOnlineProvider = Provider<bool>((ref) {
  return ref.watch(offlineModeServiceProvider).isOnline;
});

/// Provider pour les actions en attente
final pendingActionsCountProvider = Provider<int>((ref) {
  return ref.watch(offlineModeServiceProvider).pendingActionsCount;
});

/// Widget indicateur de réseau
class NetworkStatusIndicator {
  static String getIcon(NetworkStatus status) {
    switch (status) {
      case NetworkStatus.online:
        return '📶';
      case NetworkStatus.offline:
        return '📵';
      case NetworkStatus.weak:
        return '📶'; // avec indicateur faible
      case NetworkStatus.unknown:
        return '❓';
    }
  }

  static String getLabel(NetworkStatus status) {
    switch (status) {
      case NetworkStatus.online:
        return 'En ligne';
      case NetworkStatus.offline:
        return 'Hors ligne';
      case NetworkStatus.weak:
        return 'Connexion faible';
      case NetworkStatus.unknown:
        return 'Vérification...';
    }
  }
}
