import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:courier/data/repositories/auth_repository.dart';
import 'package:courier/core/constants/api_constants.dart';

class MockDio extends Mock implements Dio {}

void main() {
  late MockDio mockDio;
  late AuthRepository repo;

  setUp(() {
    mockDio = MockDio();
    repo = AuthRepository(mockDio);
  });

  group('AuthRepository.login', () {
    test('throws on 401', () async {
      when(
        () => mockDio.post(ApiConstants.login, data: any(named: 'data')),
      ).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: ApiConstants.login),
          type: DioExceptionType.badResponse,
          response: Response(
            statusCode: 401,
            requestOptions: RequestOptions(path: ''),
          ),
        ),
      );

      expect(
        () => repo.login('test@test.com', 'wrongpass'),
        throwsA(isA<Exception>()),
      );
    });

    test('throws on 422 with message', () async {
      when(
        () => mockDio.post(ApiConstants.login, data: any(named: 'data')),
      ).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: ApiConstants.login),
          type: DioExceptionType.badResponse,
          response: Response(
            statusCode: 422,
            data: {'message': 'Identifiants incorrects'},
            requestOptions: RequestOptions(path: ''),
          ),
        ),
      );

      expect(
        () => repo.login('test@test.com', 'wrong'),
        throwsA(
          predicate<Exception>(
            (e) => e.toString().contains('Identifiants incorrects'),
          ),
        ),
      );
    });

    test('throws on 422 with errors map', () async {
      when(
        () => mockDio.post(ApiConstants.login, data: any(named: 'data')),
      ).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: ApiConstants.login),
          type: DioExceptionType.badResponse,
          response: Response(
            statusCode: 422,
            data: {
              'errors': {
                'email': ['Le champ email est obligatoire'],
              },
            },
            requestOptions: RequestOptions(path: ''),
          ),
        ),
      );

      expect(
        () => repo.login('', 'pass'),
        throwsA(
          predicate<Exception>(
            (e) => e.toString().contains('email est obligatoire'),
          ),
        ),
      );
    });

    test('throws on timeout', () async {
      when(
        () => mockDio.post(ApiConstants.login, data: any(named: 'data')),
      ).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: ''),
          type: DioExceptionType.connectionTimeout,
        ),
      );

      expect(
        () => repo.login('test@test.com', 'pass'),
        throwsA(
          predicate<Exception>((e) => e.toString().contains('connexion')),
        ),
      );
    });

    test('throws on 500', () async {
      when(
        () => mockDio.post(ApiConstants.login, data: any(named: 'data')),
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

      expect(
        () => repo.login('test@test.com', 'pass'),
        throwsA(predicate<Exception>((e) => e.toString().contains('serveur'))),
      );
    });

    test('throws when token is missing from response', () async {
      when(
        () => mockDio.post(ApiConstants.login, data: any(named: 'data')),
      ).thenAnswer(
        (_) async => Response(
          data: {
            'data': {'user': {}, 'token': null},
          },
          statusCode: 200,
          requestOptions: RequestOptions(path: ''),
        ),
      );

      expect(
        () => repo.login('test@test.com', 'pass'),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('AuthRepository.refreshToken', () {
    test('returns false on error', () async {
      // SecureTokenService won't have a refresh token in test
      final result = await repo.refreshToken();
      expect(result, isFalse);
    });
  });
}
