import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'package:drpharma_client/core/network/api_client.dart';
import 'package:drpharma_client/features/pharmacies/data/datasources/pharmacies_remote_datasource.dart';
import 'package:drpharma_client/core/errors/exceptions.dart';

@GenerateMocks([ApiClient])
import 'pharmacies_remote_datasource_test.mocks.dart';

// ─── Helpers ──────────────────────────────────────────────

Response<dynamic> _makeResponse(dynamic data) => Response(
  requestOptions: RequestOptions(path: '/test'),
  data: data,
  statusCode: 200,
);

Map<String, dynamic> _makePharmacyJson({
  int id = 1,
  String name = 'Pharmacie Test',
}) => {
  'id': id,
  'name': name,
  'address': '123 Rue Test',
  'phone': '+24107000000',
  'status': 'active',
  'is_open': true,
};

void main() {
  late PharmaciesRemoteDataSource datasource;
  late MockApiClient mockApiClient;

  setUp(() {
    mockApiClient = MockApiClient();
    datasource = PharmaciesRemoteDataSource(mockApiClient);
  });

  // ── getPharmacies ──────────────────────────────────────
  group('getPharmacies', () {
    test('returns list of pharmacies on success', () async {
      when(
        mockApiClient.get(any, queryParameters: anyNamed('queryParameters')),
      ).thenAnswer(
        (_) async => _makeResponse({
          'data': [
            _makePharmacyJson(id: 1, name: 'Pharmacie A'),
            _makePharmacyJson(id: 2, name: 'Pharmacie B'),
          ],
        }),
      );

      final result = await datasource.getPharmacies();
      expect(result.length, 2);
      expect(result[0].name, 'Pharmacie A');
      expect(result[1].name, 'Pharmacie B');
    });

    test('returns empty list when data is empty', () async {
      when(
        mockApiClient.get(any, queryParameters: anyNamed('queryParameters')),
      ).thenAnswer((_) async => _makeResponse({'data': []}));

      final result = await datasource.getPharmacies();
      expect(result, isEmpty);
    });

    test('returns empty list when data is null', () async {
      when(
        mockApiClient.get(any, queryParameters: anyNamed('queryParameters')),
      ).thenAnswer((_) async => _makeResponse({'data': null}));

      final result = await datasource.getPharmacies();
      expect(result, isEmpty);
    });

    test('propagates exception when no cache available', () async {
      when(
        mockApiClient.get(any, queryParameters: anyNamed('queryParameters')),
      ).thenThrow(NetworkException(message: 'No internet'));

      expect(datasource.getPharmacies(), throwsA(isA<NetworkException>()));
    });
  });

  // ── getNearbyPharmacies ────────────────────────────────
  group('getNearbyPharmacies', () {
    test('returns nearby pharmacies on success', () async {
      when(
        mockApiClient.get(any, queryParameters: anyNamed('queryParameters')),
      ).thenAnswer(
        (_) async => _makeResponse({
          'data': [_makePharmacyJson(id: 1, name: 'Nearby Pharmacy')],
        }),
      );

      final result = await datasource.getNearbyPharmacies(
        latitude: 3.848,
        longitude: 11.502,
        radius: 5.0,
      );
      expect(result.length, 1);
      expect(result.first.name, 'Nearby Pharmacy');
    });

    test('passes latitude, longitude, radius in query params', () async {
      when(
        mockApiClient.get(any, queryParameters: anyNamed('queryParameters')),
      ).thenAnswer((_) async => _makeResponse({'data': []}));

      await datasource.getNearbyPharmacies(
        latitude: 4.0,
        longitude: 9.7,
        radius: 10.0,
      );

      final captured =
          verify(
                mockApiClient.get(
                  any,
                  queryParameters: captureAnyNamed('queryParameters'),
                ),
              ).captured.first
              as Map<String, dynamic>;

      expect(captured['latitude'], 4.0);
      expect(captured['longitude'], 9.7);
      expect(captured['radius'], 10.0);
    });

    test('does not include radius when not provided', () async {
      when(
        mockApiClient.get(any, queryParameters: anyNamed('queryParameters')),
      ).thenAnswer((_) async => _makeResponse({'data': []}));

      await datasource.getNearbyPharmacies(latitude: 4.0, longitude: 9.7);

      final captured =
          verify(
                mockApiClient.get(
                  any,
                  queryParameters: captureAnyNamed('queryParameters'),
                ),
              ).captured.first
              as Map<String, dynamic>;

      expect(captured.containsKey('radius'), false);
    });

    test('propagates exception on failure', () async {
      when(
        mockApiClient.get(any, queryParameters: anyNamed('queryParameters')),
      ).thenThrow(ServerException(message: 'Error', statusCode: 500));

      expect(
        datasource.getNearbyPharmacies(latitude: 0.0, longitude: 0.0),
        throwsA(isA<ServerException>()),
      );
    });
  });

  // ── getOnDutyPharmacies ────────────────────────────────
  group('getOnDutyPharmacies', () {
    test('returns on-duty pharmacies on success', () async {
      when(
        mockApiClient.get(any, queryParameters: anyNamed('queryParameters')),
      ).thenAnswer(
        (_) async => _makeResponse({
          'data': [_makePharmacyJson(id: 3, name: 'Pharmacie de Garde')],
        }),
      );

      final result = await datasource.getOnDutyPharmacies();
      expect(result.length, 1);
      expect(result.first.name, 'Pharmacie de Garde');
    });

    test('propagates exception when no cache', () async {
      when(
        mockApiClient.get(any, queryParameters: anyNamed('queryParameters')),
      ).thenThrow(NetworkException(message: 'Offline'));

      expect(
        datasource.getOnDutyPharmacies(),
        throwsA(isA<NetworkException>()),
      );
    });
  });

  // ── getPharmacyDetails ─────────────────────────────────
  group('getPharmacyDetails', () {
    test('returns pharmacy details on success', () async {
      when(mockApiClient.get(any)).thenAnswer(
        (_) async => _makeResponse({
          'data': _makePharmacyJson(id: 42, name: 'Pharmacie Centrale'),
        }),
      );

      final result = await datasource.getPharmacyDetails(42);
      expect(result.id, 42);
      expect(result.name, 'Pharmacie Centrale');
    });

    test('propagates exception on failure', () async {
      when(
        mockApiClient.get(any),
      ).thenThrow(ServerException(message: 'Not found', statusCode: 404));

      expect(
        datasource.getPharmacyDetails(999),
        throwsA(isA<ServerException>()),
      );
    });
  });

  // ── getFeaturedPharmacies ──────────────────────────────
  group('getFeaturedPharmacies', () {
    test('returns featured pharmacies on success', () async {
      when(mockApiClient.get(any)).thenAnswer(
        (_) async => _makeResponse({
          'data': [_makePharmacyJson(id: 10, name: 'Featured Pharmacy')],
        }),
      );

      final result = await datasource.getFeaturedPharmacies();
      expect(result.length, 1);
      expect(result.first.name, 'Featured Pharmacy');
    });

    test('propagates exception when no cache', () async {
      when(
        mockApiClient.get(any),
      ).thenThrow(ServerException(message: 'Error', statusCode: 500));

      expect(
        datasource.getFeaturedPharmacies(),
        throwsA(isA<ServerException>()),
      );
    });
  });
}
