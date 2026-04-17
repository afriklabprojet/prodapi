import 'package:hive_flutter/hive_flutter.dart';
import '../../domain/entities/treatment_entity.dart';

part 'treatment_model.g.dart';

/// Modèle Hive pour le stockage local des traitements
@HiveType(typeId: 10)
class TreatmentModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final int productId;

  @HiveField(2)
  final String productName;

  @HiveField(3)
  final String? productImage;

  @HiveField(4)
  final String? dosage;

  @HiveField(5)
  final String? frequency;

  @HiveField(6)
  final int? quantityPerRenewal;

  @HiveField(7)
  final int renewalPeriodDays;

  @HiveField(8)
  final DateTime? nextRenewalDate;

  @HiveField(9)
  final DateTime? lastOrderedAt;

  @HiveField(10)
  final bool reminderEnabled;

  @HiveField(11)
  final int reminderDaysBefore;

  @HiveField(12)
  final String? notes;

  @HiveField(13)
  final bool isActive;

  @HiveField(14)
  final DateTime createdAt;

  TreatmentModel({
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

  /// Convertit depuis l'entité domain
  factory TreatmentModel.fromEntity(TreatmentEntity entity) {
    return TreatmentModel(
      id: entity.id,
      productId: entity.productId,
      productName: entity.productName,
      productImage: entity.productImage,
      dosage: entity.dosage,
      frequency: entity.frequency,
      quantityPerRenewal: entity.quantityPerRenewal,
      renewalPeriodDays: entity.renewalPeriodDays,
      nextRenewalDate: entity.nextRenewalDate,
      lastOrderedAt: entity.lastOrderedAt,
      reminderEnabled: entity.reminderEnabled,
      reminderDaysBefore: entity.reminderDaysBefore,
      notes: entity.notes,
      isActive: entity.isActive,
      createdAt: entity.createdAt,
    );
  }

  /// Convertit vers l'entité domain
  TreatmentEntity toEntity() {
    return TreatmentEntity(
      id: id,
      productId: productId,
      productName: productName,
      productImage: productImage,
      dosage: dosage,
      frequency: frequency,
      quantityPerRenewal: quantityPerRenewal,
      renewalPeriodDays: renewalPeriodDays,
      nextRenewalDate: nextRenewalDate,
      lastOrderedAt: lastOrderedAt,
      reminderEnabled: reminderEnabled,
      reminderDaysBefore: reminderDaysBefore,
      notes: notes,
      isActive: isActive,
      createdAt: createdAt,
    );
  }

  /// Convertit depuis JSON (pour sync serveur future)
  factory TreatmentModel.fromJson(Map<String, dynamic> json) {
    return TreatmentModel(
      id: json['id'] as String,
      productId: json['product_id'] as int,
      productName: json['product_name'] as String,
      productImage: json['product_image'] as String?,
      dosage: json['dosage'] as String?,
      frequency: json['frequency'] as String?,
      quantityPerRenewal: json['quantity_per_renewal'] as int?,
      renewalPeriodDays: json['renewal_period_days'] as int,
      nextRenewalDate: json['next_renewal_date'] != null
          ? DateTime.parse(json['next_renewal_date'] as String)
          : null,
      lastOrderedAt: json['last_ordered_at'] != null
          ? DateTime.parse(json['last_ordered_at'] as String)
          : null,
      reminderEnabled: json['reminder_enabled'] as bool? ?? true,
      reminderDaysBefore: json['reminder_days_before'] as int? ?? 3,
      notes: json['notes'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  /// Convertit vers JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'product_id': productId,
      'product_name': productName,
      'product_image': productImage,
      'dosage': dosage,
      'frequency': frequency,
      'quantity_per_renewal': quantityPerRenewal,
      'renewal_period_days': renewalPeriodDays,
      'next_renewal_date': nextRenewalDate?.toIso8601String(),
      'last_ordered_at': lastOrderedAt?.toIso8601String(),
      'reminder_enabled': reminderEnabled,
      'reminder_days_before': reminderDaysBefore,
      'notes': notes,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
