import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:courier/data/repositories/wallet_repository.dart';
import 'package:courier/core/constants/api_constants.dart';
import 'package:courier/core/services/cache_service.dart';
import '../helpers/test_helpers.dart';

void main() {
  late MockDio mockDio;
  late WalletRepository repo;

  setUp(() async {
    mockDio = MockDio();
    repo = WalletRepository(mockDio);
    await setupTestDependencies();
  });

  final walletJson = {
    'balance': '15000',
    'currency': 'FCFA',
    'transactions': [
      {
        'id': 1,
        'type': 'credit',
        'amount': '2500',
        'description': 'Livraison #42',
        'created_at': '2026-02-13T10:00:00Z',
      },
    ],
  };

  // ── getWalletData ───────────────────────────────────
  group('getWalletData', () {
    test('returns WalletData from API', () async {
      when(() => mockDio.get(ApiConstants.wallet))
          .thenAnswer((_) async => successResponse({'data': walletJson}));

      final data = await repo.getWalletData();
      expect(data.balance, 15000);
      expect(data.transactions, hasLength(1));
    });

    test('serves from cache when available', () async {
      await CacheService.instance.cacheWallet(walletJson);

      final data = await repo.getWalletData();
      expect(data.balance, 15000);
      verifyNever(() => mockDio.get(any()));
    });

    test('throws on 404', () async {
      when(() => mockDio.get(ApiConstants.wallet))
          .thenThrow(dioError(statusCode: 404));

      expect(
        () => repo.getWalletData(),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'msg',
          contains('non trouvé'),
        )),
      );
    });

    test('throws on 403', () async {
      when(() => mockDio.get(ApiConstants.wallet))
          .thenThrow(dioError(
        statusCode: 403,
        data: {'message': 'Profil coursier non trouvé'},
      ));

      expect(
        () => repo.getWalletData(),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'msg',
          contains('Profil coursier'),
        )),
      );
    });

    test('throws on 401', () async {
      when(() => mockDio.get(ApiConstants.wallet))
          .thenThrow(dioError(statusCode: 401));

      expect(
        () => repo.getWalletData(),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'msg',
          contains('Session expirée'),
        )),
      );
    });
  });

  // ── canDeliver ──────────────────────────────────────
  group('canDeliver', () {
    test('returns data on success', () async {
      when(() => mockDio.get(ApiConstants.walletCanDeliver))
          .thenAnswer((_) async => successResponse({
                'data': {'can_deliver': true, 'min_balance': 500}
              }));

      final result = await repo.canDeliver();
      expect(result['can_deliver'], true);
    });

    test('throws on 403', () async {
      when(() => mockDio.get(ApiConstants.walletCanDeliver))
          .thenThrow(dioError(statusCode: 403, data: {'message': 'Profil non trouvé'}));

      expect(
        () => repo.canDeliver(),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'msg',
          contains('Profil non trouvé'),
        )),
      );
    });
  });

  // ── topUp ───────────────────────────────────────────
  group('topUp', () {
    test('returns data and invalidates cache', () async {
      when(() => mockDio.post(ApiConstants.walletTopUp, data: any(named: 'data')))
          .thenAnswer((_) async => successResponse({
                'data': {'status': 'success', 'new_balance': 20000}
              }));

      final result = await repo.topUp(
        amount: 5000,
        paymentMethod: 'mobile_money',
      );
      expect(result['status'], 'success');
    });

    test('throws with server message on error', () async {
      when(() => mockDio.post(ApiConstants.walletTopUp, data: any(named: 'data')))
          .thenThrow(dioError(
        statusCode: 400,
        data: {'message': 'Montant insuffisant'},
      ));

      expect(
        () => repo.topUp(amount: 10, paymentMethod: 'cash'),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'msg',
          contains('Montant insuffisant'),
        )),
      );
    });
  });

  // ── requestPayout ───────────────────────────────────
  group('requestPayout', () {
    test('returns data on success', () async {
      when(() => mockDio.post(ApiConstants.walletWithdraw, data: any(named: 'data')))
          .thenAnswer((_) async => successResponse({
                'data': {'status': 'pending', 'amount': 10000}
              }));

      final result = await repo.requestPayout(
        amount: 10000,
        paymentMethod: 'mtn',
        phoneNumber: '+22890001234',
      );
      expect(result['status'], 'pending');
    });
  });

  // ── getEarningsHistory ──────────────────────────────
  group('getEarningsHistory', () {
    test('returns paginated data', () async {
      when(() => mockDio.get(ApiConstants.walletEarningsHistory,
              queryParameters: any(named: 'queryParameters')))
          .thenAnswer((_) async => successResponse({
                'data': {
                  'transactions': [],
                  'total': 0,
                  'current_page': 1,
                }
              }));

      final result = await repo.getEarningsHistory(period: 'week');
      expect(result['current_page'], 1);
    });

    test('throws with server message on error', () async {
      when(() => mockDio.get(ApiConstants.walletEarningsHistory,
              queryParameters: any(named: 'queryParameters')))
          .thenThrow(dioError(
        statusCode: 500,
        data: {'message': 'Erreur interne'},
      ));

      expect(
        () => repo.getEarningsHistory(),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'msg',
          contains('Erreur'),
        )),
      );
    });
  });
}
