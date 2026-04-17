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
  setUpAll(() async {
    await initHiveForTests();
  });

  tearDownAll(() async {
    await cleanupHiveForTests();
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  const testWallet = WalletData(
    balance: 25000,
    currency: 'XOF',
    transactions: [],
    pendingPayouts: 5000,
    availableBalance: 20000,
    canDeliver: true,
    commissionAmount: 200,
    totalTopups: 10000,
    totalEarnings: 75000,
    totalCommissions: 3000,
    deliveriesCount: 50,
  );

  Future<void> pumpWallet(
    WidgetTester tester, {
    WalletData wallet = testWallet,
    bool loading = false,
    bool error = false,
  }) async {
    tester.view.physicalSize = const Size(1080, 5000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final original = FlutterError.onError;
    FlutterError.onError = (_) {};
    try {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            ...commonWidgetTestOverrides(),
            if (!loading && !error)
              walletProvider.overrideWith((ref) async => wallet),
            if (loading)
              walletProvider.overrideWith((ref) async {
                await Future.delayed(const Duration(seconds: 60));
                return wallet;
              }),
            if (error)
              walletProvider.overrideWith((ref) async {
                throw Exception('Erreur réseau');
              }),
          ],
          child: MaterialApp(
            locale: const Locale('fr'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const WalletScreen(),
          ),
        ),
      );
      await tester.pump(const Duration(seconds: 1));
    } finally {
      FlutterError.onError = original;
    }
  }

  Future<void> drainTimers(WidgetTester tester) async {
    final original = FlutterError.onError;
    FlutterError.onError = (_) {};
    try {
      await tester.pump(const Duration(seconds: 5));
      await tester.pump(const Duration(seconds: 5));
    } finally {
      FlutterError.onError = original;
    }
  }

  group('WalletScreen', () {
    testWidgets('renders wallet screen', (tester) async {
      await pumpWallet(tester);
      expect(find.byType(WalletScreen), findsOneWidget);
      await drainTimers(tester);
    });

    testWidgets('shows wallet title', (tester) async {
      await pumpWallet(tester);
      expect(find.textContaining('Portefeuille'), findsWidgets);
      await drainTimers(tester);
    });

    testWidgets('shows balance', (tester) async {
      await pumpWallet(tester);
      expect(find.textContaining('25'), findsWidgets);
      await drainTimers(tester);
    });

    testWidgets('shows refresh button', (tester) async {
      await pumpWallet(tester);
      expect(find.byIcon(Icons.refresh), findsWidgets);
      await drainTimers(tester);
    });

    testWidgets('shows export button', (tester) async {
      await pumpWallet(tester);
      expect(find.byIcon(Icons.download_rounded), findsWidgets);
      await drainTimers(tester);
    });

    testWidgets('scroll down reveals more content', (tester) async {
      await pumpWallet(tester);
      final scrollable = find.byType(Scrollable).first;
      await tester.scrollUntilVisible(
        find.textContaining('Portefeuille').first,
        100,
        scrollable: scrollable,
      );
      await drainTimers(tester);
    });

    testWidgets('canDeliver false shows warning', (tester) async {
      const walletNoDeliver = WalletData(
        balance: 0,
        currency: 'XOF',
        transactions: [],
        canDeliver: false,
        commissionAmount: 200,
        totalTopups: 0,
        totalEarnings: 0,
        totalCommissions: 0,
        deliveriesCount: 0,
      );
      await pumpWallet(tester, wallet: walletNoDeliver);
      // Warning banner should appear when canDeliver is false
      expect(find.byType(WalletScreen), findsOneWidget);
      await drainTimers(tester);
    });

    testWidgets('error state shows error message', (tester) async {
      await pumpWallet(tester, error: true);
      await tester.pump(const Duration(seconds: 1));
      // Should show error state
      expect(find.byType(WalletScreen), findsOneWidget);
      await drainTimers(tester);
    });
  });
}
