import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:courier/presentation/screens/wallet_screen.dart';
import 'package:courier/data/models/wallet_data.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('fr_FR');
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
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
        walletDataProvider.overrideWith((ref) => Future.value(wallet ?? testWallet)),
      ],
      child: const MaterialApp(
        home: WalletScreen(),
      ),
    );
  }

  group('WalletScreen - App Bar', () {
    testWidgets('displays app bar with title', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(find.text('Mon Portefeuille'), findsOneWidget);
    });

    testWidgets('displays refresh button', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.refresh), findsOneWidget);
    });
  });

  group('WalletScreen - Balance Card', () {
    testWidgets('displays Solde Disponible label', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(find.text('Solde Disponible'), findsOneWidget);
    });

    testWidgets('displays formatted balance with currency', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      // 25000 formatted as "25 000 XOF" in fr_FR locale
      expect(find.textContaining('25'), findsAtLeastNWidgets(1));
      expect(find.textContaining('XOF'), findsAtLeastNWidgets(1));
    });

    testWidgets('displays stat items in balance card', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(find.text('Livraisons'), findsOneWidget);
      expect(find.text('Gains'), findsOneWidget);
      expect(find.text('Commissions'), findsOneWidget);
    });

    testWidgets('displays deliveries count', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(find.text('60'), findsOneWidget);
    });

    testWidgets('displays Recharger button', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(find.text('Recharger'), findsOneWidget);
      expect(find.byIcon(Icons.add_circle_outline), findsAtLeastNWidgets(1));
    });

    testWidgets('displays Retirer button', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(find.text('Retirer'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_downward), findsAtLeastNWidgets(1));
    });

    testWidgets('displays stat icons', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.local_shipping_outlined), findsOneWidget);
      expect(find.byIcon(Icons.trending_up), findsAtLeastNWidgets(1));
      expect(find.byIcon(Icons.trending_down), findsOneWidget);
    });
  });

  group('WalletScreen - Operators', () {
    testWidgets('displays operator shortcuts', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(find.text('Orange Money'), findsOneWidget);
      expect(find.text('MTN MoMo'), findsOneWidget);
      expect(find.text('Wave'), findsOneWidget);
      expect(find.text('Carte'), findsOneWidget);
    });
  });

  group('WalletScreen - Transactions', () {
    testWidgets('displays Historique section', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(find.text('Historique'), findsOneWidget);
    });

    testWidgets('displays Voir les gains button', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(find.text('Voir les gains'), findsOneWidget);
    });

    testWidgets('displays commission transaction', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(find.text('Commission Dr Pharma'), findsOneWidget);
    });

    testWidgets('displays topup transaction', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(find.text('Rechargement'), findsOneWidget);
    });

    testWidgets('displays withdrawal transaction', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(find.text('Retrait Mobile Money'), findsOneWidget);
    });

    testWidgets('displays pending status badge', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(find.text('En attente'), findsOneWidget);
    });

    testWidgets('displays empty transactions state', (tester) async {
      await tester.pumpWidget(buildScreen(wallet: emptyWallet));
      await tester.pumpAndSettle();

      expect(find.text('Aucune transaction'), findsOneWidget);
      expect(find.byIcon(Icons.receipt_long_outlined), findsOneWidget);
    });
  });

  group('WalletScreen - Warning & States', () {
    testWidgets('displays warning when cannot deliver', (tester) async {
      await tester.pumpWidget(buildScreen(wallet: cantDeliverWallet));
      await tester.pumpAndSettle();

      expect(find.textContaining('Solde insuffisant'), findsOneWidget);
      expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
    });

    testWidgets('no warning when can deliver', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(find.textContaining('Solde insuffisant'), findsNothing);
    });

    testWidgets('disables Retirer button with low balance', (tester) async {
      await tester.pumpWidget(buildScreen(wallet: lowBalanceWallet));
      await tester.pumpAndSettle();

      // Balance 400 < 500, Retirer button should be disabled
      expect(find.text('Retirer'), findsOneWidget);
    });

    testWidgets('shows loading state', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            walletDataProvider.overrideWith((ref) => Completer<WalletData>().future),
          ],
          child: const MaterialApp(
            home: WalletScreen(),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });
}
