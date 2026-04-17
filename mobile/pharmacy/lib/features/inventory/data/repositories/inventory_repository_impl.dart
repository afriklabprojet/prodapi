import 'package:dartz/dartz.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/network/network_info.dart';
import '../../../../core/services/cache_service.dart';
import '../../../../core/services/offline_storage_service.dart';
import '../../domain/entities/category_entity.dart';
import '../../domain/entities/product_entity.dart';
import '../../domain/entities/product_batch_entity.dart';
import '../../domain/repositories/inventory_repository.dart';
import '../datasources/inventory_remote_datasource.dart';
import '../models/product_model.dart';
import '../models/category_model.dart';

/// Implémentation du repository d'inventaire avec support offline.
class InventoryRepositoryImpl implements InventoryRepository {
  final InventoryRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;
  final CacheService cacheService;
  final OfflineStorageService offlineStorage;

  InventoryRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
    required this.cacheService,
    required this.offlineStorage,
  });

  // ============================================================
  // HELPERS
  // ============================================================

  static const _networkError = NetworkFailure('Pas de connexion internet');

  /// Exécute une action avec vérification réseau.
  Future<Either<Failure, T>> _withNetwork<T>(
    Future<T> Function() action, {
    Either<Failure, T>? offlineFallback,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        return Right(await action());
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      } catch (e) {
        return Left(ServerFailure(e.toString()));
      }
    }
    return offlineFallback ?? const Left(_networkError);
  }

  /// Exécute une action void avec vérification réseau.
  Future<Either<Failure, void>> _withNetworkVoid(
    Future<void> Function() action, {
    PendingAction? Function()? offlineAction,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        await action();
        return const Right(null);
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      } catch (e) {
        return Left(ServerFailure(e.toString()));
      }
    }
    // Queue offline action if provided
    final pending = offlineAction?.call();
    if (pending != null) {
      await offlineStorage.queueAction(pending);
      return const Right(null);
    }
    return const Left(_networkError);
  }

  /// Crée un PendingAction pour une opération offline.
  PendingAction _createPendingAction(
    String actionName,
    int productId,
    Map<String, dynamic> data,
  ) {
    return PendingAction(
      id: '${actionName}_${productId}_${DateTime.now().millisecondsSinceEpoch}',
      type: ActionType.update,
      collection: 'products',
      entityId: productId.toString(),
      data: {'action': actionName, 'productId': productId, ...data},
      createdAt: DateTime.now(),
    );
  }

  // ============================================================
  // PRODUCTS
  // ============================================================

  @override
  Future<Either<Failure, List<ProductEntity>>> getProducts() async {
    return _withNetwork(() async {
      final models = await remoteDataSource.getProducts();
      await cacheService.setData(
        key: CacheKeys.inventory,
        data: models.map((e) => e.toJson()).toList(),
        expiration: CacheService.shortCacheDuration,
      );
      return models.map((e) => e.toEntity()).toList();
    }, offlineFallback: _getCachedProducts());
  }

  Either<Failure, List<ProductEntity>>? _getCachedProducts() {
    final cached = cacheService.getData<List<dynamic>>(
      key: CacheKeys.inventory,
    );
    if (cached != null) {
      final entities = cached
          .map(
            (json) =>
                ProductModel.fromJson(json as Map<String, dynamic>).toEntity(),
          )
          .toList();
      return Right(entities);
    }
    return null;
  }

  @override
  Future<Either<Failure, void>> updateStock(int productId, int newQuantity) =>
      _withNetworkVoid(
        () => remoteDataSource.updateStock(productId, newQuantity),
        offlineAction: () => _createPendingAction('update_stock', productId, {
          'quantity': newQuantity,
        }),
      );

  @override
  Future<Either<Failure, void>> updatePrice(int productId, double newPrice) =>
      _withNetworkVoid(
        () => remoteDataSource.updatePrice(productId, newPrice),
        offlineAction: () => _createPendingAction('update_price', productId, {
          'price': newPrice,
        }),
      );

  @override
  Future<Either<Failure, void>> toggleAvailability(int productId) =>
      _withNetworkVoid(() => remoteDataSource.toggleAvailability(productId));

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
  }) {
    final data = <String, dynamic>{
      'name': name,
      'description': description,
      'price': price,
      'stock_quantity': stockQuantity,
      'category_id': category,
      'requires_prescription': requiresPrescription,
      if (barcode != null) 'barcode': barcode,
      if (brand != null) 'brand': brand,
      if (manufacturer != null) 'manufacturer': manufacturer,
      if (activeIngredient != null) 'active_ingredient': activeIngredient,
      if (unit != null) 'unit': unit,
      if (usageInstructions != null) 'usage_instructions': usageInstructions,
      if (sideEffects != null) 'side_effects': sideEffects,
      if (expiryDate != null)
        'expiry_date': expiryDate.toIso8601String().split('T')[0],
    };

    return _withNetwork(
      () async =>
          (await remoteDataSource.addProduct(data, image: image)).toEntity(),
    );
  }

  // ============================================================
  // CATEGORIES
  // ============================================================

  @override
  Future<Either<Failure, List<CategoryEntity>>> getCategories() async {
    return _withNetwork(() async {
      final models = await remoteDataSource.getCategories();
      await cacheService.setData(
        key: CacheKeys.categories,
        data: models.map((m) => m.toJson()).toList(),
        expiration: CacheService.longCacheDuration,
      );
      return models.map((m) => m.toEntity()).toList();
    }, offlineFallback: _getCachedCategories());
  }

  Either<Failure, List<CategoryEntity>>? _getCachedCategories() {
    final cached = cacheService.getData<List<dynamic>>(
      key: CacheKeys.categories,
    );
    if (cached != null) {
      final entities = cached
          .map(
            (json) =>
                CategoryModel.fromJson(json as Map<String, dynamic>).toEntity(),
          )
          .toList();
      return Right(entities);
    }
    return null;
  }

  @override
  Future<Either<Failure, CategoryEntity>> addCategory(
    String name,
    String? description,
  ) => _withNetwork(
    () async =>
        (await remoteDataSource.addCategory(name, description)).toEntity(),
  );

  @override
  Future<Either<Failure, CategoryEntity>> updateCategory(
    int id,
    String name,
    String? description,
  ) => _withNetwork(
    () async => (await remoteDataSource.updateCategory(
      id,
      name,
      description,
    )).toEntity(),
  );

  @override
  Future<Either<Failure, void>> deleteCategory(int id) =>
      _withNetworkVoid(() => remoteDataSource.deleteCategory(id));

  @override
  Future<Either<Failure, ProductEntity>> updateProduct(
    int id,
    Map<String, dynamic> data, {
    XFile? image,
  }) => _withNetwork(
    () async => (await remoteDataSource.updateProduct(
      id,
      data,
      image: image,
    )).toEntity(),
  );

  @override
  Future<Either<Failure, void>> deleteProduct(int id) =>
      _withNetworkVoid(() => remoteDataSource.deleteProduct(id));

  // ============================================================
  // PROMOTIONS
  // ============================================================

  @override
  Future<Either<Failure, void>> applyPromotion(
    int productId,
    double discountPercentage, {
    DateTime? endDate,
  }) => _withNetworkVoid(
    () => remoteDataSource.applyPromotion(
      productId,
      discountPercentage,
      endDate: endDate,
    ),
  );

  @override
  Future<Either<Failure, void>> removePromotion(int productId) =>
      _withNetworkVoid(() => remoteDataSource.removePromotion(productId));

  @override
  Future<Either<Failure, void>> markAsLoss(
    int productId,
    int quantity,
    String reason,
  ) => _withNetworkVoid(
    () => remoteDataSource.markAsLoss(productId, quantity, reason),
  );

  // ============================================================
  // BATCHES
  // ============================================================

  @override
  Future<Either<Failure, List<ProductBatchEntity>>> getProductBatches({
    int? productId,
  }) => _withNetwork(() async {
    final models = await remoteDataSource.getProductBatches(
      productId: productId,
    );
    return models.map((m) => m.toEntity()).toList();
  });

  @override
  Future<Either<Failure, ProductBatchEntity>> addBatch({
    required int productId,
    required String batchNumber,
    String? lotNumber,
    required DateTime expiryDate,
    required int quantity,
    String? supplier,
  }) => _withNetwork(() async {
    final model = await remoteDataSource.addBatch({
      'product_id': productId,
      'batch_number': batchNumber,
      if (lotNumber != null) 'lot_number': lotNumber,
      'expiry_date': expiryDate.toIso8601String().split('T')[0],
      'quantity': quantity,
      if (supplier != null) 'supplier': supplier,
    });
    return model.toEntity();
  });

  @override
  Future<Either<Failure, void>> deleteBatch(int batchId) =>
      _withNetworkVoid(() => remoteDataSource.deleteBatch(batchId));
}
