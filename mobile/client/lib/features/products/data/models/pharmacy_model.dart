import 'package:json_annotation/json_annotation.dart';
import '../../domain/entities/pharmacy_entity.dart';

part 'pharmacy_model.g.dart';

/// Convertit une valeur dynamique (num, String, ou null) en double
double? _parseDouble(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}

@JsonSerializable()
class PharmacyModel {
  final int id;
  final String name;
  @JsonKey(defaultValue: '')
  final String address;
  final String? phone;
  final String? email;
  @JsonKey(fromJson: _parseDouble)
  final double? latitude;
  @JsonKey(fromJson: _parseDouble)
  final double? longitude;
  @JsonKey(defaultValue: 'active')
  final String status;
  @JsonKey(name: 'is_open', defaultValue: false)
  final bool isOpen;

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
  });

  factory PharmacyModel.fromJson(Map<String, dynamic> json) {
    json = Map<String, dynamic>.from(json);
    if (json['id'] is String) {
      json['id'] = int.tryParse(json['id']) ?? 0;
    }
    return _$PharmacyModelFromJson(json);
  }

  Map<String, dynamic> toJson() => _$PharmacyModelToJson(this);

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
    );
  }
}
