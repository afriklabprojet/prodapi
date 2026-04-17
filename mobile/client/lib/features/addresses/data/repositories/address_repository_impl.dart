import 'package:dartz/dartz.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/services/app_logger.dart';
import '../../domain/entities/address_entity.dart';
import '../../domain/repositories/address_repository.dart';
import '../datasources/address_remote_datasource.dart';

class AddressRepositoryImpl implements AddressRepository {
  final AddressRemoteDataSource remoteDataSource;

  AddressRepositoryImpl(this.remoteDataSource);

  @override
  Future<Either<Failure, List<AddressEntity>>> getAddresses() async {
    try {
      final models = await remoteDataSource.getAddresses();
      return Right(models.map((m) => m.toEntity()).toList());
    } on UnauthorizedException catch (e) {
      return Left(UnauthorizedFailure(message: e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } catch (e) {
      AppLogger.error('AddressRepository.getAddresses failed', error: e);
      return Left(ServerFailure(message: 'Impossible de charger les adresses.'));
    }
  }

  @override
  Future<Either<Failure, AddressEntity>> getAddress(int id) async {
    try {
      final model = await remoteDataSource.getAddress(id);
      return Right(model.toEntity());
    } on UnauthorizedException catch (e) {
      return Left(UnauthorizedFailure(message: e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } catch (e) {
      AppLogger.error('AddressRepository.getAddress failed', error: e);
      return Left(ServerFailure(message: 'Impossible de charger l\'adresse.'));
    }
  }

  @override
  Future<Either<Failure, AddressEntity>> getDefaultAddress() async {
    try {
      final model = await remoteDataSource.getDefaultAddress();
      return Right(model.toEntity());
    } on UnauthorizedException catch (e) {
      return Left(UnauthorizedFailure(message: e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } catch (e) {
      AppLogger.error('AddressRepository.getDefaultAddress failed', error: e);
      return Left(ServerFailure(message: 'Impossible de charger l\'adresse par défaut.'));
    }
  }

  @override
  Future<Either<Failure, AddressEntity>> createAddress({
    required String label,
    required String address,
    String? city,
    String? district,
    String? phone,
    String? instructions,
    double? latitude,
    double? longitude,
    bool isDefault = false,
  }) async {
    try {
      final model = await remoteDataSource.createAddress(
        label: label,
        address: address,
        city: city,
        district: district,
        phone: phone,
        instructions: instructions,
        latitude: latitude,
        longitude: longitude,
        isDefault: isDefault,
      );
      return Right(model.toEntity());
    } on UnauthorizedException catch (e) {
      return Left(UnauthorizedFailure(message: e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } catch (e) {
      AppLogger.error('AddressRepository.createAddress failed', error: e);
      return Left(ServerFailure(message: 'Impossible d\'ajouter l\'adresse.'));
    }
  }

  @override
  Future<Either<Failure, AddressEntity>> updateAddress({
    required int id,
    String? label,
    String? address,
    String? city,
    String? district,
    String? phone,
    String? instructions,
    double? latitude,
    double? longitude,
    bool? isDefault,
  }) async {
    try {
      final model = await remoteDataSource.updateAddress(
        id: id,
        label: label,
        address: address,
        city: city,
        district: district,
        phone: phone,
        instructions: instructions,
        latitude: latitude,
        longitude: longitude,
        isDefault: isDefault,
      );
      return Right(model.toEntity());
    } on UnauthorizedException catch (e) {
      return Left(UnauthorizedFailure(message: e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } catch (e) {
      AppLogger.error('AddressRepository.updateAddress failed', error: e);
      return Left(ServerFailure(message: 'Impossible de modifier l\'adresse.'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteAddress(int id) async {
    try {
      await remoteDataSource.deleteAddress(id);
      return const Right(null);
    } on UnauthorizedException catch (e) {
      return Left(UnauthorizedFailure(message: e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } catch (e) {
      AppLogger.error('AddressRepository.deleteAddress failed', error: e);
      return Left(ServerFailure(message: 'Impossible de supprimer l\'adresse.'));
    }
  }

  @override
  Future<Either<Failure, AddressEntity>> setDefaultAddress(int id) async {
    try {
      final model = await remoteDataSource.setDefaultAddress(id);
      return Right(model.toEntity());
    } on UnauthorizedException catch (e) {
      return Left(UnauthorizedFailure(message: e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } catch (e) {
      AppLogger.error('AddressRepository.setDefaultAddress failed', error: e);
      return Left(ServerFailure(message: 'Une erreur est survenue.'));
    }
  }

  @override
  Future<Either<Failure, AddressFormData>> getLabels() async {
    try {
      final data = await remoteDataSource.getLabels();
      return Right(data);
    } on UnauthorizedException catch (e) {
      return Left(UnauthorizedFailure(message: e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } catch (e) {
      AppLogger.error('AddressRepository.getLabels failed', error: e);
      return Left(ServerFailure(message: 'Une erreur est survenue.'));
    }
  }
}
