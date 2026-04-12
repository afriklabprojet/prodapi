import 'package:json_annotation/json_annotation.dart';
import '../../domain/entities/order_entity.dart';
import '../../domain/entities/delivery_address_entity.dart';
import 'order_item_model.dart';

part 'order_model.g.dart';

/// Helper to convert String or num to double (API returns "2500.00" as String)
double _toDouble(dynamic value) {
  if (value == null) return 0.0;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? 0.0;
  return 0.0;
}

/// Helper to convert nullable String or num to double
double? _toDoubleNullable(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}

@JsonSerializable()
class OrderModel {
  final int id;
  final String reference;
  @JsonKey(name: 'status')
  final String status;
  @JsonKey(name: 'payment_status', defaultValue: 'pending')
  final String paymentStatus;
  @JsonKey(name: 'delivery_code')
  final String? deliveryCode;
  @JsonKey(name: 'payment_mode')
  final String paymentMode;
  @JsonKey(name: 'pharmacy_id')
  final int? pharmacyId;
  @JsonKey(name: 'pharmacy')
  final PharmacyBasicModel? pharmacy;
  @JsonKey(defaultValue: [])
  final List<OrderItemModel> items;
  @JsonKey(name: 'items_count', defaultValue: 0)
  final int itemsCount;
  @JsonKey(fromJson: _toDoubleNullable)
  final double? subtotal;
  @JsonKey(name: 'delivery_fee', fromJson: _toDoubleNullable)
  final double? deliveryFee;
  @JsonKey(name: 'total_amount', fromJson: _toDouble)
  final double totalAmount;
  @JsonKey(defaultValue: 'XOF')
  final String currency;
  @JsonKey(name: 'delivery_address', defaultValue: '')
  final String deliveryAddress;
  @JsonKey(name: 'delivery_city')
  final String? deliveryCity;
  @JsonKey(name: 'delivery_latitude')
  final double? deliveryLatitude;
  @JsonKey(name: 'delivery_longitude')
  final double? deliveryLongitude;
  @JsonKey(name: 'customer_phone')
  final String? customerPhone;
  @JsonKey(name: 'customer_notes')
  final String? customerNotes;
  @JsonKey(name: 'prescription_image')
  final String? prescriptionImage;
  @JsonKey(name: 'created_at')
  final String createdAt;
  @JsonKey(name: 'confirmed_at')
  final String? confirmedAt;
  @JsonKey(name: 'paid_at')
  final String? paidAt;
  @JsonKey(name: 'delivered_at')
  final String? deliveredAt;
  @JsonKey(name: 'cancelled_at')
  final String? cancelledAt;
  @JsonKey(name: 'cancellation_reason')
  final String? cancellationReason;

  const OrderModel({
    required this.id,
    required this.reference,
    this.deliveryCode,
    required this.status,
    this.paymentStatus = 'pending',
    required this.paymentMode,
    this.pharmacyId,
    this.pharmacy,
    this.items = const [],
    this.itemsCount = 0,
    this.subtotal,
    this.deliveryFee,
    required this.totalAmount,
    this.currency = 'XOF',
    required this.deliveryAddress,
    this.deliveryCity,
    this.deliveryLatitude,
    this.deliveryLongitude,
    this.customerPhone,
    this.customerNotes,
    this.prescriptionImage,
    required this.createdAt,
    this.confirmedAt,
    this.paidAt,
    this.deliveredAt,
    this.cancelledAt,
    this.cancellationReason,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    // Pre-convert potential String→num fields for safety
    // (Laravel decimal casts return strings like "5.3599320")
    final mJson = Map<String, dynamic>.from(json);

    // Convert id (usually int, but could be String)
    if (mJson['id'] is String) {
      mJson['id'] = int.tryParse(mJson['id'] as String) ?? 0;
    }

    // Convert pharmacy_id
    if (mJson['pharmacy_id'] is String) {
      mJson['pharmacy_id'] = int.tryParse(mJson['pharmacy_id'] as String) ?? 0;
    }

    // Convert delivery_latitude/longitude (decimal:7 cast → String in Laravel)
    if (mJson['delivery_latitude'] is String) {
      mJson['delivery_latitude'] = double.tryParse(
        mJson['delivery_latitude'] as String,
      );
    }
    if (mJson['delivery_longitude'] is String) {
      mJson['delivery_longitude'] = double.tryParse(
        mJson['delivery_longitude'] as String,
      );
    }

    // Convert pharmacy.id if pharmacy is present
    if (mJson['pharmacy'] is Map) {
      final pharmacy = Map<String, dynamic>.from(mJson['pharmacy'] as Map);
      if (pharmacy['id'] is String) {
        pharmacy['id'] = int.tryParse(pharmacy['id'] as String) ?? 0;
      }
      mJson['pharmacy'] = pharmacy;
    }

    return _$OrderModelFromJson(mJson);
  }

  Map<String, dynamic> toJson() => _$OrderModelToJson(this);

  OrderEntity toEntity() {
    return OrderEntity(
      id: id,
      reference: reference,
      deliveryCode: deliveryCode,
      status: _parseOrderStatus(status),
      paymentStatus: paymentStatus,
      paymentMode: _parsePaymentMode(paymentMode),
      pharmacyId: pharmacyId ?? pharmacy?.id ?? 0,
      pharmacyName: pharmacy?.name ?? '',
      pharmacyPhone: pharmacy?.phone,
      pharmacyAddress: pharmacy?.address,
      itemsCount: items.isNotEmpty ? items.length : itemsCount,
      items: items.map((item) => item.toEntity()).toList(),
      subtotal: subtotal ?? 0.0,
      deliveryFee: deliveryFee ?? 0.0,
      totalAmount: totalAmount,
      currency: currency,
      deliveryAddress: DeliveryAddressEntity(
        address: deliveryAddress,
        city: deliveryCity,
        latitude: deliveryLatitude,
        longitude: deliveryLongitude,
        phone: customerPhone,
      ),
      customerNotes: customerNotes,
      prescriptionImage: prescriptionImage,
      createdAt: DateTime.tryParse(createdAt) ?? DateTime.now(),
      confirmedAt: confirmedAt != null ? DateTime.tryParse(confirmedAt!) : null,
      paidAt: paidAt != null ? DateTime.tryParse(paidAt!) : null,
      deliveredAt: deliveredAt != null ? DateTime.tryParse(deliveredAt!) : null,
      cancelledAt: cancelledAt != null ? DateTime.tryParse(cancelledAt!) : null,
      cancellationReason: cancellationReason,
    );
  }

  OrderStatus _parseOrderStatus(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return OrderStatus.pending;
      case 'confirmed':
        return OrderStatus.confirmed;
      case 'processing':
      case 'preparing':
        return OrderStatus.preparing;
      case 'ready':
        return OrderStatus.ready;
      case 'delivering':
        return OrderStatus.delivering;
      case 'delivered':
        return OrderStatus.delivered;
      case 'cancelled':
        return OrderStatus.cancelled;
      case 'failed':
        return OrderStatus.failed;
      default:
        return OrderStatus.pending;
    }
  }

  PaymentMode _parsePaymentMode(String mode) {
    switch (mode.toLowerCase()) {
      case 'platform':
        return PaymentMode.platform;
      case 'on_delivery':
      case 'cash':
        return PaymentMode.onDelivery;
      default:
        return PaymentMode.platform;
    }
  }
}

@JsonSerializable()
class PharmacyBasicModel {
  final int id;
  final String name;
  final String? phone;
  final String? address;

  const PharmacyBasicModel({
    required this.id,
    required this.name,
    this.phone,
    this.address,
  });

  factory PharmacyBasicModel.fromJson(Map<String, dynamic> json) =>
      _$PharmacyBasicModelFromJson(json);

  Map<String, dynamic> toJson() => _$PharmacyBasicModelToJson(this);
}
