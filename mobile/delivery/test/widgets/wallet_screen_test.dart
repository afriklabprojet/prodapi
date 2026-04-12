import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:courier/presentation/screens/wallet_screen.dart';
import 'package:courier/presentation/widgets/wallet/wallet_widgets.dart';
import 'package:courier/presentation/providers/wallet_provider.dart'
    show walletProvider;
import 'package:courier/data/models/wallet_data.dart';
import 'package:courier/data/repositories/jeko_payment_repository.dart';
import 'package:courier/data/repositories/wallet_repository.dart';
import 'package:intl/date_symbol_data_local.dart';

class FakeJekoRepo extends JekoPaymentRepository {
  FakeJekoRepo({
    PaymentStatusResponse? statusResponse,
    List<PaymentStatusResponse>? statusSequence,
    this.shouldThrowTopup = false,
    this.shouldThrowStatus = false,
  }) : _statusResponse =
           statusResponse ??
           PaymentStatusResponse(
             reference: 'REF123',
             status: 'pending',
             statusLabel: 'En attente',
             amount: 5000,
             currency: 'XOF',
             paymentMethod: 'wave',
             isFinal: false,
           ),
       _statusSequence = statusSequence,
       super(Dio());

  final PaymentStatusResponse _statusResponse;
  final List<PaymentStatusResponse>? _statusSequence;
  final bool shouldThrowTopup;
  final bool shouldThrowStatus;
  double? lastAmount;
  JekoPaymentMethod? lastMethod;
  int _statusIndex = 0;

  @override
  Future<PaymentInitResponse> initiateWalletTopup({
    required double amount,
    required JekoPaymentMethod method,
  }) async {
    if (shouldThrowTopup) throw Exception('Topup failed');
    lastAmount = amount;
    lastMethod = method;
    return PaymentInitResponse(
      reference: 'REF123',
      redirectUrl: 'https://example.com/pay',
      amount: amount,
      currency: 'XOF',
      paymentMethod: method.value,
    );
  }

  @override
  Future<PaymentStatusResponse> checkPaymentStatus(String reference) async {
    if (shouldThrowStatus) throw Exception('Status failed');
    final sequence = _statusSequence;
    if (sequence != null && sequence.isNotEmpty) {
      final response = sequence[_statusIndex.clamp(0, sequence.length - 1)];
      if (_statusIndex < sequence.length - 1) {
        _statusIndex++;
      }
      return response;
    }
    return _statusResponse;
  }
}

class FakeWalletRepo extends WalletRepository {
  FakeWalletRepo({this.shouldThrow = false}) : super(Dio());

  final bool shouldThrow;
  double? lastAmount;
  String? lastMethod;
  String? lastPhone;

  @override
  Future<Map<String, dynamic>> requestPayout({
    required double amount,
    required String paymentMethod,
    required String phoneNumber,
  }) async {
    if (shouldThrow) throw Exception('Payout failed');
    lastAmount = amount;
    lastMethod = paymentMethod;
    lastPhone = phoneNumber;
    return {'success': true};
  }
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('fr_FR');
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (_) async => null);
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
  });

  final testWallet = WalletData(
    balance: 25000,
    totalCommissions: 4800,
    deliveriesCount: 60,
    totalEarnings: 120000,
    totalTopups: 50000,
    canDeliver: true,
    commissionAmount: 200,
    transactions: [
      WalletTransaction(
        id: 1,
        type: 'credit',
        category: 'commission',
        amount: 200,
        description: 'Commission livraison #123',
        status: 'completed',
        createdAt: DateTime(2026, 2, 13, 10, 0),
      ),
      WalletTransaction(
        id: 2,
        type: 'credit',
        category: 'topup',
        amount: 5000,
        description: 'Recharge Mobile Money',
        status: 'completed',
        createdAt: DateTime(2026, 2, 12, 15, 0),
      ),
      WalletTransaction(
        id: 3,
        type: 'debit',
        category: 'withdrawal',
        amount: 3000,
        description: 'Retrait Mobile Money',
        status: 'pending',
        createdAt: DateTime(2026, 2, 11, 9, 30),
      ),
    ],
  );

  final cantDeliverWallet = WalletData(
    balance: 50,
    canDeliver: false,
    commissionAmount: 200,
    transactions: [],
  );

  final emptyWallet = WalletData(
    balance: 0,
    canDeliver: true,
    transactions: [],
  );

  final lowBalanceWallet = WalletData(
    balance: 400,
    canDeliver: true,
    transactions: [],
  );

  Widget buildScreen({WalletData? wallet}) {
    return ProviderScope(
      overrides: [
        walletProvider.overrideWith(
          (ref) => Future.value(wallet ?? testWallet),
        ),
      ],
      child: const MaterialApp(home: WalletScreen()),
    );
  }

  Widget buildTopUpSheet({String? preselectedMethod, FakeJekoRepo? repo}) {
    return ProviderScope(
      overrides: [
        jekoPaymentRepositoryProvider.overrideWithValue(repo ?? FakeJekoRepo()),
      ],
      child: MaterialApp(
        home: Scaffold(body: TopUpSheet(preselectedMethod: preselectedMethod)),
      ),
    );
  }

  Widget buildWithdrawSheet({double maxAmount = 10000, FakeWalletRepo? repo}) {
    return ProviderScope(
      overrides: [
        walletRepositoryProvider.overrideWithValue(repo ?? FakeWalletRepo()),
      ],
      child: MaterialApp(
        home: Scaffold(body: WithdrawSheet(maxAmount: maxAmount)),
      ),
    );
  }

  Widget buildPaymentStatusDialog({
    required PaymentStatusResponse status,
    FakeJekoRepo? repo,
  }) {
    return ProviderScope(
      overrides: [
        jekoPaymentRepositoryProvider.overrideWithValue(
          repo ?? FakeJekoRepo(statusResponse: status),
        ),
      ],
      child: const MaterialApp(
        home: Scaffold(
          body: PaymentStatusDialog(reference: 'REF123', amount: 5000),
        ),
      ),
    );
  }

  Future<void> pumpLargeWidget(WidgetTester tester, Widget widget) async {
    tester.view.physicalSize = const Size(1200, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(widget);
    await tester.pump();
  }

  group('WalletScreen - App Bar', () {
    testWidgets('displays app bar with title', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('Mon Portefeuille'), findsOneWidget);
    });

    testWidgets('displays refresh button', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pump(const Duration(seconds: 1));

      expect(find.byIcon(Icons.refresh), findsOneWidget);
    });
  });

  group('WalletScreen - Balance Card', () {
    testWidgets('displays Solde Disponible label', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('Solde Disponible'), findsOneWidget);
    });

    testWidgets('displays formatted balance with currency', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pump(const Duration(seconds: 1));

      // 25000 formatted as "25 000 XOF" in fr_FR locale
      expect(find.textContaining('25'), findsAtLeastNWidgets(1));
      expect(find.textContaining('XOF'), findsAtLeastNWidgets(1));
    });

    testWidgets('displays stat items in balance card', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('Livraisons'), findsOneWidget);
      expect(find.text('Gains'), findsOneWidget);
      expect(find.text('Commissions'), findsOneWidget);
    });

    testWidgets('displays deliveries count', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('60'), findsOneWidget);
    });

    testWidgets('displays Recharger button', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('Recharger'), findsOneWidget);
      expect(find.byIcon(Icons.add_circle_outline), findsAtLeastNWidgets(1));
    });

    testWidgets('displays Retirer button', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('Retirer'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_downward), findsAtLeastNWidgets(1));
    });

    testWidgets('displays stat icons', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pump(const Duration(seconds: 1));

      expect(find.byIcon(Icons.local_shipping_outlined), findsOneWidget);
      expect(find.byIcon(Icons.trending_up), findsAtLeastNWidgets(1));
      expect(find.byIcon(Icons.trending_down), findsOneWidget);
    });
  });

  group('WalletScreen - Operators', () {
    testWidgets('displays operator shortcuts', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('Orange Money'), findsOneWidget);
      expect(find.text('MTN MoMo'), findsOneWidget);
      expect(find.text('Wave'), findsOneWidget);
      expect(find.text('Carte'), findsOneWidget);
    });
  });

  group('WalletScreen - Transactions', () {
    testWidgets('displays Historique section', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('Historique'), findsOneWidget);
    });

    testWidgets('displays Voir les gains button', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('Voir les gains'), findsOneWidget);
    });

    testWidgets('displays commission transaction', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('Commission Dr Pharma'), findsOneWidget);
    });

    testWidgets('displays topup transaction', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('Rechargement'), findsOneWidget);
    });

    testWidgets('displays withdrawal transaction', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('Retrait Mobile Money'), findsOneWidget);
    });

    testWidgets('displays pending status badge', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('En attente'), findsOneWidget);
    });

    testWidgets('displays empty transactions state', (tester) async {
      await tester.pumpWidget(buildScreen(wallet: emptyWallet));
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('Aucune transaction'), findsOneWidget);
      expect(find.byIcon(Icons.receipt_long_outlined), findsOneWidget);
    });
  });

  group('WalletScreen - Warning & States', () {
    testWidgets('displays warning when cannot deliver', (tester) async {
      await tester.pumpWidget(buildScreen(wallet: cantDeliverWallet));
      await tester.pump(const Duration(seconds: 1));

      expect(find.textContaining('Solde insuffisant'), findsOneWidget);
      expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
    });

    testWidgets('no warning when can deliver', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pump(const Duration(seconds: 1));

      expect(find.textContaining('Solde insuffisant'), findsNothing);
    });

    testWidgets('disables Retirer button with low balance', (tester) async {
      await tester.pumpWidget(buildScreen(wallet: lowBalanceWallet));
      await tester.pump(const Duration(seconds: 1));

      // Balance 400 < 500, Retirer button should be disabled
      expect(find.text('Retirer'), findsOneWidget);
    });

    testWidgets('shows loading state', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            walletProvider.overrideWith(
              (ref) => Completer<WalletData>().future,
            ),
          ],
          child: const MaterialApp(home: WalletScreen()),
        ),
      );
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });

  group('TopUpSheet', () {
    testWidgets('renders payment title and methods', (tester) async {
      await pumpLargeWidget(tester, buildTopUpSheet());

      expect(find.text('Recharger mon compte'), findsOneWidget);
      expect(find.text('Paiement sécurisé via JEKO'), findsOneWidget);
      expect(find.text('Moyen de paiement'), findsOneWidget);
      expect(find.text('Wave'), findsOneWidget);
      expect(find.text('Orange Money'), findsOneWidget);
      expect(find.text('MTN MoMo'), findsOneWidget);
      expect(find.text('Djamo'), findsOneWidget);
    });

    testWidgets('preselected method updates info banner', (tester) async {
      await pumpLargeWidget(
        tester,
        buildTopUpSheet(preselectedMethod: 'orange_money'),
      );

      expect(find.textContaining('Orange Money'), findsWidgets);
    });

    testWidgets('preset amount selection enables payment button', (
      tester,
    ) async {
      await pumpLargeWidget(tester, buildTopUpSheet());

      await tester.tap(find.byType(ChoiceChip).first);
      await tester.pump();

      expect(find.textContaining('Payer'), findsOneWidget);
      expect(find.byIcon(Icons.lock_outline), findsOneWidget);
    });

    testWidgets('custom amount mode shows text field', (tester) async {
      await pumpLargeWidget(tester, buildTopUpSheet());

      await tester.tap(find.text('Montant personnalisé'));
      await tester.pump();

      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Entrez le montant'), findsOneWidget);
    });

    testWidgets('custom amount below minimum shows validation error', (
      tester,
    ) async {
      await pumpLargeWidget(tester, buildTopUpSheet());

      await tester.tap(find.text('Montant personnalisé'));
      await tester.pump();
      await tester.enterText(find.byType(TextField), '100');
      await tester.pump();

      expect(find.textContaining('Minimum 500'), findsOneWidget);
    });

    testWidgets('custom amount above maximum shows validation error', (
      tester,
    ) async {
      await pumpLargeWidget(tester, buildTopUpSheet());

      await tester.tap(find.text('Montant personnalisé'));
      await tester.pump();
      await tester.enterText(find.byType(TextField), '1000001');
      await tester.pump();

      expect(find.textContaining('Maximum'), findsOneWidget);
    });

    testWidgets('close icon is visible', (tester) async {
      await pumpLargeWidget(tester, buildTopUpSheet());

      expect(find.byIcon(Icons.close), findsOneWidget);
    });

    testWidgets('info banner is shown', (tester) async {
      await pumpLargeWidget(tester, buildTopUpSheet());

      expect(find.textContaining('Vous serez redirigé vers'), findsOneWidget);
      expect(find.byIcon(Icons.info_outline), findsAtLeastNWidgets(1));
    });
  });

  group('PaymentStatusDialog', () {
    testWidgets('shows pending state', (tester) async {
      final repo = FakeJekoRepo(
        statusSequence: [
          PaymentStatusResponse(
            reference: 'REF123',
            status: 'pending',
            statusLabel: 'En attente',
            amount: 5000,
            currency: 'XOF',
            paymentMethod: 'wave',
            isFinal: false,
          ),
          PaymentStatusResponse(
            reference: 'REF123',
            status: 'success',
            statusLabel: 'Succès',
            amount: 5000,
            currency: 'XOF',
            paymentMethod: 'wave',
            isFinal: true,
          ),
        ],
      );

      await pumpLargeWidget(
        tester,
        buildPaymentStatusDialog(
          status: PaymentStatusResponse(
            reference: 'REF123',
            status: 'pending',
            statusLabel: 'En attente',
            amount: 5000,
            currency: 'XOF',
            paymentMethod: 'wave',
            isFinal: false,
          ),
          repo: repo,
        ),
      );

      expect(find.text('Paiement en cours...'), findsOneWidget);
      expect(
        find.textContaining('Veuillez terminer le paiement'),
        findsOneWidget,
      );
      expect(find.text('Vérifier le statut'), findsOneWidget);

      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
    });

    testWidgets('shows success state when payment is successful', (
      tester,
    ) async {
      await pumpLargeWidget(
        tester,
        buildPaymentStatusDialog(
          status: PaymentStatusResponse(
            reference: 'REF123',
            status: 'success',
            statusLabel: 'Succès',
            amount: 5000,
            currency: 'XOF',
            paymentMethod: 'wave',
            isFinal: true,
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.text('Paiement réussi !'), findsOneWidget);
      expect(find.text('Continuer'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
    });

    testWidgets('shows failed state when payment fails', (tester) async {
      await pumpLargeWidget(
        tester,
        buildPaymentStatusDialog(
          status: PaymentStatusResponse(
            reference: 'REF123',
            status: 'failed',
            statusLabel: 'Échec',
            amount: 5000,
            currency: 'XOF',
            paymentMethod: 'wave',
            isFinal: true,
            errorMessage: 'Paiement refusé',
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.text('Paiement échoué'), findsOneWidget);
      expect(find.text('Paiement refusé'), findsOneWidget);
      expect(find.text('Fermer'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });
  });

  group('WithdrawSheet', () {
    testWidgets('renders withdraw form fields', (tester) async {
      await pumpLargeWidget(tester, buildWithdrawSheet());

      expect(find.text('Retrait de fonds'), findsOneWidget);
      expect(find.textContaining('Solde disponible'), findsOneWidget);
      expect(find.text('Numéro de téléphone'), findsOneWidget);
      expect(find.text('Montant à retirer'), findsOneWidget);
      expect(find.text('Confirmer le retrait'), findsWidgets);
    });

    testWidgets('shows operator mismatch warning for phone prefix', (
      tester,
    ) async {
      await pumpLargeWidget(tester, buildWithdrawSheet());

      await tester.enterText(find.byType(TextField).first, '0512345678');
      await tester.pump();

      expect(
        find.textContaining('Ce numéro semble être un numéro'),
        findsOneWidget,
      );
      expect(find.textContaining('MTN'), findsWidgets);
    });

    testWidgets('shows phone validation error for short number', (
      tester,
    ) async {
      await pumpLargeWidget(tester, buildWithdrawSheet());

      await tester.enterText(find.byType(TextField).first, '07');
      await tester.enterText(find.byType(TextField).last, '600');
      await tester.tap(
        find.widgetWithText(ElevatedButton, 'Confirmer le retrait'),
      );
      await tester.pump();

      expect(find.textContaining('10 chiffres'), findsOneWidget);
    });

    testWidgets('shows insufficient balance error for too large amount', (
      tester,
    ) async {
      await pumpLargeWidget(tester, buildWithdrawSheet(maxAmount: 1000));

      await tester.enterText(find.byType(TextField).first, '0712345678');
      await tester.enterText(find.byType(TextField).last, '50000');
      await tester.tap(
        find.widgetWithText(ElevatedButton, 'Confirmer le retrait'),
      );
      await tester.pump();

      expect(find.textContaining('Solde insuffisant'), findsOneWidget);
    });

    testWidgets('successful withdraw flow reports payout and shows snackbar', (
      tester,
    ) async {
      final repo = FakeWalletRepo();
      await pumpLargeWidget(tester, buildWithdrawSheet(repo: repo));

      await tester.enterText(find.byType(TextField).first, '0712345678');
      await tester.enterText(find.byType(TextField).last, '600');
      await tester.tap(
        find.widgetWithText(ElevatedButton, 'Confirmer le retrait'),
      );
      await tester.pumpAndSettle();

      expect(find.text('Confirmer le retrait'), findsWidgets);
      await tester.tap(
        find.widgetWithText(ElevatedButton, 'Confirmer le retrait').last,
      );
      await tester.pumpAndSettle();

      expect(repo.lastAmount, 600);
      expect(repo.lastMethod, 'orange');
      expect(repo.lastPhone, contains('+225'));
    });

    testWidgets('failed withdraw shows error snackbar', (tester) async {
      final repo = FakeWalletRepo(shouldThrow: true);
      await pumpLargeWidget(tester, buildWithdrawSheet(repo: repo));

      await tester.enterText(find.byType(TextField).first, '0712345678');
      await tester.enterText(find.byType(TextField).last, '600');
      await tester.tap(
        find.widgetWithText(ElevatedButton, 'Confirmer le retrait'),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.widgetWithText(ElevatedButton, 'Confirmer le retrait').last,
      );
      await tester.pumpAndSettle();

      expect(find.byType(SnackBar), findsOneWidget);
    });
  });
}
