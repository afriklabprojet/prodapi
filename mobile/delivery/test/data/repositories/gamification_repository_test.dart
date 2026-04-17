import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:courier/data/repositories/gamification_repository.dart';

class MockDio extends Mock implements Dio {}

void main() {
  late MockDio mockDio;
  late GamificationRepository repo;

  setUp(() {
    mockDio = MockDio();
    repo = GamificationRepository(mockDio);
  });

  group('getGamificationData', () {
    test('throws on DioException', () async {
      when(() => mockDio.get('/courier/gamification')).thenThrow(DioException(
        requestOptions: RequestOptions(path: ''),
        type: DioExceptionType.badResponse,
        response: Response(
          statusCode: 500,
          data: {'message': 'Server error'},
          requestOptions: RequestOptions(path: ''),
        ),
      ));

      expect(
        () => repo.getGamificationData(),
        throwsA(predicate<Exception>(
          (e) => e.toString().contains('Server error'),
        )),
      );
    });
  });

  group('getLeaderboard', () {
    test('returns list on success', () async {
      when(() => mockDio.get(
            '/courier/leaderboard',
            queryParameters: any(named: 'queryParameters'),
          )).thenAnswer((_) async => Response(
            data: {
              'data': [
                {
                  'id': 1,
                  'name': 'Ali',
                  'rank': 1,
                  'score': 100,
                  'deliveries': 50,
                  'avatar_url': null,
                  'is_current_user': true,
                },
              ],
            },
            statusCode: 200,
            requestOptions: RequestOptions(path: ''),
          ));

      final result = await repo.getLeaderboard();
      expect(result.length, 1);
      expect(result.first.courierName, 'Ali');
    });

    test('returns empty list when data is null', () async {
      when(() => mockDio.get(
            '/courier/leaderboard',
            queryParameters: any(named: 'queryParameters'),
          )).thenAnswer((_) async => Response(
            data: {},
            statusCode: 200,
            requestOptions: RequestOptions(path: ''),
          ));

      final result = await repo.getLeaderboard();
      expect(result, isEmpty);
    });

    test('throws on error', () async {
      when(() => mockDio.get(
            '/courier/leaderboard',
            queryParameters: any(named: 'queryParameters'),
          )).thenThrow(DioException(
        requestOptions: RequestOptions(path: ''),
        type: DioExceptionType.badResponse,
        response: Response(
          statusCode: 403,
          data: {'message': 'Forbidden'},
          requestOptions: RequestOptions(path: ''),
        ),
      ));

      expect(() => repo.getLeaderboard(), throwsA(isA<Exception>()));
    });
  });

  group('getBadges', () {
    test('returns empty list when no data', () async {
      when(() => mockDio.get('/courier/badges')).thenAnswer(
        (_) async => Response(
          data: {},
          statusCode: 200,
          requestOptions: RequestOptions(path: ''),
        ),
      );

      final result = await repo.getBadges();
      expect(result, isEmpty);
    });

    test('throws on error', () async {
      when(() => mockDio.get('/courier/badges')).thenThrow(DioException(
        requestOptions: RequestOptions(path: ''),
        type: DioExceptionType.badResponse,
        response: Response(
          statusCode: 500,
          requestOptions: RequestOptions(path: ''),
        ),
      ));

      expect(() => repo.getBadges(), throwsA(isA<Exception>()));
    });
  });

  group('getLevel', () {
    test('throws on error', () async {
      when(() => mockDio.get('/courier/level')).thenThrow(DioException(
        requestOptions: RequestOptions(path: ''),
        type: DioExceptionType.badResponse,
        response: Response(
          statusCode: 404,
          requestOptions: RequestOptions(path: ''),
        ),
      ));

      expect(() => repo.getLevel(), throwsA(isA<Exception>()));
    });
  });

  group('getDailyChallenges', () {
    test('throws on 401', () async {
      when(() => mockDio.get('/courier/challenges')).thenThrow(DioException(
        requestOptions: RequestOptions(path: ''),
        type: DioExceptionType.badResponse,
        response: Response(
          statusCode: 401,
          requestOptions: RequestOptions(path: ''),
        ),
      ));

      expect(
        () => repo.getDailyChallenges(),
        throwsA(predicate<Exception>(
          (e) => e.toString().contains('Session expirée'),
        )),
      );
    });

    test('throws on 500', () async {
      when(() => mockDio.get('/courier/challenges')).thenThrow(DioException(
        requestOptions: RequestOptions(path: ''),
        type: DioExceptionType.badResponse,
        response: Response(
          statusCode: 500,
          requestOptions: RequestOptions(path: ''),
        ),
      ));

      expect(
        () => repo.getDailyChallenges(),
        throwsA(predicate<Exception>(
          (e) => e.toString().contains('serveur'),
        )),
      );
    });
  });
}
