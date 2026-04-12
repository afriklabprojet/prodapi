import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:courier/data/repositories/statistics_repository.dart';
import 'package:courier/core/constants/api_constants.dart';
import '../../helpers/test_helpers.dart';

class MockDio extends Mock implements Dio {}

void main() {
  late MockDio mockDio;
  late StatisticsRepository repo;

  setUpAll(() async {
    await setupTestDependencies();
  });

  setUp(() {
    mockDio = MockDio();
    repo = StatisticsRepository(mockDio);
  });

  group('getStatistics', () {
    test('throws on 403 with COURIER_PROFILE_NOT_FOUND', () async {
      when(() => mockDio.get(
            ApiConstants.statistics,
            queryParameters: any(named: 'queryParameters'),
          )).thenThrow(DioException(
        requestOptions: RequestOptions(path: ''),
        type: DioExceptionType.badResponse,
        response: Response(
          statusCode: 403,
          data: {
            'message': 'Not found',
            'error_code': 'COURIER_PROFILE_NOT_FOUND',
          },
          requestOptions: RequestOptions(path: ''),
        ),
      ));

      expect(
        () => repo.getStatistics(),
        throwsA(predicate<Exception>(
          (e) => e.toString().contains('Profil coursier non trouvé'),
        )),
      );
    });

    test('throws on 403 generic', () async {
      when(() => mockDio.get(
            ApiConstants.statistics,
            queryParameters: any(named: 'queryParameters'),
          )).thenThrow(DioException(
        requestOptions: RequestOptions(path: ''),
        type: DioExceptionType.badResponse,
        response: Response(
          statusCode: 403,
          data: {'message': 'Accès refusé'},
          requestOptions: RequestOptions(path: ''),
        ),
      ));

      expect(
        () => repo.getStatistics(),
        throwsA(predicate<Exception>(
          (e) => e.toString().contains('Accès refusé'),
        )),
      );
    });

    test('throws on 401', () async {
      when(() => mockDio.get(
            ApiConstants.statistics,
            queryParameters: any(named: 'queryParameters'),
          )).thenThrow(DioException(
        requestOptions: RequestOptions(path: ''),
        type: DioExceptionType.badResponse,
        response: Response(
          statusCode: 401,
          requestOptions: RequestOptions(path: ''),
        ),
      ));

      expect(
        () => repo.getStatistics(),
        throwsA(predicate<Exception>(
          (e) => e.toString().contains('Session expirée'),
        )),
      );
    });

    test('throws generic on non-dio errors', () async {
      when(() => mockDio.get(
            ApiConstants.statistics,
            queryParameters: any(named: 'queryParameters'),
          )).thenThrow(Exception('random error'));

      expect(
        () => repo.getStatistics(),
        throwsA(predicate<Exception>(
          (e) => e.toString().contains('Impossible de charger'),
        )),
      );
    });
  });
}
