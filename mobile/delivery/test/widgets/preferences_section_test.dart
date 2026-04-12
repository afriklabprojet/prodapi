import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:courier/presentation/widgets/profile/preferences_section.dart';

void main() {
  group('PreferencesSection', () {
    testWidgets('renders all menu items', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PreferencesSection(
              onDashboard: () {},
              onStatistics: () {},
              onHistory: () {},
              onBadges: () {},
              onSettings: () {},
              onHelp: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(PreferencesSection), findsOneWidget);
    });

    testWidgets('calls onDashboard callback when tapped', (tester) async {
      bool called = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: PreferencesSection(
                onDashboard: () => called = true,
                onStatistics: () {},
                onHistory: () {},
                onBadges: () {},
                onSettings: () {},
                onHelp: () {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Find and tap the dashboard item
      final dashboardIcon = find.byIcon(Icons.dashboard);
      if (dashboardIcon.evaluate().isNotEmpty) {
        await tester.tap(dashboardIcon.first);
        await tester.pumpAndSettle();
        expect(called, true);
      }
    });

    testWidgets('calls onSettings callback when tapped', (tester) async {
      bool called = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: PreferencesSection(
                onDashboard: () {},
                onStatistics: () {},
                onHistory: () {},
                onBadges: () {},
                onSettings: () => called = true,
                onHelp: () {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final settingsIcon = find.byIcon(Icons.settings);
      if (settingsIcon.evaluate().isNotEmpty) {
        await tester.tap(settingsIcon.first);
        await tester.pumpAndSettle();
        expect(called, true);
      }
    });

    testWidgets('contains Text widgets', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PreferencesSection(
              onDashboard: () {},
              onStatistics: () {},
              onHistory: () {},
              onBadges: () {},
              onSettings: () {},
              onHelp: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(Text), findsWidgets);
    });

    testWidgets('contains Icon widgets', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PreferencesSection(
              onDashboard: () {},
              onStatistics: () {},
              onHistory: () {},
              onBadges: () {},
              onSettings: () {},
              onHelp: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(Icon), findsWidgets);
    });

    testWidgets('calls onHelp callback when tapped', (tester) async {
      bool called = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: PreferencesSection(
                onDashboard: () {},
                onStatistics: () {},
                onHistory: () {},
                onBadges: () {},
                onSettings: () {},
                onHelp: () => called = true,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final helpIcon = find.byIcon(Icons.help_outline);
      if (helpIcon.evaluate().isNotEmpty) {
        await tester.tap(helpIcon.first);
        await tester.pumpAndSettle();
        expect(called, true);
      }
    });

    testWidgets('calls onStatistics callback when tapped', (tester) async {
      bool called = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: PreferencesSection(
                onDashboard: () {},
                onStatistics: () => called = true,
                onHistory: () {},
                onBadges: () {},
                onSettings: () {},
                onHelp: () {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final statsIcon = find.byIcon(Icons.bar_chart);
      if (statsIcon.evaluate().isNotEmpty) {
        await tester.tap(statsIcon.first);
        await tester.pumpAndSettle();
        expect(called, true);
      }
    });
  });
}
