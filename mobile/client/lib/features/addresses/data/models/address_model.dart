import 'package:json_annotation/json_annotation.dart';
import '../../domain/entities/address_entity.dart';

part 'address_model.g.dart';

// Custom converter for handling String/num to double
class StringToDoubleConverter implements JsonConverter<double?, dynamic> {
  const StringToDoubleConverter();

  @override
  double? fromJson(dynamic json) {
    if (json == null) return null;
    if (json is num) return json.toDouble();
    if (json is String) return double.tryParse(json);
    return null;
  }

  @override
  dynamic toJson(double? object) => object;
}

@JsonSerializable()
class AddressModel {
  final int id;
  final String label;
  final String address;
  final String? city;
  final String? district;
  final String? phone;
  final String? instructions;
  @StringToDoubleConverter()
  final double? latitude;
  @StringToDoubleConverter()
  final double? longitude;
  @JsonKey(name: 'is_default', defaultValue: false)
  final bool isDefault;
  @JsonKey(name: 'full_address', defaultValue: '')
  final String fullAddress;
  @JsonKey(name: 'has_coordinates', defaultValue: false)
  final bool hasCoordinates;
  @JsonKey(name: 'created_at', defaultValue: '')
  final String createdAt;
  @JsonKey(name: 'updated_at', defaultValue: '')
  final String updatedAt;

  const AddressModel({
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

  factory AddressModel.fromJson(Map<String, dynamic> json) =>
      _$AddressModelFromJson(json);

  Map<String, dynamic> toJson() => _$AddressModelToJson(this);

  AddressEntity toEntity() {
    return AddressEntity(
      id: id,
      label: label,
      address: address,
      city: city,
      district: district,
      phone: phone,
      instructions: instructions,
      latitude: latitude,
      longitude: longitude,
      isDefault: isDefault,
      fullAddress: fullAddress,
      hasCoordinates: hasCoordinates,
      createdAt: DateTime.tryParse(createdAt) ?? DateTime.now(),
      updatedAt: DateTime.tryParse(updatedAt) ?? DateTime.now(),
    );
  }

  factory AddressModel.fromEntity(AddressEntity entity) {
    return AddressModel(
      id: entity.id,
      label: entity.label,
      address: entity.address,
      city: entity.city,
      district: entity.district,
      phone: entity.phone,
      instructions: entity.instructions,
      latitude: entity.latitude,
      longitude: entity.longitude,
      isDefault: entity.isDefault,
      fullAddress: entity.fullAddress,
      hasCoordinates: entity.hasCoordinates,
      createdAt: entity.createdAt.toIso8601String(),
      updatedAt: entity.updatedAt.toIso8601String(),
    );
  }
}
