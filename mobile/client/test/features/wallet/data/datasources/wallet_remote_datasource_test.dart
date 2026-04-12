import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:drpharma_client/features/wallet/data/datasources/wallet_remote_datasource.dart';
import 'package:drpharma_client/core/network/api_client.dart';

// ─── Mock ──────────────────────────────────────────────────

class MockApiClient extends Mock implements ApiClient {}

// ─── Helpers ───────────────────────────────────────────────

Response<dynamic> _makeResponse(dynamic data) => Response(
  requestOptions: RequestOptions(path: '/test'),
  data: data,
  statusCode: 200,
);

Map<String, dynamic> _makeWalletJson() => {
  'balance': 15000.0,
  'currency': 'XOF',
  'pending_withdrawals': 0,
  'available_balance': 15000.0,
  'minimum_withdrawal': 500,
  'statistics': {
    'total_topups': 50000.0,
    'total_withdrawals': 35000.0,
    'total_orders': 10,
  },
};

Map<String, dynamic> _makeTransactionJson({int id = 1}) => {
  'id': id,
  'type': 'topup',
  'amount': 5000.0,
  'balance_before': 10000.0,
  'balance_after': 15000.0,
  'reference': 'TXN-00$id',
  'description': 'Rechargement',
  'created_at': '2024-01-01T10:00:00Z',
};

void main() {
  late WalletRemoteDataSource datasource;
  late MockApiClient mockApiClient;

  setUp(() {
    mockApiClient = MockApiClient();
    datasource = WalletRemoteDataSource(mockApiClient);
  });

  // ── getWallet ──────────────────────────────────────────
  group('getWallet', () {
    test('returns wallet model on success', () async {
      when(
        () => mockApiClient.get(any()),
      ).thenAnswer((_) async => _makeResponse({'data': _makeWalletJson()}));

      final result = await datasource.getWallet();
      expect(result.balance, 15000.0);
      expect(result.currency, 'XOF');
      expect(result.availableBalance, 15000.0);
    });

    test('throws on null data', () async {
      when(
        () => mockApiClient.get(any()),
      ).thenAnswer((_) async => _makeResponse({'data': null}));

      expect(datasource.getWallet(), throwsException);
    });

    test('throws on invalid data type', () async {
      when(
        () => mockApiClient.get(any()),
      ).thenAnswer((_) async => _makeResponse({'data': 'invalid'}));

      expect(datasource.getWallet(), throwsException);
    });

    test('propagates API exception', () async {
      when(
        () => mockApiClient.get(any()),
      ).thenThrow(Exception('Network error'));
      expect(datasource.getWallet(), throwsException);
    });
  });

  // ── getTransactions ────────────────────────────────────
  group('getTransactions', () {
    test('returns list of transactions on success', () async {
      when(
        () => mockApiClient.get(
          any(),
          queryParameters: any(named: 'queryParameters'),
        ),
      ).thenAnswer(
        (_) async => _makeResponse({
          'data': [_makeTransactionJson(id: 1), _makeTransactionJson(id: 2)],
        }),
      );

      final result = await datasource.getTransactions();
      expect(result.length, 2);
    });

    test('returns empty list when data is null', () async {
      when(
        () => mockApiClient.get(
          any(),
          queryParameters: any(named: 'queryParameters'),
        ),
      ).thenAnswer((_) async => _makeResponse({'data': null}));

      final result = await datasource.getTransactions();
      expect(result, isEmpty);
    });

    test('returns empty list when data is not a list', () async {
      when(
        () => mockApiClient.get(
          any(),
          queryParameters: any(named: 'queryParameters'),
        ),
      ).thenAnswer((_) async => _makeResponse({'data': {}}));

      final result = await datasource.getTransactions();
      expect(result, isEmpty);
    });

    test('passes category param when provided', () async {
      when(
        () => mockApiClient.get(
          any(),
          queryParameters: any(named: 'queryParameters'),
        ),
      ).thenAnswer((_) async => _makeResponse({'data': []}));

      await datasource.getTransactions(category: 'topup');

      final captured =
          verify(
                () => mockApiClient.get(
                  any(),
                  queryParameters: captureAny(named: 'queryParameters'),
                ),
              ).captured.first
              as Map<String, dynamic>;

      expect(captured['category'], 'topup');
    });
  });

  // ── initiateTopUp ──────────────────────────────────────
  group('initiateTopUp', () {
    test('returns redirect data on success', () async {
      when(
        () => mockApiClient.post(any(), data: any(named: 'data')),
      ).thenAnswer(
        (_) async => _makeResponse({
          'data': {
            'redirect_url': 'https://pay.example.com',
            'reference': 'REF-001',
          },
        }),
      );

      final result = await datasource.initiateTopUp(
        amount: 5000,
        paymentMethod: 'mobile_money',
      );
      expect(result['redirect_url'], 'https://pay.example.com');
      expect(result['reference'], 'REF-001');
    });

    test('passes amount and payment_method in request', () async {
      when(
        () => mockApiClient.post(any(), data: any(named: 'data')),
      ).thenAnswer(
        (_) async => _makeResponse({
          'data': {'reference': 'REF-001'},
        }),
      );

      await datasource.initiateTopUp(amount: 2000, paymentMethod: 'card');

      final captured =
          verify(
                () =>
                    mockApiClient.post(any(), data: captureAny(named: 'data')),
              ).captured.first
              as Map<String, dynamic>;

      expect(captured['amount'], 2000);
      expect(captured['payment_method'], 'card');
      expect(captured['type'], 'wallet_topup');
    });

    test('throws on invalid response', () async {
      when(
        () => mockApiClient.post(any(), data: any(named: 'data')),
      ).thenAnswer((_) async => _makeResponse({'data': null}));

      expect(
        datasource.initiateTopUp(amount: 1000, paymentMethod: 'mobile_money'),
        throwsException,
      );
    });
  });

  // ── checkPaymentStatus ─────────────────────────────────
  group('checkPaymentStatus', () {
    test('returns status data', () async {
      when(() => mockApiClient.get(any())).thenAnswer(
        (_) async => _makeResponse({
          'data': {'status': 'success', 'reference': 'REF-001'},
        }),
      );

      final result = await datasource.checkPaymentStatus('REF-001');
      expect(result['status'], 'success');
    });

    test('throws on null data', () async {
      when(
        () => mockApiClient.get(any()),
      ).thenAnswer((_) async => _makeResponse({'data': null}));

      expect(datasource.checkPaymentStatus('REF-001'), throwsException);
    });
  });

  // ── topUp ──────────────────────────────────────────────
  group('topUp', () {
    test('returns result data', () async {
      when(
        () => mockApiClient.post(any(), data: any(named: 'data')),
      ).thenAnswer(
        (_) async => _makeResponse({
          'data': {'balance': 20000.0, 'status': 'completed'},
        }),
      );

      final result = await datasource.topUp(
        amount: 5000,
        paymentMethod: 'mobile_money',
      );
      expect(result['balance'], 20000.0);
    });

    test('includes paymentReference when provided', () async {
      when(
        () => mockApiClient.post(any(), data: any(named: 'data')),
      ).thenAnswer(
        (_) async => _makeResponse({
          'data': {'balance': 10000.0},
        }),
      );

      await datasource.topUp(
        amount: 5000,
        paymentMethod: 'mobile_money',
        paymentReference: 'PAY-REF-123',
      );

      final captured =
          verify(
                () =>
                    mockApiClient.post(any(), data: captureAny(named: 'data')),
              ).captured.first
              as Map<String, dynamic>;

      expect(captured['payment_reference'], 'PAY-REF-123');
    });

    test('throws on invalid response', () async {
      when(
        () => mockApiClient.post(any(), data: any(named: 'data')),
      ).thenAnswer((_) async => _makeResponse({'data': 'oops'}));

      expect(
        datasource.topUp(amount: 1000, paymentMethod: 'mobile_money'),
        throwsException,
      );
    });
  });

  // ── withdraw ───────────────────────────────────────────
  group('withdraw', () {
    test('returns result data on success', () async {
      when(
        () => mockApiClient.post(any(), data: any(named: 'data')),
      ).thenAnswer(
        (_) async => _makeResponse({
          'data': {'status': 'pending', 'reference': 'WD-001'},
        }),
      );

      final result = await datasource.withdraw(
        amount: 3000,
        paymentMethod: 'mobile_money',
        phoneNumber: '+24100000000',
      );
      expect(result['status'], 'pending');
    });

    test('throws on invalid response', () async {
      when(
        () => mockApiClient.post(any(), data: any(named: 'data')),
      ).thenAnswer((_) async => _makeResponse({'data': null}));

      expect(
        datasource.withdraw(
          amount: 1000,
          paymentMethod: 'mobile_money',
          phoneNumber: '+24100000000',
        ),
        throwsException,
      );
    });
  });

  // ── payOrder ───────────────────────────────────────────
  group('payOrder', () {
    test('returns result data on success', () async {
      when(
        () => mockApiClient.post(any(), data: any(named: 'data')),
      ).thenAnswer(
        (_) async => _makeResponse({
          'data': {'status': 'paid', 'transaction_id': 42},
        }),
      );

      final result = await datasource.payOrder(
        amount: 8000,
        orderReference: 'ORD-123',
      );
      expect(result['status'], 'paid');
    });

    test('throws on invalid response', () async {
      when(
        () => mockApiClient.post(any(), data: any(named: 'data')),
      ).thenAnswer((_) async => _makeResponse({'data': null}));

      expect(
        datasource.payOrder(amount: 1000, orderReference: 'ORD-X'),
        throwsException,
      );
    });
  });
}
