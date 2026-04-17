import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/services/app_logger.dart';
import '../../domain/entities/treatment_entity.dart';
import '../../domain/repositories/treatments_repository.dart';
import '../datasources/treatments_local_datasource.dart';
import '../models/treatment_model.dart';

/// Implémentation du repository des traitements
class TreatmentsRepositoryImpl implements TreatmentsRepository {
  final TreatmentsLocalDatasource _localDatasource;

  TreatmentsRepositoryImpl(this._localDatasource);

  @override
  Future<Either<Failure, List<TreatmentEntity>>> getTreatments() async {
    try {
      final models = await _localDatasource.getAllTreatments();
      final entities = models.map((m) => m.toEntity()).toList();
      return Right(entities);
    } catch (e) {
      AppLogger.error('Error getting treatments', error: e);
      return Left(CacheFailure(message: 'Erreur lors du chargement des traitements'));
    }
  }

  @override
  Future<Either<Failure, List<TreatmentEntity>>> getTreatmentsNeedingRenewal() async {
    try {
      final models = await _localDatasource.getTreatmentsNeedingRenewal();
      final entities = models.map((m) => m.toEntity()).toList();
      return Right(entities);
    } catch (e) {
      AppLogger.error('Error getting treatments needing renewal', error: e);
      return Left(CacheFailure(message: 'Erreur lors du chargement des rappels'));
    }
  }

  @override
  Future<Either<Failure, TreatmentEntity>> addTreatment(TreatmentEntity treatment) async {
    try {
      final model = TreatmentModel.fromEntity(treatment);
      final savedModel = await _localDatasource.addTreatment(model);
      return Right(savedModel.toEntity());
    } catch (e) {
      AppLogger.error('Error adding treatment', error: e);
      return Left(CacheFailure(message: 'Erreur lors de l\'ajout du traitement'));
    }
  }

  @override
  Future<Either<Failure, TreatmentEntity>> updateTreatment(TreatmentEntity treatment) async {
    try {
      final model = TreatmentModel.fromEntity(treatment);
      final updatedModel = await _localDatasource.updateTreatment(model);
      return Right(updatedModel.toEntity());
    } catch (e) {
      AppLogger.error('Error updating treatment', error: e);
      return Left(CacheFailure(message: 'Erreur lors de la mise à jour du traitement'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteTreatment(String treatmentId) async {
    try {
      await _localDatasource.deleteTreatment(treatmentId);
      return const Right(null);
    } catch (e) {
      AppLogger.error('Error deleting treatment', error: e);
      return Left(CacheFailure(message: 'Erreur lors de la suppression du traitement'));
    }
  }

  @override
  Future<Either<Failure, TreatmentEntity>> markAsOrdered(String treatmentId) async {
    try {
      final updatedModel = await _localDatasource.markAsOrdered(treatmentId);
      return Right(updatedModel.toEntity());
    } catch (e) {
      AppLogger.error('Error marking treatment as ordered', error: e);
      return Left(CacheFailure(message: 'Erreur lors de la mise à jour du traitement'));
    }
  }

  @override
  Future<Either<Failure, TreatmentEntity>> toggleReminder(String treatmentId, bool enabled) async {
    try {
      final updatedModel = await _localDatasource.toggleReminder(treatmentId, enabled);
      return Right(updatedModel.toEntity());
    } catch (e) {
      AppLogger.error('Error toggling treatment reminder', error: e);
      return Left(CacheFailure(message: 'Erreur lors de la mise à jour des rappels'));
    }
  }
}
