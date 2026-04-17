import 'package:equatable/equatable.dart';

/// Entité Pharmacie (couche Domain - module pharmacies)
/// Note: C'est la même structure que dans products mais dans un module différent
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
  final String? imageUrl;
  final bool? isOnDuty;
  final double? distance;
  final String? openingHours;
  final String? closingHours;
  final String? dutyType;
  final String? dutyEndAt;
  final String? description;

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
    this.imageUrl,
    this.isOnDuty,
    this.distance,
    this.openingHours,
    this.closingHours,
    this.dutyType,
    this.dutyEndAt,
    this.description,
  });

  bool get hasCoordinates => latitude != null && longitude != null;
  String get distanceText => distance != null ? '${distance!.toStringAsFixed(1)} km' : '';
  String get distanceLabel => distanceText;

  @override
  List<Object?> get props => [
        id, name, address, phone, email,
        latitude, longitude, status, isOpen,
      ];
}
