import 'package:dartz/dartz.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/services/app_logger.dart';
import '../../domain/entities/product_entity.dart';
import '../../domain/repositories/products_repository.dart';
import '../datasources/products_local_datasource.dart';
import '../datasources/products_remote_datasource.dart';

class ProductsRepositoryImpl implements ProductsRepository {
  final ProductsRemoteDataSource remoteDataSource;
  final ProductsLocalDataSource localDataSource;

  ProductsRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
  });

  @override
  Future<Either<Failure, List<ProductEntity>>> getProducts({
    int page = 1,
    int perPage = 20,
  }) async {
    try {
      final models = await remoteDataSource.getProducts(
        page: page,
        perPage: perPage,
      );
      // Cache uniquement la première page
      if (page == 1) {
        await localDataSource.cacheProducts(models);
      }
      return Right(models.map((m) => m.toEntity()).toList());
    } on NetworkException catch (e) {
      if (page == 1) {
        final cached = await localDataSource.getCachedProducts();
        if (cached != null) {
          return Right(cached.map((m) => m.toEntity()).toList());
        }
      }
      return Left(NetworkFailure(message: e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } catch (e) {
      AppLogger.error('ProductsRepository.getProducts failed', error: e);
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, ProductEntity>> getProductDetails(
    int productId,
  ) async {
    try {
      final model = await remoteDataSource.getProductDetails(productId);
      await localDataSource.cacheProductDetails(model);
      return Right(model.toEntity());
    } on NetworkException catch (e) {
      final cached = await localDataSource.getCachedProductDetails(productId);
      if (cached != null) {
        return Right(cached.toEntity());
      }
      return Left(NetworkFailure(message: e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } catch (e) {
      AppLogger.error('ProductsRepository.getProductDetails failed', error: e);
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<ProductEntity>>> searchProducts({
    required String query,
    int page = 1,
    int perPage = 20,
  }) async {
    try {
      final models = await remoteDataSource.searchProducts(
        query: query,
        page: page,
        perPage: perPage,
      );
      return Right(models.map((m) => m.toEntity()).toList());
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } catch (e) {
      AppLogger.error('ProductsRepository.searchProducts failed', error: e);
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<ProductEntity>>> getProductsByCategory({
    required String category,
    int page = 1,
    int perPage = 20,
  }) async {
    try {
      final models = await remoteDataSource.getProductsByCategory(
        category: category,
        page: page,
        perPage: perPage,
      );
      return Right(models.map((m) => m.toEntity()).toList());
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } catch (e) {
      AppLogger.error(
        'ProductsRepository.getProductsByCategory failed',
        error: e,
      );
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<ProductEntity>>> getProductsByPharmacy({
    required int pharmacyId,
    int page = 1,
    int perPage = 20,
  }) async {
    try {
      final models = await remoteDataSource.getProductsByPharmacy(
        pharmacyId: pharmacyId,
        page: page,
        perPage: perPage,
      );
      return Right(models.map((m) => m.toEntity()).toList());
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } catch (e) {
      AppLogger.error(
        'ProductsRepository.getProductsByPharmacy failed',
        error: e,
      );
      return Left(ServerFailure(message: e.toString()));
    }
  }
}
