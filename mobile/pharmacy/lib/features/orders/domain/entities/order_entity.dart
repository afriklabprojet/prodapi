class OrderEntity {
  final int id;
  final String reference;
  final String status;
  final String paymentMode;
  final String paymentStatus;
  final bool isPaid;
  final double totalAmount;
  final String? deliveryAddress;
  final String? customerNotes;
  final String? pharmacyNotes;
  final String? prescriptionImage;
  final DateTime createdAt;
  final String customerName;
  final String customerPhone;
  final int? customerId;
  final int? itemsCount;
  final List<OrderItemEntity>? items;
  final double? deliveryFee;
  final double? subtotal;
  // Delivery info
  final int? deliveryId;
  final int? courierId;
  final String? courierName;
  final String? courierPhone;

  const OrderEntity({
    required this.id,
    required this.reference,
    required this.status,
    required this.paymentMode,
    this.paymentStatus = 'pending',
    this.isPaid = false,
    required this.totalAmount,
    required this.createdAt,
    required this.customerName,
    required this.customerPhone,
    this.customerId,
    this.deliveryAddress,
    this.customerNotes,
    this.pharmacyNotes,
    this.prescriptionImage,
    this.itemsCount,
    this.items,
    this.deliveryFee,
    this.subtotal,
    this.deliveryId,
    this.courierId,
    this.courierName,
    this.courierPhone,
  });

  /// Whether the pharmacy can confirm this order
  bool get canBeConfirmed => status == 'pending' && isPaid;

  /// Whether the order is pending and unpaid
  bool get isPendingUnpaid => status == 'pending' && !isPaid;

  OrderEntity copyWith({
    int? id,
    String? reference,
    String? status,
    String? paymentMode,
    String? paymentStatus,
    bool? isPaid,
    double? totalAmount,
    String? deliveryAddress,
    String? customerNotes,
    String? pharmacyNotes,
    String? prescriptionImage,
    DateTime? createdAt,
    String? customerName,
    String? customerPhone,
    int? customerId,
    int? itemsCount,
    List<OrderItemEntity>? items,
    double? deliveryFee,
    double? subtotal,
    int? deliveryId,
    int? courierId,
    String? courierName,
    String? courierPhone,
  }) {
    return OrderEntity(
      id: id ?? this.id,
      reference: reference ?? this.reference,
      status: status ?? this.status,
      paymentMode: paymentMode ?? this.paymentMode,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      isPaid: isPaid ?? this.isPaid,
      totalAmount: totalAmount ?? this.totalAmount,
      createdAt: createdAt ?? this.createdAt,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      customerId: customerId ?? this.customerId,
      deliveryAddress: deliveryAddress ?? this.deliveryAddress,
      customerNotes: customerNotes ?? this.customerNotes,
      pharmacyNotes: pharmacyNotes ?? this.pharmacyNotes,
      prescriptionImage: prescriptionImage ?? this.prescriptionImage,
      itemsCount: itemsCount ?? this.itemsCount,
      items: items ?? this.items,
      deliveryFee: deliveryFee ?? this.deliveryFee,
      subtotal: subtotal ?? this.subtotal,
      deliveryId: deliveryId ?? this.deliveryId,
      courierId: courierId ?? this.courierId,
      courierName: courierName ?? this.courierName,
      courierPhone: courierPhone ?? this.courierPhone,
    );
  }
}

class OrderItemEntity {
  final String name;
  final int quantity;
  final double unitPrice;
  final double totalPrice;

  const OrderItemEntity({
    required this.name,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
  });
}
