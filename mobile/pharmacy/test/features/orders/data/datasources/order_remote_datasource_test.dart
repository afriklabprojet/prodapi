import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:drpharma_pharmacy/core/network/api_client.dart';
import 'package:drpharma_pharmacy/features/orders/data/datasources/order_remote_datasource.dart';
import 'package:drpharma_pharmacy/features/orders/data/models/order_model.dart';

class MockApiClient extends Mock implements ApiClient {}

void main() {
  late OrderRemoteDataSourceImpl dataSource;
  late MockApiClient mockApiClient;

  setUp(() {
    mockApiClient = MockApiClient();
    dataSource = OrderRemoteDataSourceImpl(apiClient: mockApiClient);
  });

  setUpAll(() {
    registerFallbackValue(Options());
  });

  final tOrderJson = {
    'id': 1,
    'reference': 'ORD-001',
    'status': 'pending',
    'payment_mode': 'cash',
    'total_amount': 15000,
    'customer': {'name': 'John Doe', 'phone': '+225 0123456789'},
    'items': [],
    'created_at': '2024-01-15T10:30:00.000Z',
  };

  final tOrdersListJson = [
    tOrderJson,
    {
      'id': 2,
      'reference': 'ORD-002',
      'status': 'confirmed',
      'payment_mode': 'mobile_money',
      'total_amount': 25000,
      'customer': {'name': 'Jane Doe'},
      'items': [],
      'created_at': '2024-01-15T11:30:00.000Z',
    },
  ];

  group('OrderRemoteDataSourceImpl', () {
    group('getOrders', () {
      test('should call apiClient.get with correct endpoint', () async {
        // arrange
        when(
          () => mockApiClient.authorizedOptions(any()),
        ).thenReturn(Options(headers: {'Authorization': 'Bearer token'}));
        when(
          () => mockApiClient.get(
            any(),
            queryParameters: any(named: 'queryParameters'),
            options: any(named: 'options'),
          ),
        ).thenAnswer(
          (_) async => Response(
            requestOptions: RequestOptions(path: '/pharmacy/orders'),
            statusCode: 200,
            data: {'data': tOrdersListJson},
          ),
        );

        // act
        await dataSource.getOrders();

        // assert
        verify(
          () => mockApiClient.get(
            '/pharmacy/orders',
            queryParameters: {'per_page': 20},
            options: any(named: 'options'),
          ),
        ).called(1);
      });

      test('should call apiClient.get with status filter', () async {
        // arrange
        when(
          () => mockApiClient.authorizedOptions(any()),
        ).thenReturn(Options(headers: {'Authorization': 'Bearer token'}));
        when(
          () => mockApiClient.get(
            any(),
            queryParameters: any(named: 'queryParameters'),
            options: any(named: 'options'),
          ),
        ).thenAnswer(
          (_) async => Response(
            requestOptions: RequestOptions(path: '/pharmacy/orders'),
            statusCode: 200,
            data: {'data': tOrdersListJson},
          ),
        );

        // act
        await dataSource.getOrders(status: 'pending');

        // assert
        verify(
          () => mockApiClient.get(
            '/pharmacy/orders',
            queryParameters: {'per_page': 20, 'status': 'pending'},
            options: any(named: 'options'),
          ),
        ).called(1);
      });

      test('should return list of OrderModel on success', () async {
        // arrange
        when(
          () => mockApiClient.authorizedOptions(any()),
        ).thenReturn(Options(headers: {'Authorization': 'Bearer token'}));
        when(
          () => mockApiClient.get(
            any(),
            queryParameters: any(named: 'queryParameters'),
            options: any(named: 'options'),
          ),
        ).thenAnswer(
          (_) async => Response(
            requestOptions: RequestOptions(path: '/pharmacy/orders'),
            statusCode: 200,
            data: {'data': tOrdersListJson},
          ),
        );

        // act
        final result = await dataSource.getOrders();

        // assert
        expect(result, isA<PaginatedOrdersResponse>());
        expect(result.orders.length, equals(2));
        expect(result.orders[0].reference, equals('ORD-001'));
        expect(result.orders[1].reference, equals('ORD-002'));
      });
    });

    group('getOrderDetails', () {
      test('should call apiClient.get with correct endpoint', () async {
        // arrange
        when(
          () => mockApiClient.get(
            any(),
            queryParameters: any(named: 'queryParameters'),
            options: any(named: 'options'),
          ),
        ).thenAnswer(
          (_) async => Response(
            requestOptions: RequestOptions(path: '/pharmacy/orders/1'),
            statusCode: 200,
            data: {'data': tOrderJson},
          ),
        );

        // act
        await dataSource.getOrderDetails(1);

        // assert
        verify(
          () => mockApiClient.get(
            '/pharmacy/orders/1',
            queryParameters: any(named: 'queryParameters'),
            options: any(named: 'options'),
          ),
        ).called(1);
      });

      test('should return OrderModel on success', () async {
        // arrange
        when(
          () => mockApiClient.get(
            any(),
            queryParameters: any(named: 'queryParameters'),
            options: any(named: 'options'),
          ),
        ).thenAnswer(
          (_) async => Response(
            requestOptions: RequestOptions(path: '/pharmacy/orders/1'),
            statusCode: 200,
            data: {'data': tOrderJson},
          ),
        );

        // act
        final result = await dataSource.getOrderDetails(1);

        // assert
        expect(result, isA<OrderModel>());
        expect(result.id, equals(1));
        expect(result.reference, equals('ORD-001'));
      });
    });

    group('confirmOrder', () {
      test('should call apiClient.post with correct endpoint', () async {
        // arrange
        when(
          () => mockApiClient.post(
            any(),
            data: any(named: 'data'),
            queryParameters: any(named: 'queryParameters'),
            options: any(named: 'options'),
          ),
        ).thenAnswer(
          (_) async => Response(
            requestOptions: RequestOptions(path: '/pharmacy/orders/1/confirm'),
            statusCode: 200,
            data: {'message': 'Order confirmed'},
          ),
        );

        // act
        await dataSource.confirmOrder(1);

        // assert
        verify(
          () => mockApiClient.post(
            '/pharmacy/orders/1/confirm',
            data: any(named: 'data'),
            queryParameters: any(named: 'queryParameters'),
            options: any(named: 'options'),
          ),
        ).called(1);
      });
    });

    group('markOrderReady', () {
      test('should call apiClient.post with correct endpoint', () async {
        // arrange
        when(
          () => mockApiClient.post(
            any(),
            data: any(named: 'data'),
            queryParameters: any(named: 'queryParameters'),
            options: any(named: 'options'),
          ),
        ).thenAnswer(
          (_) async => Response(
            requestOptions: RequestOptions(path: '/pharmacy/orders/1/ready'),
            statusCode: 200,
            data: {'message': 'Order marked as ready'},
          ),
        );

        // act
        await dataSource.markOrderReady(1);

        // assert
        verify(
          () => mockApiClient.post(
            '/pharmacy/orders/1/ready',
            data: any(named: 'data'),
            queryParameters: any(named: 'queryParameters'),
            options: any(named: 'options'),
          ),
        ).called(1);
      });
    });

    group('rejectOrder', () {
      test('should call apiClient.post without reason', () async {
        // arrange
        when(
          () => mockApiClient.post(
            any(),
            data: any(named: 'data'),
            queryParameters: any(named: 'queryParameters'),
            options: any(named: 'options'),
          ),
        ).thenAnswer(
          (_) async => Response(
            requestOptions: RequestOptions(path: '/pharmacy/orders/1/reject'),
            statusCode: 200,
            data: {'message': 'Order rejected'},
          ),
        );

        // act
        await dataSource.rejectOrder(1);

        // assert
        verify(
          () => mockApiClient.post(
            '/pharmacy/orders/1/reject',
            data: null,
            queryParameters: any(named: 'queryParameters'),
            options: any(named: 'options'),
          ),
        ).called(1);
      });

      test('should call apiClient.post with reason', () async {
        // arrange
        when(
          () => mockApiClient.post(
            any(),
            data: any(named: 'data'),
            queryParameters: any(named: 'queryParameters'),
            options: any(named: 'options'),
          ),
        ).thenAnswer(
          (_) async => Response(
            requestOptions: RequestOptions(path: '/pharmacy/orders/1/reject'),
            statusCode: 200,
            data: {'message': 'Order rejected'},
          ),
        );

        // act
        await dataSource.rejectOrder(1, reason: 'Out of stock');

        // assert
        verify(
          () => mockApiClient.post(
            '/pharmacy/orders/1/reject',
            data: {'reason': 'Out of stock'},
            queryParameters: any(named: 'queryParameters'),
            options: any(named: 'options'),
          ),
        ).called(1);
      });
    });

    group('addNotes', () {
      test('should call apiClient.post with notes data', () async {
        // arrange
        when(
          () => mockApiClient.post(
            any(),
            data: any(named: 'data'),
            queryParameters: any(named: 'queryParameters'),
            options: any(named: 'options'),
          ),
        ).thenAnswer(
          (_) async => Response(
            requestOptions: RequestOptions(path: '/pharmacy/orders/1/notes'),
            statusCode: 200,
            data: {'message': 'Notes added'},
          ),
        );

        // act
        await dataSource.addNotes(1, 'Customer wants bag');

        // assert
        verify(
          () => mockApiClient.post(
            '/pharmacy/orders/1/notes',
            data: {'notes': 'Customer wants bag'},
            queryParameters: any(named: 'queryParameters'),
            options: any(named: 'options'),
          ),
        ).called(1);
      });
    });
  });
}
