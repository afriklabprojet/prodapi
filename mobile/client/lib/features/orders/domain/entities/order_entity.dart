import 'package:equatable/equatable.dart';
import 'order_item_entity.dart';
import 'delivery_address_entity.dart';

/// Statuts possibles d'une commande
enum OrderStatus {
  pending,
  confirmed,
  preparing,
  ready,
  delivering,
  delivered,
  cancelled,
  failed,
}

/// Modes de paiement
enum PaymentMode {
  platform,
  onDelivery;

  String get displayName {
    switch (this) {
      case PaymentMode.platform:
        return 'Paiement en ligne';
      case PaymentMode.onDelivery:
        return 'Paiement à la livraison';
    }
  }
}

/// Extension pour ajouter displayName à OrderStatus
extension OrderStatusExtension on OrderStatus {
  String get displayName {
    switch (this) {
      case OrderStatus.pending:
        return 'En attente';
      case OrderStatus.confirmed:
        return 'Confirmée';
      case OrderStatus.preparing:
        return 'En préparation';
      case OrderStatus.ready:
        return 'Prête';
      case OrderStatus.delivering:
        return 'En livraison';
      case OrderStatus.delivered:
        return 'Livrée';
      case OrderStatus.cancelled:
        return 'Annulée';
      case OrderStatus.failed:
        return 'Échouée';
    }
  }
}

/// Entité Commande (couche Domain)
class OrderEntity extends Equatable {
  final int id;
  final String reference;
  final String? deliveryCode;
  final OrderStatus status;
  final String paymentStatus;
  final PaymentMode paymentMode;
  final int pharmacyId;
  final String pharmacyName;
  final String? pharmacyPhone;
  final String? pharmacyAddress;
  final List<OrderItemEntity> items;
  final int itemsCount;
  final double subtotal;
  final double deliveryFee;
  final double totalAmount;
  final String currency;
  final DeliveryAddressEntity deliveryAddress;
  final String? customerNotes;
  final String? prescriptionImage;
  final DateTime createdAt;
  final DateTime? confirmedAt;
  final DateTime? paidAt;
  final DateTime? deliveredAt;
  final DateTime? cancelledAt;
  final String? cancellationReason;

  const OrderEntity({
    required this.id,
    required this.reference,
    this.deliveryCode,
    required this.status,
    required this.paymentStatus,
    required this.paymentMode,
    required this.pharmacyId,
    required this.pharmacyName,
    this.pharmacyPhone,
    this.pharmacyAddress,
    required this.items,
    this.itemsCount = 0,
    required this.subtotal,
    required this.deliveryFee,
    required this.totalAmount,
    this.currency = 'XOF',
    required this.deliveryAddress,
    this.customerNotes,
    this.prescriptionImage,
    required this.createdAt,
    this.confirmedAt,
    this.paidAt,
    this.deliveredAt,
    this.cancelledAt,
    this.cancellationReason,
  });

  bool get isPending => status == OrderStatus.pending;
  bool get isConfirmed => status == OrderStatus.confirmed;
  bool get isPreparing => status == OrderStatus.preparing;
  bool get isDelivering => status == OrderStatus.delivering;
  bool get isDelivered => status == OrderStatus.delivered;
  bool get isCancelled => status == OrderStatus.cancelled;
  bool get isPaid => paymentStatus == 'paid';
  bool get canCancel => isPending || isConfirmed || isPreparing;
  bool get canBeCancelled => canCancel;
  bool get needsPayment => paymentMode == PaymentMode.platform && !isPaid && !isCancelled;
  int get itemCount => items.isNotEmpty ? items.length : itemsCount;
  double get total => totalAmount;

  String get statusLabel {
    switch (status) {
      case OrderStatus.pending:
        return 'En attente';
      case OrderStatus.confirmed:
        return 'Confirmée';
      case OrderStatus.preparing:
        return 'En préparation';
      case OrderStatus.ready:
        return 'Prête';
      case OrderStatus.delivering:
        return 'En livraison';
      case OrderStatus.delivered:
        return 'Livrée';
      case OrderStatus.cancelled:
        return 'Annulée';
      case OrderStatus.failed:
        return 'Échouée';
    }
  }

  @override
  List<Object?> get props => [
        id, reference, status, paymentStatus, pharmacyId,
        totalAmount, createdAt,
      ];
}

