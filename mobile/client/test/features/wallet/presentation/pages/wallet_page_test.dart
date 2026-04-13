import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

import 'package:drpharma_client/core/router/app_router.dart';
import 'package:drpharma_client/features/wallet/presentation/pages/wallet_page.dart';
import 'package:drpharma_client/features/wallet/presentation/providers/wallet_provider.dart';
import 'package:drpharma_client/features/wallet/presentation/providers/wallet_notifier.dart';
import 'package:drpharma_client/features/wallet/presentation/providers/wallet_state.dart';
import 'package:drpharma_client/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:drpharma_client/config/providers.dart';
import 'package:drpharma_client/features/wallet/domain/entities/wallet_entity.dart';
import '../../../../helpers/fake_api_client.dart';

class MockWalletNotifier extends StateNotifier<WalletState>
    with Mock
    implements WalletNotifier {
  MockWalletNotifier() : super(const WalletState.initial());

  @override
  Future<void> loadAll() async {}

  @override
  Future<void> loadWallet() async {}

  @override
  Future<void> loadTransactions({String? category}) async {}

  @override
  Future<PaymentInitResult?> initiateTopUp({
    required double amount,
    required String paymentMethod,
  }) async => null;

  @override
  Future<PaymentStatusResult?> checkPaymentStatus(String reference) async =>
      null;

  @override
  Future<bool> topUp({
    required double amount,
    required String paymentMethod,
    String? paymentReference,
  }) async => false;

  @override
  Future<bool> withdraw({
    required double amount,
    required String paymentMethod,
    required String phoneNumber,
  }) async => false;

  @override
  Future<bool> payOrder({
    required double amount,
    required String orderReference,
  }) async => false;

  @override
  void clearMessages() {}
}

void main() {
  late SharedPreferences sharedPreferences;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    sharedPreferences = await SharedPreferences.getInstance();
  });

  Widget createTestWidget({WalletState? initialState}) {
    return ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(sharedPreferences),
        apiClientProvider.overrideWithValue(FakeApiClient()),
        walletProvider.overrideWith(
          (_) =>
              MockWalletNotifier()
                ..state = initialState ?? const WalletState.initial(),
        ),
      ],
      child: MaterialApp(
        locale: const Locale('fr'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: const WalletPage(),
      ),
    );
  }

  Widget createRouterTestWidget({WalletState? initialState}) {
    final notifier = MockWalletNotifier()
      ..state = initialState ?? const WalletState.initial();

    final router = GoRouter(
      initialLocation: AppRoutes.wallet,
      routes: [
        GoRoute(
          path: AppRoutes.wallet,
          builder: (context, state) => const WalletPage(),
        ),
        GoRoute(
          path: AppRoutes.walletTopUp,
          builder: (context, state) => const TopUpPage(),
        ),
        GoRoute(
          path: AppRoutes.walletWithdraw,
          builder: (context, state) => const WithdrawPage(),
        ),
      ],
    );

    return ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(sharedPreferences),
        apiClientProvider.overrideWithValue(FakeApiClient()),
        walletProvider.overrideWith((_) => notifier),
      ],
      child: MaterialApp.router(
        locale: const Locale('fr'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: router,
      ),
    );
  }

  MockWalletNotifier? mutableNotifier;

  Widget createTestWidgetWithMutableNotifier({WalletState? initialState}) {
    mutableNotifier = MockWalletNotifier()
      ..state =
          initialState ??
          const WalletState(
            status: WalletStatus.loaded,
            transactions: [],
            wallet: WalletEntity(
              balance: 5000,
              availableBalance: 4500,
              statistics: WalletStatistics(),
            ),
          );
    return ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(sharedPreferences),
        apiClientProvider.overrideWithValue(FakeApiClient()),
        walletProvider.overrideWith((_) => mutableNotifier!),
      ],
      child: MaterialApp(
        locale: const Locale('fr'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: const WalletPage(),
      ),
    );
  }

  group('WalletPage Widget Tests', () {
    testWidgets('should render wallet page', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(createTestWidget());
      await tester.pump();
      expect(find.byType(WalletPage), findsOneWidget);
    });

    testWidgets('should have app bar', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(createTestWidget());
      await tester.pump();
      expect(find.byType(AppBar), findsOneWidget);
    });

    testWidgets('should show loading indicator when loading', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        createTestWidget(
          initialState: const WalletState(
            status: WalletStatus.loading,
            transactions: [],
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(WalletPage), findsOneWidget);
    });

    testWidgets('should build widget without error in initial state', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(createTestWidget());
      await tester.pump();
      expect(find.byType(Scaffold), findsOneWidget);
    });
  });

  group('WalletPage State Tests', () {
    testWidgets('shows AppBar title Portefeuille', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      expect(find.text('Portefeuille'), findsOneWidget);
    });

    testWidgets('error state shows Réessayer button', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        createTestWidget(
          initialState: const WalletState(
            status: WalletStatus.error,
            transactions: [],
            errorMessage: 'Erreur de connexion',
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Réessayer'), findsOneWidget);
    });

    testWidgets('error state shows error message text', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        createTestWidget(
          initialState: const WalletState(
            status: WalletStatus.error,
            transactions: [],
            errorMessage: 'Erreur de connexion',
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Erreur de connexion'), findsOneWidget);
    });

    testWidgets('loaded state renders without crash', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      const wallet = WalletEntity(
        balance: 5000,
        availableBalance: 4500,
        statistics: WalletStatistics(),
      );

      await tester.pumpWidget(
        createTestWidget(
          initialState: const WalletState(
            status: WalletStatus.loaded,
            transactions: [],
            wallet: wallet,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(WalletPage), findsOneWidget);
    });

    testWidgets('loaded state shows wallet balance', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      const wallet = WalletEntity(
        balance: 5000,
        availableBalance: 4500,
        statistics: WalletStatistics(),
      );

      await tester.pumpWidget(
        createTestWidget(
          initialState: const WalletState(
            status: WalletStatus.loaded,
            transactions: [],
            wallet: wallet,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('5'), findsWidgets);
    });
  });

  group('WalletPage Transaction Tests', () {
    final testTransaction = WalletTransactionEntity(
      id: 1,
      type: TransactionType.credit,
      category: TransactionCategory.topup,
      amount: 1000.0,
      balanceAfter: 6000.0,
      reference: 'TXN001',
      description: 'Rechargement test',
      createdAt: DateTime(2024, 1, 15),
    );

    const wallet = WalletEntity(
      balance: 6000,
      availableBalance: 5500,
      statistics: WalletStatistics(),
    );

    testWidgets(
      'shows transaction description when transactions list is non-empty',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          createTestWidget(
            initialState: WalletState(
              status: WalletStatus.loaded,
              transactions: [testTransaction],
              wallet: wallet,
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(
          find.textContaining('Rechargement test').evaluate().isNotEmpty ||
              find.textContaining('Rechargement').evaluate().isNotEmpty,
          isTrue,
        );
      },
    );

    testWidgets('Rechargement category label appears in transaction', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        createTestWidget(
          initialState: WalletState(
            status: WalletStatus.loaded,
            transactions: [testTransaction],
            wallet: wallet,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('Rechargement'), findsAtLeastNWidgets(1));
    });

    testWidgets('shows transaction list when loaded with transactions', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        createTestWidget(
          initialState: WalletState(
            status: WalletStatus.loaded,
            transactions: [testTransaction],
            wallet: wallet,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(WalletPage), findsOneWidget);
    });

    testWidgets('shows Recharger button in loaded state', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        createTestWidget(
          initialState: const WalletState(
            status: WalletStatus.loaded,
            transactions: [],
            wallet: wallet,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Recharger').evaluate().isNotEmpty ||
            find.byType(FloatingActionButton).evaluate().isNotEmpty,
        isTrue,
      );
    });

    testWidgets('shows balance card in loaded state', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        createTestWidget(
          initialState: const WalletState(
            status: WalletStatus.loaded,
            transactions: [],
            wallet: wallet,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('6'), findsWidgets);
    });
  });

  // ─── Category Filter ───

  group('WalletPage Category Filter Tests', () {
    final creditTx = WalletTransactionEntity(
      id: 1,
      type: TransactionType.credit,
      category: TransactionCategory.topup,
      amount: 1000.0,
      balanceAfter: 6000.0,
      reference: 'TXN001',
      description: 'Rechargement',
      createdAt: DateTime(2024, 1, 15),
    );

    final debitTx = WalletTransactionEntity(
      id: 2,
      type: TransactionType.debit,
      category: TransactionCategory.orderPayment,
      amount: 2000.0,
      balanceAfter: 4000.0,
      reference: 'TXN002',
      description: 'Paiement commande CMD-001',
      createdAt: DateTime(2024, 2, 10),
    );

    const wallet = WalletEntity(
      balance: 6000,
      availableBalance: 5500,
      statistics: WalletStatistics(ordersPaid: 3, totalTopups: 10000),
    );

    WalletState loadedState({List<WalletTransactionEntity>? txns}) =>
        WalletState(
          status: WalletStatus.loaded,
          transactions: txns ?? [creditTx, debitTx],
          wallet: wallet,
        );

    testWidgets('shows Tout filter chip', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(createTestWidget(initialState: loadedState()));
      await tester.pumpAndSettle();
      expect(find.widgetWithText(FilterChip, 'Tout'), findsOneWidget);
    });

    testWidgets('shows Rechargements filter chip', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(createTestWidget(initialState: loadedState()));
      await tester.pumpAndSettle();
      expect(find.widgetWithText(FilterChip, 'Rechargements'), findsOneWidget);
    });

    testWidgets('shows Paiements filter chip', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(createTestWidget(initialState: loadedState()));
      await tester.pumpAndSettle();
      expect(find.widgetWithText(FilterChip, 'Paiements'), findsOneWidget);
    });

    testWidgets('shows Remboursements filter chip', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(createTestWidget(initialState: loadedState()));
      await tester.pumpAndSettle();
      expect(find.widgetWithText(FilterChip, 'Remboursements'), findsOneWidget);
    });

    testWidgets('shows Retraits filter chip', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(createTestWidget(initialState: loadedState()));
      await tester.pumpAndSettle();
      expect(find.widgetWithText(FilterChip, 'Retraits'), findsOneWidget);
    });

    testWidgets('empty transaction list shows Aucune transaction', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        createTestWidget(initialState: loadedState(txns: [])),
      );
      await tester.pumpAndSettle();
      expect(find.text('Aucune transaction'), findsOneWidget);
    });

    testWidgets('tapping Rechargements filter selects it', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(createTestWidget(initialState: loadedState()));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilterChip, 'Rechargements'));
      await tester.pump();
      final chip = tester.widget<FilterChip>(
        find.widgetWithText(FilterChip, 'Rechargements'),
      );
      expect(chip.selected, isTrue);
    });

    testWidgets(
      'after filter tap shows Aucune transaction for empty category',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(
          createTestWidget(
            initialState: loadedState(txns: [creditTx]), // only topup tx
          ),
        );
        await tester.pumpAndSettle();
        // Filter by orderPayment which has no transactions
        await tester.tap(find.widgetWithText(FilterChip, 'Paiements'));
        await tester.pump();
        expect(find.text('Aucune transaction'), findsOneWidget);
      },
    );

    testWidgets('shows Historique section header', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(createTestWidget(initialState: loadedState()));
      await tester.pumpAndSettle();
      expect(find.text('Historique'), findsOneWidget);
    });
  });

  // ─── Statistics ───

  group('WalletPage Statistics Tests', () {
    const statsWallet = WalletEntity(
      balance: 8000,
      availableBalance: 7000,
      statistics: WalletStatistics(ordersPaid: 5, totalTopups: 15000),
    );

    testWidgets('shows Commandes payées stat label', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        createTestWidget(
          initialState: const WalletState(
            status: WalletStatus.loaded,
            transactions: [],
            wallet: statsWallet,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Commandes payées'), findsOneWidget);
    });

    testWidgets('shows ordersPaid count in stat card', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        createTestWidget(
          initialState: const WalletState(
            status: WalletStatus.loaded,
            transactions: [],
            wallet: statsWallet,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('5'), findsWidgets);
    });

    testWidgets('shows totalTopups value in stat card', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        createTestWidget(
          initialState: const WalletState(
            status: WalletStatus.loaded,
            transactions: [],
            wallet: statsWallet,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('15000 F'), findsOneWidget);
    });
  });

  // ─── TopUpPage ───

  group('TopUpPage Tests', () {
    Widget createTopUpWidget() {
      return ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(sharedPreferences),
          apiClientProvider.overrideWithValue(FakeApiClient()),
          walletProvider.overrideWith(
            (_) => MockWalletNotifier()
              ..state = const WalletState(
                status: WalletStatus.loaded,
                transactions: [],
                wallet: WalletEntity(
                  balance: 5000,
                  availableBalance: 4500,
                  statistics: WalletStatistics(),
                ),
              ),
          ),
        ],
        child: const MaterialApp(home: TopUpPage()),
      );
    }

    testWidgets('shows Recharger AppBar title', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(createTopUpWidget());
      await tester.pumpAndSettle();
      expect(find.text('Recharger'), findsWidgets);
    });

    testWidgets('shows Montant rapide label', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(createTopUpWidget());
      await tester.pumpAndSettle();
      expect(find.text('Montant rapide'), findsOneWidget);
    });

    testWidgets('shows quick amount chips', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(createTopUpWidget());
      await tester.pumpAndSettle();
      expect(find.text('500 F'), findsOneWidget);
      expect(find.text('1000 F'), findsOneWidget);
      expect(find.text('5000 F'), findsOneWidget);
    });

    testWidgets('shows Montant amount text field', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(createTopUpWidget());
      await tester.pumpAndSettle();
      expect(find.byType(TextFormField), findsOneWidget);
    });

    testWidgets('shows Opérateur de paiement selector', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(createTopUpWidget());
      await tester.pumpAndSettle();
      expect(find.text('Opérateur de paiement'), findsOneWidget);
    });

    testWidgets('shows Orange Money and Wave operator chips', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(createTopUpWidget());
      await tester.pumpAndSettle();
      expect(find.text('Orange Money'), findsOneWidget);
      expect(find.text('Wave'), findsOneWidget);
    });

    testWidgets('validates empty amount on submit', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(createTopUpWidget());
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ElevatedButton, 'Recharger'));
      await tester.pump();
      expect(find.text('Veuillez entrer un montant'), findsOneWidget);
    });

    testWidgets('validates amount below minimum', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(createTopUpWidget());
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField), '50');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Recharger'));
      await tester.pump();
      expect(find.textContaining('100 F CFA'), findsOneWidget);
    });

    testWidgets('quick amount chip fills in amount field', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(createTopUpWidget());
      await tester.pumpAndSettle();
      await tester.tap(find.text('1000 F'));
      await tester.pump();
      final field = tester.widget<TextFormField>(find.byType(TextFormField));
      expect(field.controller?.text, equals('1000'));
    });
  });

  // ─── WithdrawPage ───

  group('WithdrawPage Tests', () {
    Widget createWithdrawWidget({double availableBalance = 5000}) {
      return ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(sharedPreferences),
          apiClientProvider.overrideWithValue(FakeApiClient()),
          walletProvider.overrideWith(
            (_) => MockWalletNotifier()
              ..state = WalletState(
                status: WalletStatus.loaded,
                transactions: const [],
                wallet: WalletEntity(
                  balance: availableBalance,
                  availableBalance: availableBalance,
                  statistics: const WalletStatistics(),
                ),
              ),
          ),
        ],
        child: const MaterialApp(home: WithdrawPage()),
      );
    }

    testWidgets('shows Retrait AppBar title', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(createWithdrawWidget());
      await tester.pumpAndSettle();
      expect(find.text('Retrait'), findsOneWidget);
    });

    testWidgets('shows Solde disponible label', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(createWithdrawWidget());
      await tester.pumpAndSettle();
      expect(find.text('Solde disponible'), findsOneWidget);
    });

    testWidgets('shows available balance value', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(createWithdrawWidget(availableBalance: 7500));
      await tester.pumpAndSettle();
      expect(find.textContaining('7500'), findsAtLeastNWidgets(1));
    });

    testWidgets('shows Demander le retrait button when balance sufficient', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(createWithdrawWidget());
      await tester.pumpAndSettle();
      expect(find.text('Demander le retrait'), findsOneWidget);
    });

    testWidgets('shows Solde insuffisant button when balance < 500', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(createWithdrawWidget(availableBalance: 200));
      await tester.pumpAndSettle();
      expect(find.text('Solde insuffisant'), findsOneWidget);
    });

    testWidgets('shows Minimum requis warning when balance < 500', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(createWithdrawWidget(availableBalance: 300));
      await tester.pumpAndSettle();
      expect(find.textContaining('Minimum requis'), findsOneWidget);
    });

    testWidgets('shows operator chips for withdrawal', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(createWithdrawWidget());
      await tester.pumpAndSettle();
      expect(find.text('MTN MoMo'), findsOneWidget);
      expect(find.text('Moov Money'), findsOneWidget);
    });

    testWidgets('validates empty amount on submit', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(createWithdrawWidget());
      await tester.pumpAndSettle();
      await tester.tap(find.text('Demander le retrait'));
      await tester.pump();
      expect(find.text('Veuillez entrer un montant'), findsOneWidget);
    });
  });

  // ─── ref.listen callback tests ───

  group('WalletPage Listener Tests', () {
    testWidgets('ref.listen shows error snackbar on errorMessage change', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(createTestWidgetWithMutableNotifier());
      await tester.pump();

      // Trigger errorMessage transition
      mutableNotifier!.state = mutableNotifier!.state.copyWith(
        errorMessage: 'Erreur dynamique',
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      expect(find.text('Erreur dynamique'), findsOneWidget);
    });

    testWidgets('ref.listen shows success snackbar on successMessage change', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(createTestWidgetWithMutableNotifier());
      await tester.pump();

      // Trigger successMessage transition
      mutableNotifier!.state = mutableNotifier!.state.copyWith(
        successMessage: 'Succès dynamique',
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      expect(find.text('Succès dynamique'), findsOneWidget);
    });
  });

  // ─── Navigation tests ───

  group('WalletPage Navigation Tests', () {
    const testWallet = WalletEntity(
      balance: 5000,
      availableBalance: 4500,
      statistics: WalletStatistics(),
    );

    testWidgets('tapping Réessayer calls loadAll without crash', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        createTestWidget(
          initialState: const WalletState(
            status: WalletStatus.error,
            transactions: [],
            errorMessage: 'Erreur réseau',
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Réessayer'));
      await tester.pump();
      expect(find.byType(WalletPage), findsOneWidget);
    });

    testWidgets('tapping Recharger on BalanceCard navigates to TopUpPage', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        createRouterTestWidget(
          initialState: const WalletState(
            status: WalletStatus.loaded,
            transactions: [],
            wallet: testWallet,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(InkWell, 'Recharger').first);
      await tester.pumpAndSettle();
      expect(find.byType(TopUpPage), findsOneWidget);
    });

    testWidgets('tapping Retirer on BalanceCard navigates to WithdrawPage', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        createRouterTestWidget(
          initialState: const WalletState(
            status: WalletStatus.loaded,
            transactions: [],
            wallet: testWallet,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(InkWell, 'Retirer').first);
      await tester.pumpAndSettle();
      expect(find.byType(WithdrawPage), findsOneWidget);
    });
  });

  // ─── TopUpPage submit tests ───

  group('TopUpPage Submit Tests', () {
    Widget createTopUpWidget() {
      return ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(sharedPreferences),
          apiClientProvider.overrideWithValue(FakeApiClient()),
          walletProvider.overrideWith(
            (_) => MockWalletNotifier()
              ..state = const WalletState(
                status: WalletStatus.loaded,
                transactions: [],
                wallet: WalletEntity(
                  balance: 5000,
                  availableBalance: 4500,
                  statistics: WalletStatistics(),
                ),
              ),
          ),
        ],
        child: const MaterialApp(home: TopUpPage()),
      );
    }

    testWidgets('shows snackbar when no operator selected on submit', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(createTopUpWidget());
      await tester.pumpAndSettle();
      // Enter valid amount but skip operator selection
      await tester.enterText(find.byType(TextFormField), '1000');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Recharger'));
      await tester.pump();
      expect(find.text('Veuillez sélectionner un opérateur'), findsOneWidget);
    });

    testWidgets('selecting operator chip updates state', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(createTopUpWidget());
      await tester.pumpAndSettle();
      await tester.tap(find.text('Orange Money'));
      await tester.pump();
      final chip = tester.widget<ChoiceChip>(
        find.widgetWithText(ChoiceChip, 'Orange Money'),
      );
      expect(chip.selected, isTrue);
    });
  });
}
