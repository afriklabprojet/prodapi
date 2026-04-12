import 'package:dartz/dartz.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/services/cache_service.dart';
import '../../../../core/services/offline_storage_service.dart';
import '../../domain/entities/order_entity.dart';
import '../../domain/repositories/order_repository.dart';
import '../datasources/order_remote_datasource.dart';
import '../models/order_model.dart';
import '../../../../core/constants/app_constants.dart';

/// Implémentation du repository des commandes avec support offline.
class OrderRepositoryImpl implements OrderRepository {
  final OrderRemoteDataSource remoteDataSource;
  final CacheService cacheService;
  final OfflineStorageService offlineStorage;

  OrderRepositoryImpl({
    required this.remoteDataSource,
    required this.cacheService,
    required this.offlineStorage,
  });

  // ============================================================
  // HELPERS
  // ============================================================

  /// Exécute une action avec support offline optionnel.
  /// Si `offlineAction` est fourni, l'action est mise en queue hors ligne.
  Future<Either<Failure, void>> _executeAction(
    Future<void> Function() action, {
    PendingAction? Function()? offlineAction,
  }) async {
    try {
      await action();
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException {
      final pending = offlineAction?.call();
      if (pending != null) {
        await offlineStorage.queueAction(pending);
        return const Right(null);
      }
      return Left(NetworkFailure('Pas de connexion internet'));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  /// Crée un PendingAction pour une action sur commande.
  PendingAction _createPendingAction(
    String actionName,
    int orderId, {
    Map<String, dynamic>? extraData,
  }) {
    return PendingAction(
      id: '${actionName}_${orderId}_${DateTime.now().millisecondsSinceEpoch}',
      type: ActionType.update,
      collection: 'orders',
      entityId: orderId.toString(),
      data: {'action': actionName, 'orderId': orderId, ...?extraData},
      createdAt: DateTime.now(),
    );
  }

  // ============================================================
  // READ OPERATIONS
  // ============================================================

  @override
  Future<Either<Failure, PaginatedOrdersResult>> getOrders({
    String? status,
    String? cursor,
    int perPage = 20,
  }) async {
    final cacheKey = status != null
        ? '${CacheKeys.orders}_${status}_${cursor ?? 'first'}'
        : '${CacheKeys.orders}_${cursor ?? 'first'}';
    try {
      final response = await remoteDataSource.getOrders(
        status: status,
        cursor: cursor,
        perPage: perPage,
      );

      // Masquer les commandes en attente de paiement trop anciennes
      final now = DateTime.now();
      final filteredOrders = response.orders.map((m) => m.toEntity()).where((
        order,
      ) {
        if (order.isPendingUnpaid) {
          final age = now.difference(order.createdAt);
          return age < AppConstants.pendingUnpaidOrderTimeout;
        }
        return true;
      }).toList();

      // Cache the result for offline fallback (première page seulement)
      if (cursor == null) {
        await cacheService.setData(
          key: cacheKey,
          data: response.orders.map((m) => m.toJson()).toList(),
          expiration: CacheService.shortCacheDuration,
        );
      }

      return Right(
        PaginatedOrdersResult(
          orders: filteredOrders,
          nextCursor: response.nextCursor,
          perPage: response.perPage,
          total: response.total,
        ),
      );
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException {
      // Fallback: return cached data if available (first page only)
      if (cursor == null) {
        final cached = cacheService.getData<List<dynamic>>(key: cacheKey);
        if (cached != null) {
          final entities = cached
              .map(
                (json) => OrderModel.fromJson(
                  json as Map<String, dynamic>,
                ).toEntity(),
              )
              .toList();
          return Right(
            PaginatedOrdersResult(
              orders: entities,
              nextCursor: null, // Pas de pagination en mode hors ligne
              perPage: perPage,
              total: entities.length,
            ),
          );
        }
      }
      return Left(NetworkFailure('Pas de connexion internet'));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, OrderEntity>> getOrderDetails(int orderId) async {
    try {
      final model = await remoteDataSource.getOrderDetails(orderId);
      return Right(model.toEntity());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException {
      return Left(NetworkFailure('Pas de connexion internet'));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  // ============================================================
  // WRITE OPERATIONS (avec support offline)
  // ============================================================

  @override
  Future<Either<Failure, void>> confirmOrder(int orderId) => _executeAction(
    () => remoteDataSource.confirmOrder(orderId),
    offlineAction: () => _createPendingAction('confirm', orderId),
  );

  @override
  Future<Either<Failure, void>> markOrderReady(int orderId) => _executeAction(
    () => remoteDataSource.markOrderReady(orderId),
    offlineAction: () => _createPendingAction('mark_ready', orderId),
  );

  @override
  Future<Either<Failure, void>> markOrderDelivered(
    int orderId,
  ) => _executeAction(
    () => remoteDataSource.markOrderDelivered(orderId),
    // Pas de support offline pour delivered (besoin de confirmation immédiate)
  );

  @override
  Future<Either<Failure, void>> rejectOrder(int orderId, {String? reason}) =>
      _executeAction(
        () => remoteDataSource.rejectOrder(orderId, reason: reason),
        offlineAction: () => _createPendingAction(
          'reject',
          orderId,
          extraData: {'reason': reason},
        ),
      );

  @override
  Future<Either<Failure, void>> addNotes(int orderId, String notes) =>
      _executeAction(
        () => remoteDataSource.addNotes(orderId, notes),
        // Pas de support offline pour notes
      );
}
