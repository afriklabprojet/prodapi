import '../../domain/entities/prescription_entity.dart';

/// Model pour les prescriptions (couche Data)
/// Gère la sérialisation/désérialisation JSON
class PrescriptionModel {
  final int id;
  final String status;
  final String? notes;
  final List<String> images;
  final String? rejectionReason;
  final double? quoteAmount;
  final String? pharmacyNotes;
  final String createdAt;
  final String? validatedAt;
  final int? orderId;
  final String? orderReference;
  final String? source;
  final String fulfillmentStatus;
  final int dispensingCount;

  const PrescriptionModel({
    required this.id,
    required this.status,
    this.notes,
    required this.images,
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

  factory PrescriptionModel.fromJson(Map<String, dynamic> json) {
    // Handle 'images' which can be a list of strings or list of maps
    List<String> imageUrls = [];
    final imagesRaw = json['images'];
    if (imagesRaw is List) {
      for (final img in imagesRaw) {
        if (img is String) {
          imageUrls.add(img);
        } else if (img is Map && img['url'] != null) {
          imageUrls.add(img['url'] as String);
        }
      }
    }

    return PrescriptionModel(
      id: json['id'] as int,
      status: json['status'] as String? ?? 'pending',
      notes: json['notes'] as String?,
      images: imageUrls,
      rejectionReason: json['rejection_reason'] as String?,
      quoteAmount: json['quote_amount'] != null 
          ? double.tryParse(json['quote_amount'].toString()) 
          : null,
      pharmacyNotes: json['pharmacy_notes'] as String?,
      createdAt: json['created_at'] as String,
      validatedAt: json['validated_at'] as String?,
      orderId: json['order_id'] as int?,
      orderReference: json['order_reference'] as String?,
      source: json['source'] as String?,
      fulfillmentStatus: json['fulfillment_status']?.toString() ?? 'none',
      dispensingCount: (json['dispensing_count'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'status': status,
      'notes': notes,
      'images': images,
      'rejection_reason': rejectionReason,
      'quote_amount': quoteAmount,
      'pharmacy_notes': pharmacyNotes,
      'created_at': createdAt,
      'validated_at': validatedAt,
      'order_id': orderId,
      'order_reference': orderReference,
      'source': source,
      'fulfillment_status': fulfillmentStatus,
      'dispensing_count': dispensingCount,
    };
  }

  /// Convertit le Model en Entity (couche Domain)
  PrescriptionEntity toEntity() {
    return PrescriptionEntity(
      id: id,
      status: status,
      notes: notes,
      imageUrls: images,
      rejectionReason: rejectionReason,
      quoteAmount: quoteAmount,
      pharmacyNotes: pharmacyNotes,
      createdAt: DateTime.tryParse(createdAt) ?? DateTime.now(),
      validatedAt: validatedAt != null ? DateTime.tryParse(validatedAt!) : null,
      orderId: orderId,
      orderReference: orderReference,
      source: source,
      fulfillmentStatus: fulfillmentStatus,
      dispensingCount: dispensingCount,
    );
  }
}
