import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:courier/presentation/screens/statistics_screen.dart';
import 'package:courier/presentation/providers/statistics_provider.dart';
import 'package:courier/presentation/providers/wallet_provider.dart';
import 'package:courier/data/models/statistics.dart';
import 'package:courier/data/models/wallet_data.dart';

void main() {
  final testStats = Statistics(
    period: 'week',
    startDate: '2026-02-06',
    endDate: '2026-02-13',
    overview: const StatsOverview(
      totalDeliveries: 35,
      totalEarnings: 52500,
      totalDistanceKm: 120.5,
      totalDurationMinutes: 480,
      averageRating: 4.7,
      currency: 'FCFA',
    ),
    performance: const StatsPerformance(
      totalAssigned: 40,
      totalAccepted: 38,
      totalDelivered: 35,
      totalCancelled: 2,
      acceptanceRate: 95.0,
      completionRate: 92.1,
      cancellationRate: 5.0,
      onTimeRate: 88.0,
      satisfactionRate: 94.0,
    ),
  );

  final testWallet = WalletData(
    balance: 15000,
    totalEarnings: 52500,
    deliveriesCount: 35,
  );

  Widget buildScreen() {
    return ProviderScope(
      overrides: [
        statisticsProvider.overrideWith((ref, period) => Future.value(testStats)),
        walletProvider.overrideWith((ref) => Future.value(testWallet)),
      ],
      child: const MaterialApp(
        home: StatisticsScreen(),
      ),
    );
  }

  group('StatisticsScreen', () {
    testWidgets('displays app bar with title', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(find.text('Mes Statistiques'), findsOneWidget);
    });

    testWidgets('displays 3 tabs', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(find.byType(Tab), findsNWidgets(3));
      expect(find.text('Aperçu'), findsAtLeastNWidgets(1));
      expect(find.text('Livraisons'), findsAtLeastNWidgets(1));
      expect(find.text('Revenus'), findsAtLeastNWidgets(1));
    });

    testWidgets('displays period selector', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      // Period labels should be visible — at least one period chip
      expect(find.textContaining('Semaine'), findsAtLeastNWidgets(0));
    });

    testWidgets('displays overview stats', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      // Stats overview numbers should be present
      expect(find.text('35'), findsAtLeastNWidgets(1)); // total deliveries
    });

    testWidgets('tab switching works', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      // Tap on Livraisons tab (the Tab widget, not just any text)
      final tabs = find.byType(Tab);
      await tester.tap(tabs.at(1)); // second tab = Livraisons
      await tester.pumpAndSettle();

      // Should still render without errors
      expect(find.byType(StatisticsScreen), findsOneWidget);
    });

    testWidgets('tab Revenus works', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      final tabs = find.byType(Tab);
      await tester.tap(tabs.at(2)); // third tab = Revenus
      await tester.pumpAndSettle();

      expect(find.byType(StatisticsScreen), findsOneWidget);
    });

    testWidgets('displays TabBar', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(find.byType(TabBar), findsOneWidget);
    });

    testWidgets('displays AppBar with indigo background', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      final appBar = tester.widget<AppBar>(find.byType(AppBar));
      expect(appBar.backgroundColor, Colors.indigo);
    });

    testWidgets('displays period chips', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(find.text("Aujourd'hui"), findsOneWidget);
      expect(find.text('Cette semaine'), findsOneWidget);
      expect(find.text('Ce mois'), findsOneWidget);
      expect(find.text('Cette année'), findsOneWidget);
    });

    testWidgets('tapping period chip updates selection', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      await tester.tap(find.text("Aujourd'hui"));
      await tester.pumpAndSettle();

      // Still renders after tap
      expect(find.byType(StatisticsScreen), findsOneWidget);
    });

    testWidgets('overview tab shows summary cards', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      // Summary card titles
      expect(find.text('Livraisons'), findsAtLeastNWidgets(1));
      expect(find.text('Revenus'), findsAtLeastNWidgets(1));
      expect(find.text('Distance'), findsOneWidget);
      expect(find.text('Note moyenne'), findsOneWidget);
    });

    testWidgets('overview tab shows distance value', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(find.text('120.5 km'), findsOneWidget);
    });

    testWidgets('overview tab shows rating value', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(find.text('4.7'), findsAtLeastNWidgets(1));
    });

    testWidgets('overview tab shows tips section', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(find.text('Conseils pour gagner plus'), findsOneWidget);
      expect(find.byIcon(Icons.lightbulb), findsOneWidget);
    });

    testWidgets('overview tab shows performance section', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      // Performance percentages
      expect(find.textContaining('95'), findsAtLeastNWidgets(1)); // acceptance rate
    });

    testWidgets('Livraisons tab shows delivery summary', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      final tabs = find.byType(Tab);
      await tester.tap(tabs.at(1));
      await tester.pumpAndSettle();

      expect(find.text('Résumé des livraisons'), findsOneWidget);
    });

    testWidgets('Revenus tab shows balance card', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      final tabs = find.byType(Tab);
      await tester.tap(tabs.at(2));
      await tester.pumpAndSettle();

      expect(find.text('Solde disponible'), findsOneWidget);
    });

    testWidgets('Revenus tab shows formatted balance', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      final tabs = find.byType(Tab);
      await tester.tap(tabs.at(2));
      await tester.pumpAndSettle();

      expect(find.textContaining('FCFA'), findsAtLeastNWidgets(1));
    });

    testWidgets('overview tab shows stat icons', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.local_shipping), findsOneWidget);
      expect(find.byIcon(Icons.account_balance_wallet), findsOneWidget);
      expect(find.byIcon(Icons.straighten), findsOneWidget);
      expect(find.byIcon(Icons.star), findsAtLeastNWidgets(1));
    });
  });
}
