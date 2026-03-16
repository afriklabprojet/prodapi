import 'package:dartz/dartz.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/services/app_logger.dart';
import '../../domain/entities/order_entity.dart';
import '../../domain/entities/order_item_entity.dart';
import '../../domain/entities/delivery_address_entity.dart';
import '../../domain/repositories/orders_repository.dart';
import '../datasources/orders_remote_datasource.dart';
import '../datasources/orders_local_datasource.dart';
import '../models/order_item_model.dart';
import '../models/delivery_address_model.dart';

class OrdersRepositoryImpl implements OrdersRepository {
  final OrdersRemoteDataSource remoteDataSource;
  final OrdersLocalDataSource localDataSource;

  OrdersRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
  });

  @override
  Future<Either<Failure, List<OrderEntity>>> getOrders({
    String? status,
    int page = 1,
    int perPage = 20,
  }) async {
    try {
      final orders = await remoteDataSource.getOrders(
        status: status,
        page: page,
        perPage: perPage,
      );

      // Cache only first page without status filter
      if (page == 1 && status == null) {
        await localDataSource.cacheOrders(orders);
      }

      return Right(orders.map((model) => model.toEntity()).toList());
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } on UnauthorizedException catch (e) {
      return Left(UnauthorizedFailure(message: e.message));
    } on NetworkException catch (e) {
      // Try to return cached data on network error
      final cachedOrders = localDataSource.getCachedOrders();
      if (cachedOrders != null && page == 1 && status == null) {
        return Right(cachedOrders.map((model) => model.toEntity()).toList());
      }
      return Left(NetworkFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: 'An unexpected error occurred'));
    }
  }

  @override
  Future<Either<Failure, OrderEntity>> getOrderDetails(int orderId) async {
    try {
      final order = await remoteDataSource.getOrderDetails(orderId);

      // Cache individual order
      await localDataSource.cacheOrder(order);

      return Right(order.toEntity());
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } on UnauthorizedException catch (e) {
      return Left(UnauthorizedFailure(message: e.message));
    } on NetworkException catch (e) {
      // Try to return cached order on network error
      final cachedOrder = localDataSource.getCachedOrder(orderId);
      if (cachedOrder != null) {
        return Right(cachedOrder.toEntity());
      }
      return Left(NetworkFailure(message: e.message));
    } catch (e, stackTrace) {
      AppLogger.error('[OrdersRepository] GetOrderDetails unexpected error', error: e, stackTrace: stackTrace);
      return Left(ServerFailure(message: 'An unexpected error occurred: $e'));
    }
  }

  @override
  Future<Either<Failure, OrderEntity>> createOrder({
    required int pharmacyId,
    required List<OrderItemEntity> items,
    required DeliveryAddressEntity deliveryAddress,
    required String paymentMode,
    String? prescriptionImage,
    String? customerNotes,
    int? prescriptionId,
  }) async {
    try {
      final itemModels = items
          .map((item) => OrderItemModel.fromEntity(item))
          .toList();

      final addressModel = DeliveryAddressModel.fromEntity(deliveryAddress);

      final order = await remoteDataSource.createOrder(
        pharmacyId: pharmacyId,
        items: itemModels,
        deliveryAddress: addressModel.toJson(),
        paymentMode: paymentMode,
        prescriptionImage: prescriptionImage,
        customerNotes: customerNotes,
        prescriptionId: prescriptionId,
      );

      // Cache the created order
      await localDataSource.cacheOrder(order);

      return Right(order.toEntity());
    } on ValidationException catch (e) {
      String msg = 'Erreur de validation';
      if (e.errors.isNotEmpty) {
        msg = e.errors.values.expand((element) => element).join('\n');
      }
      return Left(ValidationFailure(message: msg, errors: e.errors));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } on UnauthorizedException catch (e) {
      return Left(UnauthorizedFailure(message: e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } catch (e, stackTrace) {
      AppLogger.error('[OrdersRepository] CreateOrder unexpected error', error: e, stackTrace: stackTrace);
      return Left(ServerFailure(message: 'An unexpected error occurred: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> cancelOrder(int orderId, String reason) async {
    try {
      await remoteDataSource.cancelOrder(orderId, reason);

      // Clear cache to force refresh
      await localDataSource.clearCache();

      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } on UnauthorizedException catch (e) {
      return Left(UnauthorizedFailure(message: e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: 'An unexpected error occurred'));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> initiatePayment({
    required int orderId,
    required String provider,
    String? paymentMethod,
  }) async {
    try {
      final result = await remoteDataSource.initiatePayment(
        orderId: orderId,
        provider: provider,
        paymentMethod: paymentMethod,
      );

      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } on UnauthorizedException catch (e) {
      return Left(UnauthorizedFailure(message: e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: 'An unexpected error occurred'));
    }
  }

  @override
  Future<Map<String, dynamic>?> getTrackingInfo(int orderId) async {
    try {
      return await remoteDataSource.getTrackingInfo(orderId);
    } catch (e) {
      return null;
    }
  }
}
