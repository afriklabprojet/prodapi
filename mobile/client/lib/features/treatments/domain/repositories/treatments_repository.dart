import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/treatment_entity.dart';

/// Repository interface pour les traitements
abstract class TreatmentsRepository {
  /// Récupère tous les traitements actifs
  Future<Either<Failure, List<TreatmentEntity>>> getTreatments();

  /// Récupère les traitements qui ont besoin d'un renouvellement
  Future<Either<Failure, List<TreatmentEntity>>> getTreatmentsNeedingRenewal();

  /// Ajoute un nouveau traitement
  Future<Either<Failure, TreatmentEntity>> addTreatment(TreatmentEntity treatment);

  /// Met à jour un traitement existant
  Future<Either<Failure, TreatmentEntity>> updateTreatment(TreatmentEntity treatment);

  /// Supprime un traitement
  Future<Either<Failure, void>> deleteTreatment(String treatmentId);

  /// Marque un traitement comme commandé (met à jour lastOrderedAt et nextRenewalDate)
  Future<Either<Failure, TreatmentEntity>> markAsOrdered(String treatmentId);

  /// Active/désactive les rappels pour un traitement
  Future<Either<Failure, TreatmentEntity>> toggleReminder(String treatmentId, bool enabled);
}
