// ignore_for_file: deprecated_member_use
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drpharma_pharmacy/features/dashboard/presentation/widgets/segmented_tab_bar.dart';
import 'package:drpharma_pharmacy/features/dashboard/presentation/widgets/dashboard_empty_state.dart';
import 'package:drpharma_pharmacy/features/dashboard/presentation/widgets/dashboard_skeletons.dart';
import 'package:drpharma_pharmacy/features/dashboard/presentation/widgets/dashboard_info_tabs.dart';
import 'package:drpharma_pharmacy/features/wallet/presentation/providers/wallet_provider.dart';
import 'package:drpharma_pharmacy/features/wallet/data/models/wallet_data.dart';
import 'package:drpharma_pharmacy/features/orders/presentation/providers/order_list_provider.dart';
import 'package:drpharma_pharmacy/features/orders/presentation/providers/state/order_list_state.dart';
import 'package:drpharma_pharmacy/features/prescriptions/presentation/providers/prescription_provider.dart';
import 'package:drpharma_pharmacy/l10n/app_localizations.dart';

// ---------------------------------------------------------------------------
// Test helpers
// ---------------------------------------------------------------------------

Widget _testApp(Widget child, {List<Override> overrides = const []}) {
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('fr'),
      home: Scaffold(body: SingleChildScrollView(child: child)),
    ),
  );
}

// ---------------------------------------------------------------------------
// SegmentedTabBar tests
// ---------------------------------------------------------------------------
void main() {
  group('SegmentedTabBar', () {
    testWidgets('renders all labels', (tester) async {
      await tester.pumpWidget(
        _testApp(
          SegmentedTabBar(
            labels: const ['Finances', 'Commandes', 'Ordonnances'],
            selectedIndex: 0,
            onTabChanged: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Finances'), findsOneWidget);
      expect(find.text('Commandes'), findsOneWidget);
      expect(find.text('Ordonnances'), findsOneWidget);
    });

    testWidgets('calls onTabChanged when tapped', (tester) async {
      int? tappedIndex;
      await tester.pumpWidget(
        _testApp(
          SegmentedTabBar(
            labels: const ['A', 'B', 'C'],
            selectedIndex: 0,
            onTabChanged: (i) => tappedIndex = i,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('B'));
      expect(tappedIndex, 1);

      await tester.tap(find.text('C'));
      expect(tappedIndex, 2);
    });

    testWidgets('has correct semantics for selected tab', (tester) async {
      await tester.pumpWidget(
        _testApp(
          SegmentedTabBar(
            labels: const ['A', 'B'],
            selectedIndex: 1,
            onTabChanged: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify semantics label for the selected tab includes "sélectionné"
      final selectedSemanticsNode = tester.getSemantics(
        find.bySemanticsLabel(RegExp(r'Onglet B.*sélectionné')),
      );
      expect(
        selectedSemanticsNode.getSemanticsData().flags &
                SemanticsFlag.isSelected.index !=
            0,
        isTrue,
      );
      expect(
        selectedSemanticsNode.getSemanticsData().flags &
                SemanticsFlag.isButton.index !=
            0,
        isTrue,
      );
    });
  });

  // ---------------------------------------------------------------------------
  // DashboardEmptyState tests
  // ---------------------------------------------------------------------------
  group('DashboardEmptyState', () {
    testWidgets('displays icon and message', (tester) async {
      await tester.pumpWidget(
        _testApp(
          const DashboardEmptyState(
            icon: Icons.inbox_rounded,
            message: 'Nothing here',
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.inbox_rounded), findsOneWidget);
      expect(find.text('Nothing here'), findsOneWidget);
    });

    testWidgets('shows action button when provided', (tester) async {
      bool tapped = false;
      await tester.pumpWidget(
        _testApp(
          DashboardEmptyState(
            icon: Icons.add,
            message: 'Empty',
            actionLabel: 'Add',
            onAction: () => tapped = true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Add'), findsOneWidget);
      await tester.tap(find.text('Add'));
      expect(tapped, isTrue);
    });

    testWidgets('hides action button when not provided', (tester) async {
      await tester.pumpWidget(
        _testApp(const DashboardEmptyState(icon: Icons.add, message: 'Empty')),
      );
      await tester.pumpAndSettle();

      expect(find.byType(TextButton), findsNothing);
    });
  });

  // ---------------------------------------------------------------------------
  // Skeleton widget tests
  // ---------------------------------------------------------------------------
  group('Skeleton widgets', () {
    testWidgets('FinancialCardSkeleton renders', (tester) async {
      await tester.pumpWidget(_testApp(const FinancialCardSkeleton()));
      await tester.pump();
      expect(find.byType(FinancialCardSkeleton), findsOneWidget);
    });

    testWidgets('OrderRowSkeleton renders', (tester) async {
      await tester.pumpWidget(_testApp(const OrderRowSkeleton()));
      await tester.pump();
      expect(find.byType(OrderRowSkeleton), findsOneWidget);
    });

    testWidgets('PrescriptionRowSkeleton renders', (tester) async {
      await tester.pumpWidget(_testApp(const PrescriptionRowSkeleton()));
      await tester.pump();
      expect(find.byType(PrescriptionRowSkeleton), findsOneWidget);
    });

    testWidgets('SkeletonList generates correct children count', (
      tester,
    ) async {
      await tester.pumpWidget(
        _testApp(
          SkeletonList(count: 4, itemBuilder: () => const OrderRowSkeleton()),
        ),
      );
      await tester.pump();
      expect(find.byType(OrderRowSkeleton), findsNWidgets(4));
    });
  });

  // ---------------------------------------------------------------------------
  // DashboardInfoTabs (orchestrator) tests
  // ---------------------------------------------------------------------------
  group('DashboardInfoTabs', () {
    testWidgets('renders Finances tab by default with tab labels', (
      tester,
    ) async {
      await tester.pumpWidget(
        _testApp(
          DashboardInfoTabs(walletKey: GlobalKey()),
          overrides: [
            walletProvider.overrideWith(
              (ref) => Stream.value(
                WalletData(
                  balance: 25000,
                  currency: 'XOF',
                  totalEarnings: 150000,
                  totalCommissionPaid: 0,
                  transactions: [],
                ),
              ),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      // Tab labels visible
      expect(find.text('Finances'), findsOneWidget);
      expect(find.text('Commandes'), findsOneWidget);
      expect(find.text('Ordonnances'), findsOneWidget);

      // Financial content should be rendered (balance card with 25K)
      expect(find.text('Solde'), findsOneWidget);
      expect(find.text('25K'), findsOneWidget);
    });

    testWidgets('switches to Orders tab when tab 1 selected', (tester) async {
      await tester.pumpWidget(
        _testApp(
          DashboardInfoTabs(walletKey: GlobalKey()),
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
            // Orders provider with empty state (loaded, no orders)
            orderListProvider.overrideWith(() => _EmptyOrderListNotifier()),
          ],
        ),
      );
      await tester.pumpAndSettle();

      // Tap "Commandes"
      await tester.tap(find.text('Commandes'));
      await tester.pumpAndSettle();

      // Empty orders state should show
      expect(find.text('Aucune commande récente'), findsOneWidget);
    });

    testWidgets('switches to Prescriptions tab when tab 2 selected', (
      tester,
    ) async {
      await tester.pumpWidget(
        _testApp(
          DashboardInfoTabs(walletKey: GlobalKey()),
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
            prescriptionListProvider.overrideWith(
              () => _EmptyPrescriptionNotifier(),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      // Tap "Ordonnances"
      await tester.tap(find.text('Ordonnances'));
      await tester.pumpAndSettle();

      // Empty prescriptions state
      expect(find.text('Aucune ordonnance récente'), findsOneWidget);
    });
  });
}

// ---------------------------------------------------------------------------
// Minimal test notifiers
// ---------------------------------------------------------------------------

class _EmptyOrderListNotifier extends OrderListNotifier {
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
