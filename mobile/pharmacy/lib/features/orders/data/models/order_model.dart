import 'package:json_annotation/json_annotation.dart';
import '../../domain/entities/order_entity.dart';
import '../../domain/enums/order_status.dart';

part 'order_model.g.dart';

/// Convertit une valeur dynamique (String ou num) en double
double _toDouble(dynamic value) {
  if (value == null) return 0.0;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? 0.0;
  return 0.0;
}

/// Convertit une valeur dynamique nullable en double nullable
double? _toDoubleNullable(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}

/// Convertit une valeur dynamique en int
int _toInt(dynamic value) {
  if (value == null) return 0;
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? 0;
  return 0;
}

/// Convertit une valeur dynamique nullable en int nullable
int? _toIntNullable(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}

/// Convertit une valeur dynamique en String (gère null)
String _toString(dynamic value) {
  if (value == null) return 'Produit inconnu';
  return value.toString();
}

@JsonSerializable()
class OrderModel {
  final int id;
  final String reference;
  final String status;
  @JsonKey(name: 'payment_mode')
  final String paymentMode;
  @JsonKey(name: 'payment_status')
  final String? paymentStatus;
  @JsonKey(name: 'paid_at')
  final String? paidAt;
  @JsonKey(name: 'total_amount', fromJson: _toDouble)
  final double totalAmount;
  @JsonKey(name: 'delivery_address')
  final String? deliveryAddress;
  @JsonKey(name: 'customer_notes')
  final String? customerNotes;
  @JsonKey(name: 'pharmacy_notes')
  final String? pharmacyNotes;
  @JsonKey(name: 'prescription_image')
  final String? prescriptionImage;
  @JsonKey(name: 'created_at')
  final String createdAt;
  final Map<String, dynamic> customer;
  @JsonKey(name: 'items_count', fromJson: _toIntNullable)
  final int? itemsCount;
  final List<OrderItemModel>? items;
  @JsonKey(name: 'delivery_fee', fromJson: _toDoubleNullable)
  final double? deliveryFee;
  @JsonKey(fromJson: _toDoubleNullable)
  final double? subtotal;
  // Delivery info
  final Map<String, dynamic>? delivery;

  const OrderModel({
    required this.id,
    required this.reference,
    required this.status,
    required this.paymentMode,
    this.paymentStatus,
    this.paidAt,
    required this.totalAmount,
    required this.createdAt,
    required this.customer,
    this.deliveryAddress,
    this.customerNotes,
    this.pharmacyNotes,
    this.prescriptionImage,
    this.itemsCount,
    this.items,
    this.deliveryFee,
    this.subtotal,
    this.delivery,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) =>
      _$OrderModelFromJson(json);

  Map<String, dynamic> toJson() => _$OrderModelToJson(this);

  OrderEntity toEntity() {
    // Extract delivery/courier info
    final deliveryData = delivery;
    final courierData = deliveryData?['courier'] as Map<String, dynamic>?;
    
    // Determine if order is paid
    final effectivePaymentStatus = paymentStatus ?? 'pending';
    final isPaid = paidAt != null
        || effectivePaymentStatus == 'paid'
        || paymentMode == 'cash'; // Cash orders are paid on delivery
    
    return OrderEntity(
      id: id,
      reference: reference,
      status: OrderStatus.fromApi(status),
      paymentMode: paymentMode,
      paymentStatus: effectivePaymentStatus,
      isPaid: isPaid,
      totalAmount: totalAmount,
      createdAt: DateTime.tryParse(createdAt) ?? DateTime.now(),
      customerName: customer['name'] ?? 'Inconnu',
      customerPhone: customer['phone'] ?? '',
      customerId: _toIntNullable(customer['id']),
      deliveryAddress: deliveryAddress,
      customerNotes: customerNotes,
      pharmacyNotes: pharmacyNotes,
      prescriptionImage: prescriptionImage,
      itemsCount: itemsCount,
      items: items?.map((e) => e.toEntity()).toList(),
      deliveryFee: deliveryFee,
      subtotal: subtotal,
      deliveryId: _toIntNullable(deliveryData?['id']),
      courierId: _toIntNullable(courierData?['id']),
      courierName: courierData?['name'] as String?,
      courierPhone: courierData?['phone'] as String?,
    );
  }
}

@JsonSerializable()
class OrderItemModel {
  @JsonKey(fromJson: _toString)
  final String name;
  @JsonKey(fromJson: _toInt)
  final int quantity;
  @JsonKey(name: 'unit_price', fromJson: _toDouble)
  final double unitPrice;
  @JsonKey(name: 'total_price', fromJson: _toDouble)
  final double totalPrice;

  const OrderItemModel({
    required this.name,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
  });

  factory OrderItemModel.fromJson(Map<String, dynamic> json) =>
      _$OrderItemModelFromJson(json);

  Map<String, dynamic> toJson() => _$OrderItemModelToJson(this);

  OrderItemEntity toEntity() {
    return OrderItemEntity(
      name: name,
      quantity: quantity,
      unitPrice: unitPrice,
      totalPrice: totalPrice,
    );
  }
}
