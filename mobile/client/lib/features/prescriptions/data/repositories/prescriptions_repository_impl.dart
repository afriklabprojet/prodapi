import 'package:dartz/dartz.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/services/app_logger.dart';
import '../../data/datasources/prescriptions_remote_datasource.dart';
import '../../data/models/prescription_model.dart';
import '../../domain/entities/prescription_entity.dart';

class PrescriptionsRepositoryImpl {
  final PrescriptionsRemoteDataSource remoteDataSource;

  PrescriptionsRepositoryImpl({required this.remoteDataSource});

  Future<Either<Failure, List<PrescriptionEntity>>> getPrescriptions() async {
    try {
      final jsonList = await remoteDataSource.getPrescriptions();
      final entities = jsonList
          .map((json) => PrescriptionModel.fromJson(json).toEntity())
          .toList();
      return Right(entities);
    } on UnauthorizedException catch (e) {
      return Left(UnauthorizedFailure(message: e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } catch (e) {
      AppLogger.error(
        'PrescriptionsRepository.getPrescriptions failed',
        error: e,
      );
      return Left(ServerFailure(message: e.toString()));
    }
  }

  Future<Either<Failure, PrescriptionEntity>> getPrescriptionDetails(
    int prescriptionId,
  ) async {
    try {
      final json = await remoteDataSource.getPrescriptionDetails(
        prescriptionId,
      );
      final entity = PrescriptionModel.fromJson(json).toEntity();
      return Right(entity);
    } on UnauthorizedException catch (e) {
      return Left(UnauthorizedFailure(message: e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } catch (e) {
      AppLogger.error(
        'PrescriptionsRepository.getPrescriptionDetails failed',
        error: e,
      );
      return Left(ServerFailure(message: e.toString()));
    }
  }

  Future<Either<Failure, Map<String, dynamic>>> payPrescription({
    required int prescriptionId,
    required String paymentMethod,
  }) async {
    try {
      final response = await remoteDataSource.payPrescription(
        prescriptionId,
        paymentMethod,
      );
      return Right(response);
    } on UnauthorizedException catch (e) {
      return Left(UnauthorizedFailure(message: e.message));
    } on ValidationException catch (e) {
      return Left(ValidationFailure(message: e.firstError, errors: e.errors));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } catch (e) {
      AppLogger.error(
        'PrescriptionsRepository.payPrescription failed',
        error: e,
      );
      return Left(ServerFailure(message: e.toString()));
    }
  }
}
