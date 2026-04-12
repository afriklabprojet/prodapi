import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:courier/presentation/widgets/gamification/gamification_widgets.dart';
import 'package:courier/data/models/gamification.dart';
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

  final unlockedBadge = GamificationBadge(
    id: 'b1',
    name: 'Première Livraison',
    description: 'Effectuer votre première livraison',
    iconName: 'delivery',
    color: Colors.green,
    isUnlocked: true,
    unlockedAt: DateTime(2024, 6, 15),
    requiredValue: 1,
    currentValue: 1,
    category: 'delivery',
  );

  final lockedBadge = GamificationBadge(
    id: 'b2',
    name: 'Marathonien',
    description: 'Effectuer 100 livraisons',
    iconName: 'speed',
    color: Colors.blue,
    isUnlocked: false,
    requiredValue: 100,
    currentValue: 42,
    category: 'delivery',
  );

  Widget buildBadgeWidget(GamificationBadge badge, {bool showProgress = true}) {
    return ProviderScope(
      overrides: commonWidgetTestOverrides(),
      child: MaterialApp(
        home: Scaffold(
          body: Center(
            child: BadgeWidget(badge: badge, showProgress: showProgress),
          ),
        ),
      ),
    );
  }

  group('BadgeWidget dialog', () {
    testWidgets('tapping unlocked badge shows dialog with Débloqué', (
      tester,
    ) async {
      await tester.pumpWidget(buildBadgeWidget(unlockedBadge));
      await tester.pump(const Duration(seconds: 1));

      // Tap the badge to open dialog
      await tester.tap(find.byType(GestureDetector).first);
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      // Verify dialog content
      expect(find.text('Première Livraison'), findsWidgets);
      expect(find.text('Effectuer votre première livraison'), findsWidgets);
      expect(find.text('Débloqué'), findsOneWidget);
      expect(find.text('Fermer'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
    });

    testWidgets('tapping locked badge shows dialog with progress', (
      tester,
    ) async {
      await tester.pumpWidget(buildBadgeWidget(lockedBadge));
      await tester.pump(const Duration(seconds: 1));

      await tester.tap(find.byType(GestureDetector).first);
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('Marathonien'), findsWidgets);
      expect(find.text('Effectuer 100 livraisons'), findsWidgets);
      expect(find.text('42 / 100'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      expect(find.text('Fermer'), findsOneWidget);
    });

    testWidgets('dialog can be closed with Fermer button', (tester) async {
      await tester.pumpWidget(buildBadgeWidget(unlockedBadge));
      await tester.pump(const Duration(seconds: 1));

      await tester.tap(find.byType(GestureDetector).first);
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('Fermer'), findsOneWidget);
      await tester.tap(find.text('Fermer'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      // Dialog should be dismissed
      expect(find.text('Débloqué'), findsNothing);
    });

    testWidgets('locked badge renders circular progress and lock icon', (
      tester,
    ) async {
      await tester.pumpWidget(buildBadgeWidget(lockedBadge));
      await tester.pump(const Duration(seconds: 1));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byIcon(Icons.lock), findsOneWidget);
    });

    testWidgets('unlocked badge does not show lock icon', (tester) async {
      await tester.pumpWidget(buildBadgeWidget(unlockedBadge));
      await tester.pump(const Duration(seconds: 1));

      expect(find.byIcon(Icons.lock), findsNothing);
    });

    testWidgets('badge without showProgress hides circular indicator', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildBadgeWidget(lockedBadge, showProgress: false),
      );
      await tester.pump(const Duration(seconds: 1));

      // No circular progress when showProgress is false
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });
  });
}
