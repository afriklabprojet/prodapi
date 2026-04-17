import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:courier/data/repositories/gamification_repository.dart';
import 'package:courier/data/models/gamification.dart';

class MockDio extends Mock implements Dio {}

void main() {
  late MockDio mockDio;
  late GamificationRepository repository;

  setUp(() {
    mockDio = MockDio();
    repository = GamificationRepository(mockDio);
  });

  group('GamificationRepository', () {
    test('constructor creates instance', () {
      expect(repository, isA<GamificationRepository>());
    });

    group('getGamificationData', () {
      test('returns GamificationData on success', () async {
        when(() => mockDio.get('/courier/gamification')).thenAnswer(
          (_) async => Response(
            requestOptions: RequestOptions(path: '/courier/gamification'),
            statusCode: 200,
            data: {
              'data': {
                'level': {
                  'level': 5,
                  'title': 'Expert',
                  'current_xp': 1200,
                  'required_xp': 2000,
                  'total_xp': 5200,
                  'color': '#FF5722',
                  'perks': <String>[],
                },
                'badges': <Map<String, dynamic>>[],
                'stats': {'total_deliveries': 100, 'total_xp': 5200},
              },
            },
          ),
        );

        final result = await repository.getGamificationData();
        expect(result, isA<GamificationData>());
      });

      test('throws on error', () async {
        when(() => mockDio.get('/courier/gamification')).thenThrow(
          DioException(
            requestOptions: RequestOptions(path: '/courier/gamification'),
            type: DioExceptionType.badResponse,
            response: Response(
              requestOptions: RequestOptions(path: '/courier/gamification'),
              statusCode: 500,
            ),
          ),
        );

        expect(
          () => repository.getGamificationData(),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('getLeaderboard', () {
      test('returns list of LeaderboardEntry', () async {
        when(
          () => mockDio.get(
            '/courier/leaderboard',
            queryParameters: any(named: 'queryParameters'),
          ),
        ).thenAnswer(
          (_) async => Response(
            requestOptions: RequestOptions(path: '/courier/leaderboard'),
            statusCode: 200,
            data: {
              'data': <Map<String, dynamic>>[
                {
                  'courier_id': 1,
                  'name': 'John',
                  'avatar': null,
                  'xp': 5000,
                  'rank': 1,
                  'deliveries': 100,
                },
              ],
            },
          ),
        );

        final result = await repository.getLeaderboard(period: 'week');
        expect(result, isA<List<LeaderboardEntry>>());
      });
    });

    group('getBadges', () {
      test('returns list of GamificationBadge', () async {
        when(() => mockDio.get('/courier/badges')).thenAnswer(
          (_) async => Response(
            requestOptions: RequestOptions(path: '/courier/badges'),
            statusCode: 200,
            data: {
              'data': <Map<String, dynamic>>[
                {
                  'id': 'speed-1',
                  'name': 'Speed Demon',
                  'description': 'Fast delivery',
                  'icon_name': 'flash_on',
                  'color': '#FF5722',
                  'is_unlocked': true,
                  'required_value': 10,
                  'current_value': 15,
                  'category': 'speed',
                },
              ],
            },
          ),
        );

        final result = await repository.getBadges();
        expect(result, isA<List<GamificationBadge>>());
      });
    });

    group('getLevel', () {
      test('returns CourierLevel', () async {
        when(() => mockDio.get('/courier/level')).thenAnswer(
          (_) async => Response(
            requestOptions: RequestOptions(path: '/courier/level'),
            statusCode: 200,
            data: {
              'data': {
                'level': 3,
                'title': 'Confirmé',
                'current_xp': 800,
                'required_xp': 1500,
                'total_xp': 2800,
                'color': '#4CAF50',
                'perks': <String>[],
              },
            },
          ),
        );

        final result = await repository.getLevel();
        expect(result, isA<CourierLevel>());
      });
    });

    group('getDailyChallenges', () {
      test('returns DailyChallengesData', () async {
        when(() => mockDio.get('/courier/challenges')).thenAnswer(
          (_) async => Response(
            requestOptions: RequestOptions(path: '/courier/challenges'),
            statusCode: 200,
            data: {
              'data': {
                'challenges': <Map<String, dynamic>>[],
                'bonus_xp': 0,
                'all_completed': false,
              },
            },
          ),
        );

        final result = await repository.getDailyChallenges();
        expect(result, isA<DailyChallengesData>());
      });
    });

    group('claimChallengeReward', () {
      test('returns true on success', () async {
        when(() => mockDio.post('/courier/challenges/ch-1/claim')).thenAnswer(
          (_) async => Response(
            requestOptions: RequestOptions(
              path: '/courier/challenges/ch-1/claim',
            ),
            statusCode: 200,
            data: {'success': true},
          ),
        );

        final result = await repository.claimChallengeReward('ch-1');
        expect(result, true);
      });

      test('throws on failure', () async {
        when(() => mockDio.post('/courier/challenges/ch-1/claim')).thenThrow(
          DioException(
            requestOptions: RequestOptions(
              path: '/courier/challenges/ch-1/claim',
            ),
            type: DioExceptionType.badResponse,
            response: Response(
              requestOptions: RequestOptions(
                path: '/courier/challenges/ch-1/claim',
              ),
              statusCode: 400,
            ),
          ),
        );

        expect(
          () => repository.claimChallengeReward('ch-1'),
          throwsA(isA<Exception>()),
        );
      });
    });
  });
}
