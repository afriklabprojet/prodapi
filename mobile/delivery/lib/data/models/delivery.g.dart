// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'delivery.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Delivery _$DeliveryFromJson(Map<String, dynamic> json) => _Delivery(
  id: safeInt(json['id']),
  orderId: safeIntOrNull(json['order_id']),
  reference: json['reference'] as String,
  pharmacyName: json['pharmacy_name'] as String,
  pharmacyAddress: json['pharmacy_address'] as String,
  pharmacyPhone: json['pharmacy_phone'] as String?,
  customerName: json['customer_name'] as String,
  customerPhone: json['customer_phone'] as String?,
  deliveryAddress: json['delivery_address'] as String,
  pharmacyLat: safeDoubleOrNull(json['pharmacy_latitude']),
  pharmacyLng: safeDoubleOrNull(json['pharmacy_longitude']),
  deliveryLat: safeDoubleOrNull(json['delivery_latitude']),
  deliveryLng: safeDoubleOrNull(json['delivery_longitude']),
  totalAmount: safeDouble(json['total_amount']),
  deliveryFee: safeDoubleOrNull(json['delivery_fee']),
  commission: safeDoubleOrNull(json['commission']),
  estimatedEarnings: safeDoubleOrNull(json['estimated_earnings']),
  distanceKm: safeDoubleOrNull(json['distance_km']),
  estimatedDuration: safeIntOrNull(json['estimated_duration']),
  status: json['status'] as String,
  createdAt: json['created_at'] as String?,
  updatedAt: json['updated_at'] as String?,
  notes: json['notes'] as String?,
);

Map<String, dynamic> _$DeliveryToJson(_Delivery instance) => <String, dynamic>{
  'id': instance.id,
  'order_id': instance.orderId,
  'reference': instance.reference,
  'pharmacy_name': instance.pharmacyName,
  'pharmacy_address': instance.pharmacyAddress,
  'pharmacy_phone': instance.pharmacyPhone,
  'customer_name': instance.customerName,
  'customer_phone': instance.customerPhone,
  'delivery_address': instance.deliveryAddress,
  'pharmacy_latitude': instance.pharmacyLat,
  'pharmacy_longitude': instance.pharmacyLng,
  'delivery_latitude': instance.deliveryLat,
  'delivery_longitude': instance.deliveryLng,
  'total_amount': instance.totalAmount,
  'delivery_fee': instance.deliveryFee,
  'commission': instance.commission,
  'estimated_earnings': instance.estimatedEarnings,
  'distance_km': instance.distanceKm,
  'estimated_duration': instance.estimatedDuration,
  'status': instance.status,
  'created_at': instance.createdAt,
  'updated_at': instance.updatedAt,
  'notes': instance.notes,
};
