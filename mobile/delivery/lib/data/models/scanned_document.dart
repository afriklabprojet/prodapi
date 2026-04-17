import 'dart:io';
import 'package:flutter/material.dart';

/// Types de documents scannables
enum DocumentType {
  prescription('Ordonnance', Icons.medical_services, Colors.blue),
  receipt('Reçu de commande', Icons.receipt_long, Colors.green),
  idCard('Pièce d\'identité', Icons.credit_card, Colors.orange),
  deliveryProof('Preuve de livraison', Icons.verified, Colors.purple),
  insurance('Carte d\'assurance', Icons.health_and_safety, Colors.teal),
  other('Autre document', Icons.description, Colors.grey);

  final String label;
  final IconData icon;
  final Color color;

  const DocumentType(this.label, this.icon, this.color);
}

/// Statut du traitement OCR
enum OcrStatus {
  pending('En attente', Icons.hourglass_empty),
  processing('Traitement...', Icons.loop),
  success('Terminé', Icons.check_circle),
  failed('Échec', Icons.error),
  skipped('Ignoré', Icons.skip_next);

  final String label;
  final IconData icon;

  const OcrStatus(this.label, this.icon);
}

/// Qualité du scan
enum ScanQuality {
  poor(1, 'Mauvaise', Colors.red),
  fair(2, 'Acceptable', Colors.orange),
  good(3, 'Bonne', Colors.green),
  excellent(4, 'Excellente', Colors.blue);

  final int stars;
  final String label;
  final Color color;

  const ScanQuality(this.stars, this.label, this.color);

  static ScanQuality fromScore(double score) {
    if (score >= 0.9) return ScanQuality.excellent;
    if (score >= 0.7) return ScanQuality.good;
    if (score >= 0.5) return ScanQuality.fair;
    return ScanQuality.poor;
  }
}

/// Résultat OCR extrait du document
class OcrResult {
  final String rawText;
  final Map<String, String> extractedFields;
  final double confidence;
  final OcrStatus status;
  final String? errorMessage;
  final DateTime processedAt;

  OcrResult({
    required this.rawText,
    this.extractedFields = const {},
    this.confidence = 0.0,
    this.status = OcrStatus.pending,
    this.errorMessage,
    DateTime? processedAt,
  }) : processedAt = processedAt ?? DateTime.now();

  /// Résultat vide
  factory OcrResult.empty() => OcrResult(
        rawText: '',
        status: OcrStatus.pending,
      );

  /// Résultat d'erreur
  factory OcrResult.error(String message) => OcrResult(
        rawText: '',
        status: OcrStatus.failed,
        errorMessage: message,
      );

  bool get isSuccess => status == OcrStatus.success;
  bool get hasExtractedData => extractedFields.isNotEmpty;

  /// Champs extraits pour ordonnance
  String? get patientName => extractedFields['patient_name'];
  String? get doctorName => extractedFields['doctor_name'];
  String? get medicationList => extractedFields['medications'];
  String? get prescriptionDate => extractedFields['date'];

  /// Champs extraits pour reçu
  String? get orderNumber => extractedFields['order_number'];
  String? get totalAmount => extractedFields['total_amount'];
  String? get pharmacyName => extractedFields['pharmacy_name'];
}

/// Zone d'intérêt détectée dans le document
class DocumentRegion {
  final String label;
  final Rect bounds;
  final String? value;
  final double confidence;

  DocumentRegion({
    required this.label,
    required this.bounds,
    this.value,
    this.confidence = 0.0,
  });
}

/// Document scanné avec métadonnées
class ScannedDocument {
  final String id;
  final DocumentType type;
  final File originalImage;
  final File? processedImage;
  final ScanQuality quality;
  final OcrResult? ocrResult;
  final List<DocumentRegion> regions;
  final DateTime scannedAt;
  final int? deliveryId;
  final String? notes;
  final bool isUploaded;
  final String? cloudUrl;

  ScannedDocument({
    required this.id,
    required this.type,
    required this.originalImage,
    this.processedImage,
    this.quality = ScanQuality.good,
    this.ocrResult,
    this.regions = const [],
    DateTime? scannedAt,
    this.deliveryId,
    this.notes,
    this.isUploaded = false,
    this.cloudUrl,
  }) : scannedAt = scannedAt ?? DateTime.now();

  /// Copie avec modifications
  ScannedDocument copyWith({
    String? id,
    DocumentType? type,
    File? originalImage,
    File? processedImage,
    ScanQuality? quality,
    OcrResult? ocrResult,
    List<DocumentRegion>? regions,
    DateTime? scannedAt,
    int? deliveryId,
    String? notes,
    bool? isUploaded,
    String? cloudUrl,
  }) {
    return ScannedDocument(
      id: id ?? this.id,
      type: type ?? this.type,
      originalImage: originalImage ?? this.originalImage,
      processedImage: processedImage ?? this.processedImage,
      quality: quality ?? this.quality,
      ocrResult: ocrResult ?? this.ocrResult,
      regions: regions ?? this.regions,
      scannedAt: scannedAt ?? this.scannedAt,
      deliveryId: deliveryId ?? this.deliveryId,
      notes: notes ?? this.notes,
      isUploaded: isUploaded ?? this.isUploaded,
      cloudUrl: cloudUrl ?? this.cloudUrl,
    );
  }

  /// Fichier à utiliser (traité si disponible, sinon original)
  File get displayImage => processedImage ?? originalImage;

  /// Vérifie si le document a été traité par OCR
  bool get hasOcr => ocrResult != null && ocrResult!.isSuccess;

  /// Résumé du contenu extrait
  String get contentSummary {
    if (ocrResult == null) return 'Non analysé';
    if (!ocrResult!.isSuccess) return 'Analyse échouée';

    switch (type) {
      case DocumentType.prescription:
        final patient = ocrResult!.patientName ?? 'Patient inconnu';
        final meds = ocrResult!.medicationList ?? 'Médicaments non détectés';
        return '$patient - $meds';

      case DocumentType.receipt:
        final order = ocrResult!.orderNumber ?? 'N° inconnu';
        final amount = ocrResult!.totalAmount ?? '0';
        return 'Commande $order - $amount FCFA';

      case DocumentType.idCard:
        return ocrResult!.extractedFields['name'] ?? 'Identité non détectée';

      default:
        return ocrResult!.rawText.isNotEmpty
            ? ocrResult!.rawText.substring(
                0, ocrResult!.rawText.length > 50 ? 50 : ocrResult!.rawText.length)
            : 'Contenu non détecté';
    }
  }

  /// Convertit en Map pour JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'quality': quality.name,
      'scanned_at': scannedAt.toIso8601String(),
      'delivery_id': deliveryId,
      'notes': notes,
      'is_uploaded': isUploaded,
      'cloud_url': cloudUrl,
      'ocr_result': ocrResult != null
          ? {
              'raw_text': ocrResult!.rawText,
              'extracted_fields': ocrResult!.extractedFields,
              'confidence': ocrResult!.confidence,
              'status': ocrResult!.status.name,
            }
          : null,
    };
  }
}

/// État du scanner de documents
class DocumentScannerState {
  final bool isInitialized;
  final bool isProcessing;
  final bool hasFlash;
  final bool flashEnabled;
  final List<ScannedDocument> scannedDocuments;
  final DocumentType? selectedType;
  final String? error;

  const DocumentScannerState({
    this.isInitialized = false,
    this.isProcessing = false,
    this.hasFlash = true,
    this.flashEnabled = false,
    this.scannedDocuments = const [],
    this.selectedType,
    this.error,
  });

  DocumentScannerState copyWith({
    bool? isInitialized,
    bool? isProcessing,
    bool? hasFlash,
    bool? flashEnabled,
    List<ScannedDocument>? scannedDocuments,
    DocumentType? selectedType,
    String? error,
  }) {
    return DocumentScannerState(
      isInitialized: isInitialized ?? this.isInitialized,
      isProcessing: isProcessing ?? this.isProcessing,
      hasFlash: hasFlash ?? this.hasFlash,
      flashEnabled: flashEnabled ?? this.flashEnabled,
      scannedDocuments: scannedDocuments ?? this.scannedDocuments,
      selectedType: selectedType ?? this.selectedType,
      error: error,
    );
  }

  int get documentCount => scannedDocuments.length;

  List<ScannedDocument> documentsOfType(DocumentType type) {
    return scannedDocuments.where((d) => d.type == type).toList();
  }
}
