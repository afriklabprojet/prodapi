import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drpharma_pharmacy/features/dashboard/presentation/widgets/dashboard_info_tabs.dart';
import 'package:drpharma_pharmacy/features/dashboard/presentation/widgets/dashboard_empty_state.dart';
import 'package:drpharma_pharmacy/features/dashboard/presentation/providers/dashboard_ui_provider.dart';
import 'package:drpharma_pharmacy/features/wallet/presentation/providers/wallet_provider.dart';
import 'package:drpharma_pharmacy/features/wallet/data/models/wallet_data.dart';
import 'package:drpharma_pharmacy/features/orders/presentation/providers/order_list_provider.dart';
import 'package:drpharma_pharmacy/features/orders/presentation/providers/state/order_list_state.dart';
import 'package:drpharma_pharmacy/features/prescriptions/presentation/providers/prescription_provider.dart';
import 'package:drpharma_pharmacy/l10n/app_localizations.dart';

/// Integration test for the Dashboard Info Tabs feature.
///
/// Run with:
///   flutter test integration_test/dashboard_info_tabs_test.dart
///
/// Tests the full user journey through the 3 dashboard tabs:
///   Finances → Commandes → Ordonnances → back to Finances
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Dashboard Info Tabs — full tab cycle', () {
    testWidgets('user can navigate across all 3 tabs', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            walletProvider.overrideWith(
              (ref) => Stream.value(
                WalletData(
                  balance: 50000,
                  currency: 'XOF',
                  totalEarnings: 200000,
                  totalCommissionPaid: 5000,
                  transactions: [],
                ),
              ),
            ),
            orderListProvider.overrideWith(() => _EmptyOrderNotifier()),
            prescriptionListProvider.overrideWith(
              () => _EmptyPrescriptionNotifier(),
            ),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('fr'),
            home: Scaffold(
              body: SingleChildScrollView(
                child: DashboardInfoTabs(walletKey: GlobalKey()),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // ── Step 1: Finances tab (default) ──
      expect(find.text('Finances'), findsOneWidget);
      expect(find.text('Solde'), findsOneWidget);
      expect(find.text('50K'), findsOneWidget);
      expect(find.text('Total gagné'), findsOneWidget);
      expect(find.text('200K'), findsOneWidget);

      // ── Step 2: Switch to Orders ──
      await tester.tap(find.text('Commandes'));
      await tester.pumpAndSettle();

      expect(find.text('Aucune commande récente'), findsOneWidget);
      expect(find.byType(DashboardEmptyState), findsOneWidget);

      // ── Step 3: Switch to Prescriptions ──
      await tester.tap(find.text('Ordonnances'));
      await tester.pumpAndSettle();

      expect(find.text('Aucune ordonnance récente'), findsOneWidget);

      // ── Step 4: Return to Finances ──
      await tester.tap(find.text('Finances'));
      await tester.pumpAndSettle();

      expect(find.text('Solde'), findsOneWidget);
      expect(find.text('50K'), findsOneWidget);
    });

    testWidgets('tab state is preserved via provider', (tester) async {
      final container = ProviderContainer(
        overrides: [
          walletProvider.overrideWith(
            (ref) => Stream.value(
              WalletData(
                balance: 0,
                currency: 'XOF',
                totalEarnings: 0,
                totalCommissionPaid: 0,
                transactions: [],
              ),
            ),
          ),
          orderListProvider.overrideWith(() => _EmptyOrderNotifier()),
          prescriptionListProvider.overrideWith(
            () => _EmptyPrescriptionNotifier(),
          ),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('fr'),
            home: Scaffold(
              body: SingleChildScrollView(
                child: DashboardInfoTabs(walletKey: GlobalKey()),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Switch to Prescriptions
      await tester.tap(find.text('Ordonnances'));
      await tester.pumpAndSettle();

      // Verify provider state is 2
      expect(container.read(selectedInfoTabProvider), 2);

      container.dispose();
    });
  });
}

// ---------------------------------------------------------------------------
// Minimal test notifiers
// ---------------------------------------------------------------------------

class _EmptyOrderNotifier extends OrderListNotifier {
  @override
  OrderListState build() {
    return OrderListState(status: OrderLoadStatus.loaded, orders: []);
  }
}

class _EmptyPrescriptionNotifier extends PrescriptionListNotifier {
  @override
  PrescriptionListState build() {
    return PrescriptionListState(
      status: PrescriptionStatus.loaded,
      prescriptions: [],
    );
  }
}
