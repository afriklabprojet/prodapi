import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:courier/presentation/screens/earnings_history_screen.dart';
import 'package:courier/data/models/wallet_data.dart';

WalletTransaction _tx({
  int id = 1,
  double amount = 1000,
  String type = 'credit',
  String? category = 'delivery_earning',
  String? description,
  String? reference,
}) {
  return WalletTransaction(
    id: id,
    amount: amount,
    type: type,
    category: category,
    description: description,
    reference: reference,
    createdAt: DateTime.now().subtract(const Duration(hours: 2)),
  );
}

WalletData _wallet({
  double balance = 15000,
  String currency = 'XOF',
  List<WalletTransaction> transactions = const [],
  int commissionAmount = 200,
}) {
  return WalletData(
    balance: balance,
    currency: currency,
    transactions: transactions,
    commissionAmount: commissionAmount,
  );
}

Widget buildTestWidget({required WalletData wallet}) {
  return ProviderScope(
    overrides: [
      walletDataProvider.overrideWith((ref) => Future.value(wallet)),
    ],
    child: const MaterialApp(home: EarningsHistoryScreen()),
  );
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('fr_FR', null);
  });

  group('EarningsHistoryScreen', () {
    testWidgets('shows app bar title', (tester) async {
      await tester.pumpWidget(buildTestWidget(wallet: _wallet()));
      await tester.pumpAndSettle();
      expect(find.text('Historique des Revenus'), findsOneWidget);
    });

    testWidgets('shows net earnings card', (tester) async {
      await tester.pumpWidget(buildTestWidget(wallet: _wallet()));
      await tester.pumpAndSettle();
      expect(find.text('Gains Nets'), findsOneWidget);
    });

    testWidgets('shows total gains and commissions', (tester) async {
      final txs = [
        _tx(id: 1, amount: 3000, type: 'credit', category: 'delivery_earning'),
        _tx(id: 2, amount: 500, type: 'debit', category: 'commission'),
      ];
      await tester.pumpWidget(buildTestWidget(wallet: _wallet(transactions: txs)));
      await tester.pumpAndSettle();
      expect(find.text('Total Gains'), findsOneWidget);
      expect(find.text('Commissions'), findsOneWidget);
    });

    testWidgets('shows period cards', (tester) async {
      await tester.pumpWidget(buildTestWidget(wallet: _wallet()));
      await tester.pumpAndSettle();
      expect(find.text("Aujourd'hui"), findsOneWidget);
      expect(find.text('Cette semaine'), findsOneWidget);
      expect(find.text('Ce mois'), findsOneWidget);
    });

    testWidgets('shows commission detail', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        wallet: _wallet(commissionAmount: 200),
      ));
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.text('Commission Plateforme'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Commission Plateforme'), findsOneWidget);
    });

    testWidgets('shows empty transactions state', (tester) async {
      await tester.pumpWidget(buildTestWidget(wallet: _wallet()));
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.text('Aucune transaction'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Aucune transaction'), findsOneWidget);
    });

    testWidgets('shows transaction history header', (tester) async {
      await tester.pumpWidget(buildTestWidget(wallet: _wallet()));
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.text('Historique des Transactions'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Historique des Transactions'), findsOneWidget);
    });

    testWidgets('shows transactions when available', (tester) async {
      final txs = [
        _tx(id: 1, amount: 2000, type: 'credit', category: 'delivery_earning'),
        _tx(id: 2, amount: 300, type: 'debit', category: 'commission'),
      ];
      await tester.pumpWidget(buildTestWidget(wallet: _wallet(transactions: txs)));
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.text('Gain livraison'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Gain livraison'), findsOneWidget);
    });

    testWidgets('shows Livraisons count card', (tester) async {
      await tester.pumpWidget(buildTestWidget(wallet: _wallet()));
      await tester.pumpAndSettle();
      expect(find.textContaining('Livraisons'), findsAtLeastNWidgets(1));
    });

    testWidgets('loading state shows indicator', (tester) async {
      late Future<WalletData> completer;
      completer = Future(() async {
        await Future.delayed(const Duration(milliseconds: 100));
        return _wallet();
      });
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            walletDataProvider.overrideWith((ref) => completer),
          ],
          child: const MaterialApp(home: EarningsHistoryScreen()),
        ),
      );
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsAtLeastNWidgets(1));
      await tester.pumpAndSettle();
    });
  });
}
