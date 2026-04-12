import 'package:flutter/foundation.dart';
import '../network/network_info.dart';
import 'offline_storage_service.dart';

/// Types d'actions sur les commandes pouvant être mises en file d'attente
enum OrderActionType {
  confirm('confirm', 'Confirmation'),
  markReady('mark_ready', 'Prête'),
  reject('reject', 'Rejet'),
  deliver('deliver', 'Livraison');

  final String value;
  final String displayName;
  const OrderActionType(this.value, this.displayName);
}

/// Résultat d'une action sur commande
class OrderActionResult {
  final bool success;
  final bool isQueued;
  final String? errorMessage;
  final String? queuedActionId;

  const OrderActionResult({
    required this.success,
    this.isQueued = false,
    this.errorMessage,
    this.queuedActionId,
  });

  /// Action réussie immédiatement
  factory OrderActionResult.success() => const OrderActionResult(success: true);

  /// Action mise en file d'attente (offline)
  factory OrderActionResult.queued(String actionId) => OrderActionResult(
    success: true,
    isQueued: true,
    queuedActionId: actionId,
  );

  /// Échec de l'action
  factory OrderActionResult.failure(String message) =>
      OrderActionResult(success: false, errorMessage: message);
}

/// Service de gestion des actions commande avec support offline
/// Gère la file d'attente et la synchronisation automatique
class OrderQueueService {
  final OfflineStorageService _offlineStorage;
  final NetworkInfo _networkInfo;

  // Callbacks pour notifier l'UI
  Function(int orderId, OrderActionType action)? onActionQueued;
  Function(int orderId, OrderActionType action)? onActionSynced;
  Function(int orderId, String error)? onActionFailed;

  OrderQueueService({
    required OfflineStorageService offlineStorage,
    required NetworkInfo networkInfo,
  }) : _offlineStorage = offlineStorage,
       _networkInfo = networkInfo;

  /// Met en file d'attente une action sur commande
  Future<OrderActionResult> queueOrderAction({
    required int orderId,
    required OrderActionType action,
    String? reason,
  }) async {
    final actionId =
        '${action.value}_order_${orderId}_${DateTime.now().millisecondsSinceEpoch}';

    final pendingAction = PendingAction(
      id: actionId,
      type: ActionType.update,
      collection: OfflineCollections.orders,
      entityId: orderId.toString(),
      data: {
        'action': action.value,
        'orderId': orderId,
        if (reason != null) 'reason': reason,
      },
      createdAt: DateTime.now(),
    );

    await _offlineStorage.queueAction(pendingAction);

    if (kDebugMode) {
      debugPrint(
        '📥 [OrderQueue] Action queued: ${action.displayName} for order #$orderId',
      );
    }

    onActionQueued?.call(orderId, action);

    return OrderActionResult.queued(actionId);
  }

  /// Retourne les actions en attente pour une commande spécifique
  List<PendingAction> getPendingActionsForOrder(int orderId) {
    return _offlineStorage
        .getPendingActions()
        .where(
          (a) =>
              a.collection == OfflineCollections.orders &&
              a.entityId == orderId.toString(),
        )
        .toList();
  }

  /// Vérifie si une commande a des actions en attente
  bool hasOrderPendingActions(int orderId) {
    return getPendingActionsForOrder(orderId).isNotEmpty;
  }

  /// Retourne le nombre total d'actions commande en attente
  int get pendingOrderActionsCount {
    return _offlineStorage
        .getPendingActions()
        .where((a) => a.collection == OfflineCollections.orders)
        .length;
  }

  /// Vérifie si on est connecté au réseau
  Future<bool> isConnected() => _networkInfo.isConnected;

  /// Annule une action en attente
  Future<void> cancelPendingAction(String actionId) async {
    await _offlineStorage.removeAction(actionId);
    if (kDebugMode) {
      debugPrint('🗑️ [OrderQueue] Action cancelled: $actionId');
    }
  }

  /// Annule toutes les actions en attente pour une commande
  Future<void> cancelAllPendingActionsForOrder(int orderId) async {
    final actions = getPendingActionsForOrder(orderId);
    for (final action in actions) {
      await _offlineStorage.removeAction(action.id);
    }
    if (kDebugMode) {
      debugPrint('🗑️ [OrderQueue] All actions cancelled for order #$orderId');
    }
  }

  /// Retourne un résumé des actions en attente
  Map<OrderActionType, int> getPendingActionsSummary() {
    final actions = _offlineStorage.getPendingActions().where(
      (a) => a.collection == OfflineCollections.orders,
    );

    final summary = <OrderActionType, int>{};
    for (final action in actions) {
      final actionType = _parseActionType(action.data?['action'] as String?);
      if (actionType != null) {
        summary[actionType] = (summary[actionType] ?? 0) + 1;
      }
    }
    return summary;
  }

  OrderActionType? _parseActionType(String? value) {
    if (value == null) return null;
    return OrderActionType.values.cast<OrderActionType?>().firstWhere(
      (e) => e?.value == value,
      orElse: () => null,
    );
  }
}
