import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:courier/presentation/screens/settings/accessibility_settings_screen.dart';
import 'package:courier/core/services/accessibility_service.dart';
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

  Widget buildScreen() {
    return ProviderScope(
      overrides: [
        ...commonWidgetTestOverrides(),
        accessibilityProvider.overrideWith(() => AccessibilityNotifier()),
      ],
      child: const MaterialApp(home: AccessibilitySettingsScreen()),
    );
  }

  group('AccessibilitySettingsScreen', () {
    testWidgets('renders with scaffold and title', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(find.text('Accessibilité'), findsOneWidget);
    });

    testWidgets('displays accessibility options intro', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(find.text('Options d\'accessibilité'), findsOneWidget);
    });

    testWidgets('displays vision section', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(find.text('Vision'), findsOneWidget);
    });

    testWidgets('displays contrast toggle', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(find.text('Contraste élevé'), findsOneWidget);
    });

    testWidgets('displays large text toggle', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(find.text('Texte large'), findsOneWidget);
    });

    // ── Additional content assertions ──

    testWidgets('shows bold text toggle', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();
      expect(find.text('Texte en gras'), findsOneWidget);
    });

    testWidgets('shows text size section', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();
      expect(find.text('Taille du texte'), findsOneWidget);
    });

    testWidgets('shows motion section', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Mouvement'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Mouvement'), findsOneWidget);
    });

    testWidgets('shows animations toggle', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Réduire les animations'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Réduire les animations'), findsOneWidget);
    });

    testWidgets('shows screen reader section', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Lecteur d\'écran'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Lecteur d\'écran'), findsOneWidget);
    });

    testWidgets('shows VoiceOver/TalkBack item', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('VoiceOver / TalkBack'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('VoiceOver / TalkBack'), findsOneWidget);
    });

    testWidgets('shows preview section', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Aperçu'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Aperçu'), findsOneWidget);
    });

    testWidgets('shows accessibility icon', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.accessibility_new), findsWidgets);
    });

    testWidgets('shows intro subtitle', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();
      expect(find.textContaining('Personnalisez'), findsWidgets);
    });
  });
}
