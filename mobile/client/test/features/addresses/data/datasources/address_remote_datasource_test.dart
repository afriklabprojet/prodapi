import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'package:drpharma_client/core/network/api_client.dart';
import 'package:drpharma_client/features/addresses/data/datasources/address_remote_datasource.dart';
import 'package:drpharma_client/core/errors/exceptions.dart';

@GenerateMocks([ApiClient])
import 'address_remote_datasource_test.mocks.dart';

// ─── Helpers ──────────────────────────────────────────────

Response<dynamic> _makeResponse(dynamic data) => Response(
  requestOptions: RequestOptions(path: '/test'),
  data: data,
  statusCode: 200,
);

Map<String, dynamic> _makeAddressJson({int id = 1, String label = 'Maison'}) =>
    {
      'id': id,
      'label': label,
      'address': '123 Rue Test, Yaoundé',
      'city': 'Yaoundé',
      'phone': '+24100000000',
      'is_default': false,
      'full_address': '123 Rue Test, Yaoundé',
      'has_coordinates': false,
      'created_at': '2024-01-01T00:00:00.000Z',
      'updated_at': '2024-01-01T00:00:00.000Z',
    };

void main() {
  late AddressRemoteDataSource datasource;
  late MockApiClient mockApiClient;

  setUp(() {
    mockApiClient = MockApiClient();
    datasource = AddressRemoteDataSource(mockApiClient);
  });

  // ── getAddresses ───────────────────────────────────────
  group('getAddresses', () {
    test('returns list of addresses on success', () async {
      when(mockApiClient.get(any)).thenAnswer(
        (_) async => _makeResponse({
          'data': [
            _makeAddressJson(id: 1, label: 'Maison'),
            _makeAddressJson(id: 2, label: 'Bureau'),
          ],
        }),
      );

      final result = await datasource.getAddresses();
      expect(result.length, 2);
      expect(result[0].label, 'Maison');
      expect(result[1].label, 'Bureau');
    });

    test('returns empty list when data is empty', () async {
      when(
        mockApiClient.get(any),
      ).thenAnswer((_) async => _makeResponse({'data': []}));

      final result = await datasource.getAddresses();
      expect(result, isEmpty);
    });

    test('returns empty list when data is null', () async {
      when(
        mockApiClient.get(any),
      ).thenAnswer((_) async => _makeResponse({'data': null}));

      final result = await datasource.getAddresses();
      expect(result, isEmpty);
    });

    test('propagates exception on API error', () async {
      when(
        mockApiClient.get(any),
      ).thenThrow(ServerException(message: 'Error', statusCode: 500));

      expect(datasource.getAddresses(), throwsA(isA<ServerException>()));
    });
  });

  // ── getAddress ─────────────────────────────────────────
  group('getAddress', () {
    test('returns address on success', () async {
      when(mockApiClient.get(any)).thenAnswer(
        (_) async =>
            _makeResponse({'data': _makeAddressJson(id: 42, label: 'Famille')}),
      );

      final result = await datasource.getAddress(42);
      expect(result.id, 42);
      expect(result.label, 'Famille');
    });

    test('propagates exception on API error', () async {
      when(
        mockApiClient.get(any),
      ).thenThrow(ServerException(message: 'Not found', statusCode: 404));

      expect(datasource.getAddress(999), throwsA(isA<ServerException>()));
    });
  });

  // ── getDefaultAddress ──────────────────────────────────
  group('getDefaultAddress', () {
    test('returns default address on success', () async {
      when(mockApiClient.get(any)).thenAnswer(
        (_) async => _makeResponse({
          'data': {..._makeAddressJson(id: 1), 'is_default': true},
        }),
      );

      final result = await datasource.getDefaultAddress();
      expect(result.isDefault, true);
    });

    test('propagates exception on API error', () async {
      when(
        mockApiClient.get(any),
      ).thenThrow(ServerException(message: 'No default', statusCode: 404));

      expect(datasource.getDefaultAddress(), throwsA(isA<ServerException>()));
    });
  });

  // ── createAddress ──────────────────────────────────────
  group('createAddress', () {
    test('returns created address on success', () async {
      when(mockApiClient.post(any, data: anyNamed('data'))).thenAnswer(
        (_) async =>
            _makeResponse({'data': _makeAddressJson(id: 10, label: 'Travail')}),
      );

      final result = await datasource.createAddress(
        label: 'Travail',
        address: '456 Avenue du Travail',
        city: 'Douala',
        phone: '+24100000001',
      );

      expect(result.id, 10);
      expect(result.label, 'Travail');
    });

    test('sends correct data to API', () async {
      when(mockApiClient.post(any, data: anyNamed('data'))).thenAnswer(
        (_) async => _makeResponse({'data': _makeAddressJson(id: 5)}),
      );

      await datasource.createAddress(
        label: 'Maison',
        address: '789 Rue de la Paix',
        isDefault: true,
      );

      final captured =
          verify(
                mockApiClient.post(any, data: captureAnyNamed('data')),
              ).captured.first
              as Map<String, dynamic>;

      expect(captured['label'], 'Maison');
      expect(captured['address'], '789 Rue de la Paix');
      expect(captured['is_default'], true);
    });

    test('propagates exception on API error', () async {
      when(mockApiClient.post(any, data: anyNamed('data'))).thenThrow(
        ValidationException(
          errors: {
            'address': ['Adresse requise'],
          },
        ),
      );

      expect(
        datasource.createAddress(label: 'Test', address: ''),
        throwsA(isA<ValidationException>()),
      );
    });
  });

  // ── updateAddress ──────────────────────────────────────
  group('updateAddress', () {
    test('returns updated address on success', () async {
      when(mockApiClient.put(any, data: anyNamed('data'))).thenAnswer(
        (_) async => _makeResponse({
          'data': {..._makeAddressJson(id: 7), 'label': 'Bureau Mis à Jour'},
        }),
      );

      final result = await datasource.updateAddress(
        id: 7,
        label: 'Bureau Mis à Jour',
      );

      expect(result.label, 'Bureau Mis à Jour');
    });

    test('sends only provided fields', () async {
      when(mockApiClient.put(any, data: anyNamed('data'))).thenAnswer(
        (_) async => _makeResponse({'data': _makeAddressJson(id: 3)}),
      );

      await datasource.updateAddress(id: 3, city: 'Bafoussam');

      final captured =
          verify(
                mockApiClient.put(any, data: captureAnyNamed('data')),
              ).captured.first
              as Map<String, dynamic>;

      expect(captured['city'], 'Bafoussam');
      expect(captured.containsKey('label'), false);
    });

    test('propagates exception on API error', () async {
      when(
        mockApiClient.put(any, data: anyNamed('data')),
      ).thenThrow(ServerException(message: 'Error', statusCode: 500));

      expect(
        datasource.updateAddress(id: 1, label: 'New Label'),
        throwsA(isA<ServerException>()),
      );
    });
  });

  // ── deleteAddress ──────────────────────────────────────
  group('deleteAddress', () {
    test('completes without error on success', () async {
      when(
        mockApiClient.delete(any),
      ).thenAnswer((_) async => _makeResponse({'success': true}));

      await expectLater(datasource.deleteAddress(1), completes);
    });

    test('propagates exception on failure', () async {
      when(
        mockApiClient.delete(any),
      ).thenThrow(ServerException(message: 'Not found', statusCode: 404));

      expect(datasource.deleteAddress(999), throwsA(isA<ServerException>()));
    });
  });

  // ── setDefaultAddress ──────────────────────────────────
  group('setDefaultAddress', () {
    test('returns updated default address on success', () async {
      when(mockApiClient.post(any)).thenAnswer(
        (_) async => _makeResponse({
          'data': {..._makeAddressJson(id: 5), 'is_default': true},
        }),
      );

      final result = await datasource.setDefaultAddress(5);
      expect(result.isDefault, true);
    });

    test('propagates exception on failure', () async {
      when(
        mockApiClient.post(any),
      ).thenThrow(ServerException(message: 'Error', statusCode: 422));

      expect(datasource.setDefaultAddress(1), throwsA(isA<ServerException>()));
    });
  });

  // ── getLabels ──────────────────────────────────────────
  group('getLabels', () {
    test('returns labels from new format (object)', () async {
      when(mockApiClient.get(any)).thenAnswer(
        (_) async => _makeResponse({
          'data': {
            'labels': ['Maison', 'Bureau', 'Famille'],
            'default_phone': '+24100000000',
            'user_name': 'Jean Dupont',
          },
        }),
      );

      final result = await datasource.getLabels();
      expect(result.labels, ['Maison', 'Bureau', 'Famille']);
      expect(result.defaultPhone, '+24100000000');
      expect(result.userName, 'Jean Dupont');
    });

    test('returns labels from legacy format (list)', () async {
      when(mockApiClient.get(any)).thenAnswer(
        (_) async => _makeResponse({
          'data': ['Maison', 'Bureau', 'Autre'],
        }),
      );

      final result = await datasource.getLabels();
      expect(result.labels, ['Maison', 'Bureau', 'Autre']);
    });

    test('returns default labels when data format is unrecognized', () async {
      when(
        mockApiClient.get(any),
      ).thenAnswer((_) async => _makeResponse({'data': null}));

      final result = await datasource.getLabels();
      expect(result.labels, isNotEmpty);
    });

    test('propagates exception on API error', () async {
      when(
        mockApiClient.get(any),
      ).thenThrow(ServerException(message: 'Error', statusCode: 500));

      expect(datasource.getLabels(), throwsA(isA<ServerException>()));
    });
  });
}
