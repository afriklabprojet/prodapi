import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'package:drpharma_client/core/network/api_client.dart';
import 'package:drpharma_client/features/products/data/datasources/products_remote_datasource.dart';
import 'package:drpharma_client/core/errors/exceptions.dart';

@GenerateMocks([ApiClient])
import 'products_remote_datasource_test.mocks.dart';

// ─── Helpers ──────────────────────────────────────────────

Response<dynamic> _makeResponse(dynamic data) => Response(
  requestOptions: RequestOptions(path: '/test'),
  data: data,
  statusCode: 200,
);

Map<String, dynamic> _makePharmacyJson({int id = 1}) => {
  'id': id,
  'name': 'Pharmacie Test',
  'address': '123 Rue Test',
  'phone': '+24107000000',
  'status': 'active',
  'is_open': true,
};

Map<String, dynamic> _makeProductJson({
  int id = 1,
  String name = 'Paracetamol',
}) => {
  'id': id,
  'name': name,
  'price': 500.0,
  'stock_quantity': 10,
  'requires_prescription': false,
  'pharmacy': _makePharmacyJson(),
  'created_at': '2024-01-01T00:00:00.000Z',
  'updated_at': '2024-01-01T00:00:00.000Z',
};

void main() {
  late ProductsRemoteDataSource datasource;
  late MockApiClient mockApiClient;

  setUp(() {
    mockApiClient = MockApiClient();
    datasource = ProductsRemoteDataSource(mockApiClient);
  });

  // ── getProducts ────────────────────────────────────────
  group('getProducts', () {
    test('returns list of products on success', () async {
      when(
        mockApiClient.get(any, queryParameters: anyNamed('queryParameters')),
      ).thenAnswer(
        (_) async => _makeResponse({
          'data': [
            _makeProductJson(id: 1, name: 'Paracetamol'),
            _makeProductJson(id: 2, name: 'Ibuprofène'),
          ],
        }),
      );

      final result = await datasource.getProducts();
      expect(result.length, 2);
      expect(result[0].name, 'Paracetamol');
      expect(result[1].name, 'Ibuprofène');
    });

    test('handles nested data structure (data.data)', () async {
      when(
        mockApiClient.get(any, queryParameters: anyNamed('queryParameters')),
      ).thenAnswer(
        (_) async => _makeResponse({
          'data': {
            'data': [_makeProductJson(id: 1)],
          },
        }),
      );

      final result = await datasource.getProducts();
      expect(result.length, 1);
    });

    test('returns empty list when data is empty', () async {
      when(
        mockApiClient.get(any, queryParameters: anyNamed('queryParameters')),
      ).thenAnswer((_) async => _makeResponse({'data': []}));

      final result = await datasource.getProducts();
      expect(result, isEmpty);
    });

    test('propagates exception when no cache', () async {
      when(
        mockApiClient.get(any, queryParameters: anyNamed('queryParameters')),
      ).thenThrow(NetworkException(message: 'No internet'));

      expect(datasource.getProducts(), throwsA(isA<NetworkException>()));
    });

    test('passes pagination params', () async {
      when(
        mockApiClient.get(any, queryParameters: anyNamed('queryParameters')),
      ).thenAnswer((_) async => _makeResponse({'data': []}));

      await datasource.getProducts(page: 3, perPage: 5);

      final captured =
          verify(
                mockApiClient.get(
                  any,
                  queryParameters: captureAnyNamed('queryParameters'),
                ),
              ).captured.first
              as Map<String, dynamic>;

      expect(captured['page'], 3);
      expect(captured['per_page'], 5);
    });
  });

  // ── getProductDetails ──────────────────────────────────
  group('getProductDetails', () {
    test('returns product details on success', () async {
      when(mockApiClient.get(any)).thenAnswer(
        (_) async =>
            _makeResponse({'data': _makeProductJson(id: 42, name: 'Aspirine')}),
      );

      final result = await datasource.getProductDetails(42);
      expect(result.id, 42);
      expect(result.name, 'Aspirine');
    });

    test('handles nested product key in response', () async {
      when(mockApiClient.get(any)).thenAnswer(
        (_) async => _makeResponse({
          'data': {'product': _makeProductJson(id: 99, name: 'Vitamines')},
        }),
      );

      final result = await datasource.getProductDetails(99);
      expect(result.name, 'Vitamines');
    });

    test('propagates exception on failure', () async {
      when(
        mockApiClient.get(any),
      ).thenThrow(ServerException(message: 'Not found', statusCode: 404));

      expect(
        datasource.getProductDetails(999),
        throwsA(isA<ServerException>()),
      );
    });
  });

  // ── searchProducts ─────────────────────────────────────
  group('searchProducts', () {
    test('returns search results on success', () async {
      when(
        mockApiClient.get(any, queryParameters: anyNamed('queryParameters')),
      ).thenAnswer(
        (_) async => _makeResponse({
          'data': [_makeProductJson(id: 1, name: 'Paracetamol 500mg')],
        }),
      );

      final result = await datasource.searchProducts(query: 'paracetamol');
      expect(result.length, 1);
      expect(result.first.name, 'Paracetamol 500mg');
    });

    test('passes query in params', () async {
      when(
        mockApiClient.get(any, queryParameters: anyNamed('queryParameters')),
      ).thenAnswer((_) async => _makeResponse({'data': []}));

      await datasource.searchProducts(query: 'doliprane');

      final captured =
          verify(
                mockApiClient.get(
                  any,
                  queryParameters: captureAnyNamed('queryParameters'),
                ),
              ).captured.first
              as Map<String, dynamic>;

      expect(captured['q'], 'doliprane');
    });

    test('propagates exception when no cache', () async {
      when(
        mockApiClient.get(any, queryParameters: anyNamed('queryParameters')),
      ).thenThrow(ServerException(message: 'Error', statusCode: 503));

      expect(
        datasource.searchProducts(query: 'test'),
        throwsA(isA<ServerException>()),
      );
    });
  });

  // ── getProductsByCategory ──────────────────────────────
  group('getProductsByCategory', () {
    test('returns products for category on success', () async {
      when(
        mockApiClient.get(any, queryParameters: anyNamed('queryParameters')),
      ).thenAnswer(
        (_) async => _makeResponse({
          'data': [_makeProductJson(id: 5, name: 'Antibiotique')],
        }),
      );

      final result = await datasource.getProductsByCategory(
        category: 'antibiotiques',
      );
      expect(result.length, 1);
      expect(result.first.name, 'Antibiotique');
    });

    test('propagates exception when no cache', () async {
      when(
        mockApiClient.get(any, queryParameters: anyNamed('queryParameters')),
      ).thenThrow(NetworkException(message: 'Offline'));

      expect(
        datasource.getProductsByCategory(category: 'vitamines'),
        throwsA(isA<NetworkException>()),
      );
    });
  });

  // ── getProductsByPharmacy ──────────────────────────────
  group('getProductsByPharmacy', () {
    test('returns products for pharmacy on success', () async {
      when(
        mockApiClient.get(any, queryParameters: anyNamed('queryParameters')),
      ).thenAnswer(
        (_) async => _makeResponse({
          'data': [_makeProductJson(id: 7, name: 'Doliprane')],
        }),
      );

      final result = await datasource.getProductsByPharmacy(pharmacyId: 1);
      expect(result.length, 1);
      expect(result.first.name, 'Doliprane');
    });

    test('propagates exception when no cache', () async {
      when(
        mockApiClient.get(any, queryParameters: anyNamed('queryParameters')),
      ).thenThrow(ServerException(message: 'Error', statusCode: 500));

      expect(
        datasource.getProductsByPharmacy(pharmacyId: 999),
        throwsA(isA<ServerException>()),
      );
    });
  });
}
