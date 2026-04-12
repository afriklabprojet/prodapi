import 'package:equatable/equatable.dart';

/// Entité représentant un traitement récurrent d'un patient
class TreatmentEntity extends Equatable {
  final String id;
  final int productId;
  final String productName;
  final String? productImage;
  final String? dosage; // ex: "500mg"
  final String? frequency; // ex: "2 fois par jour"
  final int? quantityPerRenewal; // quantité à commander
  final int renewalPeriodDays; // ex: 30 jours
  final DateTime? nextRenewalDate;
  final DateTime? lastOrderedAt;
  final bool reminderEnabled;
  final int reminderDaysBefore; // rappel X jours avant renouvellement
  final String? notes;
  final bool isActive;
  final DateTime createdAt;

  const TreatmentEntity({
    required this.id,
    required this.productId,
    required this.productName,
    this.productImage,
    this.dosage,
    this.frequency,
    this.quantityPerRenewal,
    required this.renewalPeriodDays,
    this.nextRenewalDate,
    this.lastOrderedAt,
    this.reminderEnabled = true,
    this.reminderDaysBefore = 3,
    this.notes,
    this.isActive = true,
    required this.createdAt,
  });

  /// Calcule le nombre de jours restants avant le prochain renouvellement
  int? get daysUntilRenewal {
    if (nextRenewalDate == null) return null;
    return nextRenewalDate!.difference(DateTime.now()).inDays;
  }

  /// Vérifie si le traitement a besoin d'être renouvelé bientôt
  bool get needsRenewalSoon {
    final days = daysUntilRenewal;
    if (days == null) return false;
    return days <= reminderDaysBefore;
  }

  /// Vérifie si le traitement est en retard de renouvellement
  bool get isOverdue {
    final days = daysUntilRenewal;
    if (days == null) return false;
    return days < 0;
  }

  /// Copie avec modifications
  TreatmentEntity copyWith({
    String? id,
    int? productId,
    String? productName,
    String? productImage,
    String? dosage,
    String? frequency,
    int? quantityPerRenewal,
    int? renewalPeriodDays,
    DateTime? nextRenewalDate,
    DateTime? lastOrderedAt,
    bool? reminderEnabled,
    int? reminderDaysBefore,
    String? notes,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return TreatmentEntity(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      productImage: productImage ?? this.productImage,
      dosage: dosage ?? this.dosage,
      frequency: frequency ?? this.frequency,
      quantityPerRenewal: quantityPerRenewal ?? this.quantityPerRenewal,
      renewalPeriodDays: renewalPeriodDays ?? this.renewalPeriodDays,
      nextRenewalDate: nextRenewalDate ?? this.nextRenewalDate,
      lastOrderedAt: lastOrderedAt ?? this.lastOrderedAt,
      reminderEnabled: reminderEnabled ?? this.reminderEnabled,
      reminderDaysBefore: reminderDaysBefore ?? this.reminderDaysBefore,
      notes: notes ?? this.notes,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        productId,
        productName,
        productImage,
        dosage,
        frequency,
        quantityPerRenewal,
        renewalPeriodDays,
        nextRenewalDate,
        lastOrderedAt,
        reminderEnabled,
        reminderDaysBefore,
        notes,
        isActive,
        createdAt,
      ];
}

/// Fréquences de prise prédéfinies
enum TreatmentFrequency {
  onceDaily('1 fois par jour'),
  twiceDaily('2 fois par jour'),
  thriceDaily('3 fois par jour'),
  fourTimesDaily('4 fois par jour'),
  onceWeekly('1 fois par semaine'),
  asNeeded('Au besoin'),
  custom('Personnalisé');

  final String label;
  const TreatmentFrequency(this.label);
}

/// Périodes de renouvellement prédéfinies
enum RenewalPeriod {
  oneWeek(7, '1 semaine'),
  twoWeeks(14, '2 semaines'),
  oneMonth(30, '1 mois'),
  twoMonths(60, '2 mois'),
  threeMonths(90, '3 mois'),
  sixMonths(180, '6 mois'),
  custom(0, 'Personnalisé');

  final int days;
  final String label;
  const RenewalPeriod(this.days, this.label);
}
