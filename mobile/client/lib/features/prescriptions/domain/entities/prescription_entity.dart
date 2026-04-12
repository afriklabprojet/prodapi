import 'package:equatable/equatable.dart';

/// Entité Prescription (couche Domain)
class PrescriptionEntity extends Equatable {
  final int id;
  final String status;
  final String? notes;
  final List<String> imageUrls;
  final String? rejectionReason;
  final double? quoteAmount;
  final String? pharmacyNotes;
  final DateTime createdAt;
  final DateTime? validatedAt;
  final int? orderId;
  final String? orderReference;
  final String? source;
  final String fulfillmentStatus;
  final int dispensingCount;

  const PrescriptionEntity({
    required this.id,
    required this.status,
    this.notes,
    required this.imageUrls,
    this.rejectionReason,
    this.quoteAmount,
    this.pharmacyNotes,
    required this.createdAt,
    this.validatedAt,
    this.orderId,
    this.orderReference,
    this.source,
    this.fulfillmentStatus = 'none',
    this.dispensingCount = 0,
  });

  bool get isPending => status == 'pending';
  bool get isValidated => status == 'validated';
  bool get isRejected => status == 'rejected';
  bool get hasQuote => quoteAmount != null && quoteAmount! > 0;
  bool get isLinkedToOrder => orderId != null;
  bool get isFullyDispensed => fulfillmentStatus == 'full';
  bool get isPartiallyDispensed => fulfillmentStatus == 'partial';

  String get statusLabel {
    switch (status) {
      case 'pending':
        return 'En attente';
      case 'validated':
        return 'Validée';
      case 'rejected':
        return 'Rejetée';
      case 'quoted':
        return 'Devis envoyé';
      default:
        return status;
    }
  }

  @override
  List<Object?> get props => [id, status, createdAt];
}
