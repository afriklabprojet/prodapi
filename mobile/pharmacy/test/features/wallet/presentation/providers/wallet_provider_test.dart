import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:drpharma_pharmacy/features/wallet/data/datasources/wallet_remote_datasource.dart';
import 'package:drpharma_pharmacy/features/wallet/data/models/wallet_data.dart';
import 'package:drpharma_pharmacy/features/wallet/presentation/providers/wallet_provider.dart';

// Mock classes
class MockWalletRemoteDataSource extends Mock
    implements WalletRemoteDataSource {}

void main() {
  late MockWalletRemoteDataSource mockDatasource;
  late ProviderContainer container;

  // Test data
  final testWalletJson = {
    'balance': '150000',
    'currency': 'XOF',
    'total_earnings': '500000',
    'total_commission_paid': '25000',
    'transactions': [
      {
        'id': 1,
        'amount': '50000',
        'type': 'credit',
        'description': 'Paiement commande DR-001',
        'reference': 'TX-001',
        'date': '2024-01-15',
      },
      {
        'id': 2,
        'amount': '10000',
        'type': 'debit',
        'description': 'Retrait Mobile Money',
        'reference': 'WD-001',
        'date': '2024-01-14',
      },
    ],
  };

  final testWithdrawalResponse = {
    'success': true,
    'withdrawal_id': 123,
    'amount': 50000,
    'status': 'pending',
    'message': 'Retrait en cours de traitement',
  };

  setUp(() {
    mockDatasource = MockWalletRemoteDataSource();
    container = ProviderContainer(
      overrides: [
        walletRemoteDataSourceProvider.overrideWithValue(mockDatasource),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  group('WalletData', () {
    test('should parse from JSON correctly', () {
      final walletData = WalletData.fromJson(testWalletJson);

      expect(walletData.balance, 150000.0);
      expect(walletData.currency, 'XOF');
      expect(walletData.totalEarnings, 500000.0);
      expect(walletData.totalCommissionPaid, 25000.0);
      expect(walletData.transactions.length, 2);
    });

    test('should handle missing fields with defaults', () {
      final walletData = WalletData.fromJson({});

      expect(walletData.balance, 0.0);
      expect(walletData.currency, 'XOF');
      expect(walletData.totalEarnings, 0.0);
      expect(walletData.transactions, isEmpty);
    });

    test('should handle null balance gracefully', () {
      final walletData = WalletData.fromJson({
        'balance': null,
        'currency': 'EUR',
      });

      expect(walletData.balance, 0.0);
      expect(walletData.currency, 'EUR');
    });
  });

  group('WalletTransaction', () {
    test('should parse from JSON correctly', () {
      final transaction = WalletTransaction.fromJson({
        'id': 1,
        'amount': '50000',
        'type': 'credit',
        'description': 'Test payment',
        'reference': 'REF-001',
        'date': '2024-01-15',
      });

      expect(transaction.id, 1);
      expect(transaction.amount, 50000.0);
      expect(transaction.type, 'credit');
      expect(transaction.description, 'Test payment');
      expect(transaction.reference, 'REF-001');
      expect(transaction.date, '2024-01-15');
    });

    test('should handle numeric amount', () {
      final transaction = WalletTransaction.fromJson({
        'id': 2,
        'amount': 25000,
        'type': 'debit',
      });

      expect(transaction.amount, 25000.0);
    });
  });

  group('WalletActionsNotifier', () {
    group('requestWithdrawal', () {
      test('should return success response on valid withdrawal', () async {
        // Arrange
        when(
          () => mockDatasource.requestWithdrawal(
            amount: 50000,
            paymentMethod: 'mobile_money',
            phone: '+22501020304',
            pin: '1234',
          ),
        ).thenAnswer((_) async => testWithdrawalResponse);

        // Act
        final notifier = container.read(walletActionsProvider.notifier);
        final result = await notifier.requestWithdrawal(
          amount: 50000,
          paymentMethod: 'mobile_money',
          phone: '+22501020304',
          pin: '1234',
        );

        // Assert
        expect(result['success'], true);
        expect(result['withdrawal_id'], 123);

        final state = container.read(walletActionsProvider);
        expect(state.isLoading, false);
        expect(state.error, isNull);
      });

      test('should set loading state during withdrawal', () async {
        // Arrange
        when(
          () => mockDatasource.requestWithdrawal(
            amount: any(named: 'amount'),
            paymentMethod: any(named: 'paymentMethod'),
            phone: any(named: 'phone'),
            pin: any(named: 'pin'),
          ),
        ).thenAnswer((_) async {
          await Future.delayed(const Duration(milliseconds: 100));
          return testWithdrawalResponse;
        });

        // Act
        final notifier = container.read(walletActionsProvider.notifier);
        final withdrawalFuture = notifier.requestWithdrawal(
          amount: 50000,
          paymentMethod: 'mobile_money',
          phone: '+22501020304',
          pin: '1234',
        );

        // Assert loading state
        await Future.microtask(() {});
        expect(container.read(walletActionsProvider).isLoading, true);

        await withdrawalFuture;
      });

      test('should handle withdrawal error', () async {
        // Arrange
        when(
          () => mockDatasource.requestWithdrawal(
            amount: any(named: 'amount'),
            paymentMethod: any(named: 'paymentMethod'),
            phone: any(named: 'phone'),
            pin: any(named: 'pin'),
          ),
        ).thenThrow(Exception('Insufficient balance'));

        // Act & Assert
        final notifier = container.read(walletActionsProvider.notifier);

        expect(
          () => notifier.requestWithdrawal(
            amount: 1000000,
            paymentMethod: 'mobile_money',
            phone: '+22501020304',
            pin: '1234',
          ),
          throwsException,
        );
      });

      test('should support bank transfer withdrawal', () async {
        // Arrange
        when(
          () => mockDatasource.requestWithdrawal(
            amount: 100000,
            paymentMethod: 'bank_transfer',
            accountDetails: 'CI-BICICI-123456789',
            pin: '1234',
          ),
        ).thenAnswer((_) async => testWithdrawalResponse);

        // Act
        final notifier = container.read(walletActionsProvider.notifier);
        final result = await notifier.requestWithdrawal(
          amount: 100000,
          paymentMethod: 'bank_transfer',
          accountDetails: 'CI-BICICI-123456789',
          pin: '1234',
        );

        // Assert
        expect(result['success'], true);
        verify(
          () => mockDatasource.requestWithdrawal(
            amount: 100000,
            paymentMethod: 'bank_transfer',
            accountDetails: 'CI-BICICI-123456789',
            pin: '1234',
          ),
        ).called(1);
      });
    });

    group('saveBankInfo', () {
      test('should save bank info successfully', () async {
        // Arrange
        when(
          () => mockDatasource.saveBankInfo(
            bankName: 'BICICI',
            holderName: 'Test User',
            accountNumber: '123456789',
            iban: 'CI12345678901234',
          ),
        ).thenAnswer((_) async {});

        // Act
        final notifier = container.read(walletActionsProvider.notifier);
        await notifier.saveBankInfo(
          bankName: 'BICICI',
          holderName: 'Test User',
          accountNumber: '123456789',
          iban: 'CI12345678901234',
        );

        // Assert
        final state = container.read(walletActionsProvider);
        expect(state.isLoading, false);
        expect(state.error, isNull);
        verify(
          () => mockDatasource.saveBankInfo(
            bankName: 'BICICI',
            holderName: 'Test User',
            accountNumber: '123456789',
            iban: 'CI12345678901234',
          ),
        ).called(1);
      });

      test('should handle save bank info error', () async {
        // Arrange
        when(
          () => mockDatasource.saveBankInfo(
            bankName: any(named: 'bankName'),
            holderName: any(named: 'holderName'),
            accountNumber: any(named: 'accountNumber'),
            iban: any(named: 'iban'),
          ),
        ).thenThrow(Exception('Invalid account number'));

        // Act & Assert
        final notifier = container.read(walletActionsProvider.notifier);
        expect(
          () => notifier.saveBankInfo(
            bankName: 'BICICI',
            holderName: 'Test',
            accountNumber: 'invalid',
          ),
          throwsException,
        );
      });
    });

    group('saveMobileMoneyInfo', () {
      test('should save mobile money info successfully', () async {
        // Arrange
        when(
          () => mockDatasource.saveMobileMoneyInfo(
            operator: 'Orange Money',
            phoneNumber: '+22501020304',
            accountName: 'Test User',
            isPrimary: true,
          ),
        ).thenAnswer((_) async {});

        // Act
        final notifier = container.read(walletActionsProvider.notifier);
        await notifier.saveMobileMoneyInfo(
          operator: 'Orange Money',
          phoneNumber: '+22501020304',
          accountName: 'Test User',
          isPrimary: true,
        );

        // Assert
        final state = container.read(walletActionsProvider);
        expect(state.isLoading, false);
        expect(state.error, isNull);
      });

      test('should save MTN Money info', () async {
        // Arrange
        when(
          () => mockDatasource.saveMobileMoneyInfo(
            operator: 'MTN Money',
            phoneNumber: '+22505060708',
            accountName: 'Test User',
            isPrimary: false,
          ),
        ).thenAnswer((_) async {});

        // Act
        final notifier = container.read(walletActionsProvider.notifier);
        await notifier.saveMobileMoneyInfo(
          operator: 'MTN Money',
          phoneNumber: '+22505060708',
          accountName: 'Test User',
          isPrimary: false,
        );

        // Assert
        verify(
          () => mockDatasource.saveMobileMoneyInfo(
            operator: 'MTN Money',
            phoneNumber: '+22505060708',
            accountName: 'Test User',
            isPrimary: false,
          ),
        ).called(1);
      });
    });
  });

  group('WalletActionsState', () {
    test('should have correct default values', () {
      const state = WalletActionsState();
      expect(state.isLoading, false);
      expect(state.error, isNull);
    });

    test('should store loading state', () {
      const state = WalletActionsState(isLoading: true);
      expect(state.isLoading, true);
    });

    test('should store error message', () {
      const state = WalletActionsState(error: 'Network error');
      expect(state.error, 'Network error');
      expect(state.isLoading, false);
    });
  });

  group('WithdrawalSettings', () {
    test('should parse from JSON correctly', () {
      final settings = WithdrawalSettings.fromJson({
        'threshold': 50000,
        'auto_withdraw': true,
        'has_pin': true,
        'has_mobile_money': true,
        'has_bank_info': false,
      });

      expect(settings.threshold, 50000.0);
      expect(settings.autoWithdraw, true);
      expect(settings.hasPin, true);
      expect(settings.hasMobileMoney, true);
      expect(settings.hasBankInfo, false);
    });

    test('should use default threshold when not provided', () {
      final settings = WithdrawalSettings.fromJson({});

      expect(settings.threshold, 50000.0); // Default value
      expect(settings.autoWithdraw, false);
    });

    test('should parse config when provided', () {
      final settings = WithdrawalSettings.fromJson({
        'threshold': 75000,
        'auto_withdraw': true,
        'config': {
          'min_threshold': 5000,
          'max_threshold': 1000000,
          'default_threshold': 75000,
          'step': 10000,
          'auto_withdraw_allowed': true,
          'require_pin': false,
          'require_mobile_money': false,
        },
      });

      expect(settings.threshold, 75000.0);
      expect(settings.config.minThreshold, 5000.0);
      expect(settings.config.maxThreshold, 1000000.0);
      expect(settings.config.step, 10000.0);
      expect(settings.config.requirePin, false);
    });

    test('should serialize to JSON correctly', () {
      final settings = WithdrawalSettings(
        threshold: 50000,
        autoWithdraw: true,
        hasPin: true,
        hasMobileMoney: true,
        hasBankInfo: false,
      );
      final json = settings.toJson();
      expect(json['threshold'], 50000);
      expect(json['auto_withdraw'], true);
      expect(json['has_pin'], true);
    });
  });

  group('WalletActionsNotifier - getWithdrawalSettings', () {
    test('should return settings on success', () async {
      final settingsJson = {
        'threshold': 50000,
        'auto_withdraw': false,
        'has_pin': true,
        'has_mobile_money': true,
        'has_bank_info': false,
      };

      when(
        () => mockDatasource.getWithdrawalSettings(),
      ).thenAnswer((_) async => settingsJson);

      final notifier = container.read(walletActionsProvider.notifier);
      final result = await notifier.getWithdrawalSettings();

      expect(result['threshold'], 50000);
      expect(result['has_pin'], true);
      final state = container.read(walletActionsProvider);
      expect(state.isLoading, false);
      expect(state.error, isNull);
    });

    test('should set error state on failure', () async {
      when(
        () => mockDatasource.getWithdrawalSettings(),
      ).thenThrow(Exception('Network error'));

      final notifier = container.read(walletActionsProvider.notifier);
      expect(() => notifier.getWithdrawalSettings(), throwsException);
    });
  });

  group('WalletActionsNotifier - setWithdrawalThreshold', () {
    test('should set threshold successfully', () async {
      when(
        () => mockDatasource.setWithdrawalThreshold(
          threshold: 75000,
          autoWithdraw: true,
        ),
      ).thenAnswer((_) async => {'threshold': 75000, 'auto_withdraw': true});

      final notifier = container.read(walletActionsProvider.notifier);
      final result = await notifier.setWithdrawalThreshold(
        threshold: 75000,
        autoWithdraw: true,
      );

      expect(result['threshold'], 75000);
      expect(result['auto_withdraw'], true);
      final state = container.read(walletActionsProvider);
      expect(state.isLoading, false);
    });

    test('should handle error when setting threshold', () async {
      when(
        () => mockDatasource.setWithdrawalThreshold(
          threshold: any(named: 'threshold'),
          autoWithdraw: any(named: 'autoWithdraw'),
        ),
      ).thenThrow(Exception('Server error'));

      final notifier = container.read(walletActionsProvider.notifier);
      expect(
        () =>
            notifier.setWithdrawalThreshold(threshold: -1, autoWithdraw: false),
        throwsException,
      );
    });
  });

  group('WalletActionsNotifier - error recovery', () {
    test('should recover from error state after successful action', () async {
      // First: cause an error
      when(
        () => mockDatasource.requestWithdrawal(
          amount: any(named: 'amount'),
          paymentMethod: any(named: 'paymentMethod'),
          phone: any(named: 'phone'),
          pin: any(named: 'pin'),
        ),
      ).thenThrow(Exception('Insufficient balance'));

      final notifier = container.read(walletActionsProvider.notifier);

      try {
        await notifier.requestWithdrawal(
          amount: 1000000,
          paymentMethod: 'mobile_money',
          phone: '+22501020304',
          pin: '1234',
        );
      } catch (_) {}

      // error state should be set
      expect(container.read(walletActionsProvider).error, isNotNull);

      // Now: successful action resets error
      when(
        () => mockDatasource.saveMobileMoneyInfo(
          operator: any(named: 'operator'),
          phoneNumber: any(named: 'phoneNumber'),
          accountName: any(named: 'accountName'),
          isPrimary: any(named: 'isPrimary'),
        ),
      ).thenAnswer((_) async {});

      await notifier.saveMobileMoneyInfo(
        operator: 'Orange Money',
        phoneNumber: '+22501020304',
        accountName: 'Test',
      );

      final state = container.read(walletActionsProvider);
      expect(state.isLoading, false);
      expect(state.error, isNull);
    });
  });

  group('WalletData - edge cases', () {
    test('should handle string balance with decimals', () {
      final data = WalletData.fromJson({
        'balance': '150000.50',
        'total_earnings': '500000.75',
      });
      expect(data.balance, 150000.50);
      expect(data.totalEarnings, 500000.75);
    });

    test('should handle integer values as strings', () {
      final data = WalletData.fromJson({
        'balance': 150000,
        'total_earnings': 500000,
      });
      expect(data.balance, 150000.0);
      expect(data.totalEarnings, 500000.0);
    });

    test('should handle empty transactions list', () {
      final data = WalletData.fromJson({'balance': '0', 'transactions': []});
      expect(data.transactions, isEmpty);
      expect(data.balance, 0.0);
    });

    test('should handle malformed transaction in list', () {
      final data = WalletData.fromJson({
        'transactions': [
          {'id': 1, 'amount': 'invalid-amount', 'type': 'credit'},
          {'id': 2, 'amount': '5000', 'type': 'debit'},
        ],
      });
      expect(data.transactions.length, 2);
      expect(data.transactions[0].amount, 0.0); // Failed parse defaults to 0
      expect(data.transactions[1].amount, 5000.0);
    });
  });

  group('WithdrawalConfig', () {
    test('defaults should have correct values', () {
      final config = WithdrawalConfig.defaults();
      expect(config.minThreshold, 10000);
      expect(config.maxThreshold, 500000);
      expect(config.defaultThreshold, 50000);
      expect(config.step, 5000);
      expect(config.autoWithdrawAllowed, true);
      expect(config.requirePin, true);
      expect(config.requireMobileMoney, true);
    });

    test('should parse from JSON correctly', () {
      final config = WithdrawalConfig.fromJson({
        'min_threshold': 20000,
        'max_threshold': 1000000,
        'default_threshold': 100000,
        'step': 25000,
        'auto_withdraw_allowed': false,
        'require_pin': false,
        'require_mobile_money': false,
      });
      expect(config.minThreshold, 20000);
      expect(config.maxThreshold, 1000000);
      expect(config.step, 25000);
      expect(config.autoWithdrawAllowed, false);
    });
  });
}
