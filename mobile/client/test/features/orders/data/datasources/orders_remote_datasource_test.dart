import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'package:drpharma_client/core/network/api_client.dart';
import 'package:drpharma_client/features/orders/data/datasources/orders_remote_datasource.dart';
import 'package:drpharma_client/features/orders/data/models/order_item_model.dart';
import 'package:drpharma_client/core/errors/exceptions.dart';

@GenerateMocks([ApiClient])
import 'orders_remote_datasource_test.mocks.dart';

// ─── Helpers ──────────────────────────────────────────────

Response<dynamic> _makeResponse(dynamic data, {int statusCode = 200}) =>
    Response(
      requestOptions: RequestOptions(path: '/test'),
      data: data,
      statusCode: statusCode,
    );

Map<String, dynamic> _makeOrderJson({
  int id = 1,
  String status = 'pending',
  String reference = '',
}) => {
  'id': id,
  'reference': reference.isEmpty
      ? 'REF-${id.toString().padLeft(3, '0')}'
      : reference,
  'status': status,
  'payment_status': 'pending',
  'payment_mode': 'cash',
  'total_amount': 5000.0,
  'delivery_address': '123 Rue Test',
  'created_at': '2024-01-01T00:00:00.000Z',
  'items': <dynamic>[],
};

void main() {
  late OrdersRemoteDataSource datasource;
  late MockApiClient mockApiClient;

  setUp(() {
    mockApiClient = MockApiClient();
    datasource = OrdersRemoteDataSource(mockApiClient);
  });

  // ── getOrders ──────────────────────────────────────────
  group('getOrders', () {
    test('returns list of orders on success', () async {
      when(
        mockApiClient.get(any, queryParameters: anyNamed('queryParameters')),
      ).thenAnswer(
        (_) async => _makeResponse({
          'data': [_makeOrderJson(id: 1), _makeOrderJson(id: 2)],
        }),
      );

      final result = await datasource.getOrders();

      expect(result.length, 2);
      expect(result[0].id, 1);
      expect(result[1].id, 2);
    });

    test('returns empty list when data is null', () async {
      when(
        mockApiClient.get(any, queryParameters: anyNamed('queryParameters')),
      ).thenAnswer((_) async => _makeResponse({'data': null}));

      final result = await datasource.getOrders();
      expect(result, isEmpty);
    });

    test('returns empty list when data is not a List', () async {
      when(
        mockApiClient.get(any, queryParameters: anyNamed('queryParameters')),
      ).thenAnswer((_) async => _makeResponse({'data': 'invalid'}));

      final result = await datasource.getOrders();
      expect(result, isEmpty);
    });

    test('passes pagination parameters', () async {
      when(
        mockApiClient.get(any, queryParameters: anyNamed('queryParameters')),
      ).thenAnswer((_) async => _makeResponse({'data': []}));

      await datasource.getOrders(page: 2, perPage: 10);

      final captured =
          verify(
                mockApiClient.get(
                  any,
                  queryParameters: captureAnyNamed('queryParameters'),
                ),
              ).captured.first
              as Map<String, dynamic>;

      expect(captured['page'], 2);
      expect(captured['per_page'], 10);
    });

    test('passes status filter when provided', () async {
      when(
        mockApiClient.get(any, queryParameters: anyNamed('queryParameters')),
      ).thenAnswer((_) async => _makeResponse({'data': []}));

      await datasource.getOrders(status: 'pending');

      final captured =
          verify(
                mockApiClient.get(
                  any,
                  queryParameters: captureAnyNamed('queryParameters'),
                ),
              ).captured.first
              as Map<String, dynamic>;
      expect(captured['status'], 'pending');
    });

    test('propagates ServerException', () async {
      when(
        mockApiClient.get(any, queryParameters: anyNamed('queryParameters')),
      ).thenThrow(ServerException(message: 'Server error', statusCode: 500));

      expect(datasource.getOrders(), throwsA(isA<ServerException>()));
    });

    test('propagates NetworkException', () async {
      when(
        mockApiClient.get(any, queryParameters: anyNamed('queryParameters')),
      ).thenThrow(NetworkException(message: 'No internet'));

      expect(datasource.getOrders(), throwsA(isA<NetworkException>()));
    });
  });

  // ── getOrderDetails ────────────────────────────────────
  group('getOrderDetails', () {
    test('returns order on success', () async {
      when(mockApiClient.get(any)).thenAnswer(
        (_) async => _makeResponse({'data': _makeOrderJson(id: 42)}),
      );

      final result = await datasource.getOrderDetails(42);
      expect(result.id, 42);
      expect(result.reference, 'REF-042');
    });

    test('throws Exception when data is null', () async {
      when(
        mockApiClient.get(any),
      ).thenAnswer((_) async => _makeResponse({'data': null}));

      expect(datasource.getOrderDetails(1), throwsException);
    });

    test('throws Exception when data is not a Map', () async {
      when(
        mockApiClient.get(any),
      ).thenAnswer((_) async => _makeResponse({'data': []}));

      expect(datasource.getOrderDetails(1), throwsException);
    });
  });

  // ── createOrder ────────────────────────────────────────
  group('createOrder', () {
    final items = const [
      OrderItemModel(
        productId: 1,
        name: 'Paracetamol',
        quantity: 2,
        unitPrice: 500.0,
        totalPrice: 1000.0,
      ),
    ];

    test('throws ValidationException when customer_phone is missing', () {
      final deliveryAddress = {'delivery_address': '123 Rue Test'};

      expect(
        datasource.createOrder(
          pharmacyId: 1,
          items: items,
          deliveryAddress: deliveryAddress,
          paymentMode: 'cash',
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('throws ValidationException when phone is empty string', () {
      final deliveryAddress = {
        'delivery_address': '123 Rue Test',
        'customer_phone': '',
      };

      expect(
        datasource.createOrder(
          pharmacyId: 1,
          items: items,
          deliveryAddress: deliveryAddress,
          paymentMode: 'cash',
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('creates order and fetches full details on success', () async {
      final deliveryAddress = {
        'customer_phone': '+24107000000',
        'delivery_address': '123 Rue Test',
      };

      when(mockApiClient.post(any, data: anyNamed('data'))).thenAnswer(
        (_) async => _makeResponse({
          'data': {'order_id': 99, 'status': 'pending', 'reference': 'REF-099'},
        }),
      );
      when(mockApiClient.get(any)).thenAnswer(
        (_) async => _makeResponse({'data': _makeOrderJson(id: 99)}),
      );

      final result = await datasource.createOrder(
        pharmacyId: 1,
        items: items,
        deliveryAddress: deliveryAddress,
        paymentMode: 'cash',
      );

      expect(result.id, 99);
    });

    test(
      'returns minimal order when getOrderDetails fails after create',
      () async {
        final deliveryAddress = {
          'customer_phone': '+24107000000',
          'delivery_address': '123 Rue Test',
        };

        when(mockApiClient.post(any, data: anyNamed('data'))).thenAnswer(
          (_) async => _makeResponse({
            'data': {
              'order_id': 77,
              'status': 'pending',
              'reference': 'REF-077',
            },
          }),
        );
        when(
          mockApiClient.get(any),
        ).thenThrow(Exception('details unavailable'));

        final result = await datasource.createOrder(
          pharmacyId: 1,
          items: items,
          deliveryAddress: deliveryAddress,
          paymentMode: 'cash',
        );

        expect(result.id, 77);
        expect(result.status, 'pending');
      },
    );

    test('throws Exception when post response data is invalid', () async {
      final deliveryAddress = {
        'customer_phone': '+24107000000',
        'delivery_address': '123 Rue Test',
      };

      when(
        mockApiClient.post(any, data: anyNamed('data')),
      ).thenAnswer((_) async => _makeResponse({'data': null}));

      expect(
        datasource.createOrder(
          pharmacyId: 1,
          items: items,
          deliveryAddress: deliveryAddress,
          paymentMode: 'cash',
        ),
        throwsException,
      );
    });

    test('accepts phone from "phone" fallback key', () async {
      final deliveryAddress = {
        'phone': '+24107000000',
        'delivery_address': '123 Rue Test',
      };

      when(mockApiClient.post(any, data: anyNamed('data'))).thenAnswer(
        (_) async => _makeResponse({
          'data': {'order_id': 55, 'status': 'pending', 'reference': 'REF-055'},
        }),
      );
      when(mockApiClient.get(any)).thenAnswer(
        (_) async => _makeResponse({'data': _makeOrderJson(id: 55)}),
      );

      final result = await datasource.createOrder(
        pharmacyId: 1,
        items: items,
        deliveryAddress: deliveryAddress,
        paymentMode: 'cash',
      );
      expect(result.id, 55);
    });
  });

  // ── cancelOrder ────────────────────────────────────────
  group('cancelOrder', () {
    test('completes without error on success', () async {
      when(
        mockApiClient.post(any, data: anyNamed('data')),
      ).thenAnswer((_) async => _makeResponse({'success': true}));

      await expectLater(
        datasource.cancelOrder(1, 'Customer changed mind'),
        completes,
      );
    });

    test('propagates exception on failure', () async {
      when(
        mockApiClient.post(any, data: anyNamed('data')),
      ).thenThrow(ServerException(message: 'Cannot cancel', statusCode: 422));

      expect(
        datasource.cancelOrder(1, 'reason'),
        throwsA(isA<ServerException>()),
      );
    });
  });

  // ── initiatePayment ────────────────────────────────────
  group('initiatePayment', () {
    test('maps redirect_url to payment_url', () async {
      when(mockApiClient.post(any, data: anyNamed('data'))).thenAnswer(
        (_) async => _makeResponse({
          'data': {
            'redirect_url': 'https://pay.example.com/pay',
            'reference': 'PAY-001',
          },
        }),
      );

      final result = await datasource.initiatePayment(
        orderId: 1,
        provider: 'stripe',
      );

      expect(result['payment_url'], 'https://pay.example.com/pay');
      expect(result['redirect_url'], 'https://pay.example.com/pay');
    });

    test(
      'preserves existing payment_url when redirect_url also present',
      () async {
        when(mockApiClient.post(any, data: anyNamed('data'))).thenAnswer(
          (_) async => _makeResponse({
            'data': {
              'redirect_url': 'https://pay.example.com/redirect',
              'payment_url': 'https://pay.example.com/original',
            },
          }),
        );

        final result = await datasource.initiatePayment(
          orderId: 1,
          provider: 'stripe',
        );

        // When payment_url already exists, redirect_url should not override
        expect(result['payment_url'], 'https://pay.example.com/original');
      },
    );

    test('throws Exception when payment data is null', () async {
      when(
        mockApiClient.post(any, data: anyNamed('data')),
      ).thenAnswer((_) async => _makeResponse({'data': null}));

      expect(
        datasource.initiatePayment(orderId: 1, provider: 'stripe'),
        throwsException,
      );
    });

    test('passes payment_method when provided', () async {
      when(mockApiClient.post(any, data: anyNamed('data'))).thenAnswer(
        (_) async => _makeResponse({
          'data': {'redirect_url': 'https://pay.example.com'},
        }),
      );

      await datasource.initiatePayment(
        orderId: 1,
        provider: 'mobile_money',
        paymentMethod: 'moov',
      );

      final capturedData =
          verify(
                mockApiClient.post(any, data: captureAnyNamed('data')),
              ).captured.first
              as Map<String, dynamic>;

      expect(capturedData['payment_method'], 'moov');
    });
  });

  // ── getTrackingInfo ────────────────────────────────────
  group('getTrackingInfo', () {
    test('returns delivery map when present', () async {
      when(mockApiClient.get(any)).thenAnswer(
        (_) async => _makeResponse({
          'data': {
            'id': 1,
            'delivery': {'status': 'in_transit', 'eta': '2024-01-02'},
          },
        }),
      );

      final result = await datasource.getTrackingInfo(1);
      expect(result, isNotNull);
      expect(result!['status'], 'in_transit');
    });

    test('returns null when delivery is absent', () async {
      when(mockApiClient.get(any)).thenAnswer(
        (_) async => _makeResponse({
          'data': {'id': 1},
        }),
      );

      final result = await datasource.getTrackingInfo(1);
      expect(result, isNull);
    });

    test('returns null when data is null', () async {
      when(
        mockApiClient.get(any),
      ).thenAnswer((_) async => _makeResponse({'data': null}));

      final result = await datasource.getTrackingInfo(1);
      expect(result, isNull);
    });
  });
}
