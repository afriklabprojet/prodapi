import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dartz/dartz.dart';

import 'package:drpharma_client/config/providers.dart';
import 'package:drpharma_client/core/errors/failures.dart';
import 'package:drpharma_client/core/network/api_client.dart';
import 'package:drpharma_client/features/prescriptions/presentation/providers/prescription_ocr_provider.dart';
import 'package:drpharma_client/features/products/domain/repositories/products_repository.dart';

// ─────────────────────────────────────────────────────────
// Mocks
// ─────────────────────────────────────────────────────────

class MockApiClient extends Mock implements ApiClient {}

class MockProductsRepository extends Mock implements ProductsRepository {}

// ─────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────

File _createTempFile() {
  final dir = Directory.systemTemp;
  final file = File(
    '${dir.path}/test_ocr_${DateTime.now().millisecondsSinceEpoch}.jpg',
  );
  file.writeAsBytesSync([255, 216, 255, 224]); // JPEG magic bytes
  return file;
}

void main() {
  late MockApiClient mockApiClient;
  late MockProductsRepository mockProductsRepository;
  late ProviderContainer container;

  setUp(() {
    mockApiClient = MockApiClient();
    mockProductsRepository = MockProductsRepository();

    container = ProviderContainer(
      overrides: [
        apiClientProvider.overrideWithValue(mockApiClient),
        productsRepositoryProvider.overrideWithValue(mockProductsRepository),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  group('PrescriptionOcrNotifier', () {
    // ── initial state ──────────────────────────────────────
    test('initial state has no results and not loading', () {
      final state = container.read(prescriptionOcrProvider);
      expect(state.isLoading, isFalse);
      expect(state.hasResults, isFalse);
      expect(state.error, isNull);
      expect(state.matchedProducts, isEmpty);
      expect(state.unmatchedMedications, isEmpty);
    });

    // ── clear ──────────────────────────────────────────────
    group('clear', () {
      test('resets state to initial', () async {
        final file = _createTempFile();
        addTearDown(() => file.deleteSync());

        when(
          () => mockApiClient.post(
            any(),
            data: any(named: 'data'),
            queryParameters: any(named: 'queryParameters'),
            options: any(named: 'options'),
          ),
        ).thenAnswer(
          (_) async => Response(
            requestOptions: RequestOptions(path: '/prescriptions/ocr'),
            statusCode: 200,
            data: {
              'matched_products': <dynamic>[],
              'unmatched_medications': ['Doliprane'],
              'confidence': 60.0,
              'raw_text': 'some text',
            },
          ),
        );

        await container
            .read(prescriptionOcrProvider.notifier)
            .analyzeImage(file);

        expect(container.read(prescriptionOcrProvider).hasResults, isTrue);

        container.read(prescriptionOcrProvider.notifier).clear();

        final state = container.read(prescriptionOcrProvider);
        expect(state.isLoading, isFalse);
        expect(state.hasResults, isFalse);
        expect(state.error, isNull);
      });
    });

    // ── analyzeImage ───────────────────────────────────────
    group('analyzeImage', () {
      test('success — no matched, some unmatched', () async {
        final file = _createTempFile();
        addTearDown(() => file.deleteSync());

        when(
          () => mockApiClient.post(
            any(),
            data: any(named: 'data'),
            queryParameters: any(named: 'queryParameters'),
            options: any(named: 'options'),
          ),
        ).thenAnswer(
          (_) async => Response(
            requestOptions: RequestOptions(path: '/prescriptions/ocr'),
            statusCode: 200,
            data: {
              'matched_products': <dynamic>[],
              'unmatched_medications': ['Aspirin', 'Ibuprofène'],
              'confidence': 75.0,
              'raw_text': 'Prendre Aspirin',
            },
          ),
        );

        await container
            .read(prescriptionOcrProvider.notifier)
            .analyzeImage(file);

        final state = container.read(prescriptionOcrProvider);
        expect(state.isLoading, isFalse);
        expect(state.matchedProducts, isEmpty);
        expect(state.unmatchedMedications, ['Aspirin', 'Ibuprofène']);
        expect(state.confidence, 75.0);
        expect(state.rawText, 'Prendre Aspirin');
        expect(state.error, isNull);
      });

      test('success — matched product without productId', () async {
        final file = _createTempFile();
        addTearDown(() => file.deleteSync());

        when(
          () => mockApiClient.post(
            any(),
            data: any(named: 'data'),
            queryParameters: any(named: 'queryParameters'),
            options: any(named: 'options'),
          ),
        ).thenAnswer(
          (_) async => Response(
            requestOptions: RequestOptions(path: '/prescriptions/ocr'),
            statusCode: 200,
            data: {
              'matched_products': [
                {
                  'name': 'Doliprane',
                  'dosage': '500mg',
                  'confidence': 0.9,
                  // no product_id
                },
              ],
              'unmatched_medications': <dynamic>[],
              'confidence': 90.0,
            },
          ),
        );

        await container
            .read(prescriptionOcrProvider.notifier)
            .analyzeImage(file);

        final state = container.read(prescriptionOcrProvider);
        expect(state.matchedProducts.length, 1);
        expect(state.matchedProducts[0].name, 'Doliprane');
        expect(state.matchedProducts[0].productId, isNull);
      });

      test(
        'success — matched product with productId loads product details',
        () async {
          final file = _createTempFile();
          addTearDown(() => file.deleteSync());

          when(
            () => mockApiClient.post(
              any(),
              data: any(named: 'data'),
              queryParameters: any(named: 'queryParameters'),
              options: any(named: 'options'),
            ),
          ).thenAnswer(
            (_) async => Response(
              requestOptions: RequestOptions(path: '/prescriptions/ocr'),
              statusCode: 200,
              data: {
                'matched_products': [
                  {'name': 'Paracétamol', 'confidence': 0.95, 'product_id': 99},
                ],
                'unmatched_medications': <dynamic>[],
                'confidence': 95.0,
              },
            ),
          );

          // Product repo returns failure → falls back to keeping medication without product
          when(() => mockProductsRepository.getProductDetails(99)).thenAnswer(
            (_) async => const Left(ServerFailure(message: 'Not found')),
          );

          await container
              .read(prescriptionOcrProvider.notifier)
              .analyzeImage(file);

          final state = container.read(prescriptionOcrProvider);
          expect(state.matchedProducts.length, 1);
          expect(state.matchedProducts[0].productId, 99);
          expect(state.matchedProducts[0].product, isNull);
        },
      );

      test('non-200 response — sets error', () async {
        final file = _createTempFile();
        addTearDown(() => file.deleteSync());

        when(
          () => mockApiClient.post(
            any(),
            data: any(named: 'data'),
            queryParameters: any(named: 'queryParameters'),
            options: any(named: 'options'),
          ),
        ).thenAnswer(
          (_) async => Response(
            requestOptions: RequestOptions(path: '/prescriptions/ocr'),
            statusCode: 422,
            data: null,
          ),
        );

        await container
            .read(prescriptionOcrProvider.notifier)
            .analyzeImage(file);

        final state = container.read(prescriptionOcrProvider);
        expect(state.isLoading, isFalse);
        expect(state.error, isNotNull);
      });

      test('exception — sets error message', () async {
        final file = _createTempFile();
        addTearDown(() => file.deleteSync());

        when(
          () => mockApiClient.post(
            any(),
            data: any(named: 'data'),
            queryParameters: any(named: 'queryParameters'),
            options: any(named: 'options'),
          ),
        ).thenThrow(Exception('Connection error'));

        await container
            .read(prescriptionOcrProvider.notifier)
            .analyzeImage(file);

        final state = container.read(prescriptionOcrProvider);
        expect(state.isLoading, isFalse);
        expect(state.error, isNotNull);
        expect(state.error, contains('connexion'));
      });

      test('unmatched as map with name field', () async {
        final file = _createTempFile();
        addTearDown(() => file.deleteSync());

        when(
          () => mockApiClient.post(
            any(),
            data: any(named: 'data'),
            queryParameters: any(named: 'queryParameters'),
            options: any(named: 'options'),
          ),
        ).thenAnswer(
          (_) async => Response(
            requestOptions: RequestOptions(path: '/prescriptions/ocr'),
            statusCode: 200,
            data: {
              'matched_products': <dynamic>[],
              'unmatched_medications': [
                {'name': 'Morphine'},
                {'name': ''},
              ],
              'confidence': 50.0,
            },
          ),
        );

        await container
            .read(prescriptionOcrProvider.notifier)
            .analyzeImage(file);

        final state = container.read(prescriptionOcrProvider);
        // Empty-name entries are filtered out
        expect(state.unmatchedMedications, ['Morphine']);
      });
    });
  });
}
