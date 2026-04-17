import 'dart:typed_data';
import 'package:dartz/dartz.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/services/app_logger.dart';
import '../../domain/entities/profile_entity.dart';
import '../../domain/entities/update_profile_entity.dart';
import '../../domain/repositories/profile_repository.dart';
import '../datasources/profile_local_datasource.dart';
import '../datasources/profile_remote_datasource.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  final ProfileRemoteDataSource remoteDataSource;
  final ProfileLocalDataSource localDataSource;

  ProfileRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
  });

  @override
  Future<Either<Failure, ProfileEntity>> getProfile() async {
    try {
      final model = await remoteDataSource.getProfile();
      await localDataSource.cacheProfile(model);
      return Right(model.toEntity());
    } on NetworkException catch (e) {
      final cached = await localDataSource.getCachedProfile();
      if (cached != null) return Right(cached.toEntity());
      return Left(NetworkFailure(message: e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } catch (e) {
      AppLogger.error('ProfileRepository.getProfile failed', error: e);
      return Left(ServerFailure(message: 'Une erreur inattendue est survenue.'));
    }
  }

  @override
  Future<Either<Failure, ProfileEntity>> updateProfile(
    UpdateProfileEntity updateProfile,
  ) async {
    try {
      final data = <String, dynamic>{};
      if (updateProfile.name != null) data['name'] = updateProfile.name;
      if (updateProfile.email != null) data['email'] = updateProfile.email;
      if (updateProfile.phone != null) data['phone'] = updateProfile.phone;
      if (updateProfile.address != null) {
        data['address'] = updateProfile.address;
      }

      final model = await remoteDataSource.updateProfile(data);
      await localDataSource.cacheProfile(model);
      return Right(model.toEntity());
    } on ValidationException catch (e) {
      return Left(ValidationFailure(message: e.firstError, errors: e.errors));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } catch (e) {
      AppLogger.error('ProfileRepository.updateProfile failed', error: e);
      return Left(ServerFailure(message: 'Une erreur inattendue est survenue.'));
    }
  }

  @override
  Future<Either<Failure, String>> uploadAvatar(Uint8List imageBytes) async {
    try {
      final url = await remoteDataSource.uploadAvatar(imageBytes);
      return Right(url);
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } catch (e) {
      AppLogger.error('ProfileRepository.uploadAvatar failed', error: e);
      return Left(ServerFailure(message: 'Une erreur inattendue est survenue.'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteAvatar() async {
    try {
      await remoteDataSource.deleteAvatar();
      return const Right(null);
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } catch (e) {
      AppLogger.error('ProfileRepository.deleteAvatar failed', error: e);
      return Left(ServerFailure(message: 'Une erreur inattendue est survenue.'));
    }
  }
}
