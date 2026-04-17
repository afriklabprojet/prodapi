import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:dio/dio.dart';

import 'package:drpharma_client/core/network/api_client.dart';
import 'package:drpharma_client/features/orders/data/repositories/pricing_repository_impl.dart';

@GenerateMocks([ApiClient])
import 'pricing_repository_impl_test.mocks.dart';

void main() {
  late MockApiClient mockApiClient;
  late PricingRepositoryImpl repository;

  setUp(() {
    mockApiClient = MockApiClient();
    repository = PricingRepositoryImpl(apiClient: mockApiClient);
  });

  group('PricingRepositoryImpl', () {
    group('getPricing', () {
      test('should return PricingConfigEntity on success', () async {
        // Arrange
        when(mockApiClient.get('/pricing')).thenAnswer(
          (_) async => Response(
            data: {
              'data': {
                'delivery': {
                  'base_fee': 250,
                  'fee_per_km': 150,
                  'min_fee': 400,
                  'max_fee': 6000,
                },
                'service': {
                  'service_fee': {
                    'enabled': true,
                    'percentage': 5,
                    'min': 200,
                    'max': 3000,
                  },
                  'payment_fee': {
                    'enabled': true,
                    'fixed_fee': 100,
                    'percentage': 2.0,
                  },
                },
              },
            },
            statusCode: 200,
            requestOptions: RequestOptions(path: '/pricing'),
          ),
        );

        // Act
        final result = await repository.getPricing();

        // Assert
        expect(result.isRight(), true);
        result.fold(
          (failure) => fail('Should not return failure'),
          (config) {
            expect(config.delivery.baseFee, 250);
            expect(config.delivery.feePerKm, 150);
            expect(config.service.serviceFee.percentage, 5);
          },
        );
        verify(mockApiClient.get('/pricing')).called(1);
      });

      test('should return defaults on API error', () async {
        // Arrange
        when(mockApiClient.get('/pricing')).thenThrow(
          DioException(
            requestOptions: RequestOptions(path: '/pricing'),
            type: DioExceptionType.badResponse,
          ),
        );

        // Act
        final result = await repository.getPricing();

        // Assert - Returns defaults instead of failure
        expect(result.isRight(), true);
        result.fold(
          (failure) => fail('Should return defaults, not failure'),
          (config) {
            expect(config.delivery.baseFee, 200);
            expect(config.delivery.feePerKm, 100);
            expect(config.service.serviceFee.percentage, 3);
          },
        );
      });
    });

    group('calculateFees', () {
      test('should return PricingCalculationEntity on success', () async {
        // Arrange
        when(mockApiClient.post('/pricing/calculate', data: anyNamed('data')))
            .thenAnswer(
          (_) async => Response(
            data: {
              'data': {
                'subtotal': 10000,
                'delivery_fee': 500,
                'service_fee': 300,
                'payment_fee': 200,
                'total_amount': 11000,
                'pharmacy_amount': 10000,
              },
            },
            statusCode: 200,
            requestOptions: RequestOptions(path: '/pricing/calculate'),
          ),
        );

        // Act
        final result = await repository.calculateFees(
          subtotal: 10000,
          deliveryFee: 500,
          paymentMode: 'mobile_money',
        );

        // Assert
        expect(result.isRight(), true);
        result.fold(
          (failure) => fail('Should not return failure'),
          (calculation) {
            expect(calculation.subtotal, 10000);
            expect(calculation.deliveryFee, 500);
            expect(calculation.serviceFee, 300);
            expect(calculation.totalAmount, 11000);
          },
        );
      });

      test('should return failure on API error', () async {
        // Arrange
        when(mockApiClient.post('/pricing/calculate', data: anyNamed('data')))
            .thenThrow(
          DioException(
            requestOptions: RequestOptions(path: '/pricing/calculate'),
            type: DioExceptionType.badResponse,
          ),
        );

        // Act
        final result = await repository.calculateFees(
          subtotal: 10000,
          deliveryFee: 500,
          paymentMode: 'cash',
        );

        // Assert
        expect(result.isLeft(), true);
        result.fold(
          (failure) => expect(failure.message, 'Erreur lors du calcul des frais'),
          (calculation) => fail('Should return failure'),
        );
      });
    });

    group('estimateDeliveryFee', () {
      test('should return delivery fee on success', () async {
        // Arrange
        when(mockApiClient.post('/pricing/delivery', data: anyNamed('data')))
            .thenAnswer(
          (_) async => Response(
            data: {
              'data': {
                'delivery_fee': 750,
              },
            },
            statusCode: 200,
            requestOptions: RequestOptions(path: '/pricing/delivery'),
          ),
        );

        // Act
        final result = await repository.estimateDeliveryFee(distanceKm: 5.0);

        // Assert
        expect(result.isRight(), true);
        result.fold(
          (failure) => fail('Should not return failure'),
          (fee) => expect(fee, 750),
        );
      });

      test('should return default fee on API error', () async {
        // Arrange
        when(mockApiClient.post('/pricing/delivery', data: anyNamed('data')))
            .thenThrow(
          DioException(
            requestOptions: RequestOptions(path: '/pricing/delivery'),
            type: DioExceptionType.badResponse,
          ),
        );

        // Act
        final result = await repository.estimateDeliveryFee(distanceKm: 5.0);

        // Assert - Returns default 300 instead of failure
        expect(result.isRight(), true);
        result.fold(
          (failure) => fail('Should return default fee, not failure'),
          (fee) => expect(fee, 300),
        );
      });

      test('should use default when delivery_fee is null', () async {
        // Arrange
        when(mockApiClient.post('/pricing/delivery', data: anyNamed('data')))
            .thenAnswer(
          (_) async => Response(
            data: {
              'data': {
                'delivery_fee': null,
              },
            },
            statusCode: 200,
            requestOptions: RequestOptions(path: '/pricing/delivery'),
          ),
        );

        // Act
        final result = await repository.estimateDeliveryFee(distanceKm: 3.0);

        // Assert
        expect(result.isRight(), true);
        result.fold(
          (failure) => fail('Should not return failure'),
          (fee) => expect(fee, 300),
        );
      });
    });
  });
}
