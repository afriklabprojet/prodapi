import 'package:dartz/dartz.dart';
import '../../../../core/errors/failure.dart';
import '../entities/prescription_entity.dart';

/// Interface abstraite du repository de prescriptions
/// Définit le contrat que l'implémentation data layer doit respecter.
abstract class PrescriptionRepository {
  /// Récupère toutes les prescriptions de la pharmacie
  Future<Either<Failure, List<PrescriptionEntity>>> getPrescriptions();
  
  /// Récupère une prescription par son ID
  Future<Either<Failure, PrescriptionEntity>> getPrescription(int id);
  
  /// Met à jour le statut d'une prescription
  Future<Either<Failure, PrescriptionEntity>> updateStatus(
    int id,
    String status, {
    String? notes,
    double? quoteAmount,
  });
  
  /// Analyse une prescription avec OCR
  Future<Either<Failure, PrescriptionAnalysisResult>> analyzePrescription(
    int id, {
    bool force = false,
  });
}

/// Résultat de l'analyse OCR d'une prescription
class PrescriptionAnalysisResult {
  final List<ExtractedMedication> extractedMedications;
  final List<MatchedProduct> matchedProducts;
  final List<String> unmatchedMedications;
  final double confidence;
  final String status;
  final String? error;

  const PrescriptionAnalysisResult({
    required this.extractedMedications,
    required this.matchedProducts,
    required this.unmatchedMedications,
    required this.confidence,
    required this.status,
    this.error,
  });
}

/// Médicament extrait par OCR
class ExtractedMedication {
  final String name;
  final String? dosage;
  final String? frequency;
  final int? quantity;
  final double confidence;

  const ExtractedMedication({
    required this.name,
    this.dosage,
    this.frequency,
    this.quantity,
    required this.confidence,
  });
}

/// Produit trouvé dans l'inventaire correspondant à un médicament
class MatchedProduct {
  final int productId;
  final String productName;
  final String medicationName;
  final double price;
  final int stockQuantity;
  final double matchScore;

  const MatchedProduct({
    required this.productId,
    required this.productName,
    required this.medicationName,
    required this.price,
    required this.stockQuantity,
    required this.matchScore,
  });
}
