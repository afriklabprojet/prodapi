import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:drpharma_client/core/network/api_client.dart';
import 'package:drpharma_client/features/addresses/domain/entities/address_entity.dart';
import 'package:drpharma_client/features/orders/presentation/providers/delivery_fee_notifier.dart';

// ─────────────────────────────────────────────────────────
// Fake ApiClient
// ─────────────────────────────────────────────────────────

class _FakeApiClient extends ApiClient {
  Map<String, dynamic> _nextData = {};
  Exception? _nextError;

  _FakeApiClient() : super(enableCertificatePinning: false);

  void stubPost(Map<String, dynamic> data) {
    _nextData = data;
    _nextError = null;
  }

  void failPost(Exception e) {
    _nextError = e;
  }

  @override
  Future<Response> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    if (_nextError != null) {
      final e = _nextError!;
      _nextError = null;
      throw e;
    }
    return Response(
      requestOptions: RequestOptions(path: path),
      statusCode: 200,
      data: _nextData,
    );
  }
}

// ─────────────────────────────────────────────────────────
// Test address helper
// ─────────────────────────────────────────────────────────

AddressEntity _makeAddress({
  double lat = 5.3484,
  double lng = -4.0167,
  String? city = 'Abidjan',
}) => AddressEntity(
  id: 1,
  label: 'Domicile',
  address: '123 Rue Test',
  city: city,
  latitude: lat,
  longitude: lng,
  isDefault: true,
  fullAddress: '123 Rue Test, Abidjan',
  hasCoordinates: true,
  createdAt: DateTime(2024),
  updatedAt: DateTime(2024),
);

void main() {
  group('DeliveryFeeNotifier', () {
    late _FakeApiClient fakeApiClient;
    late DeliveryFeeNotifier notifier;

    setUp(() {
      fakeApiClient = _FakeApiClient();
      notifier = DeliveryFeeNotifier(apiClient: fakeApiClient);
    });

    // ── initial state ──────────────────────────────────────
    group('initial state', () {
      test('fee is null', () => expect(notifier.state.fee, isNull));
      test(
        'isLoading is false',
        () => expect(notifier.state.isLoading, isFalse),
      );
      test('error is null', () => expect(notifier.state.error, isNull));
      test(
        'lastDistanceKm is null',
        () => expect(notifier.lastDistanceKm, isNull),
      );
    });

    // ── DeliveryFeeState model ─────────────────────────────
    group('DeliveryFeeState model', () {
      test('copyWith updates fee', () {
        const s = DeliveryFeeState();
        final next = s.copyWith(fee: 1500.0);
        expect(next.fee, 1500.0);
      });

      test('copyWith clearFee resets fee to null', () {
        const s = DeliveryFeeState(fee: 500.0);
        final next = s.copyWith(clearFee: true);
        expect(next.fee, isNull);
      });

      test('copyWith clearError resets error to null', () {
        const s = DeliveryFeeState(error: 'oops');
        final next = s.copyWith(clearError: true);
        expect(next.error, isNull);
      });
    });

    // ── estimateDeliveryFee ────────────────────────────────
    group('estimateDeliveryFee', () {
      test('success — reads delivery_fee directly', () async {
        fakeApiClient.stubPost({'delivery_fee': 1200, 'distance_km': 3.5});

        await notifier.estimateDeliveryFee(address: _makeAddress());

        expect(notifier.state.isLoading, isFalse);
        expect(notifier.state.fee, 1200.0);
        expect(notifier.state.error, isNull);
        expect(notifier.lastDistanceKm, 3.5);
      });

      test('success — reads delivery_fee from data wrapper', () async {
        fakeApiClient.stubPost({
          'data': {'delivery_fee': 800},
        });

        await notifier.estimateDeliveryFee(address: _makeAddress());

        expect(notifier.state.fee, 800.0);
      });

      test('success — defaults to 0.0 when fee missing', () async {
        fakeApiClient.stubPost({'some_other_field': 'value'});

        await notifier.estimateDeliveryFee(address: _makeAddress());

        expect(notifier.state.fee, 0.0);
        expect(notifier.lastDistanceKm, isNull);
      });

      test('success — address without city omits city field', () async {
        fakeApiClient.stubPost({'delivery_fee': 500.0});

        // Should not throw even without city
        await notifier.estimateDeliveryFee(address: _makeAddress(city: null));

        expect(notifier.state.fee, 500.0);
      });

      test('error — sets error message and clears loading', () async {
        fakeApiClient.failPost(Exception('Network error'));

        await notifier.estimateDeliveryFee(address: _makeAddress());

        expect(notifier.state.isLoading, isFalse);
        expect(notifier.state.fee, isNull);
        expect(notifier.state.error, isNotNull);
      });

      test('transitions through loading state', () async {
        fakeApiClient.stubPost({'delivery_fee': 600.0});

        final loadingStates = <bool>[];
        notifier.addListener((s) => loadingStates.add(s.isLoading));

        await notifier.estimateDeliveryFee(address: _makeAddress());

        expect(loadingStates, contains(true));
        expect(loadingStates.last, isFalse);
      });

      test('clears previous error on new estimate', () async {
        // First call fails
        fakeApiClient.failPost(Exception('err'));
        await notifier.estimateDeliveryFee(address: _makeAddress());
        expect(notifier.state.error, isNotNull);

        // Second call succeeds
        fakeApiClient.stubPost({'delivery_fee': 300.0});
        await notifier.estimateDeliveryFee(address: _makeAddress());
        expect(notifier.state.error, isNull);
        expect(notifier.state.fee, 300.0);
      });
    });

    // ── reset ──────────────────────────────────────────────
    group('reset', () {
      test('resets all state to defaults', () async {
        fakeApiClient.stubPost({'delivery_fee': 900.0, 'distance_km': 5.0});
        await notifier.estimateDeliveryFee(address: _makeAddress());
        expect(notifier.state.fee, isNotNull);

        notifier.reset();

        expect(notifier.state.fee, isNull);
        expect(notifier.state.isLoading, isFalse);
        expect(notifier.state.error, isNull);
      });
    });
  });
}
