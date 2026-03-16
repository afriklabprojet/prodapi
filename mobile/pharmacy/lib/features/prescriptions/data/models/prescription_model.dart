// No json_annotation import needed - manual fromJson for robust type handling.

class PrescriptionModel {
  final int id;
  final int customerId;
  final String status;
  final String? notes;
  final List<String>? images;
  final String? adminNotes;
  final String? pharmacyNotes;
  final double? quoteAmount;
  final String createdAt;
  final Map<String, dynamic>? customer;

  // OCR fields
  final List<dynamic>? extractedMedications;
  final List<dynamic>? matchedProducts;
  final List<dynamic>? unmatchedMedications;
  final double? ocrConfidence;
  final String? analyzedAt;
  final String? analysisStatus;
  final String? analysisError;

  PrescriptionModel({
    required this.id,
    required this.customerId,
    required this.status,
    this.notes,
    this.images,
    this.adminNotes,
    this.pharmacyNotes,
    this.quoteAmount,
    required this.createdAt,
    this.customer,
    this.extractedMedications,
    this.matchedProducts,
    this.unmatchedMedications,
    this.ocrConfidence,
    this.analyzedAt,
    this.analysisStatus,
    this.analysisError,
  });

  /// Safe parser - handles numeric fields returned as String or num from MySQL/PDO.
  factory PrescriptionModel.fromJson(Map<String, dynamic> json) {
    return PrescriptionModel(
      id: _parseInt(json['id']) ?? 0,
      customerId: _parseInt(json['customer_id']) ?? 0,
      status: json['status']?.toString() ?? 'pending',
      notes: json['notes']?.toString(),
      images: (json['images'] as List<dynamic>?)
          ?.map((e) => e?.toString() ?? '')
          .toList(),
      adminNotes: json['admin_notes']?.toString(),
      pharmacyNotes: json['pharmacy_notes']?.toString(),
      quoteAmount: _parseDouble(json['quote_amount']),
      createdAt: json['created_at']?.toString() ?? DateTime.now().toIso8601String(),
      customer: json['customer'] as Map<String, dynamic>?,
      extractedMedications: json['extracted_medications'] as List<dynamic>?,
      matchedProducts: json['matched_products'] as List<dynamic>?,
      unmatchedMedications: json['unmatched_medications'] as List<dynamic>?,
      ocrConfidence: _parseDouble(json['ocr_confidence']),
      analyzedAt: json['analyzed_at']?.toString(),
      analysisStatus: json['analysis_status']?.toString(),
      analysisError: json['analysis_error']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'customer_id': customerId,
        'status': status,
        'notes': notes,
        'images': images,
        'admin_notes': adminNotes,
        'pharmacy_notes': pharmacyNotes,
        'quote_amount': quoteAmount,
        'created_at': createdAt,
        'customer': customer,
        'extracted_medications': extractedMedications,
        'matched_products': matchedProducts,
        'unmatched_medications': unmatchedMedications,
        'ocr_confidence': ocrConfidence,
        'analyzed_at': analyzedAt,
        'analysis_status': analysisStatus,
        'analysis_error': analysisError,
      };

  bool get isAnalyzed => analysisStatus == 'completed';
  bool get needsManualReview => analysisStatus == 'manual_review';
  bool get analysisFailed => analysisStatus == 'failed';
  bool get isPendingAnalysis =>
      analysisStatus == null || analysisStatus == 'pending';

  /// Parse a value that may be int, double, or String into int.
  static int? _parseInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is double) return v.toInt();
    if (v is num) return v.toInt();
    return int.tryParse(v.toString());
  }

  /// Parse a value that may be int, double, or String into double.
  static double? _parseDouble(dynamic v) {
    if (v == null) return null;
    if (v is double) return v;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString());
  }
}
