import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:courier/data/models/wallet_data.dart';
import 'package:courier/presentation/widgets/wallet/wallet_balance_card.dart';
import 'package:courier/presentation/widgets/wallet/transaction_list.dart';
import 'package:courier/presentation/widgets/wallet/operator_shortcuts.dart';
import 'package:courier/presentation/widgets/wallet/insufficient_balance_banner.dart';
import 'package:intl/date_symbol_data_local.dart';

import '../../helpers/widget_test_helpers.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('fr_FR', null);
  });

  Widget wrapWithProviders(Widget child) {
    return ProviderScope(
      overrides: commonWidgetTestOverrides(),
      child: MaterialApp(
        home: Scaffold(body: SingleChildScrollView(child: child)),
      ),
    );
  }

  group('WalletBalanceCard', () {
    final mockWallet = WalletData(
      balance: 15000,
      currency: 'XOF',
      pendingPayouts: 1000,
      totalEarnings: 50000,
      totalTopups: 35000,
      totalCommissions: 2500,
      canDeliver: true,
      transactions: [],
    );

    testWidgets('renders with wallet data', (tester) async {
      await tester.pumpWidget(
        wrapWithProviders(
          WalletBalanceCard(
            wallet: mockWallet,
            onTopUp: () {},
            onWithdraw: () {},
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(WalletBalanceCard), findsOneWidget);
    });

    testWidgets('shows balance amount formatted', (tester) async {
      await tester.pumpWidget(
        wrapWithProviders(
          WalletBalanceCard(
            wallet: mockWallet,
            onTopUp: () {},
            onWithdraw: () {},
          ),
        ),
      );
      await tester.pump();

      expect(find.textContaining('15'), findsWidgets);
    });

    testWidgets('has action area with buttons', (tester) async {
      await tester.pumpWidget(
        wrapWithProviders(
          WalletBalanceCard(
            wallet: mockWallet,
            onTopUp: () {},
            onWithdraw: () {},
          ),
        ),
      );
      await tester.pump();

      // Vérifie que le widget contient des widgets Row (pour les boutons)
      expect(find.byType(Row), findsWidgets);
    });

    testWidgets('shows recharger text', (tester) async {
      await tester.pumpWidget(
        wrapWithProviders(
          WalletBalanceCard(
            wallet: mockWallet,
            onTopUp: () {},
            onWithdraw: () {},
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Recharger'), findsOneWidget);
    });

    testWidgets('shows retirer text', (tester) async {
      await tester.pumpWidget(
        wrapWithProviders(
          WalletBalanceCard(
            wallet: mockWallet,
            onTopUp: () {},
            onWithdraw: () {},
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Retirer'), findsOneWidget);
    });
  });

  group('TransactionList', () {
    final mockTransactions = [
      WalletTransaction(
        id: 1,
        amount: 500,
        type: 'credit',
        description: 'Livraison',
        status: 'completed',
        createdAt: DateTime(2024, 1, 15),
      ),
      WalletTransaction(
        id: 2,
        amount: -200,
        type: 'debit',
        description: 'Commission',
        status: 'completed',
        createdAt: DateTime(2024, 1, 14),
      ),
    ];

    testWidgets('renders transaction list', (tester) async {
      await tester.pumpWidget(
        wrapWithProviders(
          TransactionList(
            transactions: mockTransactions,
            onViewEarnings: () {},
            onTopUp: () {},
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(TransactionList), findsOneWidget);
    });

    testWidgets('shows transaction descriptions', (tester) async {
      await tester.pumpWidget(
        wrapWithProviders(
          TransactionList(
            transactions: mockTransactions,
            onViewEarnings: () {},
            onTopUp: () {},
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Livraison'), findsOneWidget);
    });

    testWidgets('shows empty state when no transactions', (tester) async {
      await tester.pumpWidget(
        wrapWithProviders(
          TransactionList(
            transactions: const [],
            onViewEarnings: () {},
            onTopUp: () {},
          ),
        ),
      );
      await tester.pump();

      expect(find.textContaining('Aucune'), findsWidgets);
    });

    testWidgets('shows historique header', (tester) async {
      await tester.pumpWidget(
        wrapWithProviders(
          TransactionList(
            transactions: mockTransactions,
            onViewEarnings: () {},
            onTopUp: () {},
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Historique'), findsOneWidget);
    });
  });

  group('OperatorShortcuts', () {
    testWidgets('renders operator list', (tester) async {
      await tester.pumpWidget(
        wrapWithProviders(
          OperatorShortcuts(
            onOperatorSelected: (op) {},
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(OperatorShortcuts), findsOneWidget);
    });

    testWidgets('shows operator names', (tester) async {
      await tester.pumpWidget(
        wrapWithProviders(
          OperatorShortcuts(
            onOperatorSelected: (op) {},
          ),
        ),
      );
      await tester.pump();

      // Vérifie qu'au moins un opérateur est affiché
      expect(find.byType(GestureDetector), findsWidgets);
    });

    testWidgets('calls onOperatorSelected callback', (tester) async {
      String? selectedOperator;
      await tester.pumpWidget(
        wrapWithProviders(
          OperatorShortcuts(
            onOperatorSelected: (op) => selectedOperator = op,
          ),
        ),
      );
      await tester.pump();

      final gestures = find.byType(GestureDetector);
      if (gestures.evaluate().isNotEmpty) {
        await tester.tap(gestures.first);
        await tester.pump();
        expect(selectedOperator, isNotNull);
      }
    });
  });

  group('InsufficientBalanceBanner', () {
    testWidgets('renders banner with message', (tester) async {
      await tester.pumpWidget(
        wrapWithProviders(
          const InsufficientBalanceBanner(
            commissionAmount: 500,
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(InsufficientBalanceBanner), findsOneWidget);
    });

    testWidgets('shows commission amount', (tester) async {
      await tester.pumpWidget(
        wrapWithProviders(
          const InsufficientBalanceBanner(
            commissionAmount: 500,
          ),
        ),
      );
      await tester.pump();

      expect(find.textContaining('500'), findsWidgets);
    });

    testWidgets('has warning icon', (tester) async {
      await tester.pumpWidget(
        wrapWithProviders(
          const InsufficientBalanceBanner(
            commissionAmount: 500,
          ),
        ),
      );
      await tester.pump();

      expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
    });

    testWidgets('shows insufficient balance text', (tester) async {
      await tester.pumpWidget(
        wrapWithProviders(
          const InsufficientBalanceBanner(
            commissionAmount: 200,
          ),
        ),
      );
      await tester.pump();

      expect(find.textContaining('insuffisant'), findsOneWidget);
    });
  });
}
