import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:drpharma_pharmacy/features/orders/data/repositories/order_repository_impl.dart';
import 'package:drpharma_pharmacy/features/orders/data/datasources/order_remote_datasource.dart';
import 'package:drpharma_pharmacy/features/orders/data/models/order_model.dart';
import 'package:drpharma_pharmacy/core/errors/exceptions.dart';
import 'package:drpharma_pharmacy/core/errors/failure.dart';

class MockOrderRemoteDataSource extends Mock implements OrderRemoteDataSource {}

void main() {
  late MockOrderRemoteDataSource mockRemoteDataSource;
  late OrderRepositoryImpl repository;

  setUp(() {
    mockRemoteDataSource = MockOrderRemoteDataSource();
    repository = OrderRepositoryImpl(
      remoteDataSource: mockRemoteDataSource,
    );
  });

  group('getOrders', () {
    final orderModels = <OrderModel>[
      OrderModel(
        id: 1,
        reference: 'DR-001',
        status: 'pending',
        paymentMode: 'platform',
        totalAmount: 5000.0,
        customer: {'name': 'Client 1', 'phone': '+225 07 00 00 00 01'},
        createdAt: '2024-01-15T10:00:00.000Z',
      ),
      OrderModel(
        id: 2,
        reference: 'DR-002',
        status: 'confirmed',
        paymentMode: 'delivery',
        totalAmount: 10000.0,
        customer: {'name': 'Client 2', 'phone': '+225 07 00 00 00 02'},
        createdAt: '2024-01-16T11:00:00.000Z',
      ),
    ];

    test('should return list of orders when remote datasource succeeds', () async {
      when(() => mockRemoteDataSource.getOrders(status: any(named: 'status')))
          .thenAnswer((_) async => orderModels);

      final result = await repository.getOrders();

      expect(result.isRight(), isTrue);
      result.fold(
        (failure) => fail('Should not return failure'),
        (orders) {
          expect(orders.length, 2);
          expect(orders[0].reference, 'DR-001');
          expect(orders[1].reference, 'DR-002');
        },
      );
    });

    test('should return list of orders with status filter', () async {
      when(() => mockRemoteDataSource.getOrders(status: 'pending'))
          .thenAnswer((_) async => [orderModels[0]]);

      final result = await repository.getOrders(status: 'pending');

      expect(result.isRight(), isTrue);
      result.fold(
        (failure) => fail('Should not return failure'),
        (orders) {
          expect(orders.length, 1);
          expect(orders[0].status, 'pending');
        },
      );
      verify(() => mockRemoteDataSource.getOrders(status: 'pending')).called(1);
    });

    test('should return NetworkFailure on NetworkException', () async {
      when(() => mockRemoteDataSource.getOrders(status: any(named: 'status')))
          .thenThrow(NetworkException(message: 'No internet'));

      final result = await repository.getOrders();

      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) => expect(failure, isA<NetworkFailure>()),
        (orders) => fail('Should not return orders'),
      );
    });

    test('should return ServerFailure on ServerException', () async {
      when(() => mockRemoteDataSource.getOrders(status: any(named: 'status')))
          .thenThrow(ServerException(message: 'Server error', statusCode: 500));

      final result = await repository.getOrders();

      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) {
          expect(failure, isA<ServerFailure>());
          expect(failure.message, 'Server error');
        },
        (orders) => fail('Should not return orders'),
      );
    });
  });

  group('getOrderDetails', () {
    const orderModel = OrderModel(
      id: 1,
      reference: 'DR-001',
      status: 'pending',
      paymentMode: 'platform',
      totalAmount: 5000.0,
      customer: {'name': 'Client Test', 'phone': '+225 07 00 00 00 00'},
      createdAt: '2024-01-15T10:00:00.000Z',
    );

    test('should return order details on success', () async {
      when(() => mockRemoteDataSource.getOrderDetails(1))
          .thenAnswer((_) async => orderModel);

      final result = await repository.getOrderDetails(1);

      expect(result.isRight(), isTrue);
      result.fold(
        (failure) => fail('Should not return failure'),
        (order) {
          expect(order.id, 1);
          expect(order.reference, 'DR-001');
        },
      );
    });

    test('should return NetworkFailure on NetworkException', () async {
      when(() => mockRemoteDataSource.getOrderDetails(1))
          .thenThrow(NetworkException(message: 'No internet'));

      final result = await repository.getOrderDetails(1);

      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) => expect(failure, isA<NetworkFailure>()),
        (order) => fail('Should not return order'),
      );
    });

    test('should return ServerFailure on ServerException', () async {
      when(() => mockRemoteDataSource.getOrderDetails(1)).thenThrow(
          ServerException(message: 'Order not found', statusCode: 404));

      final result = await repository.getOrderDetails(1);

      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) => expect(failure, isA<ServerFailure>()),
        (order) => fail('Should not return order'),
      );
    });
  });

  group('confirmOrder', () {
    test('should return Right(null) on success', () async {
      when(() => mockRemoteDataSource.confirmOrder(1))
          .thenAnswer((_) async => {});

      final result = await repository.confirmOrder(1);

      expect(result.isRight(), isTrue);
      verify(() => mockRemoteDataSource.confirmOrder(1)).called(1);
    });

    test('should return NetworkFailure on NetworkException', () async {
      when(() => mockRemoteDataSource.confirmOrder(1))
          .thenThrow(NetworkException(message: 'No internet'));

      final result = await repository.confirmOrder(1);

      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) => expect(failure, isA<NetworkFailure>()),
        (_) => fail('Should not succeed'),
      );
    });

    test('should return ServerFailure on exception', () async {
      when(() => mockRemoteDataSource.confirmOrder(1))
          .thenThrow(Exception('Failed to confirm'));

      final result = await repository.confirmOrder(1);

      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) => expect(failure, isA<ServerFailure>()),
        (_) => fail('Should not succeed'),
      );
    });
  });

  group('markOrderReady', () {
    test('should return Right(null) on success', () async {
      when(() => mockRemoteDataSource.markOrderReady(1))
          .thenAnswer((_) async => {});

      final result = await repository.markOrderReady(1);

      expect(result.isRight(), isTrue);
      verify(() => mockRemoteDataSource.markOrderReady(1)).called(1);
    });

    test('should return NetworkFailure on NetworkException', () async {
      when(() => mockRemoteDataSource.markOrderReady(1))
          .thenThrow(NetworkException(message: 'No internet'));

      final result = await repository.markOrderReady(1);

      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) => expect(failure, isA<NetworkFailure>()),
        (_) => fail('Should not succeed'),
      );
    });
  });

  group('addNotes', () {
    test('should return Right(null) on success', () async {
      when(() => mockRemoteDataSource.addNotes(1, 'Test notes'))
          .thenAnswer((_) async => {});

      final result = await repository.addNotes(1, 'Test notes');

      expect(result.isRight(), isTrue);
      verify(() => mockRemoteDataSource.addNotes(1, 'Test notes')).called(1);
    });

    test('should return NetworkFailure on NetworkException', () async {
      when(() => mockRemoteDataSource.addNotes(1, 'Test notes'))
          .thenThrow(NetworkException(message: 'No internet'));

      final result = await repository.addNotes(1, 'Test notes');

      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) => expect(failure, isA<NetworkFailure>()),
        (_) => fail('Should not succeed'),
      );
    });
  });
}
