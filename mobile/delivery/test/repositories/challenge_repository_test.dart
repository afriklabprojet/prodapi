import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:courier/data/repositories/challenge_repository.dart';
import 'package:courier/core/constants/api_constants.dart';
import '../helpers/test_helpers.dart';

void main() {
  late MockDio mockDio;
  late ChallengeRepository repo;

  setUp(() {
    mockDio = MockDio();
    repo = ChallengeRepository(mockDio);
  });

  // ── getChallenges ───────────────────────────────────
  group('getChallenges', () {
    test('returns data on success', () async {
      when(() => mockDio.get(ApiConstants.challenges))
          .thenAnswer((_) async => successResponse({
                'data': {
                  'challenges': [
                    {'id': 1, 'title': '10 livraisons', 'reward': 5000},
                  ],
                  'bonuses': [],
                }
              }));

      final data = await repo.getChallenges();
      expect(data['challenges'], hasLength(1));
    });

    test('throws on 403', () async {
      when(() => mockDio.get(ApiConstants.challenges))
          .thenThrow(dioError(
        statusCode: 403,
        data: {'message': 'Profil non trouvé'},
      ));

      expect(
        () => repo.getChallenges(),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'msg',
          contains('Profil'),
        )),
      );
    });

    test('throws on 401', () async {
      when(() => mockDio.get(ApiConstants.challenges))
          .thenThrow(dioError(statusCode: 401, data: {}));

      expect(
        () => repo.getChallenges(),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'msg',
          contains('Session expirée'),
        )),
      );
    });

    test('throws generic on unknown error', () async {
      when(() => mockDio.get(ApiConstants.challenges))
          .thenThrow(dioError(statusCode: 500, data: {}));

      expect(
        () => repo.getChallenges(),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'msg',
          contains('serveur'),
        )),
      );
    });
  });

  // ── claimReward ─────────────────────────────────────
  group('claimReward', () {
    test('returns reward data on success', () async {
      when(() => mockDio.post(ApiConstants.claimChallenge(1)))
          .thenAnswer((_) async => successResponse({
                'data': {'reward': 5000, 'status': 'claimed'}
              }));

      final result = await repo.claimReward(1);
      expect(result['reward'], 5000);
    });

    test('throws with server message on error', () async {
      when(() => mockDio.post(ApiConstants.claimChallenge(1)))
          .thenThrow(dioError(
        statusCode: 400,
        data: {'message': 'Défi pas encore complété'},
      ));

      expect(
        () => repo.claimReward(1),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'msg',
          contains('pas encore complété'),
        )),
      );
    });
  });

  // ── getActiveBonuses ────────────────────────────────
  group('getActiveBonuses', () {
    test('returns list on success', () async {
      when(() => mockDio.get(ApiConstants.bonuses))
          .thenAnswer((_) async => successResponse({
                'data': [
                  {'id': 1, 'type': 'surge', 'multiplier': 1.5},
                ]
              }));

      final bonuses = await repo.getActiveBonuses();
      expect(bonuses, hasLength(1));
      expect(bonuses[0]['multiplier'], 1.5);
    });
  });

  // ── calculateBonus ──────────────────────────────────
  group('calculateBonus', () {
    test('returns calculated bonus', () async {
      when(() => mockDio.post(ApiConstants.calculateBonus, data: any(named: 'data')))
          .thenAnswer((_) async => successResponse({
                'data': {
                  'base_earnings': 2500,
                  'bonus_amount': 375,
                  'total_earnings': 2875,
                }
              }));

      final result = await repo.calculateBonus(2500);
      expect(result['bonus_amount'], 375);
    });
  });
}
