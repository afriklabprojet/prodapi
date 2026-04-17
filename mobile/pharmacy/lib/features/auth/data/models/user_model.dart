import 'package:json_annotation/json_annotation.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/entities/pharmacy_entity.dart';

part 'user_model.g.dart';

@JsonSerializable()
class UserModel {
  final int id;
  final String name;
  final String email;
  final String phone;
  final String? role;
  final String? avatar;
  final List<PharmacyModel>? pharmacies;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    this.role,
    this.avatar,
    this.pharmacies,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) =>
      _$UserModelFromJson(json);

  Map<String, dynamic> toJson() => _$UserModelToJson(this);

  /// Convertit en entité domaine.
  UserEntity toEntity() {
    return UserEntity(
      id: id,
      name: name,
      email: email,
      phone: phone,
      role: role,
      avatar: avatar,
      pharmacies: pharmacies?.map((p) => p.toPharmacyEntity()).toList() ?? [],
    );
  }
}

/// Modèle sérialisable de pharmacie imbriqué dans UserModel.
class PharmacyModel {
  final int id;
  final String name;
  final String? address;
  final String? city;
  final String? phone;
  final String? email;
  final String status;
  final String? licenseNumber;
  final String? licenseDocument;
  final String? idCardDocument;
  final int? dutyZoneId;
  final double? latitude;
  final double? longitude;

  const PharmacyModel({
    required this.id,
    required this.name,
    this.address,
    this.city,
    this.phone,
    this.email,
    required this.status,
    this.licenseNumber,
    this.licenseDocument,
    this.idCardDocument,
    this.dutyZoneId,
    this.latitude,
    this.longitude,
  });

  factory PharmacyModel.fromJson(Map<String, dynamic> json) {
    return PharmacyModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      name: json['name']?.toString() ?? '',
      address: json['address']?.toString(),
      city: json['city']?.toString(),
      phone: json['phone']?.toString(),
      email: json['email']?.toString(),
      status: json['status']?.toString() ?? 'pending',
      licenseNumber: json['license_number']?.toString(),
      licenseDocument: json['license_document']?.toString(),
      idCardDocument: json['id_card_document']?.toString(),
      dutyZoneId: json['duty_zone_id'] is int ? json['duty_zone_id'] : int.tryParse(json['duty_zone_id']?.toString() ?? ''),
      latitude: json['latitude'] is num ? (json['latitude'] as num).toDouble() : double.tryParse(json['latitude']?.toString() ?? ''),
      longitude: json['longitude'] is num ? (json['longitude'] as num).toDouble() : double.tryParse(json['longitude']?.toString() ?? ''),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'city': city,
      'phone': phone,
      'email': email,
      'status': status,
      'license_number': licenseNumber,
      'license_document': licenseDocument,
      'id_card_document': idCardDocument,
      'duty_zone_id': dutyZoneId,
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  /// Convertit en PharmacyEntity.
  PharmacyEntity toPharmacyEntity() {
    return PharmacyEntity(
      id: id,
      name: name,
      address: address,
      city: city,
      phone: phone,
      email: email,
      status: status,
      licenseNumber: licenseNumber,
      licenseDocument: licenseDocument,
      idCardDocument: idCardDocument,
      dutyZoneId: dutyZoneId,
      latitude: latitude,
      longitude: longitude,
    );
  }
}
