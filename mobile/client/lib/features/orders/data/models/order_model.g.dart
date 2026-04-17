// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'order_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

OrderModel _$OrderModelFromJson(Map<String, dynamic> json) => OrderModel(
      id: (json['id'] as num).toInt(),
      reference: json['reference'] as String,
      deliveryCode: json['delivery_code'] as String?,
      status: json['status'] as String,
      paymentStatus: json['payment_status'] as String? ?? 'pending',
      paymentMode: json['payment_mode'] as String,
      pharmacyId: (json['pharmacy_id'] as num?)?.toInt(),
      pharmacy: json['pharmacy'] == null
          ? null
          : PharmacyBasicModel.fromJson(
              json['pharmacy'] as Map<String, dynamic>),
      items: (json['items'] as List<dynamic>?)
              ?.map((e) => OrderItemModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      itemsCount: (json['items_count'] as num?)?.toInt() ?? 0,
      subtotal: _toDoubleNullable(json['subtotal']),
      deliveryFee: _toDoubleNullable(json['delivery_fee']),
      totalAmount: _toDouble(json['total_amount']),
      currency: json['currency'] as String? ?? 'XOF',
      deliveryAddress: json['delivery_address'] as String? ?? '',
      deliveryCity: json['delivery_city'] as String?,
      deliveryLatitude: (json['delivery_latitude'] as num?)?.toDouble(),
      deliveryLongitude: (json['delivery_longitude'] as num?)?.toDouble(),
      customerPhone: json['customer_phone'] as String?,
      customerNotes: json['customer_notes'] as String?,
      prescriptionImage: json['prescription_image'] as String?,
      createdAt: json['created_at'] as String,
      confirmedAt: json['confirmed_at'] as String?,
      paidAt: json['paid_at'] as String?,
      deliveredAt: json['delivered_at'] as String?,
      cancelledAt: json['cancelled_at'] as String?,
      cancellationReason: json['cancellation_reason'] as String?,
      deliveryId: (json['delivery_id'] as num?)?.toInt(),
      courierId: (json['courier_id'] as num?)?.toInt(),
      courierName: json['courier_name'] as String?,
      courierPhone: json['courier_phone'] as String?,
    );

Map<String, dynamic> _$OrderModelToJson(OrderModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'reference': instance.reference,
      'status': instance.status,
      'payment_status': instance.paymentStatus,
      'delivery_code': instance.deliveryCode,
      'payment_mode': instance.paymentMode,
      'pharmacy_id': instance.pharmacyId,
      'pharmacy': instance.pharmacy,
      'items': instance.items,
      'items_count': instance.itemsCount,
      'subtotal': instance.subtotal,
      'delivery_fee': instance.deliveryFee,
      'total_amount': instance.totalAmount,
      'currency': instance.currency,
      'delivery_address': instance.deliveryAddress,
      'delivery_city': instance.deliveryCity,
      'delivery_latitude': instance.deliveryLatitude,
      'delivery_longitude': instance.deliveryLongitude,
      'customer_phone': instance.customerPhone,
      'customer_notes': instance.customerNotes,
      'prescription_image': instance.prescriptionImage,
      'created_at': instance.createdAt,
      'confirmed_at': instance.confirmedAt,
      'paid_at': instance.paidAt,
      'delivered_at': instance.deliveredAt,
      'cancelled_at': instance.cancelledAt,
      'cancellation_reason': instance.cancellationReason,
      'delivery_id': instance.deliveryId,
      'courier_id': instance.courierId,
      'courier_name': instance.courierName,
      'courier_phone': instance.courierPhone,
    };

PharmacyBasicModel _$PharmacyBasicModelFromJson(Map<String, dynamic> json) =>
    PharmacyBasicModel(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      phone: json['phone'] as String?,
      address: json['address'] as String?,
    );

Map<String, dynamic> _$PharmacyBasicModelToJson(PharmacyBasicModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'phone': instance.phone,
      'address': instance.address,
    };
