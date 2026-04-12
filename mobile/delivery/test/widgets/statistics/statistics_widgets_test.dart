import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:courier/presentation/widgets/statistics/statistics_widgets.dart';

void main() {
  group('StatCard', () {
    testWidgets('renders with required parameters', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StatCard(
              title: 'Livraisons',
              value: '42',
              icon: Icons.local_shipping,
              color: Colors.blue,
            ),
          ),
        ),
      );

      expect(find.byType(StatCard), findsOneWidget);
      expect(find.text('Livraisons'), findsOneWidget);
      expect(find.text('42'), findsOneWidget);
      expect(find.byIcon(Icons.local_shipping), findsOneWidget);
    });

    testWidgets('renders with trend up indicator', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StatCard(
              title: 'Revenus',
              value: '15000',
              icon: Icons.account_balance_wallet,
              color: Colors.green,
              trend: '+12%',
              trendUp: true,
            ),
          ),
        ),
      );

      expect(find.text('+12%'), findsOneWidget);
      expect(find.byIcon(Icons.trending_up), findsOneWidget);
    });

    testWidgets('renders with trend down indicator', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StatCard(
              title: 'Distance',
              value: '50',
              icon: Icons.straighten,
              color: Colors.orange,
              trend: '-5%',
              trendUp: false,
            ),
          ),
        ),
      );

      expect(find.text('-5%'), findsOneWidget);
      expect(find.byIcon(Icons.trending_down), findsOneWidget);
    });

    testWidgets('renders with suffix', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StatCard(
              title: 'Note',
              value: '4.8',
              icon: Icons.star,
              color: Colors.amber,
              suffix: '/5',
            ),
          ),
        ),
      );

      expect(find.text('4.8'), findsOneWidget);
      expect(find.text('/5'), findsOneWidget);
    });
  });

  group('PeriodChip', () {
    testWidgets('renders selected state', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PeriodChip(
              value: 'week',
              label: 'Cette semaine',
              selectedPeriod: 'week',
              onSelected: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('Cette semaine'), findsOneWidget);
    });

    testWidgets('renders unselected state', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PeriodChip(
              value: 'month',
              label: 'Ce mois',
              selectedPeriod: 'week',
              onSelected: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('Ce mois'), findsOneWidget);
    });

    testWidgets('calls onSelected when tapped', (tester) async {
      String? selectedValue;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PeriodChip(
              value: 'today',
              label: "Aujourd'hui",
              selectedPeriod: 'week',
              onSelected: (value) => selectedValue = value,
            ),
          ),
        ),
      );

      await tester.tap(find.text("Aujourd'hui"));
      expect(selectedValue, 'today');
    });
  });

  group('PeriodSelector', () {
    testWidgets('renders all period options', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PeriodSelector(
              selectedPeriod: 'week',
              onPeriodChanged: (_) {},
            ),
          ),
        ),
      );

      expect(find.text("Aujourd'hui"), findsOneWidget);
      expect(find.text('Cette semaine'), findsOneWidget);
      expect(find.text('Ce mois'), findsOneWidget);
      expect(find.text('Cette année'), findsOneWidget);
    });

    testWidgets('calls onPeriodChanged when period selected', (tester) async {
      String? newPeriod;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PeriodSelector(
              selectedPeriod: 'week',
              onPeriodChanged: (period) => newPeriod = period,
            ),
          ),
        ),
      );

      await tester.tap(find.text('Ce mois'));
      expect(newPeriod, 'month');
    });
  });

  group('LegendItem', () {
    testWidgets('renders label and color', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LegendItem(label: 'Livraisons', color: Colors.blue),
          ),
        ),
      );

      expect(find.text('Livraisons'), findsOneWidget);
      expect(find.byType(Container), findsWidgets);
    });
  });

  group('MiniStat', () {
    testWidgets('renders with all parameters', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MiniStat(
              label: 'Total',
              value: '25',
              icon: Icons.local_shipping,
              color: Colors.blue,
            ),
          ),
        ),
      );

      expect(find.text('Total'), findsOneWidget);
      expect(find.text('25'), findsOneWidget);
      expect(find.byIcon(Icons.local_shipping), findsOneWidget);
    });

    testWidgets('uses default color when not provided', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MiniStat(
              label: 'Distance',
              value: '100 km',
              icon: Icons.straighten,
            ),
          ),
        ),
      );

      expect(find.byType(MiniStat), findsOneWidget);
    });
  });

  group('PerformanceItem', () {
    testWidgets('renders with progress bar', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PerformanceItem(
              label: "Taux d'acceptation",
              value: 85,
              maxValue: 100,
              color: Colors.green,
            ),
          ),
        ),
      );

      expect(find.text("Taux d'acceptation"), findsOneWidget);
      expect(find.text('85.0'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });

    testWidgets('renders with suffix', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PerformanceItem(
              label: 'Livraisons à temps',
              value: 92,
              maxValue: 100,
              color: Colors.blue,
              suffix: '%',
            ),
          ),
        ),
      );

      expect(find.text('92.0%'), findsOneWidget);
    });

    testWidgets('handles zero maxValue', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PerformanceItem(
              label: 'Test',
              value: 50,
              maxValue: 0,
              color: Colors.purple,
            ),
          ),
        ),
      );

      expect(find.byType(PerformanceItem), findsOneWidget);
    });
  });
}
