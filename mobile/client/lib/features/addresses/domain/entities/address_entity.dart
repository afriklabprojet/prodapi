import 'package:equatable/equatable.dart';

/// Entité Adresse (couche Domain)
class AddressEntity extends Equatable {
  final int id;
  final String label;
  final String address;
  final String? city;
  final String? district;
  final String? phone;
  final String? instructions;
  final double? latitude;
  final double? longitude;
  final bool isDefault;
  final String fullAddress;
  final bool hasCoordinates;
  final DateTime createdAt;
  final DateTime updatedAt;

  const AddressEntity({
    required this.id,
    required this.label,
    required this.address,
    this.city,
    this.district,
    this.phone,
    this.instructions,
    this.latitude,
    this.longitude,
    required this.isDefault,
    required this.fullAddress,
    required this.hasCoordinates,
    required this.createdAt,
    required this.updatedAt,
  });

  AddressEntity copyWith({
    int? id,
    String? label,
    String? address,
    String? city,
    String? district,
    String? phone,
    String? instructions,
    double? latitude,
    double? longitude,
    bool? isDefault,
    String? fullAddress,
    bool? hasCoordinates,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AddressEntity(
      id: id ?? this.id,
      label: label ?? this.label,
      address: address ?? this.address,
      city: city ?? this.city,
      district: district ?? this.district,
      phone: phone ?? this.phone,
      instructions: instructions ?? this.instructions,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      isDefault: isDefault ?? this.isDefault,
      fullAddress: fullAddress ?? this.fullAddress,
      hasCoordinates: hasCoordinates ?? this.hasCoordinates,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    label,
    address,
    city,
    district,
    phone,
    instructions,
    latitude,
    longitude,
    isDefault,
    fullAddress,
    hasCoordinates,
    createdAt,
    updatedAt,
  ];
}
