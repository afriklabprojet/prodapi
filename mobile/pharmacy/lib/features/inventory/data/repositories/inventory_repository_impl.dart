import 'package:dartz/dartz.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/entities/category_entity.dart';
import '../../domain/entities/product_entity.dart';
import '../../domain/repositories/inventory_repository.dart';
import '../datasources/inventory_remote_datasource.dart';

class InventoryRepositoryImpl implements InventoryRepository {
  final InventoryRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;

  InventoryRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, List<ProductEntity>>> getProducts() async {
    if (await networkInfo.isConnected) {
      try {
        final models = await remoteDataSource.getProducts();
        return Right(models.map((e) => e.toEntity()).toList());
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      } catch (e) {
        return Left(ServerFailure(e.toString()));
      }
    }
    return const Left(NetworkFailure('No internet connection'));
  }

  @override
  Future<Either<Failure, void>> updateStock(
    int productId,
    int newQuantity,
  ) async {
    if (await networkInfo.isConnected) {
      try {
        await remoteDataSource.updateStock(productId, newQuantity);
        return const Right(null);
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      } catch (e) {
        return Left(ServerFailure(e.toString()));
      }
    }
    return const Left(NetworkFailure('No internet connection'));
  }

  @override
  Future<Either<Failure, void>> updatePrice(
    int productId,
    double newPrice,
  ) async {
    if (await networkInfo.isConnected) {
      try {
        await remoteDataSource.updatePrice(productId, newPrice);
        return const Right(null);
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      } catch (e) {
        return Left(ServerFailure(e.toString()));
      }
    }
    return const Left(NetworkFailure('No internet connection'));
  }

  @override
  Future<Either<Failure, void>> toggleAvailability(int productId) async {
    if (await networkInfo.isConnected) {
      try {
        await remoteDataSource.toggleAvailability(productId);
        return const Right(null);
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      } catch (e) {
        return Left(ServerFailure(e.toString()));
      }
    }
    return const Left(NetworkFailure('No internet connection'));
  }

  @override
  Future<Either<Failure, ProductEntity>> addProduct(
    String name,
    String description,
    double price,
    int stockQuantity,
    String category,
    bool requiresPrescription, {
    String? barcode,
    XFile? image,
    String? brand,
    String? manufacturer,
    String? activeIngredient,
    String? unit,
    DateTime? expiryDate,
    String? usageInstructions,
    String? sideEffects,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final data = {
          'name': name,
          'description': description,
          'price': price,
          'stock_quantity': stockQuantity,
          'category_id': category, // Map String(ID) to category_id
          'requires_prescription': requiresPrescription,
        };

        if (barcode != null) data['barcode'] = barcode;
        if (brand != null) data['brand'] = brand;
        if (manufacturer != null) data['manufacturer'] = manufacturer;
        if (activeIngredient != null) data['active_ingredient'] = activeIngredient;
        if (unit != null) data['unit'] = unit;
        if (usageInstructions != null) data['usage_instructions'] = usageInstructions;
        if (sideEffects != null) data['side_effects'] = sideEffects;
        if (expiryDate != null) data['expiry_date'] = expiryDate.toIso8601String().split('T')[0];

        final productModel = await remoteDataSource.addProduct(data, image: image);
        return Right(productModel.toEntity());
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      } catch (e) {
        return Left(ServerFailure(e.toString()));
      }
    }
    return const Left(NetworkFailure('No internet connection'));
  }

  @override
  Future<Either<Failure, List<CategoryEntity>>> getCategories() async {
    if (await networkInfo.isConnected) {
      try {
        final models = await remoteDataSource.getCategories();
        return Right(models.map((m) => m.toEntity()).toList());
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      } catch (e) {
        return Left(ServerFailure(e.toString()));
      }
    }
    return const Left(NetworkFailure('No internet connection'));
  }

  @override
  Future<Either<Failure, CategoryEntity>> addCategory(
    String name,
    String? description,
  ) async {
    if (await networkInfo.isConnected) {
      try {
        final model = await remoteDataSource.addCategory(name, description);
        return Right(model.toEntity());
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      } catch (e) {
        return Left(ServerFailure(e.toString()));
      }
    }
    return const Left(NetworkFailure('No internet connection'));
  }

  @override
  Future<Either<Failure, CategoryEntity>> updateCategory(
    int id,
    String name,
    String? description,
  ) async {
    if (await networkInfo.isConnected) {
      try {
        final model = await remoteDataSource.updateCategory(id, name, description);
        return Right(model.toEntity());
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      } catch (e) {
        return Left(ServerFailure(e.toString()));
      }
    }
    return const Left(NetworkFailure('No internet connection'));
  }

  @override
  Future<Either<Failure, void>> deleteCategory(int id) async {
    if (await networkInfo.isConnected) {
      try {
        await remoteDataSource.deleteCategory(id);
        return const Right(null);
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      } catch (e) {
        return Left(ServerFailure(e.toString()));
      }
    }
    return const Left(NetworkFailure('No internet connection'));
  }

  @override
  Future<Either<Failure, ProductEntity>> updateProduct(
    int id,
    Map<String, dynamic> data, {
    XFile? image,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final productModel = await remoteDataSource.updateProduct(id, data, image: image);
        return Right(productModel.toEntity());
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      } catch (e) {
        return Left(ServerFailure(e.toString()));
      }
    }
    return const Left(NetworkFailure('No internet connection'));
  }

  @override
  Future<Either<Failure, void>> deleteProduct(int id) async {
    if (await networkInfo.isConnected) {
      try {
        await remoteDataSource.deleteProduct(id);
        return const Right(null);
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      } catch (e) {
        return Left(ServerFailure(e.toString()));
      }
    }
    return const Left(NetworkFailure('No internet connection'));
  }

  @override
  Future<Either<Failure, void>> applyPromotion(
    int productId,
    double discountPercentage, {
    DateTime? endDate,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        await remoteDataSource.applyPromotion(productId, discountPercentage, endDate: endDate);
        return const Right(null);
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      } catch (e) {
        return Left(ServerFailure(e.toString()));
      }
    }
    return const Left(NetworkFailure('No internet connection'));
  }

  @override
  Future<Either<Failure, void>> removePromotion(int productId) async {
    if (await networkInfo.isConnected) {
      try {
        await remoteDataSource.removePromotion(productId);
        return const Right(null);
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      } catch (e) {
        return Left(ServerFailure(e.toString()));
      }
    }
    return const Left(NetworkFailure('No internet connection'));
  }

  @override
  Future<Either<Failure, void>> markAsLoss(
    int productId,
    int quantity,
    String reason,
  ) async {
    if (await networkInfo.isConnected) {
      try {
        await remoteDataSource.markAsLoss(productId, quantity, reason);
        return const Right(null);
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      } catch (e) {
        return Left(ServerFailure(e.toString()));
      }
    }
    return const Left(NetworkFailure('No internet connection'));
  }
}
