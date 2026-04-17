import '../../domain/entities/pharmacy_entity.dart';

/// Modèle de données Pharmacie — couche data du module pharmacies
class PharmacyModel {
  final int id;
  final String name;
  final String address;
  final String? phone;
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

  PharmacyModel({
    required this.id,
    required this.name,
    required this.address,
    this.phone,
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

  factory PharmacyModel.fromJson(Map<String, dynamic> json) {
    return PharmacyModel(
      id: json['id'] is int
          ? json['id']
          : int.tryParse(json['id'].toString()) ?? 0,
      name: json['name']?.toString() ?? '',
      address: json['address']?.toString() ?? '',
      phone: json['phone']?.toString(),
      email: json['email']?.toString(),
      latitude: _parseDouble(json['latitude']),
      longitude: _parseDouble(json['longitude']),
      status: json['status']?.toString() ?? 'active',
      isOpen: json['is_open'] == true || json['is_open'] == 1,
      imageUrl: json['image_url']?.toString() ?? json['logo']?.toString(),
      isOnDuty: json['is_on_duty'] == true || json['is_on_duty'] == 1,
      distance: _parseDouble(json['distance']),
      openingHours: json['opening_hours']?.toString(),
      closingHours: json['closing_hours']?.toString(),
      dutyType: json['duty_type']?.toString(),
      dutyEndAt: json['duty_end_at']?.toString(),
      description: json['description']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'address': address,
        if (phone != null) 'phone': phone,
        if (email != null) 'email': email,
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
        'status': status,
        'is_open': isOpen,
        if (imageUrl != null) 'image_url': imageUrl,
        if (isOnDuty != null) 'is_on_duty': isOnDuty,
        if (distance != null) 'distance': distance,
        if (openingHours != null) 'opening_hours': openingHours,
        if (closingHours != null) 'closing_hours': closingHours,
        if (dutyType != null) 'duty_type': dutyType,
      };

  PharmacyEntity toEntity() {
    return PharmacyEntity(
      id: id,
      name: name,
      address: address,
      phone: phone ?? '',
      email: email,
      latitude: latitude,
      longitude: longitude,
      status: status,
      isOpen: isOpen,
      imageUrl: imageUrl,
      isOnDuty: isOnDuty,
      distance: distance,
      openingHours: openingHours,
      closingHours: closingHours,
      dutyType: dutyType,
      dutyEndAt: dutyEndAt,
      description: description,
    );
  }

  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }
}
