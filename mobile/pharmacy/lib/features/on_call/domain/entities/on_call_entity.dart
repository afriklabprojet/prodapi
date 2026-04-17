/// Entité représentant une garde de pharmacie
class OnCallEntity {
  final int id;
  final int pharmacyId;
  final int dutyZoneId;
  final DateTime startAt;
  final DateTime endAt;
  final OnCallType type;
  final bool isActive;

  const OnCallEntity({
    required this.id,
    required this.pharmacyId,
    required this.dutyZoneId,
    required this.startAt,
    required this.endAt,
    required this.type,
    required this.isActive,
  });

  /// Indique si la garde est en cours
  bool get isOngoing {
    final now = DateTime.now();
    return now.isAfter(startAt) && now.isBefore(endAt) && isActive;
  }

  /// Indique si la garde est à venir
  bool get isUpcoming => DateTime.now().isBefore(startAt) && isActive;

  /// Indique si la garde est passée
  bool get isPast => DateTime.now().isAfter(endAt);

  /// Durée de la garde
  Duration get duration => endAt.difference(startAt);

  /// Description du type de garde
  String get typeLabel {
    switch (type) {
      case OnCallType.day:
        return 'Garde de jour';
      case OnCallType.night:
        return 'Garde de nuit';
      case OnCallType.weekend:
        return 'Garde week-end';
      case OnCallType.holiday:
        return 'Garde jour férié';
    }
  }

  OnCallEntity copyWith({
    int? id,
    int? pharmacyId,
    int? dutyZoneId,
    DateTime? startAt,
    DateTime? endAt,
    OnCallType? type,
    bool? isActive,
  }) {
    return OnCallEntity(
      id: id ?? this.id,
      pharmacyId: pharmacyId ?? this.pharmacyId,
      dutyZoneId: dutyZoneId ?? this.dutyZoneId,
      startAt: startAt ?? this.startAt,
      endAt: endAt ?? this.endAt,
      type: type ?? this.type,
      isActive: isActive ?? this.isActive,
    );
  }
}

/// Type de garde
enum OnCallType {
  day,
  night,
  weekend,
  holiday,
}

/// Extension pour convertir String en OnCallType
extension OnCallTypeExtension on String {
  OnCallType toOnCallType() {
    switch (toLowerCase()) {
      case 'day':
        return OnCallType.day;
      case 'night':
        return OnCallType.night;
      case 'weekend':
        return OnCallType.weekend;
      case 'holiday':
        return OnCallType.holiday;
      default:
        return OnCallType.day;
    }
  }
}

/// Extension pour convertir OnCallType en String
extension OnCallTypeToString on OnCallType {
  String toApiString() {
    switch (this) {
      case OnCallType.day:
        return 'day';
      case OnCallType.night:
        return 'night';
      case OnCallType.weekend:
        return 'weekend';
      case OnCallType.holiday:
        return 'holiday';
    }
  }
}
