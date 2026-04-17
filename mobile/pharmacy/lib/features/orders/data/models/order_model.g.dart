// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'order_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

OrderModel _$OrderModelFromJson(Map<String, dynamic> json) => OrderModel(
  id: (json['id'] as num).toInt(),
  reference: json['reference'] as String,
  status: json['status'] as String,
  paymentMode: json['payment_mode'] as String,
  paymentStatus: json['payment_status'] as String?,
  paidAt: json['paid_at'] as String?,
  totalAmount: _toDouble(json['total_amount']),
  createdAt: json['created_at'] as String,
  customer: json['customer'] as Map<String, dynamic>,
  deliveryAddress: json['delivery_address'] as String?,
  customerNotes: json['customer_notes'] as String?,
  pharmacyNotes: json['pharmacy_notes'] as String?,
  prescriptionImage: json['prescription_image'] as String?,
  itemsCount: _toIntNullable(json['items_count']),
  items: (json['items'] as List<dynamic>?)
      ?.map((e) => OrderItemModel.fromJson(e as Map<String, dynamic>))
      .toList(),
  deliveryFee: _toDoubleNullable(json['delivery_fee']),
  subtotal: _toDoubleNullable(json['subtotal']),
  delivery: json['delivery'] as Map<String, dynamic>?,
);

Map<String, dynamic> _$OrderModelToJson(OrderModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'reference': instance.reference,
      'status': instance.status,
      'payment_mode': instance.paymentMode,
      'payment_status': instance.paymentStatus,
      'paid_at': instance.paidAt,
      'total_amount': instance.totalAmount,
      'delivery_address': instance.deliveryAddress,
      'customer_notes': instance.customerNotes,
      'pharmacy_notes': instance.pharmacyNotes,
      'prescription_image': instance.prescriptionImage,
      'created_at': instance.createdAt,
      'customer': instance.customer,
      'items_count': instance.itemsCount,
      'items': instance.items,
      'delivery_fee': instance.deliveryFee,
      'subtotal': instance.subtotal,
      'delivery': instance.delivery,
    };

OrderItemModel _$OrderItemModelFromJson(Map<String, dynamic> json) =>
    OrderItemModel(
      name: _toString(json['name']),
      quantity: _toInt(json['quantity']),
      unitPrice: _toDouble(json['unit_price']),
      totalPrice: _toDouble(json['total_price']),
    );

Map<String, dynamic> _$OrderItemModelToJson(OrderItemModel instance) =>
    <String, dynamic>{
      'name': instance.name,
      'quantity': instance.quantity,
      'unit_price': instance.unitPrice,
      'total_price': instance.totalPrice,
    };
