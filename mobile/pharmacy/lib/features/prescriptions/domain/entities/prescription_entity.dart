/// Entité représentant une prescription/ordonnance
/// 
/// Cette entité est indépendante du format JSON de l'API
/// et représente le modèle métier de l'application.
class PrescriptionEntity {
  final int id;
  final int customerId;
  final String status;
  final String? notes;
  final List<String> images;
  final String? adminNotes;
  final String? pharmacyNotes;
  final double? quoteAmount;
  final DateTime createdAt;
  final CustomerInfo? customer;
  
  // Informations OCR
  final List<dynamic>? extractedMedications;
  final List<dynamic>? matchedProducts;
  final List<dynamic>? unmatchedMedications;
  final double? ocrConfidence;
  final DateTime? analyzedAt;
  final AnalysisStatus analysisStatus;
  final String? analysisError;

  const PrescriptionEntity({
    required this.id,
    required this.customerId,
    required this.status,
    this.notes,
    this.images = const [],
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
    this.analysisStatus = AnalysisStatus.pending,
    this.analysisError,
  });

  /// Indique si l'ordonnance a été analysée par OCR
  bool get isAnalyzed => analysisStatus == AnalysisStatus.completed;
  
  /// Indique si une revue manuelle est nécessaire
  bool get needsManualReview => analysisStatus == AnalysisStatus.manualReview;
  
  /// Indique si l'analyse a échoué
  bool get analysisFailed => analysisStatus == AnalysisStatus.failed;
  
  /// Indique si l'analyse est en attente
  bool get isPendingAnalysis => analysisStatus == AnalysisStatus.pending;

  /// Statut de prescription localisé en français
  String get statusLabel {
    switch (status) {
      case 'pending':
        return 'En attente';
      case 'processing':
        return 'En traitement';
      case 'quoted':
        return 'Devis envoyé';
      case 'approved':
        return 'Approuvée';
      case 'rejected':
        return 'Refusée';
      case 'completed':
        return 'Terminée';
      default:
        return status;
    }
  }

  PrescriptionEntity copyWith({
    int? id,
    int? customerId,
    String? status,
    String? notes,
    List<String>? images,
    String? adminNotes,
    String? pharmacyNotes,
    double? quoteAmount,
    DateTime? createdAt,
    CustomerInfo? customer,
    List<dynamic>? extractedMedications,
    List<dynamic>? matchedProducts,
    List<dynamic>? unmatchedMedications,
    double? ocrConfidence,
    DateTime? analyzedAt,
    AnalysisStatus? analysisStatus,
    String? analysisError,
  }) {
    return PrescriptionEntity(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      images: images ?? this.images,
      adminNotes: adminNotes ?? this.adminNotes,
      pharmacyNotes: pharmacyNotes ?? this.pharmacyNotes,
      quoteAmount: quoteAmount ?? this.quoteAmount,
      createdAt: createdAt ?? this.createdAt,
      customer: customer ?? this.customer,
      extractedMedications: extractedMedications ?? this.extractedMedications,
      matchedProducts: matchedProducts ?? this.matchedProducts,
      unmatchedMedications: unmatchedMedications ?? this.unmatchedMedications,
      ocrConfidence: ocrConfidence ?? this.ocrConfidence,
      analyzedAt: analyzedAt ?? this.analyzedAt,
      analysisStatus: analysisStatus ?? this.analysisStatus,
      analysisError: analysisError ?? this.analysisError,
    );
  }
}

/// Informations sur le client ayant soumis l'ordonnance
class CustomerInfo {
  final int id;
  final String name;
  final String? phone;
  final String? email;

  const CustomerInfo({
    required this.id,
    required this.name,
    this.phone,
    this.email,
  });
}

/// Statut d'analyse OCR de l'ordonnance
enum AnalysisStatus {
  pending,
  completed,
  manualReview,
  failed,
}

/// Extension pour convertir un String en AnalysisStatus
extension AnalysisStatusExtension on String? {
  AnalysisStatus toAnalysisStatus() {
    switch (this) {
      case 'completed':
        return AnalysisStatus.completed;
      case 'manual_review':
        return AnalysisStatus.manualReview;
      case 'failed':
        return AnalysisStatus.failed;
      default:
        return AnalysisStatus.pending;
    }
  }
}
