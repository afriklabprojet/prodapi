import 'package:equatable/equatable.dart';

/// Entité d'adresse de livraison
class DeliveryAddressEntity extends Equatable {
  final String address;
  final String? city;
  final double? latitude;
  final double? longitude;
  final String? phone;

  const DeliveryAddressEntity({
    required this.address,
    this.city,
    this.latitude,
    this.longitude,
    this.phone,
  });

  DeliveryAddressEntity copyWith({
    String? address,
    String? city,
    double? latitude,
    double? longitude,
    String? phone,
  }) {
    return DeliveryAddressEntity(
      address: address ?? this.address,
      city: city ?? this.city,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      phone: phone ?? this.phone,
    );
  }

  String get fullAddress {
    if (city != null && city!.isNotEmpty) {
      return '$address, $city';
    }
    return address;
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

  @override
  List<Object?> get props => [address, city, latitude, longitude, phone];
}
