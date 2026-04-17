import 'package:json_annotation/json_annotation.dart';
import '../../domain/entities/pharmacy_entity.dart';

part 'pharmacy_model.g.dart';

@JsonSerializable()
class PharmacyModel {
  final int id;
  final String name;
  final String? address;
  final String? city;
  final String? phone;
  final String? email;
  final String status;
  @JsonKey(name: 'license_number')
  final String? licenseNumber;
  @JsonKey(name: 'license_document')
  final String? licenseDocument;
  @JsonKey(name: 'id_card_document')
  final String? idCardDocument;
  @JsonKey(name: 'duty_zone_id')
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

  factory PharmacyModel.fromJson(Map<String, dynamic> json) =>
      _$PharmacyModelFromJson(json);

  Map<String, dynamic> toJson() => _$PharmacyModelToJson(this);

  PharmacyEntity toEntity() {
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
