import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:courier/presentation/screens/settings/home_widget_settings_screen.dart';
import '../../helpers/widget_test_helpers.dart';

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
      child: const MaterialApp(home: HomeWidgetSettingsScreen()),
    );
  }

  group('HomeWidgetSettingsScreen', () {
    testWidgets('renders screen', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('contains AppBar', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(AppBar), findsWidgets);
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

    testWidgets('contains Column widgets', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(Column), findsWidgets);
    });

    testWidgets('contains SizedBox widgets', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(SizedBox), findsWidgets);
    });

    // ── Content assertions ──

    testWidgets('shows AppBar title', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('Widget Écran d\'Accueil'), findsOneWidget);
    });

    testWidgets('shows preview section title', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('Aperçu du Widget'), findsOneWidget);
    });

    testWidgets('shows style section title', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('Style du Widget'), findsOneWidget);
    });

    testWidgets('shows display options section', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('Options d\'Affichage'), findsOneWidget);
    });

    testWidgets('shows daily goal section', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pump(const Duration(seconds: 1));
      // Scroll down to find the section
      await tester.scrollUntilVisible(
        find.text('Objectif Quotidien'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Objectif Quotidien'), findsOneWidget);
    });

    testWidgets('shows Compact style option', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('Compact'), findsOneWidget);
    });

    testWidgets('shows Standard style option', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('Standard'), findsOneWidget);
    });

    testWidgets('shows Détaillé style option', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('Détaillé'), findsOneWidget);
    });

    testWidgets('shows refresh icon', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pump(const Duration(seconds: 1));
      expect(find.byIcon(Icons.refresh), findsOneWidget);
    });

    testWidgets('shows gains toggle', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('Afficher les gains'), findsOneWidget);
    });

    testWidgets('shows DR PHARMA in preview', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('DR PHARMA'), findsOneWidget);
    });
  });
}
