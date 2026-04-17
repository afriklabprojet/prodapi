import 'dart:async';

/// Types d'événements temps réel déclenchés par FCM
enum RealtimeEventType {
  newOrder,
  orderStatusChanged,
  newPrescription,
  chatMessage,
  notification,
  paymentReceived,
  deliveryUpdate,
  walletUpdate, // Nouveau: pour rafraîchir le wallet (paiement, remboursement, retrait)
}

/// Événement temps réel avec données optionnelles
class RealtimeEvent {
  final RealtimeEventType type;
  final Map<String, dynamic>? data;
  final DateTime timestamp;

  RealtimeEvent({
    required this.type,
    this.data,
  }) : timestamp = DateTime.now();
}

/// Bus d'événements central pour la communication FCM → UI.
/// Remplace le polling par des rafraîchissements ciblés.
class RealtimeEventBus {
  static final RealtimeEventBus _instance = RealtimeEventBus._();
  factory RealtimeEventBus() => _instance;
  RealtimeEventBus._();

  final _controller = StreamController<RealtimeEvent>.broadcast();

  Stream<RealtimeEvent> get stream => _controller.stream;

  /// Écouter un type d'événement spécifique
  Stream<RealtimeEvent> on(RealtimeEventType type) {
    return _controller.stream.where((e) => e.type == type);
  }

  /// Publier un événement (appelé par le handler FCM)
  void emit(RealtimeEventType type, {Map<String, dynamic>? data}) {
    _controller.add(RealtimeEvent(type: type, data: data));
  }

  /// Mapper un type de notification FCM vers un événement
  static RealtimeEventType? fromFcmType(String fcmType) {
    switch (fcmType) {
      case 'new_order':
        return RealtimeEventType.newOrder;
      case 'order_status':
      case 'order_confirmed':
      case 'order_ready':
      case 'order_delivered':
        return RealtimeEventType.orderStatusChanged;
      case 'new_prescription':
        return RealtimeEventType.newPrescription;
      case 'chat_message':
        return RealtimeEventType.chatMessage;
      case 'payment':
      case 'payment_received':
        return RealtimeEventType.paymentReceived;
      case 'wallet_update':
      case 'withdrawal':
      case 'refund':
        return RealtimeEventType.walletUpdate;
      case 'delivery_assigned':
      case 'courier_arrived':
        return RealtimeEventType.deliveryUpdate;
      default:
        return RealtimeEventType.notification;
    }
  }

  void dispose() {
    _controller.close();
  }
}
