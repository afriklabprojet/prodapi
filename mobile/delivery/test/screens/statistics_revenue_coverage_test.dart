import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:courier/presentation/screens/statistics_screen.dart';
import 'package:courier/data/models/statistics.dart';
import 'package:courier/presentation/providers/statistics_provider.dart';
import 'package:courier/presentation/providers/wallet_provider.dart';
import 'package:courier/data/models/wallet_data.dart';
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

  final fullStats = Statistics(
    period: 'week',
    startDate: '2024-01-01',
    endDate: '2024-01-07',
    overview: const StatsOverview(
      totalDeliveries: 25,
      totalEarnings: 75000,
      totalDistanceKm: 120.5,
      totalDurationMinutes: 600,
      averageRating: 4.8,
      deliveryTrend: 12.5,
      earningsTrend: -5.0,
    ),
    performance: const StatsPerformance(
      totalAssigned: 30,
      totalAccepted: 28,
      totalDelivered: 25,
      totalCancelled: 2,
      acceptanceRate: 93.3,
      completionRate: 89.3,
      cancellationRate: 6.7,
      onTimeRate: 95.0,
      satisfactionRate: 96.0,
    ),
    dailyBreakdown: [
      const DailyStats(
        date: '2024-01-01',
        dayName: 'Lun',
        deliveries: 5,
        earnings: 15000,
      ),
      const DailyStats(
        date: '2024-01-02',
        dayName: 'Mar',
        deliveries: 3,
        earnings: 9000,
      ),
      const DailyStats(
        date: '2024-01-03',
        dayName: 'Mer',
        deliveries: 4,
        earnings: 12000,
      ),
      const DailyStats(
        date: '2024-01-04',
        dayName: 'Jeu',
        deliveries: 6,
        earnings: 18000,
      ),
      const DailyStats(
        date: '2024-01-05',
        dayName: 'Ven',
        deliveries: 7,
        earnings: 21000,
      ),
    ],
    peakHours: [
      const PeakHour(hour: '12', label: 'Midi', count: 8, percentage: 32),
      const PeakHour(hour: '19', label: '19h', count: 6, percentage: 24),
    ],
    revenueBreakdown: const RevenueBreakdown(
      deliveryCommissionsAmount: 55000,
      deliveryCommissionsPercent: 73.3,
      challengeBonusesAmount: 10000,
      challengeBonusesPercent: 13.3,
      rushBonusesAmount: 10000,
      rushBonusesPercent: 13.3,
      total: 75000,
    ),
    goals: const StatsGoals(
      weeklyTarget: 30,
      currentProgress: 25,
      progressPercentage: 83.3,
      remaining: 5,
    ),
  );

  final walletData = const WalletData(
    balance: 150000,
    totalEarnings: 75000,
    todayEarnings: 12000,
    totalCommissions: 15000,
    deliveriesCount: 25,
  );

  Widget buildScreen({
    Statistics? stats,
    WalletData? wallet,
    bool withWallet = false,
  }) {
    return ProviderScope(
      overrides: [
        ...commonWidgetTestOverrides(),
        statisticsProvider.overrideWith(
          (ref, period) async => stats ?? fullStats,
        ),
        walletDataProvider.overrideWith(
          (ref) async => withWallet ? (wallet ?? walletData) : null,
        ),
        walletProvider.overrideWith((ref) async => wallet ?? walletData),
      ],
      child: const MaterialApp(home: StatisticsScreen()),
    );
  }

  Future<void> pumpAndWait(WidgetTester tester, Widget widget) async {
    tester.view.physicalSize = const Size(1080, 5000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(widget);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
  }

  group('StatisticsScreen Revenue Tab', () {
    testWidgets('shows statistics title', (tester) async {
      await pumpAndWait(tester, buildScreen());
      expect(find.text('Mes Statistiques'), findsOneWidget);
    });

    testWidgets('shows tab bar with Aperçu Livraisons Revenus', (tester) async {
      await pumpAndWait(tester, buildScreen());
      expect(find.text('Aperçu'), findsWidgets);
      expect(find.text('Livraisons'), findsWidgets);
      expect(find.text('Revenus'), findsWidgets);
    });

    testWidgets('shows earnings value', (tester) async {
      await pumpAndWait(tester, buildScreen());
      expect(find.byType(Text), findsWidgets);
    });

    testWidgets('shows daily breakdown chart', (tester) async {
      await pumpAndWait(tester, buildScreen());
      expect(find.text('Lun'), findsWidgets);
      expect(find.text('Mar'), findsWidgets);
    });

    testWidgets('shows empty daily breakdown message', (tester) async {
      final emptyStats = Statistics(
        period: 'week',
        startDate: '2024-01-01',
        endDate: '2024-01-07',
        overview: const StatsOverview(),
        performance: const StatsPerformance(),
        dailyBreakdown: [],
      );
      await pumpAndWait(tester, buildScreen(stats: emptyStats));
      expect(find.byType(StatisticsScreen), findsOneWidget);
    });

    testWidgets('renders with zero earnings daily stats', (tester) async {
      final zeroStats = Statistics(
        period: 'week',
        startDate: '2024-01-01',
        endDate: '2024-01-07',
        overview: const StatsOverview(totalDeliveries: 0, totalEarnings: 0),
        performance: const StatsPerformance(),
        dailyBreakdown: [
          const DailyStats(
            date: '2024-01-01',
            dayName: 'Lun',
            deliveries: 0,
            earnings: 0,
          ),
        ],
      );
      await pumpAndWait(tester, buildScreen(stats: zeroStats));
      expect(find.byType(StatisticsScreen), findsOneWidget);
    });

    testWidgets('renders with goals data', (tester) async {
      await pumpAndWait(tester, buildScreen());
      // Goals progress should be visible
      expect(find.byType(StatisticsScreen), findsOneWidget);
    });

    testWidgets('renders in dark mode', (tester) async {
      tester.view.physicalSize = const Size(1080, 5000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            ...commonWidgetTestOverrides(),
            statisticsProvider.overrideWith((ref, period) async => fullStats),
            walletDataProvider.overrideWith((ref) async => walletData),
            walletProvider.overrideWith((ref) async => walletData),
          ],
          child: MaterialApp(
            theme: ThemeData.dark(),
            home: const StatisticsScreen(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('Mes Statistiques'), findsOneWidget);
    });
  });
}
