import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:courier/presentation/screens/battery_optimization_screen.dart';
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

  Widget buildWidget() {
    return ProviderScope(
      overrides: commonWidgetTestOverrides(),
      child: const MaterialApp(home: BatteryOptimizationScreen()),
    );
  }

  group('BatteryOptimizationScreen', () {
    testWidgets('renders battery optimization screen', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('displays title', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pump(const Duration(seconds: 1));
      expect(find.textContaining('batterie'), findsWidgets);
    });

    testWidgets('has AppBar', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(AppBar), findsOneWidget);
    });

    testWidgets('has ListView', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(ListView), findsWidgets);
    });

    testWidgets('contains Text widgets', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(Text), findsWidgets);
    });

    testWidgets('contains Icon widgets', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(Icon), findsWidgets);
    });

    testWidgets('contains Container widgets', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(Container), findsWidgets);
    });

    testWidgets('contains SizedBox widgets', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(SizedBox), findsWidgets);
    });

    // ── Content assertions ──

    testWidgets('shows "Économie de batterie" AppBar title', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('Économie de batterie'), findsOneWidget);
    });

    testWidgets('shows "Comment ça marche" info section', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('Comment ça marche'), findsOneWidget);
    });

    testWidgets('shows info icon', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pump(const Duration(seconds: 1));
      expect(find.byIcon(Icons.info_outline), findsWidgets);
    });

    testWidgets('mentions battery in text', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pump(const Duration(seconds: 1));
      expect(find.textContaining('batterie'), findsWidgets);
    });
  });
}
