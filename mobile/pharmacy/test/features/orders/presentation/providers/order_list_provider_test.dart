import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dartz/dartz.dart';
import 'package:drpharma_pharmacy/features/orders/presentation/providers/order_list_provider.dart';
import 'package:drpharma_pharmacy/features/orders/presentation/providers/order_di_providers.dart';
import 'package:drpharma_pharmacy/features/orders/presentation/providers/state/order_list_state.dart';
import 'package:drpharma_pharmacy/features/orders/domain/enums/order_status.dart';
import 'package:drpharma_pharmacy/features/orders/domain/repositories/order_repository.dart';
import 'package:drpharma_pharmacy/features/orders/domain/entities/order_entity.dart';
import 'package:drpharma_pharmacy/core/errors/failure.dart';
import '../../../../test_helpers.dart';

// Mock classes
class MockOrderRepository extends Mock implements OrderRepository {}

PaginatedOrdersResult _emptyResult() =>
    PaginatedOrdersResult(orders: [], nextCursor: null, perPage: 20, total: 0);

PaginatedOrdersResult _resultFrom(
  List<OrderEntity> orders, {
  String? nextCursor,
}) => PaginatedOrdersResult(
  orders: orders,
  nextCursor: nextCursor,
  perPage: 20,
  total: orders.length,
);

void main() {
  late MockOrderRepository mockRepository;
  late ProviderContainer container;

  setUp(() {
    mockRepository = MockOrderRepository();
    // Stub fetchOrders for build() call
    when(
      () => mockRepository.getOrders(
        status: any(named: 'status'),
        cursor: any(named: 'cursor'),
      ),
    ).thenAnswer((_) async => Right(_emptyResult()));
    container = ProviderContainer(
      overrides: [orderRepositoryProvider.overrideWithValue(mockRepository)],
    );
  });

  tearDown(() {
    container.dispose();
  });

  group('OrderListNotifier initial state', () {
    test('should have initial state with pending filter', () async {
      // Trigger build by reading the provider
      container.read(orderListProvider);
      await Future.delayed(const Duration(milliseconds: 50));

      expect(
        container.read(orderListProvider).activeFilter,
        OrderStatusFilter.pending,
      );
    });

    test('should fetch orders on creation', () async {
      container.read(orderListProvider);
      await Future.delayed(const Duration(milliseconds: 50));

      verify(
        () => mockRepository.getOrders(
          status: 'pending',
          cursor: any(named: 'cursor'),
        ),
      ).called(1);
    });
  });

  group('OrderListNotifier fetchOrders', () {
    test('should set loaded state with orders on success', () async {
      final orders = TestDataFactory.createOrderList(count: 5);

      when(
        () => mockRepository.getOrders(
          status: any(named: 'status'),
          cursor: any(named: 'cursor'),
        ),
      ).thenAnswer((_) async => Right(_resultFrom(orders)));

      container.read(orderListProvider);
      await container.read(orderListProvider.notifier).fetchOrders();

      expect(container.read(orderListProvider).status, OrderLoadStatus.loaded);
      expect(container.read(orderListProvider).orders.length, 5);
    });

    test('should set error state on failure', () async {
      when(
        () => mockRepository.getOrders(
          status: any(named: 'status'),
          cursor: any(named: 'cursor'),
        ),
      ).thenAnswer((_) async => Left(ServerFailure('Server error')));

      container.read(orderListProvider);
      await container.read(orderListProvider.notifier).fetchOrders();

      expect(container.read(orderListProvider).status, OrderLoadStatus.error);
      expect(container.read(orderListProvider).errorMessage, 'Server error');
    });

    test('should update filter when filter is provided', () async {
      final orders = TestDataFactory.createOrderList(count: 2);

      when(
        () => mockRepository.getOrders(
          status: any(named: 'status'),
          cursor: any(named: 'cursor'),
        ),
      ).thenAnswer((_) async => Right(_resultFrom(orders)));

      container.read(orderListProvider);
      await container
          .read(orderListProvider.notifier)
          .fetchOrders(filter: OrderStatusFilter.confirmed);

      expect(
        container.read(orderListProvider).activeFilter,
        OrderStatusFilter.confirmed,
      );
    });

    test('should handle network failure', () async {
      when(
        () => mockRepository.getOrders(
          status: any(named: 'status'),
          cursor: any(named: 'cursor'),
        ),
      ).thenAnswer((_) async => Left(NetworkFailure('No internet')));

      container.read(orderListProvider);
      await container.read(orderListProvider.notifier).fetchOrders();

      expect(container.read(orderListProvider).status, OrderLoadStatus.error);
      expect(container.read(orderListProvider).errorMessage, 'No internet');
    });
  });

  group('OrderListNotifier setFilter', () {
    test('should fetch orders with new filter', () async {
      final orders = TestDataFactory.createOrderList(count: 2);

      when(
        () => mockRepository.getOrders(
          status: any(named: 'status'),
          cursor: any(named: 'cursor'),
        ),
      ).thenAnswer((_) async => Right(_resultFrom(orders)));

      // Initialize the provider
      final notifier = container.read(orderListProvider.notifier);
      await notifier.fetchOrders();

      clearInteractions(mockRepository);

      // Change filter
      notifier.setFilter(OrderStatusFilter.ready);
      await Future.delayed(const Duration(milliseconds: 50));

      verify(
        () => mockRepository.getOrders(
          status: 'ready',
          cursor: any(named: 'cursor'),
        ),
      ).called(1);
    });

    test('should not fetch if filter is same', () async {
      when(
        () => mockRepository.getOrders(
          status: any(named: 'status'),
          cursor: any(named: 'cursor'),
        ),
      ).thenAnswer((_) async => Right(_emptyResult()));

      container.read(orderListProvider);
      await Future.delayed(const Duration(milliseconds: 50));

      container
          .read(orderListProvider.notifier)
          .setFilter(OrderStatusFilter.pending); // Same filter
      await Future.delayed(const Duration(milliseconds: 50));

      expect(
        container.read(orderListProvider).activeFilter,
        OrderStatusFilter.pending,
      );
    });
  });

  group('OrderListNotifier confirmOrder', () {
    test('should call repository confirmOrder and refresh list', () async {
      when(
        () => mockRepository.getOrders(
          status: any(named: 'status'),
          cursor: any(named: 'cursor'),
        ),
      ).thenAnswer((_) async => Right(_emptyResult()));
      when(
        () => mockRepository.confirmOrder(any()),
      ).thenAnswer((_) async => const Right(null));

      container.read(orderListProvider);
      await Future.delayed(const Duration(milliseconds: 50));
      await container.read(orderListProvider.notifier).confirmOrder(1);

      verify(() => mockRepository.confirmOrder(1)).called(1);
    });

    test('should return false and set error on confirm failure', () async {
      when(
        () => mockRepository.getOrders(
          status: any(named: 'status'),
          cursor: any(named: 'cursor'),
        ),
      ).thenAnswer((_) async => Right(_emptyResult()));
      when(
        () => mockRepository.confirmOrder(any()),
      ).thenAnswer((_) async => Left(ServerFailure('Cannot confirm')));

      container.read(orderListProvider);
      await Future.delayed(const Duration(milliseconds: 50));

      final result = await container
          .read(orderListProvider.notifier)
          .confirmOrder(1);
      expect(result, isFalse);
      expect(container.read(orderListProvider).errorMessage, 'Cannot confirm');
    });
  });

  group('OrderListNotifier markOrderReady', () {
    test('should call repository markOrderReady and refresh list', () async {
      when(
        () => mockRepository.getOrders(
          status: any(named: 'status'),
          cursor: any(named: 'cursor'),
        ),
      ).thenAnswer((_) async => Right(_emptyResult()));
      when(
        () => mockRepository.markOrderReady(any()),
      ).thenAnswer((_) async => const Right(null));

      container.read(orderListProvider);
      await Future.delayed(const Duration(milliseconds: 50));
      await container.read(orderListProvider.notifier).markOrderReady(2);

      verify(() => mockRepository.markOrderReady(2)).called(1);
    });

    test('should return false and set error on markReady failure', () async {
      when(
        () => mockRepository.getOrders(
          status: any(named: 'status'),
          cursor: any(named: 'cursor'),
        ),
      ).thenAnswer((_) async => Right(_emptyResult()));
      when(
        () => mockRepository.markOrderReady(any()),
      ).thenAnswer((_) async => Left(ServerFailure('Cannot mark ready')));

      container.read(orderListProvider);
      await Future.delayed(const Duration(milliseconds: 50));

      final result = await container
          .read(orderListProvider.notifier)
          .markOrderReady(2);
      expect(result, isFalse);
      expect(
        container.read(orderListProvider).errorMessage,
        'Cannot mark ready',
      );
    });
  });

  group('OrderListNotifier rejectOrder', () {
    test('should call repository rejectOrder and refresh list', () async {
      when(
        () => mockRepository.getOrders(
          status: any(named: 'status'),
          cursor: any(named: 'cursor'),
        ),
      ).thenAnswer((_) async => Right(_emptyResult()));
      when(
        () => mockRepository.rejectOrder(any(), reason: any(named: 'reason')),
      ).thenAnswer((_) async => const Right(null));

      container.read(orderListProvider);
      await Future.delayed(const Duration(milliseconds: 50));
      await container
          .read(orderListProvider.notifier)
          .rejectOrder(3, reason: 'Out of stock');

      verify(
        () => mockRepository.rejectOrder(3, reason: 'Out of stock'),
      ).called(1);
    });

    test('should return false and set error on reject failure', () async {
      when(
        () => mockRepository.getOrders(
          status: any(named: 'status'),
          cursor: any(named: 'cursor'),
        ),
      ).thenAnswer((_) async => Right(_emptyResult()));
      when(
        () => mockRepository.rejectOrder(any(), reason: any(named: 'reason')),
      ).thenAnswer((_) async => Left(ServerFailure('Cannot reject')));

      container.read(orderListProvider);
      await Future.delayed(const Duration(milliseconds: 50));

      final result = await container
          .read(orderListProvider.notifier)
          .rejectOrder(3);
      expect(result, isFalse);
      expect(container.read(orderListProvider).errorMessage, 'Cannot reject');
    });
  });

  group('OrderListNotifier updateOrderStatus', () {
    setUp(() {
      when(
        () => mockRepository.getOrders(
          status: any(named: 'status'),
          cursor: any(named: 'cursor'),
        ),
      ).thenAnswer((_) async => Right(_emptyResult()));
    });

    test('should call markOrderReady for ready status', () async {
      when(
        () => mockRepository.markOrderReady(any()),
      ).thenAnswer((_) async => const Right(null));

      container.read(orderListProvider);
      await Future.delayed(const Duration(milliseconds: 50));
      await container
          .read(orderListProvider.notifier)
          .updateOrderStatus(1, OrderStatus.ready);

      verify(() => mockRepository.markOrderReady(1)).called(1);
    });

    test('should call confirmOrder for confirmed status', () async {
      when(
        () => mockRepository.confirmOrder(any()),
      ).thenAnswer((_) async => const Right(null));

      container.read(orderListProvider);
      await Future.delayed(const Duration(milliseconds: 50));
      await container
          .read(orderListProvider.notifier)
          .updateOrderStatus(1, OrderStatus.confirmed);

      verify(() => mockRepository.confirmOrder(1)).called(1);
    });

    test('should call rejectOrder for rejected status', () async {
      when(
        () => mockRepository.rejectOrder(any(), reason: any(named: 'reason')),
      ).thenAnswer((_) async => const Right(null));

      container.read(orderListProvider);
      await Future.delayed(const Duration(milliseconds: 50));
      await container
          .read(orderListProvider.notifier)
          .updateOrderStatus(1, OrderStatus.rejected);

      verify(() => mockRepository.rejectOrder(1, reason: null)).called(1);
    });

    test('should refresh orders for other statuses', () async {
      final notifier = container.read(orderListProvider.notifier);
      await Future.delayed(const Duration(milliseconds: 50));
      clearInteractions(mockRepository);

      // cancelled falls through to fetchOrders() in the default case
      await notifier.updateOrderStatus(1, OrderStatus.cancelled);

      verify(
        () => mockRepository.getOrders(
          status: any(named: 'status'),
          cursor: any(named: 'cursor'),
        ),
      ).called(1);
    });
  });
}
