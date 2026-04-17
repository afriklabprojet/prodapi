import '../../domain/entities/delivery_address_entity.dart';

/// Modèle d'adresse de livraison pour la couche Data
class DeliveryAddressModel {
  final String address;
  final String? city;
  final double? latitude;
  final double? longitude;
  final String? phone;

  const DeliveryAddressModel({
    required this.address,
    this.city,
    this.latitude,
    this.longitude,
    this.phone,
  });

  factory DeliveryAddressModel.fromJson(Map<String, dynamic> json) {
    return DeliveryAddressModel(
      address: json['delivery_address'] as String? ?? json['address'] as String? ?? '',
      city: json['delivery_city'] as String? ?? json['city'] as String?,
      latitude: json['delivery_latitude'] != null
          ? double.tryParse(json['delivery_latitude'].toString())
          : null,
      longitude: json['delivery_longitude'] != null
          ? double.tryParse(json['delivery_longitude'].toString())
          : null,
      phone: json['customer_phone'] as String? ?? json['phone'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'delivery_address': address,
      if (city != null) 'delivery_city': city,
      if (latitude != null) 'delivery_latitude': latitude,
      if (longitude != null) 'delivery_longitude': longitude,
      if (phone != null) 'customer_phone': phone,
    };
  }

  DeliveryAddressEntity toEntity() {
    return DeliveryAddressEntity(
      address: address,
      city: city,
      latitude: latitude,
      longitude: longitude,
      phone: phone,
    );
  }

  factory DeliveryAddressModel.fromEntity(DeliveryAddressEntity entity) {
    return DeliveryAddressModel(
      address: entity.address,
      city: entity.city,
      latitude: entity.latitude,
      longitude: entity.longitude,
      phone: entity.phone,
    );
  }
}
