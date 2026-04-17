import 'dart:async';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../config/providers.dart';
import '../../features/orders/domain/entities/order_item_entity.dart';
import '../../features/orders/domain/entities/delivery_address_entity.dart';
import '../../features/profile/domain/entities/update_profile_entity.dart';
import '../providers/connectivity_provider.dart';
import '../services/app_logger.dart';

/// Type d'action en file d'attente
enum QueuedActionType {
  createOrder,
  updateProfile,
  submitPrescription,
}

/// Action en file d'attente pour exécution quand online
class QueuedAction {
  final String id;
  final QueuedActionType type;
  final Map<String, dynamic> payload;
  final DateTime queuedAt;
  final int retryCount;

  QueuedAction({
    required this.id,
    required this.type,
    required this.payload,
    required this.queuedAt,
    this.retryCount = 0,
  });

  QueuedAction copyWith({int? retryCount}) {
    return QueuedAction(
      id: id,
      type: type,
      payload: payload,
      queuedAt: queuedAt,
      retryCount: retryCount ?? this.retryCount,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'payload': payload,
        'queuedAt': queuedAt.toIso8601String(),
        'retryCount': retryCount,
      };

  factory QueuedAction.fromJson(Map<String, dynamic> json) => QueuedAction(
        id: json['id'] as String,
        type: QueuedActionType.values.firstWhere(
          (t) => t.name == json['type'],
          orElse: () => QueuedActionType.createOrder,
        ),
        payload: json['payload'] as Map<String, dynamic>,
        queuedAt: DateTime.parse(json['queuedAt'] as String),
        retryCount: json['retryCount'] as int? ?? 0,
      );
}

/// État de la file d'attente offline
class OfflineQueueState {
  final List<QueuedAction> pendingActions;
  final bool isSyncing;
  final String? lastError;

  const OfflineQueueState({
    this.pendingActions = const [],
    this.isSyncing = false,
    this.lastError,
  });

  int get pendingCount => pendingActions.length;
  bool get hasPending => pendingActions.isNotEmpty;

  OfflineQueueState copyWith({
    List<QueuedAction>? pendingActions,
    bool? isSyncing,
    String? lastError,
  }) {
    return OfflineQueueState(
      pendingActions: pendingActions ?? this.pendingActions,
      isSyncing: isSyncing ?? this.isSyncing,
      lastError: lastError,
    );
  }
}

/// Provider pour la gestion de la file d'attente offline
final offlineQueueProvider =
    StateNotifierProvider<OfflineQueueNotifier, OfflineQueueState>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return OfflineQueueNotifier(prefs, ref);
});

class OfflineQueueNotifier extends StateNotifier<OfflineQueueState> {
  final SharedPreferences _prefs;
  final Ref _ref;
  StreamSubscription<bool>? _connectivitySub;

  static const _storageKey = 'offline_queue';
  static const _maxRetries = 3;

  OfflineQueueNotifier(this._prefs, this._ref)
      : super(const OfflineQueueState()) {
    _loadQueue();
    _listenToConnectivity();
  }

  /// Charger la file d'attente depuis le stockage local
  Future<void> _loadQueue() async {
    try {
      final jsonStr = _prefs.getString(_storageKey);
      if (jsonStr != null && jsonStr.isNotEmpty) {
        final List<dynamic> jsonList = jsonDecode(jsonStr);
        final actions = jsonList
            .map((j) => QueuedAction.fromJson(j as Map<String, dynamic>))
            .toList();
        state = state.copyWith(pendingActions: actions);
      }
    } catch (_) {
      // Ignorer les erreurs de parsing
    }
  }

  /// Sauvegarder la file d'attente
  Future<void> _saveQueue() async {
    final jsonStr = jsonEncode(
      state.pendingActions.map((a) => a.toJson()).toList(),
    );
    await _prefs.setString(_storageKey, jsonStr);
  }

  /// Écouter les changements de connectivité
  void _listenToConnectivity() {
    _connectivitySub = _ref
        .read(connectivityProvider.notifier)
        .stream
        .distinct()
        .listen((isConnected) {
      if (isConnected && state.hasPending && !state.isSyncing) {
        syncPendingActions();
      }
    });
  }

  /// Ajouter une action à la file d'attente
  Future<void> enqueue(QueuedActionType type, Map<String, dynamic> payload) async {
    final action = QueuedAction(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: type,
      payload: payload,
      queuedAt: DateTime.now(),
    );

    state = state.copyWith(
      pendingActions: [...state.pendingActions, action],
      lastError: null,
    );

    await _saveQueue();
  }

  /// Synchroniser les actions en attente
  Future<void> syncPendingActions() async {
    if (!mounted || state.pendingActions.isEmpty) return;

    state = state.copyWith(isSyncing: true, lastError: null);

    final actionsToProcess = List<QueuedAction>.from(state.pendingActions);
    final completedIds = <String>[];
    final failedActions = <QueuedAction>[];

    for (final action in actionsToProcess) {
      if (!mounted) break;

      try {
        await _executeAction(action);
        completedIds.add(action.id);
      } catch (e) {
        // Retry logic
        if (action.retryCount < _maxRetries) {
          failedActions.add(action.copyWith(retryCount: action.retryCount + 1));
        }
        // After max retries, action is dropped with error notification
      }
    }

    if (mounted) {
      final remaining = state.pendingActions
          .where((a) => !completedIds.contains(a.id))
          .toList();

      // Update with failed actions that can still retry
      state = state.copyWith(
        pendingActions: [...remaining, ...failedActions]
            .where((a) => a.retryCount < _maxRetries)
            .toList(),
        isSyncing: false,
      );

      await _saveQueue();
    }
  }

  /// Exécuter une action spécifique
  Future<void> _executeAction(QueuedAction action) async {
    AppLogger.info('[OfflineQueue] Executing ${action.type.name} (retry ${action.retryCount})');

    switch (action.type) {
      case QueuedActionType.createOrder:
        await _executeCreateOrder(action.payload);
        break;
      case QueuedActionType.updateProfile:
        await _executeUpdateProfile(action.payload);
        break;
      case QueuedActionType.submitPrescription:
        await _executeSubmitPrescription(action.payload);
        break;
    }
  }

  /// Exécuter la création d'une commande offline
  Future<void> _executeCreateOrder(Map<String, dynamic> payload) async {
    final ordersRepository = _ref.read(ordersRepositoryProvider);

    final rawItems = payload['items'] as List<dynamic>;
    final items = rawItems.map((item) {
      final m = item as Map<String, dynamic>;
      return OrderItemEntity(
        productId: m['productId'] as int,
        name: m['name']?.toString() ?? '',
        quantity: m['quantity'] as int,
        unitPrice: (m['unitPrice'] as num).toDouble(),
        totalPrice: (m['unitPrice'] as num).toDouble() * (m['quantity'] as int),
      );
    }).toList();

    final addr = payload['deliveryAddress'] as Map<String, dynamic>;
    final deliveryAddress = DeliveryAddressEntity(
      address: addr['address']?.toString() ?? '',
      city: addr['city']?.toString() ?? '',
      phone: addr['phone']?.toString() ?? '',
      latitude: (addr['latitude'] as num?)?.toDouble(),
      longitude: (addr['longitude'] as num?)?.toDouble(),
    );

    final result = await ordersRepository.createOrder(
      pharmacyId: payload['pharmacyId'] as int,
      items: items,
      deliveryAddress: deliveryAddress,
      paymentMode: payload['paymentMode']?.toString() ?? 'on_delivery',
      customerNotes: payload['customerNotes']?.toString(),
      promoCode: payload['promoCode']?.toString(),
    );

    result.fold(
      (failure) {
        AppLogger.error('[OfflineQueue] CreateOrder failed: ${failure.message}');
        throw Exception(failure.message);
      },
      (order) {
        AppLogger.info('[OfflineQueue] Order created successfully: #${order.id}');
      },
    );
  }

  /// Exécuter la mise à jour du profil offline
  Future<void> _executeUpdateProfile(Map<String, dynamic> payload) async {
    final profileRepository = _ref.read(profileRepositoryProvider);
    final updateEntity = UpdateProfileEntity(
      name: payload['name']?.toString(),
      email: payload['email']?.toString(),
      phone: payload['phone']?.toString(),
      address: payload['address']?.toString(),
    );

    final result = await profileRepository.updateProfile(updateEntity);

    result.fold(
      (failure) {
        AppLogger.error('[OfflineQueue] UpdateProfile failed: ${failure.message}');
        throw Exception(failure.message);
      },
      (_) {
        AppLogger.info('[OfflineQueue] Profile updated successfully');
      },
    );
  }

  /// Exécuter l'upload d'ordonnance offline (texte/notes seulement, images non supportées offline)
  Future<void> _executeSubmitPrescription(Map<String, dynamic> payload) async {
    // Prescription upload requires binary image data which can't be reliably
    // serialized to SharedPreferences. Log and discard gracefully.
    AppLogger.warning('[OfflineQueue] Prescription upload not supported offline — action discarded');
  }

  /// Supprimer une action de la file
  Future<void> removeAction(String actionId) async {
    state = state.copyWith(
      pendingActions:
          state.pendingActions.where((a) => a.id != actionId).toList(),
    );
    await _saveQueue();
  }

  /// Vider la file d'attente
  Future<void> clearQueue() async {
    state = state.copyWith(pendingActions: []);
    await _prefs.remove(_storageKey);
  }

  @override
  void dispose() {
    _connectivitySub?.cancel();
    super.dispose();
  }
}
