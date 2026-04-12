import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:courier/data/repositories/delivery_repository.dart';
import 'package:courier/core/constants/api_constants.dart';

class MockDio extends Mock implements Dio {}

void main() {
  late MockDio mockDio;
  late DeliveryRepository repo;

  setUp(() {
    mockDio = MockDio();
    repo = DeliveryRepository(mockDio);
  });

  group('getDeliveries', () {
    test('returns list of deliveries on success', () async {
      when(
        () => mockDio.get(
          ApiConstants.deliveries,
          queryParameters: any(named: 'queryParameters'),
        ),
      ).thenAnswer(
        (_) async => Response(
          data: {
            'data': [
              {
                'id': 1,
                'reference': 'DEL-001',
                'pharmacy_name': 'Pharma Test',
                'pharmacy_address': 'Addr',
                'customer_name': 'Client',
                'delivery_address': 'Addr 2',
                'total_amount': 5000.0,
                'status': 'pending',
              },
            ],
          },
          statusCode: 200,
          requestOptions: RequestOptions(path: ''),
        ),
      );

      final result = await repo.getDeliveries();
      expect(result.length, 1);
      expect(result.first.reference, 'DEL-001');
    });

    test('returns empty list when data is not a list', () async {
      when(
        () => mockDio.get(
          ApiConstants.deliveries,
          queryParameters: any(named: 'queryParameters'),
        ),
      ).thenAnswer(
        (_) async => Response(
          data: {'data': null},
          statusCode: 200,
          requestOptions: RequestOptions(path: ''),
        ),
      );

      final result = await repo.getDeliveries();
      expect(result, isEmpty);
    });

    test('throws on error', () async {
      when(
        () => mockDio.get(
          ApiConstants.deliveries,
          queryParameters: any(named: 'queryParameters'),
        ),
      ).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: ''),
          type: DioExceptionType.badResponse,
          response: Response(
            statusCode: 500,
            requestOptions: RequestOptions(path: ''),
          ),
        ),
      );

      expect(() => repo.getDeliveries(), throwsA(isA<Exception>()));
    });
  });

  group('getDeliveryById', () {
    test('returns delivery on success', () async {
      when(() => mockDio.get(ApiConstants.deliveryShow(1))).thenAnswer(
        (_) async => Response(
          data: {
            'data': {
              'id': 1,
              'reference': 'DEL-001',
              'pharmacy_name': 'Pharma',
              'pharmacy_address': 'Addr',
              'customer_name': 'Client',
              'delivery_address': 'Addr',
              'total_amount': 5000.0,
              'status': 'pending',
            },
          },
          statusCode: 200,
          requestOptions: RequestOptions(path: ''),
        ),
      );

      final result = await repo.getDeliveryById(1);
      expect(result.id, 1);
    });

    test('throws on null data', () async {
      when(() => mockDio.get(ApiConstants.deliveryShow(1))).thenAnswer(
        (_) async => Response(
          data: {'data': null},
          statusCode: 200,
          requestOptions: RequestOptions(path: ''),
        ),
      );

      expect(() => repo.getDeliveryById(1), throwsA(isA<Exception>()));
    });
  });

  group('acceptDelivery', () {
    test('calls post on correct endpoint', () async {
      when(() => mockDio.post(ApiConstants.acceptDelivery(1))).thenAnswer(
        (_) async => Response(
          data: {'success': true},
          statusCode: 200,
          requestOptions: RequestOptions(path: ''),
        ),
      );

      await repo.acceptDelivery(1);
      verify(() => mockDio.post(ApiConstants.acceptDelivery(1))).called(1);
    });

    test('throws on error', () async {
      when(() => mockDio.post(ApiConstants.acceptDelivery(1))).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: ''),
          type: DioExceptionType.badResponse,
          response: Response(
            statusCode: 400,
            requestOptions: RequestOptions(path: ''),
          ),
        ),
      );

      expect(() => repo.acceptDelivery(1), throwsA(isA<Exception>()));
    });
  });

  group('pickupDelivery', () {
    test('throws on 400', () async {
      when(() => mockDio.post(ApiConstants.pickupDelivery(1))).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: ''),
          type: DioExceptionType.badResponse,
          response: Response(
            statusCode: 400,
            data: {'message': 'Non disponible'},
            requestOptions: RequestOptions(path: ''),
          ),
        ),
      );

      expect(
        () => repo.pickupDelivery(1),
        throwsA(
          predicate<Exception>((e) => e.toString().contains('Non disponible')),
        ),
      );
    });

    test('throws on 403', () async {
      when(() => mockDio.post(ApiConstants.pickupDelivery(1))).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: ''),
          type: DioExceptionType.badResponse,
          response: Response(
            statusCode: 403,
            requestOptions: RequestOptions(path: ''),
          ),
        ),
      );

      expect(
        () => repo.pickupDelivery(1),
        throwsA(predicate<Exception>((e) => e.toString().contains('autorisé'))),
      );
    });

    test('throws on 404', () async {
      when(() => mockDio.post(ApiConstants.pickupDelivery(1))).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: ''),
          type: DioExceptionType.badResponse,
          response: Response(
            statusCode: 404,
            requestOptions: RequestOptions(path: ''),
          ),
        ),
      );

      expect(
        () => repo.pickupDelivery(1),
        throwsA(
          predicate<Exception>((e) => e.toString().contains('introuvable')),
        ),
      );
    });
  });
}
