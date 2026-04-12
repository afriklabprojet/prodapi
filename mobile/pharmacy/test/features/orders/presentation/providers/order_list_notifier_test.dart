import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:drpharma_pharmacy/core/errors/failure.dart';
import 'package:drpharma_pharmacy/features/orders/domain/entities/order_entity.dart';
import 'package:drpharma_pharmacy/features/orders/domain/enums/order_status.dart';
import 'package:drpharma_pharmacy/features/orders/domain/repositories/order_repository.dart';
import 'package:drpharma_pharmacy/features/orders/presentation/providers/order_list_provider.dart';
import 'package:drpharma_pharmacy/features/orders/presentation/providers/order_di_providers.dart';
import 'package:drpharma_pharmacy/features/orders/presentation/providers/state/order_list_state.dart';

// Mock classes
class MockOrderRepository extends Mock implements OrderRepository {}

void main() {
  late MockOrderRepository mockRepository;
  late ProviderContainer container;

  // Test data
  final testOrder = OrderEntity(
    id: 1,
    reference: 'DR-TEST001',
    status: OrderStatus.pending,
    paymentMode: 'platform',
    totalAmount: 5000.0,
    customerName: 'Client Test',
    customerPhone: '+225 07 07 07 07 07',
    createdAt: DateTime.now(),
    items: const [],
    itemsCount: 1,
  );

  final testOrders = [
    testOrder,
    testOrder.copyWith(id: 2, reference: 'DR-TEST002'),
    testOrder.copyWith(id: 3, reference: 'DR-TEST003'),
  ];

  final paginatedResult = PaginatedOrdersResult(
    orders: testOrders,
    nextCursor: 'cursor_page_2',
    perPage: 20,
    total: 25,
  );

  setUpAll(() {
    // Register fallback values if needed
  });

  setUp(() {
    mockRepository = MockOrderRepository();

    // Create provider container with mock repository
    container = ProviderContainer(
      overrides: [orderRepositoryProvider.overrideWithValue(mockRepository)],
    );
  });

  tearDown(() {
    container.dispose();
  });

  group('OrderListNotifier', () {
    test('initial state should be loading and fetch orders', () async {
      // Arrange
      when(
        () => mockRepository.getOrders(
          status: any(named: 'status'),
          cursor: any(named: 'cursor'),
        ),
      ).thenAnswer((_) async => Right(paginatedResult));

      // Act - access notifier and explicitly call fetchOrders
      final notifier = container.read(orderListProvider.notifier);
      await notifier.fetchOrders();

      // Assert
      final state = container.read(orderListProvider);
      expect(state.status, OrderLoadStatus.loaded);
      expect(state.orders.length, 3);
    });

    test('fetchOrders should update state with orders on success', () async {
      // Arrange
      when(
        () => mockRepository.getOrders(
          status: any(named: 'status'),
          cursor: any(named: 'cursor'),
        ),
      ).thenAnswer((_) async => Right(paginatedResult));

      // Act
      final notifier = container.read(orderListProvider.notifier);
      await notifier.fetchOrders();

      // Assert
      final state = container.read(orderListProvider);
      expect(state.status, OrderLoadStatus.loaded);
      expect(state.orders, testOrders);
      expect(state.pagination.nextCursor, 'cursor_page_2');
      expect(state.pagination.hasMore, true);
      expect(state.hasMore, true);
    });

    test('fetchOrders should handle error gracefully', () async {
      // Arrange
      when(
        () => mockRepository.getOrders(
          status: any(named: 'status'),
          cursor: any(named: 'cursor'),
        ),
      ).thenAnswer((_) async => Left(ServerFailure('Network error')));

      // Act
      final notifier = container.read(orderListProvider.notifier);
      await notifier.fetchOrders();

      // Assert
      final state = container.read(orderListProvider);
      expect(state.status, OrderLoadStatus.error);
      expect(state.errorMessage, 'Network error');
      expect(state.orders, isEmpty);
    });

    test('fetchOrders with filter should apply filter', () async {
      // Arrange - setup mock that always succeeds
      when(
        () => mockRepository.getOrders(
          status: any(named: 'status'),
          cursor: any(named: 'cursor'),
        ),
      ).thenAnswer((_) async => Right(paginatedResult));

      // Act - create notifier
      final notifier = container.read(orderListProvider.notifier);

      // Explicitly call fetchOrders first to initialize
      await notifier.fetchOrders();
      expect(
        container.read(orderListProvider).activeFilter,
        OrderStatusFilter.pending,
      );

      // Now change filter
      await notifier.fetchOrders(filter: OrderStatusFilter.confirmed);

      // Assert - filter should be updated
      expect(
        container.read(orderListProvider).activeFilter,
        OrderStatusFilter.confirmed,
      );
      expect(container.read(orderListProvider).status, OrderLoadStatus.loaded);
    });

    test('loadMore should append orders', () async {
      // Arrange - first fetch
      when(
        () => mockRepository.getOrders(
          status: any(named: 'status'),
          cursor: null,
        ),
      ).thenAnswer((_) async => Right(paginatedResult));

      // Second page
      final page2Orders = [
        testOrder.copyWith(id: 4, reference: 'DR-TEST004'),
        testOrder.copyWith(id: 5, reference: 'DR-TEST005'),
      ];

      when(
        () => mockRepository.getOrders(
          status: any(named: 'status'),
          cursor: 'cursor_page_2',
        ),
      ).thenAnswer(
        (_) async => Right(
          PaginatedOrdersResult(
            orders: page2Orders,
            nextCursor: null, // No more pages
            perPage: 20,
            total: 25,
          ),
        ),
      );

      // Act
      final notifier = container.read(orderListProvider.notifier);
      await notifier.fetchOrders();
      await notifier.loadMore();

      // Assert
      final state = container.read(orderListProvider);
      expect(state.orders.length, 5); // 3 from page 1 + 2 from page 2
      expect(state.pagination.nextCursor, isNull);
      expect(state.hasMore, false);
    });

    test('loadMore should not load if already loading', () async {
      // Arrange
      when(
        () => mockRepository.getOrders(
          status: any(named: 'status'),
          cursor: any(named: 'cursor'),
        ),
      ).thenAnswer((_) async => Right(paginatedResult));

      // Act
      final notifier = container.read(orderListProvider.notifier);
      await notifier.fetchOrders();

      // Trigger loadMore twice quickly
      notifier.loadMore();
      notifier.loadMore();

      // Assert - should only call with cursor once
      await Future.delayed(const Duration(milliseconds: 100));
    });

    test('loadMore should not load if no more pages', () async {
      // Arrange - single page result (no next cursor)
      final singlePageResult = PaginatedOrdersResult(
        orders: testOrders,
        nextCursor: null,
        perPage: 20,
        total: 3,
      );

      when(
        () => mockRepository.getOrders(
          status: any(named: 'status'),
          cursor: any(named: 'cursor'),
        ),
      ).thenAnswer((_) async => Right(singlePageResult));

      // Act - trigger build and wait for auto-fetch
      final notifier = container.read(orderListProvider.notifier);
      await Future.delayed(const Duration(milliseconds: 50));

      // Clear interactions from auto-fetch
      clearInteractions(mockRepository);

      // Try to load more
      await notifier.loadMore();

      // Assert
      final state = container.read(orderListProvider);
      expect(state.hasMore, false);
      // Page 2 should never be called because hasMore is false
      verifyNever(
        () => mockRepository.getOrders(
          status: any(named: 'status'),
          cursor: any(named: 'cursor'),
        ),
      );
    });

    test('confirmOrder should return true on success', () async {
      // Arrange
      when(
        () => mockRepository.getOrders(
          status: any(named: 'status'),
          cursor: any(named: 'cursor'),
        ),
      ).thenAnswer((_) async => Right(paginatedResult));
      when(
        () => mockRepository.confirmOrder(1),
      ).thenAnswer((_) async => const Right(null));

      // Act
      final notifier = container.read(orderListProvider.notifier);
      await notifier.fetchOrders();
      final result = await notifier.confirmOrder(1);

      // Assert
      expect(result, true);
      verify(() => mockRepository.confirmOrder(1)).called(1);
    });

    test('confirmOrder should return false on failure', () async {
      // Arrange
      when(
        () => mockRepository.getOrders(
          status: any(named: 'status'),
          cursor: any(named: 'cursor'),
        ),
      ).thenAnswer((_) async => Right(paginatedResult));
      when(
        () => mockRepository.confirmOrder(1),
      ).thenAnswer((_) async => Left(ServerFailure('Cannot confirm')));

      // Act
      final notifier = container.read(orderListProvider.notifier);
      await notifier.fetchOrders();
      final result = await notifier.confirmOrder(1);

      // Assert
      expect(result, false);
      final state = container.read(orderListProvider);
      expect(state.errorMessage, 'Cannot confirm');
    });

    test('markOrderReady should return true on success', () async {
      // Arrange
      when(
        () => mockRepository.getOrders(
          status: any(named: 'status'),
          cursor: any(named: 'cursor'),
        ),
      ).thenAnswer((_) async => Right(paginatedResult));
      when(
        () => mockRepository.markOrderReady(1),
      ).thenAnswer((_) async => const Right(null));

      // Act
      final notifier = container.read(orderListProvider.notifier);
      await notifier.fetchOrders();
      final result = await notifier.markOrderReady(1);

      // Assert
      expect(result, true);
    });

    test('rejectOrder should return true on success', () async {
      // Arrange
      when(
        () => mockRepository.getOrders(
          status: any(named: 'status'),
          cursor: any(named: 'cursor'),
        ),
      ).thenAnswer((_) async => Right(paginatedResult));
      when(
        () => mockRepository.rejectOrder(1, reason: 'Out of stock'),
      ).thenAnswer((_) async => const Right(null));

      // Act
      final notifier = container.read(orderListProvider.notifier);
      await notifier.fetchOrders();
      final result = await notifier.rejectOrder(1, reason: 'Out of stock');

      // Assert
      expect(result, true);
    });

    test('setFilter should trigger new fetch with filter', () async {
      // Arrange
      when(
        () => mockRepository.getOrders(
          status: any(named: 'status'),
          cursor: any(named: 'cursor'),
        ),
      ).thenAnswer((_) async => Right(paginatedResult));

      // Act
      final notifier = container.read(orderListProvider.notifier);
      await notifier.fetchOrders();

      // Clear verifications
      clearInteractions(mockRepository);

      notifier.setFilter(OrderStatusFilter.ready);
      await Future.microtask(() {});

      // Assert
      verify(
        () => mockRepository.getOrders(
          status: 'ready',
          cursor: any(named: 'cursor'),
        ),
      ).called(1);
    });

    test('setFilter with same filter should not trigger fetch', () async {
      // Arrange
      when(
        () => mockRepository.getOrders(
          status: any(named: 'status'),
          cursor: any(named: 'cursor'),
        ),
      ).thenAnswer((_) async => Right(paginatedResult));

      // Act
      final notifier = container.read(orderListProvider.notifier);
      await notifier.fetchOrders();

      // Clear and set same filter
      clearInteractions(mockRepository);
      notifier.setFilter(OrderStatusFilter.pending); // Same as default

      // Assert - should not fetch again
      await Future.microtask(() {});
      verifyNever(
        () => mockRepository.getOrders(
          status: any(named: 'status'),
          cursor: any(named: 'cursor'),
        ),
      );
    });
  });

  group('OrderListState', () {
    test('pendingCount should return correct count', () {
      final state = OrderListState(
        orders: [
          testOrder.copyWith(status: OrderStatus.pending),
          testOrder.copyWith(status: OrderStatus.pending, id: 2),
          testOrder.copyWith(status: OrderStatus.confirmed, id: 3),
        ],
      );

      expect(state.pendingCount, 2);
    });

    test('confirmedCount should return correct count', () {
      final state = OrderListState(
        orders: [
          testOrder.copyWith(status: OrderStatus.pending),
          testOrder.copyWith(status: OrderStatus.confirmed, id: 2),
          testOrder.copyWith(status: OrderStatus.confirmed, id: 3),
        ],
      );

      expect(state.confirmedCount, 2);
    });

    test('copyWith should preserve unmodified fields', () {
      const original = OrderListState(
        status: OrderLoadStatus.loaded,
        activeFilter: OrderStatusFilter.confirmed,
      );

      final modified = original.copyWith(status: OrderLoadStatus.loading);

      expect(modified.status, OrderLoadStatus.loading);
      expect(modified.activeFilter, OrderStatusFilter.confirmed);
    });
  });

  group('PaginationMeta', () {
    test('hasMore should return true when nextCursor is not null', () {
      const meta = PaginationMeta(nextCursor: 'next_cursor_123', hasMore: true);
      expect(meta.hasMore, true);
    });

    test('hasMore should return false when nextCursor is null', () {
      const meta = PaginationMeta(nextCursor: null, hasMore: false);
      expect(meta.hasMore, false);
    });
  });
}
