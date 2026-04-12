import 'package:dartz/dartz.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/services/app_logger.dart';
import '../../domain/entities/pharmacy_entity.dart';
import '../../domain/repositories/pharmacies_repository.dart';
import '../datasources/pharmacies_remote_datasource.dart';

class PharmaciesRepositoryImpl implements PharmaciesRepository {
  final PharmaciesRemoteDataSource remoteDataSource;

  PharmaciesRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, List<PharmacyEntity>>> getPharmacies({
    int page = 1,
    int perPage = 20,
  }) async {
    try {
      final models = await remoteDataSource.getPharmacies(
        page: page,
        perPage: perPage,
      );
      return Right(models.map((m) => m.toEntity()).toList());
    } on UnauthorizedException catch (e) {
      return Left(UnauthorizedFailure(message: e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } catch (e) {
      AppLogger.error('PharmaciesRepository.getPharmacies failed', error: e);
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<PharmacyEntity>>> getNearbyPharmacies({
    required double latitude,
    required double longitude,
    double? radius,
  }) async {
    try {
      final models = await remoteDataSource.getNearbyPharmacies(
        latitude: latitude,
        longitude: longitude,
        radius: radius,
      );
      return Right(models.map((m) => m.toEntity()).toList());
    } on UnauthorizedException catch (e) {
      return Left(UnauthorizedFailure(message: e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } catch (e) {
      AppLogger.error(
        'PharmaciesRepository.getNearbyPharmacies failed',
        error: e,
      );
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<PharmacyEntity>>> getOnDutyPharmacies({
    double? latitude,
    double? longitude,
    double? radius,
  }) async {
    try {
      final models = await remoteDataSource.getOnDutyPharmacies(
        latitude: latitude,
        longitude: longitude,
        radius: radius,
      );
      return Right(models.map((m) => m.toEntity()).toList());
    } on UnauthorizedException catch (e) {
      return Left(UnauthorizedFailure(message: e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } catch (e) {
      AppLogger.error(
        'PharmaciesRepository.getOnDutyPharmacies failed',
        error: e,
      );
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, PharmacyEntity>> getPharmacyDetails(
    int pharmacyId,
  ) async {
    try {
      final model = await remoteDataSource.getPharmacyDetails(pharmacyId);
      return Right(model.toEntity());
    } on UnauthorizedException catch (e) {
      return Left(UnauthorizedFailure(message: e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } catch (e) {
      AppLogger.error(
        'PharmaciesRepository.getPharmacyDetails failed',
        error: e,
      );
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<PharmacyEntity>>> getFeaturedPharmacies() async {
    try {
      final models = await remoteDataSource.getFeaturedPharmacies();
      return Right(models.map((m) => m.toEntity()).toList());
    } on UnauthorizedException catch (e) {
      return Left(UnauthorizedFailure(message: e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } catch (e) {
      AppLogger.error(
        'PharmaciesRepository.getFeaturedPharmacies failed',
        error: e,
      );
      return Left(ServerFailure(message: e.toString()));
    }
  }
}
