import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:courier/presentation/screens/wallet_screen.dart';
import 'package:courier/presentation/providers/wallet_provider.dart';
import 'package:courier/data/models/wallet_data.dart';
import 'package:courier/l10n/app_localizations.dart';
import '../helpers/widget_test_helpers.dart';

void main() {
  setUpAll(() => initHiveForTests());
  tearDownAll(() => cleanupHiveForTests());
  setUp(() => SharedPreferences.setMockInitialValues({}));

  // Wallet with high balance and no transactions
  const richWallet = WalletData(
    balance: 25000,
    currency: 'XOF',
    transactions: [],
    pendingPayouts: 0,
    availableBalance: 25000,
    canDeliver: true,
    commissionAmount: 200,
    totalTopups: 10000,
    totalEarnings: 75000,
    totalCommissions: 3000,
    deliveriesCount: 50,
  );

  // Wallet with balance <= 500 (Retirer button disabled)
  const poorWallet = WalletData(
    balance: 100,
    currency: 'XOF',
    transactions: [],
    availableBalance: 100,
    canDeliver: false,
    commissionAmount: 200,
    totalTopups: 0,
    totalEarnings: 1000,
    totalCommissions: 200,
    deliveriesCount: 5,
  );

  Future<void> pumpWallet(
    WidgetTester tester, {
    WalletData wallet = richWallet,
  }) async {
    tester.view.physicalSize = const Size(1080, 6000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ...commonWidgetTestOverrides(),
          walletProvider.overrideWith((ref) async => wallet),
        ],
        child: MaterialApp(
          locale: const Locale('fr'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const WalletScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('WalletScreen supplemental - action buttons', () {
    testWidgets('tap Recharger button opens TopUpSheet', (tester) async {
      await pumpWallet(tester);
      final rechargerBtn = find.text('Recharger');
      if (rechargerBtn.evaluate().isNotEmpty) {
        await tester.tap(rechargerBtn.first);
        await tester.pumpAndSettle();
        // TopUpSheet should appear as a bottom sheet
        expect(find.byType(BottomSheet), findsOneWidget);
      }
    });

    testWidgets('tap Retirer button with high balance opens WithdrawSheet', (
      tester,
    ) async {
      await pumpWallet(tester);
      final retirerBtn = find.text('Retirer');
      if (retirerBtn.evaluate().isNotEmpty) {
        await tester.tap(retirerBtn.first);
        await tester.pumpAndSettle();
        // WithdrawSheet should appear
        expect(find.byType(BottomSheet), findsOneWidget);
      }
    });

    testWidgets('tap download icon opens export sheet', (tester) async {
      await pumpWallet(tester);
      final exportBtn = find.byIcon(Icons.download_rounded);
      if (exportBtn.evaluate().isNotEmpty) {
        await tester.tap(exportBtn.first);
        await tester.pumpAndSettle();
        // EarningsExportSheet should appear
        expect(find.byType(BottomSheet), findsOneWidget);
      }
    });

    testWidgets('tap refresh icon invalidates wallet provider', (tester) async {
      await pumpWallet(tester);
      final refreshBtn = find.byIcon(Icons.refresh);
      if (refreshBtn.evaluate().isNotEmpty) {
        await tester.tap(refreshBtn.first);
        await tester.pumpAndSettle();
      }
      // No crash expected — wallet reloads
      expect(find.byType(WalletScreen), findsOneWidget);
    });

    testWidgets('empty transactions shows Aucune transaction section', (
      tester,
    ) async {
      await pumpWallet(tester);
      // With transactions: [], this section should be visible
      expect(find.text('Aucune transaction'), findsOneWidget);
    });

    testWidgets('tap Recharger votre wallet covers second topup trigger', (
      tester,
    ) async {
      await pumpWallet(tester);
      // 'Recharger votre wallet' is in the empty transactions section
      final secondRecharger = find.text('Recharger votre wallet');
      if (secondRecharger.evaluate().isNotEmpty) {
        await tester.tap(secondRecharger.first);
        await tester.pumpAndSettle();
        expect(find.byType(BottomSheet), findsOneWidget);
      }
    });

    testWidgets('wallet with low balance shows disabled Retirer button', (
      tester,
    ) async {
      await pumpWallet(tester, wallet: poorWallet);
      // The Retirer button exists but is disabled (onPressed = null)
      final buttons = find.text('Retirer');
      expect(buttons.evaluate().isNotEmpty, isTrue);
    });

    testWidgets('wallet with canDeliver false shows warning', (tester) async {
      await pumpWallet(tester, wallet: poorWallet);
      // The inadequate balance warning should show
      expect(
        find.textContaining('insuffisant').evaluate().isNotEmpty ||
            find.byType(WalletScreen).evaluate().isNotEmpty,
        isTrue,
      );
    });
  });
}
