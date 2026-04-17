class OnCallModel {
  final int id;
  final int pharmacyId;
  final int dutyZoneId;
  final DateTime startAt;
  final DateTime endAt;
  final String type;
  final bool isActive;

  OnCallModel({
    required this.id,
    required this.pharmacyId,
    required this.dutyZoneId,
    required this.startAt,
    required this.endAt,
    required this.type,
    required this.isActive,
  });

  factory OnCallModel.fromJson(Map<String, dynamic> json) {
    return OnCallModel(
      id: _parseInt(json['id']) ?? 0,
      pharmacyId: _parseInt(json['pharmacy_id']) ?? 0,
      dutyZoneId: _parseInt(json['duty_zone_id']) ?? 0,
      startAt: DateTime.tryParse(json['start_at']?.toString() ?? '') ?? DateTime.now(),
      endAt: DateTime.tryParse(json['end_at']?.toString() ?? '') ?? DateTime.now(),
      type: json['type']?.toString() ?? 'night',
      isActive: json['is_active'] == 1 || json['is_active'] == true,
    );
  }

  static int? _parseInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString());
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'pharmacy_id': pharmacyId,
      'duty_zone_id': dutyZoneId,
      'start_at': startAt.toIso8601String(),
      'end_at': endAt.toIso8601String(),
      'type': type,
      'is_active': isActive,
    };
  }
}
