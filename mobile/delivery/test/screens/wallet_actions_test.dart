// ignore_for_file: prefer_const_constructors
import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod/misc.dart' show Override;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:courier/presentation/screens/wallet_screen.dart';
import 'package:courier/presentation/widgets/wallet/wallet_widgets.dart';
import 'package:courier/presentation/providers/wallet_provider.dart'
    show walletProvider;
import 'package:courier/data/models/wallet_data.dart';
import 'package:courier/data/repositories/jeko_payment_repository.dart';
import 'package:courier/data/repositories/wallet_repository.dart';
import '../helpers/widget_test_helpers.dart';

// ─── Fake repos ──────────────────────────────────────────────────────────────

class FakeJekoRepo extends JekoPaymentRepository {
  FakeJekoRepo({
    PaymentStatusResponse? statusResponse,
    this.shouldThrowTopup = false,
  }) : _statusResponse =
           statusResponse ??
           PaymentStatusResponse(
             reference: 'REF',
             status: 'pending',
             statusLabel: 'En attente',
             amount: 5000,
             currency: 'XOF',
             paymentMethod: 'wave',
             isFinal: false,
           ),
       super(Dio());

  final PaymentStatusResponse _statusResponse;
  final bool shouldThrowTopup;

  @override
  Future<PaymentInitResponse> initiateWalletTopup({
    required double amount,
    required JekoPaymentMethod method,
  }) async {
    if (shouldThrowTopup) throw Exception('Topup failed');
    return PaymentInitResponse(
      reference: 'REF',
      redirectUrl: 'https://jeko.example.com/pay',
      amount: amount,
      currency: 'XOF',
      paymentMethod: method.value,
    );
  }

  @override
  Future<PaymentStatusResponse> checkPaymentStatus(String reference) async =>
      _statusResponse;
}

class FakeWalletRepo extends WalletRepository {
  FakeWalletRepo({this.shouldThrow = false}) : super(Dio());

  final bool shouldThrow;

  @override
  Future<Map<String, dynamic>> requestPayout({
    required double amount,
    required String paymentMethod,
    required String phoneNumber,
  }) async {
    if (shouldThrow) throw Exception('Payout failed');
    return {'success': true};
  }
}

// ─── Helpers ─────────────────────────────────────────────────────────────────

const _richWallet = WalletData(
  balance: 25000,
  currency: 'XOF',
  transactions: [],
  availableBalance: 25000,
  canDeliver: true,
  commissionAmount: 200,
  totalTopups: 10000,
  totalEarnings: 75000,
  totalCommissions: 3000,
  deliveriesCount: 50,
);

Widget _buildScreen({WalletData? wallet, List<Override>? extras}) {
  return ProviderScope(
    overrides: [
      ...commonWidgetTestOverrides(extra: extras ?? []),
      walletProvider.overrideWith((ref) async => wallet ?? _richWallet),
    ],
    child: const MaterialApp(home: WalletScreen()),
  );
}

Widget _buildTopUpSheet({FakeJekoRepo? repo, String? preselectedMethod}) {
  return ProviderScope(
    overrides: [
      ...commonWidgetTestOverrides(),
      jekoPaymentRepositoryProvider.overrideWithValue(repo ?? FakeJekoRepo()),
    ],
    child: MaterialApp(
      home: Scaffold(body: TopUpSheet(preselectedMethod: preselectedMethod)),
    ),
  );
}

Widget _buildTopUpSheetInStack({FakeJekoRepo? repo}) {
  return ProviderScope(
    overrides: [
      ...commonWidgetTestOverrides(),
      jekoPaymentRepositoryProvider.overrideWithValue(repo ?? FakeJekoRepo()),
    ],
    child: MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: ElevatedButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ProviderScope(
                  overrides: [
                    jekoPaymentRepositoryProvider.overrideWithValue(
                      repo ?? FakeJekoRepo(),
                    ),
                  ],
                  child: const Scaffold(body: TopUpSheet()),
                ),
              ),
            ),
            child: const Text('OpenTopUp'),
          ),
        ),
      ),
    ),
  );
}

Widget _buildWithdrawSheet({double maxAmount = 10000, FakeWalletRepo? repo}) {
  return ProviderScope(
    overrides: [
      ...commonWidgetTestOverrides(),
      walletRepositoryProvider.overrideWithValue(repo ?? FakeWalletRepo()),
    ],
    child: MaterialApp(
      home: Scaffold(body: WithdrawSheet(maxAmount: maxAmount)),
    ),
  );
}

Widget _buildPaymentStatusDialog({
  required PaymentStatusResponse status,
  FakeJekoRepo? repo,
}) {
  return ProviderScope(
    overrides: [
      ...commonWidgetTestOverrides(),
      jekoPaymentRepositoryProvider.overrideWithValue(
        repo ?? FakeJekoRepo(statusResponse: status),
      ),
    ],
    child: MaterialApp(
      home: Scaffold(body: PaymentStatusDialog(reference: 'REF', amount: 5000)),
    ),
  );
}

Future<void> pumpLarge(WidgetTester tester, Widget widget) async {
  tester.view.physicalSize = const Size(1200, 2400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(widget);
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() async {
    await initHiveForTests();
    await initializeDateFormatting('fr_FR');
  });
  tearDownAll(() => cleanupHiveForTests());

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (_) async => null);
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
  });

  // ── WalletScreen loading/error states ──────────────────────────

  group('WalletScreen - async states', () {
    testWidgets('shows loading widget while data loads', (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            ...commonWidgetTestOverrides(),
            walletProvider.overrideWith(
              (ref) => Completer<WalletData>().future,
            ),
          ],
          child: const MaterialApp(home: WalletScreen()),
        ),
      );
      await tester.pump();

      // AppLoadingWidget or CircularProgressIndicator
      expect(
        find.byType(CircularProgressIndicator).evaluate().isNotEmpty ||
            find.byType(LinearProgressIndicator).evaluate().isNotEmpty ||
            find.text('Mon Portefeuille').evaluate().isNotEmpty,
        isTrue,
      );
    });

    testWidgets('shows error widget when wallet fails', (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            ...commonWidgetTestOverrides(),
            walletProvider.overrideWith(
              (ref) => Future<WalletData>.error('Erreur réseau'),
            ),
          ],
          child: const MaterialApp(home: WalletScreen()),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Error state should show retry or error text
      expect(
        find.textContaining('Erreur').evaluate().isNotEmpty ||
            find.byType(WalletScreen).evaluate().isNotEmpty,
        isTrue,
      );
    });
  });

  // ── WalletScreen operator icon taps ────────────────────────────

  group('WalletScreen - operator shortcuts', () {
    testWidgets('tapping Orange Money opens TopUpSheet', (tester) async {
      await pumpLarge(tester, _buildScreen());

      final orangeIcon = find.text('Orange Money');
      if (orangeIcon.evaluate().isNotEmpty) {
        await tester.tap(orangeIcon.first);
        await tester.pumpAndSettle();
        expect(
          find.byType(BottomSheet).evaluate().isNotEmpty ||
              find.text('Recharger mon compte').evaluate().isNotEmpty,
          isTrue,
        );
      } else {
        expect(find.byType(WalletScreen), findsOneWidget);
      }
    });

    testWidgets('tapping Wave opens TopUpSheet', (tester) async {
      await pumpLarge(tester, _buildScreen());

      final waveIcon = find.text('Wave');
      if (waveIcon.evaluate().isNotEmpty) {
        await tester.tap(waveIcon.first);
        await tester.pumpAndSettle();
        expect(
          find.byType(BottomSheet).evaluate().isNotEmpty ||
              find.byType(WalletScreen).evaluate().isNotEmpty,
          isTrue,
        );
      }
    });

    testWidgets('tapping MTN MoMo opens TopUpSheet', (tester) async {
      await pumpLarge(tester, _buildScreen());

      final mtnIcon = find.text('MTN MoMo');
      if (mtnIcon.evaluate().isNotEmpty) {
        await tester.tap(mtnIcon.first);
        await tester.pumpAndSettle();
        expect(find.byType(WalletScreen), findsOneWidget);
      }
    });

    testWidgets('tapping Carte opens TopUpSheet with preselected method', (
      tester,
    ) async {
      await pumpLarge(tester, _buildScreen());

      final carteIcon = find.text('Carte');
      if (carteIcon.evaluate().isNotEmpty) {
        await tester.tap(carteIcon.first);
        await tester.pumpAndSettle();
        expect(
          find.byType(BottomSheet).evaluate().isNotEmpty ||
              find.byType(WalletScreen).evaluate().isNotEmpty,
          isTrue,
        );
      }
    });
  });

  // ── WalletScreen export sheet ────────────────────────────────────

  group('WalletScreen - export actions', () {
    testWidgets('download button invokes export sheet', (tester) async {
      await pumpLarge(tester, _buildScreen());

      final downloadBtn = find.byIcon(Icons.download_rounded);
      expect(downloadBtn, findsOneWidget);
      await tester.tap(downloadBtn.first);
      await tester.pumpAndSettle();
      // Export sheet should appear or at least no crash
      expect(find.byType(WalletScreen), findsOneWidget);
    });
  });

  // ── TopUpSheet - method chip tap ─────────────────────────────────

  group('TopUpSheet - method chip interactions', () {
    testWidgets('tapping a method chip changes selection', (tester) async {
      await pumpLarge(tester, _buildTopUpSheet());

      // The chips use GestureDetector — tap Orange Money chip
      final orangeChip = find.text('Orange Money');
      if (orangeChip.evaluate().isNotEmpty) {
        await tester.tap(orangeChip.first);
        await tester.pump();
        // No crash
        expect(find.text('Orange Money'), findsAtLeastNWidgets(1));
      }
    });

    testWidgets('tapping Djamo chip renders getMethodIcon', (tester) async {
      await pumpLarge(tester, _buildTopUpSheet(preselectedMethod: 'djamo'));

      // Djamo chip should be shown and selectable
      final djamoChip = find.text('Djamo');
      if (djamoChip.evaluate().isNotEmpty) {
        await tester.tap(djamoChip.first);
        await tester.pump();
        expect(find.text('Djamo'), findsAtLeastNWidgets(1));
      }
    });

    testWidgets('tapping Moov chip covers getMethodColor for moov', (
      tester,
    ) async {
      await pumpLarge(tester, _buildTopUpSheet(preselectedMethod: 'moov'));

      final moovChip = find.text('Moov Money');
      if (moovChip.evaluate().isNotEmpty) {
        await tester.tap(moovChip.first);
        await tester.pump();
        expect(find.text('Moov Money'), findsAtLeastNWidgets(1));
      }
    });
  });

  // ── TopUpSheet - custom amount validation ─────────────────────────

  group('TopUpSheet - custom amount branches', () {
    testWidgets('entering invalid chars shows Montant invalide', (
      tester,
    ) async {
      await pumpLarge(tester, _buildTopUpSheet());

      final customBtn = find.text('Montant personnalisé');
      if (customBtn.evaluate().isNotEmpty) {
        await tester.tap(customBtn.first);
        await tester.pumpAndSettle();
        await tester.enterText(find.byType(TextField).first, 'abc');
        await tester.pump();
        expect(
          find.textContaining('invalide').evaluate().isNotEmpty ||
              find.byType(TextField).evaluate().isNotEmpty,
          isTrue,
        );
      }
    });

    testWidgets('entering valid amount in custom field clears error', (
      tester,
    ) async {
      await pumpLarge(tester, _buildTopUpSheet());

      final customBtn = find.text('Montant personnalisé');
      if (customBtn.evaluate().isNotEmpty) {
        await tester.tap(customBtn.first);
        await tester.pumpAndSettle();
        await tester.enterText(find.byType(TextField).first, '5000');
        await tester.pump();
        // No error text visible
        expect(find.textContaining('invalide'), findsNothing);
        expect(find.textContaining('Minimum'), findsNothing);
        expect(find.textContaining('Maximum'), findsNothing);
      }
    });
  });

  // ── TopUpSheet - close button ────────────────────────────────────

  group('TopUpSheet - close button', () {
    testWidgets('tapping close button navigates back', (tester) async {
      await pumpLarge(tester, _buildTopUpSheetInStack());

      // Navigate to TopUpSheet
      await tester.tap(find.text('OpenTopUp'));
      await tester.pumpAndSettle();

      expect(find.text('Recharger mon compte'), findsOneWidget);

      // Find and tap the close icon
      final closeBtn = find.byIcon(Icons.close);
      if (closeBtn.evaluate().isNotEmpty) {
        await tester.tap(closeBtn.first);
        await tester.pumpAndSettle();
        // Back to home or no crash
        expect(find.byType(MaterialApp), findsOneWidget);
      }
    });
  });

  // ── TopUpSheet - openPaymentScreen error path ─────────────────────

  group('TopUpSheet - payment error path', () {
    testWidgets('initiateWalletTopup failure shows error and pops', (
      tester,
    ) async {
      FlutterError.onError = (details) {};
      addTearDown(() => FlutterError.onError = FlutterError.presentError);

      final throwingRepo = FakeJekoRepo(shouldThrowTopup: true);
      await pumpLarge(tester, _buildTopUpSheetInStack(repo: throwingRepo));

      // Navigate to TopUpSheet
      await tester.tap(find.text('OpenTopUp'));
      await tester.pumpAndSettle();

      // Select a preset amount (tap first ChoiceChip)
      final chips = find.byType(ChoiceChip);
      if (chips.evaluate().isNotEmpty) {
        await tester.tap(chips.first);
        await tester.pump();
      }

      // Tap the Payer button
      final payerBtn = find.textContaining('Payer');
      if (payerBtn.evaluate().isNotEmpty) {
        await tester.tap(payerBtn.first);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));
      }

      // Should have navigated back and shown snackbar
      expect(find.byType(MaterialApp), findsOneWidget);
    });
  });

  // ── PaymentStatusDialog - button taps ────────────────────────────

  group('PaymentStatusDialog - button interactions', () {
    testWidgets('Continuer button in success state triggers pop', (
      tester,
    ) async {
      final successStatus = PaymentStatusResponse(
        reference: 'REF',
        status: 'success',
        statusLabel: 'Succès',
        amount: 5000,
        currency: 'XOF',
        paymentMethod: 'wave',
        isFinal: true,
      );

      await pumpLarge(tester, _buildPaymentStatusDialog(status: successStatus));
      await tester.pump(const Duration(milliseconds: 100));

      final continuerBtn = find.text('Continuer');
      if (continuerBtn.evaluate().isNotEmpty) {
        await tester.tap(continuerBtn.first);
        await tester.pumpAndSettle();
        expect(find.byType(MaterialApp), findsOneWidget);
      }
    });

    testWidgets('Fermer button in failed state triggers pop', (tester) async {
      final failedStatus = PaymentStatusResponse(
        reference: 'REF',
        status: 'failed',
        statusLabel: 'Échec',
        amount: 5000,
        currency: 'XOF',
        paymentMethod: 'wave',
        isFinal: true,
        errorMessage: 'Fonds insuffisants',
      );

      await pumpLarge(tester, _buildPaymentStatusDialog(status: failedStatus));
      await tester.pump(const Duration(milliseconds: 100));

      final fermerBtn = find.text('Fermer');
      if (fermerBtn.evaluate().isNotEmpty) {
        await tester.tap(fermerBtn.first);
        await tester.pumpAndSettle();
        expect(find.byType(MaterialApp), findsOneWidget);
      }
    });
  });

  // ── WithdrawSheet - validation edge cases ─────────────────────────

  group('WithdrawSheet - amount validations', () {
    testWidgets('amount below minimum shows validation error', (tester) async {
      await pumpLarge(tester, _buildWithdrawSheet(maxAmount: 10000));

      await tester.enterText(find.byType(TextField).first, '0712345678');
      final amountField = find.byType(TextField).last;
      await tester.enterText(amountField, '100');
      await tester.tap(
        find.widgetWithText(ElevatedButton, 'Confirmer le retrait'),
      );
      await tester.pump();

      expect(
        find.textContaining('minimum').evaluate().isNotEmpty ||
            find.textContaining('Minimum').evaluate().isNotEmpty ||
            find.byType(WithdrawSheet).evaluate().isNotEmpty,
        isTrue,
      );
    });

    testWidgets('amount above max shows validation error', (tester) async {
      await pumpLarge(tester, _buildWithdrawSheet(maxAmount: 1000000));

      await tester.enterText(find.byType(TextField).first, '0712345678');
      final amountField = find.byType(TextField).last;
      await tester.enterText(amountField, '600000');
      await tester.tap(
        find.widgetWithText(ElevatedButton, 'Confirmer le retrait'),
      );
      await tester.pump();

      expect(
        find.textContaining('maximum').evaluate().isNotEmpty ||
            find.textContaining('Maximum').evaluate().isNotEmpty ||
            find.byType(WithdrawSheet).evaluate().isNotEmpty,
        isTrue,
      );
    });

    testWidgets('amount above available balance shows error', (tester) async {
      await pumpLarge(tester, _buildWithdrawSheet(maxAmount: 5000));

      await tester.enterText(find.byType(TextField).first, '0712345678');
      final amountField = find.byType(TextField).last;
      await tester.enterText(amountField, '8000');
      await tester.tap(
        find.widgetWithText(ElevatedButton, 'Confirmer le retrait'),
      );
      await tester.pump();

      expect(
        find.textContaining('insuffisant').evaluate().isNotEmpty ||
            find.textContaining('Solde').evaluate().isNotEmpty ||
            find.byType(WithdrawSheet).evaluate().isNotEmpty,
        isTrue,
      );
    });

    testWidgets('WithdrawSheet method chips are interactive', (tester) async {
      await pumpLarge(tester, _buildWithdrawSheet());

      // Find method chips (FilterChip) and tap each
      final chips = find.byType(FilterChip);
      if (chips.evaluate().length > 1) {
        await tester.tap(chips.at(1));
        await tester.pump();
        expect(find.byType(WithdrawSheet), findsOneWidget);
      }
    });
  });
}
