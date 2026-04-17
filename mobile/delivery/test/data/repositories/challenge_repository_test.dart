import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:courier/data/repositories/challenge_repository.dart';
import 'package:courier/core/constants/api_constants.dart';

class MockDio extends Mock implements Dio {}

void main() {
  late MockDio mockDio;
  late ChallengeRepository repo;

  setUp(() {
    mockDio = MockDio();
    repo = ChallengeRepository(mockDio);
  });

  group('getChallenges', () {
    test('returns map on success', () async {
      when(() => mockDio.get(ApiConstants.challenges)).thenAnswer(
        (_) async => Response(
          data: {
            'data': {
              'challenges': {'in_progress': [], 'completed': []},
              'active_bonuses': [],
              'stats': {'in_progress_count': 0},
            },
          },
          statusCode: 200,
          requestOptions: RequestOptions(path: ''),
        ),
      );

      final result = await repo.getChallenges();
      expect(result, isA<Map<String, dynamic>>());
      expect(result.containsKey('challenges'), isTrue);
    });

    test('returns empty structure when data is not a Map', () async {
      when(() => mockDio.get(ApiConstants.challenges)).thenAnswer(
        (_) async => Response(
          data: {'data': []},
          statusCode: 200,
          requestOptions: RequestOptions(path: ''),
        ),
      );

      final result = await repo.getChallenges();
      expect(result['challenges'], isNotNull);
      expect(result['active_bonuses'], isNotNull);
    });

    test('throws on 403', () async {
      when(() => mockDio.get(ApiConstants.challenges)).thenThrow(DioException(
        requestOptions: RequestOptions(path: ''),
        type: DioExceptionType.badResponse,
        response: Response(
          statusCode: 403,
          requestOptions: RequestOptions(path: ''),
        ),
      ));

      expect(
        () => repo.getChallenges(),
        throwsA(predicate<Exception>(
          (e) => e.toString().contains('Profil coursier'),
        )),
      );
    });

    test('throws on 401', () async {
      when(() => mockDio.get(ApiConstants.challenges)).thenThrow(DioException(
        requestOptions: RequestOptions(path: ''),
        type: DioExceptionType.badResponse,
        response: Response(
          statusCode: 401,
          requestOptions: RequestOptions(path: ''),
        ),
      ));

      expect(
        () => repo.getChallenges(),
        throwsA(predicate<Exception>(
          (e) => e.toString().contains('Session expirée'),
        )),
      );
    });

    test('throws on 500', () async {
      when(() => mockDio.get(ApiConstants.challenges)).thenThrow(DioException(
        requestOptions: RequestOptions(path: ''),
        type: DioExceptionType.badResponse,
        response: Response(
          statusCode: 500,
          requestOptions: RequestOptions(path: ''),
        ),
      ));

      expect(
        () => repo.getChallenges(),
        throwsA(predicate<Exception>(
          (e) => e.toString().contains('serveur'),
        )),
      );
    });

    test('throws generic on network error', () async {
      when(() => mockDio.get(ApiConstants.challenges)).thenThrow(
        Exception('random error'),
      );

      expect(
        () => repo.getChallenges(),
        throwsA(predicate<Exception>(
          (e) => e.toString().contains('connexion'),
        )),
      );
    });
  });

  group('claimReward', () {
    test('returns map on success', () async {
      when(() => mockDio.post(ApiConstants.claimChallenge(1))).thenAnswer(
        (_) async => Response(
          data: {
            'data': {'reward': 500, 'message': 'Reward claimed'},
          },
          statusCode: 200,
          requestOptions: RequestOptions(path: ''),
        ),
      );

      final result = await repo.claimReward(1);
      expect(result['reward'], 500);
    });

    test('throws on 401', () async {
      when(() => mockDio.post(ApiConstants.claimChallenge(1))).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: ''),
          type: DioExceptionType.badResponse,
          response: Response(
            statusCode: 401,
            requestOptions: RequestOptions(path: ''),
          ),
        ),
      );

      expect(
        () => repo.claimReward(1),
        throwsA(predicate<Exception>(
          (e) => e.toString().contains('Session expirée'),
        )),
      );
    });
  });
}
