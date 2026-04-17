// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'delivery_offer.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_DeliveryOffer _$DeliveryOfferFromJson(Map<String, dynamic> json) =>
    _DeliveryOffer(
      id: safeInt(json['id']),
      orderId: safeIntOrNull(json['order_id']),
      status: json['status'] as String,
      broadcastLevel: safeInt(json['broadcast_level']),
      baseFee: safeDouble(json['base_fee']),
      bonusFee: safeDouble(json['bonus_fee']),
      expiresAt: json['expires_at'] as String,
      acceptedAt: json['accepted_at'] as String?,
      pharmacyName: json['pharmacy_name'] as String?,
      pharmacyAddress: json['pharmacy_address'] as String?,
      pharmacyPhone: json['pharmacy_phone'] as String?,
      pharmacyLat: safeDoubleOrNull(json['pharmacy_latitude']),
      pharmacyLng: safeDoubleOrNull(json['pharmacy_longitude']),
      customerName: json['customer_name'] as String?,
      deliveryAddress: json['delivery_address'] as String?,
      deliveryLat: safeDoubleOrNull(json['delivery_latitude']),
      deliveryLng: safeDoubleOrNull(json['delivery_longitude']),
      distanceKm: safeDoubleOrNull(json['distance_km']),
      estimatedDuration: safeIntOrNull(json['estimated_duration']),
      totalAmount: safeDoubleOrNull(json['total_amount']),
      createdAt: json['created_at'] as String?,
    );

Map<String, dynamic> _$DeliveryOfferToJson(_DeliveryOffer instance) =>
    <String, dynamic>{
      'id': instance.id,
      'order_id': instance.orderId,
      'status': instance.status,
      'broadcast_level': instance.broadcastLevel,
      'base_fee': instance.baseFee,
      'bonus_fee': instance.bonusFee,
      'expires_at': instance.expiresAt,
      'accepted_at': instance.acceptedAt,
      'pharmacy_name': instance.pharmacyName,
      'pharmacy_address': instance.pharmacyAddress,
      'pharmacy_phone': instance.pharmacyPhone,
      'pharmacy_latitude': instance.pharmacyLat,
      'pharmacy_longitude': instance.pharmacyLng,
      'customer_name': instance.customerName,
      'delivery_address': instance.deliveryAddress,
      'delivery_latitude': instance.deliveryLat,
      'delivery_longitude': instance.deliveryLng,
      'distance_km': instance.distanceKm,
      'estimated_duration': instance.estimatedDuration,
      'total_amount': instance.totalAmount,
      'created_at': instance.createdAt,
    };
