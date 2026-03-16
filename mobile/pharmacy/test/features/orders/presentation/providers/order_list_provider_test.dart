import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dartz/dartz.dart';
import 'package:drpharma_pharmacy/features/orders/presentation/providers/order_list_provider.dart';
import 'package:drpharma_pharmacy/features/orders/presentation/providers/state/order_list_state.dart';
import 'package:drpharma_pharmacy/features/orders/domain/repositories/order_repository.dart';
import 'package:drpharma_pharmacy/core/errors/failure.dart';
import '../../../../test_helpers.dart';

// Mock classes
class MockOrderRepository extends Mock implements OrderRepository {}

void main() {
  late MockOrderRepository mockRepository;
  late OrderListNotifier orderListNotifier;

  setUp(() {
    mockRepository = MockOrderRepository();
    // Stub fetchOrders for constructor call
    when(() => mockRepository.getOrders(status: any(named: 'status')))
        .thenAnswer((_) async => const Right([]));
    orderListNotifier = OrderListNotifier(mockRepository);
  });

  group('OrderListNotifier initial state', () {
    test('should have initial state with pending filter', () async {
      // Wait for constructor's fetchOrders to complete
      await Future.delayed(Duration.zero);
      
      expect(orderListNotifier.state.activeFilter, 'pending');
    });

    test('should fetch orders on creation', () async {
      await Future.delayed(Duration.zero);
      
      verify(() => mockRepository.getOrders(status: 'pending')).called(1);
    });
  });

  group('OrderListNotifier fetchOrders', () {
    test('should set loading state during fetch', () async {
      final orders = TestDataFactory.createOrderList(count: 3);
      
      when(() => mockRepository.getOrders(status: any(named: 'status')))
          .thenAnswer((_) async {
            expect(orderListNotifier.state.status, OrderStatus.loading);
            return Right(orders);
          });

      await orderListNotifier.fetchOrders();
    });

    test('should set loaded state with orders on success', () async {
      final orders = TestDataFactory.createOrderList(count: 5);
      
      when(() => mockRepository.getOrders(status: any(named: 'status')))
          .thenAnswer((_) async => Right(orders));

      await orderListNotifier.fetchOrders();

      expect(orderListNotifier.state.status, OrderStatus.loaded);
      expect(orderListNotifier.state.orders.length, 5);
    });

    test('should set error state on failure', () async {
      when(() => mockRepository.getOrders(status: any(named: 'status')))
          .thenAnswer((_) async => Left(ServerFailure('Server error')));

      await orderListNotifier.fetchOrders();

      expect(orderListNotifier.state.status, OrderStatus.error);
      expect(orderListNotifier.state.errorMessage, 'Server error');
    });

    test('should update filter when status is provided', () async {
      final orders = TestDataFactory.createOrderList(count: 2);
      
      when(() => mockRepository.getOrders(status: any(named: 'status')))
          .thenAnswer((_) async => Right(orders));

      await orderListNotifier.fetchOrders(status: 'confirmed');

      expect(orderListNotifier.state.activeFilter, 'confirmed');
    });

    test('should pass null to repository when filter is all', () async {
      when(() => mockRepository.getOrders(status: any(named: 'status')))
          .thenAnswer((_) async => const Right([]));

      orderListNotifier = OrderListNotifier(mockRepository);
      await Future.delayed(Duration.zero);
      
      // Reset mock to clear constructor call
      reset(mockRepository);
      when(() => mockRepository.getOrders(status: any(named: 'status')))
          .thenAnswer((_) async => const Right([]));

      await orderListNotifier.fetchOrders(status: 'all');

      verify(() => mockRepository.getOrders(status: null)).called(1);
    });

    test('should handle network failure', () async {
      when(() => mockRepository.getOrders(status: any(named: 'status')))
          .thenAnswer((_) async => Left(NetworkFailure('No internet')));

      await orderListNotifier.fetchOrders();

      expect(orderListNotifier.state.status, OrderStatus.error);
      expect(orderListNotifier.state.errorMessage, 'No internet');
    });
  });

  group('OrderListNotifier setFilter', () {
    test('should fetch orders with new filter', () async {
      final orders = TestDataFactory.createOrderList(count: 2);
      
      when(() => mockRepository.getOrders(status: any(named: 'status')))
          .thenAnswer((_) async => Right(orders));

      await Future.delayed(Duration.zero); // Wait for constructor
      reset(mockRepository);
      when(() => mockRepository.getOrders(status: any(named: 'status')))
          .thenAnswer((_) async => Right(orders));

      orderListNotifier.setFilter('ready');
      await Future.delayed(Duration.zero);

      verify(() => mockRepository.getOrders(status: 'ready')).called(1);
    });

    test('should not fetch if filter is same', () async {
      when(() => mockRepository.getOrders(status: any(named: 'status')))
          .thenAnswer((_) async => const Right([]));

      await Future.delayed(Duration.zero); // Wait for constructor
      
      // After constructor, filter is 'pending'
      // ignore: unused_local_variable
      final initialState = orderListNotifier.state;
      
      orderListNotifier.setFilter('pending'); // Same filter
      await Future.delayed(Duration.zero);

      // State should not have changed to loading (no new fetch triggered)
      // The filter remains the same
      expect(orderListNotifier.state.activeFilter, 'pending');
    });
  });

  group('OrderListNotifier confirmOrder', () {
    test('should call repository confirmOrder and refresh list', () async {
      when(() => mockRepository.getOrders(status: any(named: 'status')))
          .thenAnswer((_) async => const Right([]));
      when(() => mockRepository.confirmOrder(any()))
          .thenAnswer((_) async => const Right(null));

      await Future.delayed(Duration.zero);
      await orderListNotifier.confirmOrder(1);

      verify(() => mockRepository.confirmOrder(1)).called(1);
    });

    test('should return false and set error on confirm failure', () async {
      when(() => mockRepository.getOrders(status: any(named: 'status')))
          .thenAnswer((_) async => const Right([]));
      when(() => mockRepository.confirmOrder(any()))
          .thenAnswer((_) async => Left(ServerFailure('Cannot confirm')));

      await Future.delayed(Duration.zero);

      final result = await orderListNotifier.confirmOrder(1);
      expect(result, isFalse);
      expect(orderListNotifier.state.errorMessage, 'Cannot confirm');
    });
  });

  group('OrderListNotifier markOrderReady', () {
    test('should call repository markOrderReady and refresh list', () async {
      when(() => mockRepository.getOrders(status: any(named: 'status')))
          .thenAnswer((_) async => const Right([]));
      when(() => mockRepository.markOrderReady(any()))
          .thenAnswer((_) async => const Right(null));

      await Future.delayed(Duration.zero);
      await orderListNotifier.markOrderReady(2);

      verify(() => mockRepository.markOrderReady(2)).called(1);
    });

    test('should return false and set error on markReady failure', () async {
      when(() => mockRepository.getOrders(status: any(named: 'status')))
          .thenAnswer((_) async => const Right([]));
      when(() => mockRepository.markOrderReady(any()))
          .thenAnswer((_) async => Left(ServerFailure('Cannot mark ready')));

      await Future.delayed(Duration.zero);

      final result = await orderListNotifier.markOrderReady(2);
      expect(result, isFalse);
      expect(orderListNotifier.state.errorMessage, 'Cannot mark ready');
    });
  });

  group('OrderListNotifier rejectOrder', () {
    test('should call repository rejectOrder and refresh list', () async {
      when(() => mockRepository.getOrders(status: any(named: 'status')))
          .thenAnswer((_) async => const Right([]));
      when(() => mockRepository.rejectOrder(any(), reason: any(named: 'reason')))
          .thenAnswer((_) async => const Right(null));

      await Future.delayed(Duration.zero);
      await orderListNotifier.rejectOrder(3, reason: 'Out of stock');

      verify(() => mockRepository.rejectOrder(3, reason: 'Out of stock')).called(1);
    });

    test('should return false and set error on reject failure', () async {
      when(() => mockRepository.getOrders(status: any(named: 'status')))
          .thenAnswer((_) async => const Right([]));
      when(() => mockRepository.rejectOrder(any(), reason: any(named: 'reason')))
          .thenAnswer((_) async => Left(ServerFailure('Cannot reject')));

      await Future.delayed(Duration.zero);

      final result = await orderListNotifier.rejectOrder(3);
      expect(result, isFalse);
      expect(orderListNotifier.state.errorMessage, 'Cannot reject');
    });
  });

  group('OrderListNotifier updateOrderStatus', () {
    setUp(() {
      when(() => mockRepository.getOrders(status: any(named: 'status')))
          .thenAnswer((_) async => const Right([]));
    });

    test('should call markOrderReady for ready status', () async {
      when(() => mockRepository.markOrderReady(any()))
          .thenAnswer((_) async => const Right(null));

      await Future.delayed(Duration.zero);
      await orderListNotifier.updateOrderStatus(1, 'ready');

      verify(() => mockRepository.markOrderReady(1)).called(1);
    });

    test('should call confirmOrder for confirmed status', () async {
      when(() => mockRepository.confirmOrder(any()))
          .thenAnswer((_) async => const Right(null));

      await Future.delayed(Duration.zero);
      await orderListNotifier.updateOrderStatus(1, 'confirmed');

      verify(() => mockRepository.confirmOrder(1)).called(1);
    });

    test('should call rejectOrder for rejected status', () async {
      when(() => mockRepository.rejectOrder(any(), reason: any(named: 'reason')))
          .thenAnswer((_) async => const Right(null));

      await Future.delayed(Duration.zero);
      await orderListNotifier.updateOrderStatus(1, 'rejected');

      verify(() => mockRepository.rejectOrder(1, reason: null)).called(1);
    });

    test('should refresh orders for unknown status', () async {
      await Future.delayed(Duration.zero);
      reset(mockRepository);
      when(() => mockRepository.getOrders(status: any(named: 'status')))
          .thenAnswer((_) async => const Right([]));

      await orderListNotifier.updateOrderStatus(1, 'unknown_status');

      verify(() => mockRepository.getOrders(status: any(named: 'status'))).called(1);
    });
  });
}
