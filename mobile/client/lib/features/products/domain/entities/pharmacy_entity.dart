import 'package:equatable/equatable.dart';

/// Entité Pharmacie (couche Domain - module products)
class PharmacyEntity extends Equatable {
  final int id;
  final String name;
  final String address;
  final String phone;
  final String? email;
  final double? latitude;
  final double? longitude;
  final String status;
  final bool isOpen;

  const PharmacyEntity({
    required this.id,
    required this.name,
    required this.address,
    required this.phone,
    this.email,
    this.latitude,
    this.longitude,
    required this.status,
    required this.isOpen,
  });

  bool get hasCoordinates => latitude != null && longitude != null;

  @override
  List<Object?> get props => [
        id, name, address, phone, email,
        latitude, longitude, status, isOpen,
      ];
}
