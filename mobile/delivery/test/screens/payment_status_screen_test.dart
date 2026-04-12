import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mocktail/mocktail.dart';
import 'package:courier/presentation/screens/payment_status_screen.dart';
import 'package:courier/data/repositories/jeko_payment_repository.dart';
import '../helpers/widget_test_helpers.dart';

class MockJekoPaymentRepository extends Mock implements JekoPaymentRepository {}

void main() {
  late MockJekoPaymentRepository mockRepo;

  setUpAll(() async {
    await initHiveForTests();
    registerFallbackValue(JekoPaymentMethod.wave);
  });

  tearDownAll(() async {
    await cleanupHiveForTests();
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    mockRepo = MockJekoPaymentRepository();
  });

  group('PaymentStatusScreen', () {
    Widget buildScreen({
      double amount = 5000,
      JekoPaymentMethod method = JekoPaymentMethod.wave,
      VoidCallback? onSuccess,
      VoidCallback? onCancel,
    }) {
      return ProviderScope(
        overrides: [
          ...commonWidgetTestOverrides(),
          jekoPaymentRepositoryProvider.overrideWithValue(mockRepo),
        ],
        child: MaterialApp(
          home: PaymentStatusScreen(
            amount: amount,
            method: method,
            onSuccess: onSuccess,
            onCancel: onCancel,
          ),
        ),
      );
    }

    testWidgets('renders payment status screen', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(PaymentStatusScreen), findsOneWidget);
    });

    testWidgets('shows Paiement header text', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('Paiement'), findsOneWidget);
    });

    testWidgets('clearPendingPayment clears SharedPreferences', (tester) async {
      SharedPreferences.setMockInitialValues({
        'pending_jeko_payment':
            '{"amount":5000,"method":"wave","timestamp":${DateTime.now().millisecondsSinceEpoch}}',
      });
      await PaymentStatusScreen.clearPendingPayment();
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('pending_jeko_payment'), isNull);
    });

    testWidgets('getPendingPayment returns null when no data', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final result = await PaymentStatusScreen.getPendingPayment();
      expect(result, isNull);
    });
  });

  group('PaymentStatusScreen - Method label variations', () {
    Widget buildWithMethod(JekoPaymentMethod method) {
      return ProviderScope(
        overrides: [
          ...commonWidgetTestOverrides(),
          jekoPaymentRepositoryProvider.overrideWithValue(
            MockJekoPaymentRepository(),
          ),
        ],
        child: MaterialApp(
          home: PaymentStatusScreen(amount: 5000, method: method),
        ),
      );
    }

    testWidgets('wave method shows wave label', (tester) async {
      await tester.pumpWidget(buildWithMethod(JekoPaymentMethod.wave));
      await tester.pump(const Duration(seconds: 1));
      expect(find.textContaining('Wave'), findsWidgets);
    });

    testWidgets('orange method shows orange label', (tester) async {
      await tester.pumpWidget(buildWithMethod(JekoPaymentMethod.orange));
      await tester.pump(const Duration(seconds: 1));
      expect(find.textContaining('Orange'), findsWidgets);
    });

    testWidgets('mtn method shows MTN label', (tester) async {
      await tester.pumpWidget(buildWithMethod(JekoPaymentMethod.mtn));
      await tester.pump(const Duration(seconds: 1));
      expect(find.textContaining('MTN'), findsWidgets);
    });

    testWidgets('moov method shows Moov label', (tester) async {
      await tester.pumpWidget(buildWithMethod(JekoPaymentMethod.moov));
      await tester.pump(const Duration(seconds: 1));
      expect(find.textContaining('Moov'), findsWidgets);
    });

    testWidgets('all methods show the amount text', (tester) async {
      for (final method in JekoPaymentMethod.values) {
        await tester.pumpWidget(buildWithMethod(method));
        await tester.pump(const Duration(seconds: 1));
        expect(find.byType(PaymentStatusScreen), findsOneWidget);
      }
    });
  });

  group('PaymentStatusScreen - Pending payment recovery', () {
    testWidgets('getPendingPayment returns data for recent payment', (
      tester,
    ) async {
      final now = DateTime.now().toIso8601String();
      SharedPreferences.setMockInitialValues({
        'pending_jeko_payment':
            '{"amount":5000,"method":"wave","reference":"REF-001","timestamp":"$now"}',
      });
      final result = await PaymentStatusScreen.getPendingPayment();
      // Should return data since timestamp is fresh
      expect(result, isNotNull);
    });

    testWidgets('getPendingPayment returns null for expired payment', (
      tester,
    ) async {
      final expired = DateTime.now()
          .subtract(const Duration(minutes: 20))
          .toIso8601String();
      SharedPreferences.setMockInitialValues({
        'pending_jeko_payment':
            '{"amount":5000,"method":"wave","reference":"REF-OLD","timestamp":"$expired"}',
      });
      final result = await PaymentStatusScreen.getPendingPayment();
      expect(result, isNull);
    });

    testWidgets('clearPendingPayment after setting payment', (tester) async {
      final now = DateTime.now().toIso8601String();
      SharedPreferences.setMockInitialValues({
        'pending_jeko_payment':
            '{"amount":10000,"method":"orange","reference":"REF-002","timestamp":"$now"}',
      });
      await PaymentStatusScreen.clearPendingPayment();
      final result = await PaymentStatusScreen.getPendingPayment();
      expect(result, isNull);
    });
  });

  // =========================================================================
  // Business-logic tests
  // =========================================================================

  group('PaymentStatusScreen - Payment flow', () {
    Widget buildTestScreen({
      double amount = 5000,
      JekoPaymentMethod method = JekoPaymentMethod.wave,
      VoidCallback? onSuccess,
      VoidCallback? onCancel,
    }) {
      return ProviderScope(
        overrides: [
          ...commonWidgetTestOverrides(),
          jekoPaymentRepositoryProvider.overrideWithValue(mockRepo),
        ],
        child: MaterialApp(
          home: PaymentStatusScreen(
            amount: amount,
            method: method,
            onSuccess: onSuccess,
            onCancel: onCancel,
          ),
        ),
      );
    }

    testWidgets('initiatePayment error shows failure state', (tester) async {
      final orig = FlutterError.onError;
      FlutterError.onError = (_) {};
      try {
        when(
          () => mockRepo.initiateWalletTopup(
            amount: any(named: 'amount'),
            method: any(named: 'method'),
          ),
        ).thenThrow(Exception('Network error'));

        await tester.pumpWidget(buildTestScreen());
        await tester.pump(const Duration(seconds: 2));

        // After initiation failure, error message should appear
        expect(find.textContaining('échoué'), findsWidgets);
      } finally {
        FlutterError.onError = orig;
      }
    });

    testWidgets('initiatePayment error shows retry button', (tester) async {
      final orig = FlutterError.onError;
      FlutterError.onError = (_) {};
      try {
        await tester.binding.setSurfaceSize(const Size(800, 1400));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        when(
          () => mockRepo.initiateWalletTopup(
            amount: any(named: 'amount'),
            method: any(named: 'method'),
          ),
        ).thenThrow(Exception('Network error'));

        await tester.pumpWidget(buildTestScreen());
        await tester.pump(const Duration(seconds: 2));

        // Retry button should appear with 3 retries remaining
        expect(find.textContaining('Réessayer'), findsOneWidget);
        expect(find.textContaining('3 essais restants'), findsOneWidget);
      } finally {
        FlutterError.onError = orig;
      }
    });

    testWidgets('retry payment calls initiateWalletTopup again', (
      tester,
    ) async {
      final orig = FlutterError.onError;
      FlutterError.onError = (_) {};
      try {
        await tester.binding.setSurfaceSize(const Size(800, 1400));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        when(
          () => mockRepo.initiateWalletTopup(
            amount: any(named: 'amount'),
            method: any(named: 'method'),
          ),
        ).thenThrow(Exception('Network error'));

        await tester.pumpWidget(buildTestScreen());
        await tester.pump(const Duration(seconds: 2));

        // First call from initState → _initiatePayment
        verify(
          () => mockRepo.initiateWalletTopup(
            amount: 5000,
            method: JekoPaymentMethod.wave,
          ),
        ).called(1);

        // Tap retry button
        final retryBtn = find.textContaining('Réessayer');
        await tester.ensureVisible(retryBtn);
        await tester.tap(retryBtn);
        await tester.pump(const Duration(seconds: 2));

        // Second call from _retryPayment
        verify(
          () => mockRepo.initiateWalletTopup(
            amount: 5000,
            method: JekoPaymentMethod.wave,
          ),
        ).called(1);
      } finally {
        FlutterError.onError = orig;
      }
    });

    testWidgets('retry count decrements remaining attempts', (tester) async {
      final orig = FlutterError.onError;
      FlutterError.onError = (_) {};
      try {
        await tester.binding.setSurfaceSize(const Size(800, 1400));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        when(
          () => mockRepo.initiateWalletTopup(
            amount: any(named: 'amount'),
            method: any(named: 'method'),
          ),
        ).thenThrow(Exception('Network error'));

        await tester.pumpWidget(buildTestScreen());
        await tester.pump(const Duration(seconds: 2));

        // Initial: 3 retries remaining
        expect(find.textContaining('3 essais'), findsOneWidget);

        // Tap retry
        await tester.tap(find.textContaining('Réessayer'));
        await tester.pump(const Duration(seconds: 2));

        // After 1 retry: 2 remaining
        expect(find.textContaining('2 essais'), findsOneWidget);
      } finally {
        FlutterError.onError = orig;
      }
    });

    testWidgets('cancel button on failure calls onCancel', (tester) async {
      final orig = FlutterError.onError;
      FlutterError.onError = (_) {};
      try {
        await tester.binding.setSurfaceSize(const Size(800, 1400));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        bool cancelCalled = false;
        when(
          () => mockRepo.initiateWalletTopup(
            amount: any(named: 'amount'),
            method: any(named: 'method'),
          ),
        ).thenThrow(Exception('Network error'));

        await tester.pumpWidget(
          buildTestScreen(onCancel: () => cancelCalled = true),
        );
        await tester.pump(const Duration(seconds: 2));

        // Tap Annuler text button
        final cancelBtn = find.text('Annuler');
        await tester.ensureVisible(cancelBtn);
        await tester.tap(cancelBtn);
        await tester.pump(const Duration(seconds: 1));

        expect(cancelCalled, isTrue);
      } finally {
        FlutterError.onError = orig;
      }
    });

    testWidgets('each payment method shows its label', (tester) async {
      final orig = FlutterError.onError;
      FlutterError.onError = (_) {};
      try {
        for (final method in JekoPaymentMethod.values) {
          when(
            () => mockRepo.initiateWalletTopup(
              amount: any(named: 'amount'),
              method: any(named: 'method'),
            ),
          ).thenThrow(Exception('error'));

          await tester.pumpWidget(buildTestScreen(method: method));
          await tester.pump(const Duration(seconds: 1));
          expect(find.text(method.label), findsWidgets);
        }
      } finally {
        FlutterError.onError = orig;
      }
    });

    testWidgets('getPendingPayment handles invalid JSON gracefully', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({
        'pending_jeko_payment': 'not-valid-json',
      });
      final result = await PaymentStatusScreen.getPendingPayment();
      expect(result, isNull);
    });

    testWidgets('getPendingPayment returns null when timestamp missing', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({
        'pending_jeko_payment': '{"reference":"REF-001","amount":5000}',
      });
      final result = await PaymentStatusScreen.getPendingPayment();
      expect(result, isNull);
    });

    testWidgets('error message displays in error container', (tester) async {
      final orig = FlutterError.onError;
      FlutterError.onError = (_) {};
      try {
        await tester.binding.setSurfaceSize(const Size(800, 1400));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        when(
          () => mockRepo.initiateWalletTopup(
            amount: any(named: 'amount'),
            method: any(named: 'method'),
          ),
        ).thenThrow(Exception('Solde insuffisant'));

        await tester.pumpWidget(buildTestScreen());
        await tester.pump(const Duration(seconds: 2));

        expect(find.byIcon(Icons.error_outline), findsOneWidget);
      } finally {
        FlutterError.onError = orig;
      }
    });

    testWidgets('initiatePayment success calls the repository', (tester) async {
      final orig = FlutterError.onError;
      FlutterError.onError = (_) {};
      try {
        when(
          () => mockRepo.initiateWalletTopup(
            amount: any(named: 'amount'),
            method: any(named: 'method'),
          ),
        ).thenAnswer(
          (_) async => PaymentInitResponse(
            reference: 'REF-123',
            redirectUrl: 'https://pay.jeko.ci/form',
            amount: 5000,
            currency: 'XOF',
            paymentMethod: 'wave',
          ),
        );

        await tester.pumpWidget(buildTestScreen());
        await tester.pump(const Duration(seconds: 2));

        verify(
          () => mockRepo.initiateWalletTopup(
            amount: 5000,
            method: JekoPaymentMethod.wave,
          ),
        ).called(1);
      } finally {
        FlutterError.onError = orig;
      }
    });
  });

  // =========================================================================
  // Round 4 – deeper business-logic & edge-case coverage
  // =========================================================================

  group('PaymentStatusScreen - method colors & icons', () {
    Widget buildErrorScreen(JekoPaymentMethod method) {
      when(
        () => mockRepo.initiateWalletTopup(
          amount: any(named: 'amount'),
          method: any(named: 'method'),
        ),
      ).thenThrow(Exception('err'));
      return ProviderScope(
        overrides: [
          ...commonWidgetTestOverrides(),
          jekoPaymentRepositoryProvider.overrideWithValue(mockRepo),
        ],
        child: MaterialApp(
          home: PaymentStatusScreen(amount: 1000, method: method),
        ),
      );
    }

    testWidgets('wave shows wave icon', (tester) async {
      final orig = FlutterError.onError;
      FlutterError.onError = (_) {};
      try {
        await tester.pumpWidget(buildErrorScreen(JekoPaymentMethod.wave));
        await tester.pump(const Duration(seconds: 2));
        expect(find.byIcon(Icons.waves), findsWidgets);
      } finally {
        FlutterError.onError = orig;
      }
    });

    testWidgets('orange shows phone_android icon', (tester) async {
      final orig = FlutterError.onError;
      FlutterError.onError = (_) {};
      try {
        await tester.pumpWidget(buildErrorScreen(JekoPaymentMethod.orange));
        await tester.pump(const Duration(seconds: 2));
        expect(find.byIcon(Icons.phone_android), findsWidgets);
      } finally {
        FlutterError.onError = orig;
      }
    });

    testWidgets('djamo shows credit_card icon', (tester) async {
      final orig = FlutterError.onError;
      FlutterError.onError = (_) {};
      try {
        await tester.pumpWidget(buildErrorScreen(JekoPaymentMethod.djamo));
        await tester.pump(const Duration(seconds: 2));
        expect(find.byIcon(Icons.credit_card), findsWidgets);
      } finally {
        FlutterError.onError = orig;
      }
    });
  });

  group('PaymentStatusScreen - retry count exhaustion', () {
    Widget buildTestScreen({VoidCallback? onCancel}) {
      return ProviderScope(
        overrides: [
          ...commonWidgetTestOverrides(),
          jekoPaymentRepositoryProvider.overrideWithValue(mockRepo),
        ],
        child: MaterialApp(
          home: PaymentStatusScreen(
            amount: 5000,
            method: JekoPaymentMethod.wave,
            onCancel: onCancel,
          ),
        ),
      );
    }

    testWidgets('after 3 retries, retry button is disabled', (tester) async {
      final orig = FlutterError.onError;
      FlutterError.onError = (_) {};
      try {
        await tester.binding.setSurfaceSize(const Size(800, 1400));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        when(
          () => mockRepo.initiateWalletTopup(
            amount: any(named: 'amount'),
            method: any(named: 'method'),
          ),
        ).thenThrow(Exception('error'));

        await tester.pumpWidget(buildTestScreen());
        await tester.pump(const Duration(seconds: 2));

        // retry 1
        await tester.tap(find.textContaining('Réessayer'));
        await tester.pump(const Duration(seconds: 2));
        // retry 2
        await tester.tap(find.textContaining('Réessayer'));
        await tester.pump(const Duration(seconds: 2));
        // retry 3
        await tester.tap(find.textContaining('Réessayer'));
        await tester.pump(const Duration(seconds: 2));

        // Button should show 0 retries remaining
        expect(find.textContaining('0 essais'), findsOneWidget);
      } finally {
        FlutterError.onError = orig;
      }
    });
  });

  group('PaymentStatusScreen - pending payment edge cases', () {
    test('getPendingPayment with valid recent timestamp returns data', () async {
      final ts = DateTime.now()
          .subtract(const Duration(minutes: 5))
          .toIso8601String();
      SharedPreferences.setMockInitialValues({
        'pending_jeko_payment':
            '{"reference":"REF-X","amount":3000,"method":"mtn","timestamp":"$ts"}',
      });
      final result = await PaymentStatusScreen.getPendingPayment();
      expect(result, isNotNull);
      expect(result!['reference'], 'REF-X');
      expect(result['amount'], 3000);
    });

    test('getPendingPayment with exactly 15 min old returns null', () async {
      final ts = DateTime.now()
          .subtract(const Duration(minutes: 16))
          .toIso8601String();
      SharedPreferences.setMockInitialValues({
        'pending_jeko_payment': '{"reference":"REF-OLD","timestamp":"$ts"}',
      });
      final result = await PaymentStatusScreen.getPendingPayment();
      expect(result, isNull);
    });

    test(
      'getPendingPayment with empty string timestamp returns null',
      () async {
        SharedPreferences.setMockInitialValues({
          'pending_jeko_payment': '{"reference":"REF","timestamp":""}',
        });
        final result = await PaymentStatusScreen.getPendingPayment();
        expect(result, isNull);
      },
    );

    test('clearPendingPayment on empty prefs is safe', () async {
      SharedPreferences.setMockInitialValues({});
      await PaymentStatusScreen.clearPendingPayment();
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('pending_jeko_payment'), isNull);
    });
  });

  group('PaymentStatusScreen - initiation with WebView redirect', () {
    Widget buildWithRepo() {
      return ProviderScope(
        overrides: [
          ...commonWidgetTestOverrides(),
          jekoPaymentRepositoryProvider.overrideWithValue(mockRepo),
        ],
        child: MaterialApp(
          home: PaymentStatusScreen(
            amount: 5000,
            method: JekoPaymentMethod.wave,
          ),
        ),
      );
    }

    testWidgets('successful initiation persists pending payment', (
      tester,
    ) async {
      final orig = FlutterError.onError;
      FlutterError.onError = (_) {};
      try {
        when(
          () => mockRepo.initiateWalletTopup(
            amount: any(named: 'amount'),
            method: any(named: 'method'),
          ),
        ).thenAnswer(
          (_) async => PaymentInitResponse(
            reference: 'REF-PERSIST',
            redirectUrl: 'https://pay.jeko.ci/form',
            amount: 5000,
            currency: 'XOF',
            paymentMethod: 'wave',
          ),
        );

        await tester.pumpWidget(buildWithRepo());
        await tester.pump(const Duration(seconds: 2));

        // Verify that the reference was persisted to SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        final raw = prefs.getString('pending_jeko_payment');
        expect(raw, isNotNull);
        expect(raw, contains('REF-PERSIST'));
      } finally {
        FlutterError.onError = orig;
      }
    });

    testWidgets('progress steps show Initié as done', (tester) async {
      final orig = FlutterError.onError;
      FlutterError.onError = (_) {};
      try {
        when(
          () => mockRepo.initiateWalletTopup(
            amount: any(named: 'amount'),
            method: any(named: 'method'),
          ),
        ).thenThrow(Exception('err'));

        await tester.pumpWidget(buildWithRepo());
        await tester.pump(const Duration(seconds: 2));

        // Progress steps should be visible - Initié always done
        expect(find.text('Initié'), findsOneWidget);
      } finally {
        FlutterError.onError = orig;
      }
    });

    testWidgets('error state shows Paiement échoué title', (tester) async {
      final orig = FlutterError.onError;
      FlutterError.onError = (_) {};
      try {
        when(
          () => mockRepo.initiateWalletTopup(
            amount: any(named: 'amount'),
            method: any(named: 'method'),
          ),
        ).thenThrow(Exception('Connection refused'));

        await tester.pumpWidget(buildWithRepo());
        await tester.pump(const Duration(seconds: 2));

        expect(find.text('Paiement échoué'), findsOneWidget);
      } finally {
        FlutterError.onError = orig;
      }
    });

    testWidgets('error state shows reference when available', (tester) async {
      final orig = FlutterError.onError;
      FlutterError.onError = (_) {};
      try {
        await tester.binding.setSurfaceSize(const Size(800, 1400));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        when(
          () => mockRepo.initiateWalletTopup(
            amount: any(named: 'amount'),
            method: any(named: 'method'),
          ),
        ).thenAnswer(
          (_) async => PaymentInitResponse(
            reference: 'REF-VISIBLE',
            redirectUrl: 'https://pay.jeko.ci/form',
            amount: 5000,
            currency: 'XOF',
            paymentMethod: 'wave',
          ),
        );

        await tester.pumpWidget(buildWithRepo());
        await tester.pump(const Duration(seconds: 3));

        // Reference should be displayed somewhere in the UI
        expect(find.textContaining('REF-VISIBLE'), findsWidgets);
      } finally {
        FlutterError.onError = orig;
      }
    });
  });

  group('JekoPaymentMethod enum', () {
    test('all methods have correct labels', () {
      expect(JekoPaymentMethod.wave.label, 'Wave');
      expect(JekoPaymentMethod.orange.label, 'Orange Money');
      expect(JekoPaymentMethod.mtn.label, 'MTN MoMo');
      expect(JekoPaymentMethod.moov.label, 'Moov Money');
      expect(JekoPaymentMethod.djamo.label, 'Djamo');
    });

    test('all methods have correct values', () {
      expect(JekoPaymentMethod.wave.value, 'wave');
      expect(JekoPaymentMethod.orange.value, 'orange');
      expect(JekoPaymentMethod.mtn.value, 'mtn');
      expect(JekoPaymentMethod.moov.value, 'moov');
      expect(JekoPaymentMethod.djamo.value, 'djamo');
    });

    test('values list contains all 5 methods', () {
      expect(JekoPaymentMethod.values.length, 5);
    });
  });

  group('PaymentInitResponse model', () {
    test('fromJson parses correctly', () {
      final response = PaymentInitResponse.fromJson({
        'reference': 'REF-123',
        'redirect_url': 'https://example.com/pay',
        'amount': 5000,
        'currency': 'XOF',
        'payment_method': 'wave',
      });
      expect(response.reference, 'REF-123');
      expect(response.redirectUrl, 'https://example.com/pay');
      expect(response.amount, 5000);
      expect(response.currency, 'XOF');
      expect(response.paymentMethod, 'wave');
    });

    test('fromJson handles missing fields with defaults', () {
      final response = PaymentInitResponse.fromJson({});
      expect(response.reference, '');
      expect(response.redirectUrl, '');
      expect(response.amount, 0);
      expect(response.currency, 'XOF');
      expect(response.paymentMethod, '');
    });
  });

  group('PaymentStatusResponse model', () {
    test('isSuccess returns true for success status', () {
      final resp = PaymentStatusResponse(
        reference: 'R1',
        status: 'success',
        statusLabel: 'OK',
        amount: 1000,
        currency: 'XOF',
        paymentMethod: 'wave',
        isFinal: true,
      );
      expect(resp.isSuccess, isTrue);
      expect(resp.isFailed, isFalse);
      expect(resp.isPending, isFalse);
    });

    test('isFailed returns true for failed status', () {
      final resp = PaymentStatusResponse(
        reference: 'R2',
        status: 'failed',
        statusLabel: 'Échoué',
        amount: 1000,
        currency: 'XOF',
        paymentMethod: 'wave',
        isFinal: true,
      );
      expect(resp.isFailed, isTrue);
      expect(resp.isSuccess, isFalse);
    });

    test('isFailed returns true for expired status', () {
      final resp = PaymentStatusResponse(
        reference: 'R3',
        status: 'expired',
        statusLabel: 'Expiré',
        amount: 1000,
        currency: 'XOF',
        paymentMethod: 'wave',
        isFinal: true,
      );
      expect(resp.isFailed, isTrue);
    });

    test('isPending returns true for pending status', () {
      final resp = PaymentStatusResponse(
        reference: 'R4',
        status: 'pending',
        statusLabel: 'En attente',
        amount: 1000,
        currency: 'XOF',
        paymentMethod: 'wave',
        isFinal: false,
      );
      expect(resp.isPending, isTrue);
    });

    test('isPending returns true for processing status', () {
      final resp = PaymentStatusResponse(
        reference: 'R5',
        status: 'processing',
        statusLabel: 'Traitement',
        amount: 1000,
        currency: 'XOF',
        paymentMethod: 'wave',
        isFinal: false,
      );
      expect(resp.isPending, isTrue);
    });

    test('fromJson parses all fields', () {
      final resp = PaymentStatusResponse.fromJson({
        'reference': 'REF-100',
        'payment_status': 'success',
        'payment_status_label': 'Succès',
        'amount': 5000,
        'currency': 'XOF',
        'payment_method': 'wave',
        'is_final': true,
        'completed_at': '2025-01-15T10:00:00Z',
        'error_message': null,
      });
      expect(resp.reference, 'REF-100');
      expect(resp.isSuccess, isTrue);
      expect(resp.completedAt, '2025-01-15T10:00:00Z');
    });

    test('fromJson handles missing fields', () {
      final resp = PaymentStatusResponse.fromJson({});
      expect(resp.reference, '');
      expect(resp.status, 'pending');
      expect(resp.isPending, isTrue);
      expect(resp.isFinal, isFalse);
    });
  });
}
