import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service de stockage offline pour le fonctionnement hors connexion
/// Stocke les données localement et synchronise quand la connexion revient
class OfflineStorageService {
  final SharedPreferences _prefs;
  
  static const String _prefixData = 'offline_data_';
  static const String _keyLastSync = 'offline_last_sync';
  static const String _keyPendingActions = 'offline_pending_actions';

  OfflineStorageService(this._prefs);

  // ==================== DATA STORAGE ====================

  /// Stocke des données pour usage offline
  Future<bool> storeData<T>({
    required String collection,
    required String id,
    required Map<String, dynamic> data,
  }) async {
    try {
      final key = _dataKey(collection, id);
      final entry = OfflineDataEntry(
        id: id,
        collection: collection,
        data: data,
        lastModified: DateTime.now(),
        isSynced: true,
      );
      
      await _prefs.setString(key, jsonEncode(entry.toJson()));
      
      // Mettre à jour l'index de la collection
      await _addToCollectionIndex(collection, id);
      
      return true;
    } catch (e) {
      if (kDebugMode) debugPrint('❌ [OfflineStorage] Error storing data: $e');
      return false;
    }
  }

  /// Récupère des données stockées
  Map<String, dynamic>? getData({
    required String collection,
    required String id,
  }) {
    try {
      final key = _dataKey(collection, id);
      final jsonString = _prefs.getString(key);
      if (jsonString == null) return null;
      
      final entry = OfflineDataEntry.fromJson(jsonDecode(jsonString));
      return entry.data;
    } catch (e) {
      if (kDebugMode) debugPrint('❌ [OfflineStorage] Error getting data: $e');
      return null;
    }
  }

  /// Récupère tous les éléments d'une collection
  List<Map<String, dynamic>> getAllFromCollection(String collection) {
    try {
      final index = _getCollectionIndex(collection);
      final results = <Map<String, dynamic>>[];
      
      for (final id in index) {
        final data = getData(collection: collection, id: id);
        if (data != null) {
          results.add(data);
        }
      }
      
      return results;
    } catch (e) {
      if (kDebugMode) debugPrint('❌ [OfflineStorage] Error getting collection: $e');
      return [];
    }
  }

  /// Supprime un élément
  Future<bool> removeData({
    required String collection,
    required String id,
  }) async {
    try {
      final key = _dataKey(collection, id);
      await _prefs.remove(key);
      await _removeFromCollectionIndex(collection, id);
      return true;
    } catch (e) {
      if (kDebugMode) debugPrint('❌ [OfflineStorage] Error removing data: $e');
      return false;
    }
  }

  /// Vide une collection entière
  Future<void> clearCollection(String collection) async {
    final index = _getCollectionIndex(collection);
    for (final id in index) {
      await _prefs.remove(_dataKey(collection, id));
    }
    await _prefs.remove(_indexKey(collection));
    if (kDebugMode) debugPrint('🧹 [OfflineStorage] Collection $collection cleared');
  }

  // ==================== PENDING ACTIONS QUEUE ====================

  /// Ajoute une action à la file d'attente de synchronisation
  Future<void> queueAction(PendingAction action) async {
    try {
      final actions = getPendingActions();
      actions.add(action);
      
      final jsonList = actions.map((a) => a.toJson()).toList();
      await _prefs.setString(_keyPendingActions, jsonEncode(jsonList));
      
      if (kDebugMode) debugPrint('📥 [OfflineStorage] Action queued: ${action.type}');
    } catch (e) {
      if (kDebugMode) debugPrint('❌ [OfflineStorage] Error queuing action: $e');
    }
  }

  /// Récupère les actions en attente
  List<PendingAction> getPendingActions() {
    try {
      final jsonString = _prefs.getString(_keyPendingActions);
      if (jsonString == null) return [];
      
      final jsonList = jsonDecode(jsonString) as List;
      return jsonList.map((j) => PendingAction.fromJson(j)).toList();
    } catch (e) {
      if (kDebugMode) debugPrint('❌ [OfflineStorage] Error getting pending actions: $e');
      return [];
    }
  }

  /// Supprime une action de la file
  Future<void> removeAction(String actionId) async {
    final actions = getPendingActions();
    actions.removeWhere((a) => a.id == actionId);
    
    final jsonList = actions.map((a) => a.toJson()).toList();
    await _prefs.setString(_keyPendingActions, jsonEncode(jsonList));
  }

  /// Vide la file d'actions
  Future<void> clearPendingActions() async {
    await _prefs.remove(_keyPendingActions);
  }

  /// Nombre d'actions en attente
  int get pendingActionsCount => getPendingActions().length;

  /// Vérifie s'il y a des actions en attente
  bool get hasPendingActions => pendingActionsCount > 0;

  // ==================== SYNC MANAGEMENT ====================

  /// Enregistre la date de dernière synchronisation
  Future<void> updateLastSyncTime() async {
    await _prefs.setString(_keyLastSync, DateTime.now().toIso8601String());
  }

  /// Retourne la date de dernière synchronisation
  DateTime? getLastSyncTime() {
    final dateStr = _prefs.getString(_keyLastSync);
    if (dateStr == null) return null;
    return DateTime.parse(dateStr);
  }

  /// Temps écoulé depuis la dernière sync
  Duration? getTimeSinceLastSync() {
    final lastSync = getLastSyncTime();
    if (lastSync == null) return null;
    return DateTime.now().difference(lastSync);
  }

  // ==================== COLLECTION INDEX ====================

  Set<String> _getCollectionIndex(String collection) {
    final jsonString = _prefs.getString(_indexKey(collection));
    if (jsonString == null) return {};
    
    final list = jsonDecode(jsonString) as List;
    return list.cast<String>().toSet();
  }

  Future<void> _addToCollectionIndex(String collection, String id) async {
    final index = _getCollectionIndex(collection);
    index.add(id);
    await _prefs.setString(_indexKey(collection), jsonEncode(index.toList()));
  }

  Future<void> _removeFromCollectionIndex(String collection, String id) async {
    final index = _getCollectionIndex(collection);
    index.remove(id);
    await _prefs.setString(_indexKey(collection), jsonEncode(index.toList()));
  }

  // ==================== STORAGE STATS ====================

  /// Retourne les statistiques de stockage
  OfflineStorageStats getStats() {
    final allKeys = _prefs.getKeys();
    final dataKeys = allKeys.where((k) => k.startsWith(_prefixData));
    
    int totalSize = 0;
    final collections = <String, int>{};
    
    for (final key in dataKeys) {
      final value = _prefs.getString(key);
      if (value != null) {
        totalSize += value.length;
        
        // Extraire le nom de la collection
        final parts = key.replaceFirst(_prefixData, '').split('_');
        if (parts.isNotEmpty) {
          final collection = parts.first;
          collections[collection] = (collections[collection] ?? 0) + 1;
        }
      }
    }
    
    return OfflineStorageStats(
      totalEntries: dataKeys.length,
      totalSizeKB: totalSize / 1024,
      pendingActions: pendingActionsCount,
      collections: collections,
      lastSync: getLastSyncTime(),
    );
  }

  // ==================== HELPERS ====================

  String _dataKey(String collection, String id) => '$_prefixData${collection}_$id';
  String _indexKey(String collection) => '${_prefixData}index_$collection';
}

/// Entrée de données offline
class OfflineDataEntry {
  final String id;
  final String collection;
  final Map<String, dynamic> data;
  final DateTime lastModified;
  final bool isSynced;

  OfflineDataEntry({
    required this.id,
    required this.collection,
    required this.data,
    required this.lastModified,
    required this.isSynced,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'collection': collection,
    'data': data,
    'lastModified': lastModified.toIso8601String(),
    'isSynced': isSynced,
  };

  factory OfflineDataEntry.fromJson(Map<String, dynamic> json) {
    return OfflineDataEntry(
      id: json['id'],
      collection: json['collection'],
      data: json['data'],
      lastModified: DateTime.parse(json['lastModified']),
      isSynced: json['isSynced'] ?? true,
    );
  }
}

/// Action en attente de synchronisation
class PendingAction {
  final String id;
  final ActionType type;
  final String collection;
  final String? entityId;
  final Map<String, dynamic>? data;
  final DateTime createdAt;
  final int retryCount;

  PendingAction({
    required this.id,
    required this.type,
    required this.collection,
    this.entityId,
    this.data,
    required this.createdAt,
    this.retryCount = 0,
  });

  PendingAction copyWith({int? retryCount}) {
    return PendingAction(
      id: id,
      type: type,
      collection: collection,
      entityId: entityId,
      data: data,
      createdAt: createdAt,
      retryCount: retryCount ?? this.retryCount,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.name,
    'collection': collection,
    'entityId': entityId,
    'data': data,
    'createdAt': createdAt.toIso8601String(),
    'retryCount': retryCount,
  };

  factory PendingAction.fromJson(Map<String, dynamic> json) {
    return PendingAction(
      id: json['id'],
      type: ActionType.values.firstWhere((e) => e.name == json['type']),
      collection: json['collection'],
      entityId: json['entityId'],
      data: json['data'],
      createdAt: DateTime.parse(json['createdAt']),
      retryCount: json['retryCount'] ?? 0,
    );
  }
}

enum ActionType { create, update, delete }

/// Statistiques du stockage offline
class OfflineStorageStats {
  final int totalEntries;
  final double totalSizeKB;
  final int pendingActions;
  final Map<String, int> collections;
  final DateTime? lastSync;

  OfflineStorageStats({
    required this.totalEntries,
    required this.totalSizeKB,
    required this.pendingActions,
    required this.collections,
    this.lastSync,
  });

  @override
  String toString() {
    return 'OfflineStorageStats(entries: $totalEntries, size: ${totalSizeKB.toStringAsFixed(2)}KB, pending: $pendingActions)';
  }
}

/// Collections prédéfinies
class OfflineCollections {
  static const String orders = 'orders';
  static const String products = 'products';
  static const String categories = 'categories';
  static const String notifications = 'notifications';
  static const String prescriptions = 'prescriptions';
  static const String transactions = 'transactions';
}
