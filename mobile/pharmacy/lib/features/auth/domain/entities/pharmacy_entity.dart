class PharmacyEntity {
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

  const PharmacyEntity({
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
}
