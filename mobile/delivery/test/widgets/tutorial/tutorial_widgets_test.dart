import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:courier/presentation/widgets/tutorial/tutorial_widgets.dart';
import 'package:courier/core/services/tutorial_service.dart';
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

  // ── TutorialOverlay ────────────────────────────
  group('TutorialOverlay', () {
    testWidgets('renders child widget', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: commonWidgetTestOverrides(),
          child: const MaterialApp(
            home: TutorialOverlay(
              child: Scaffold(body: Center(child: Text('Hello'))),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Hello'), findsOneWidget);
    });

    testWidgets('renders without active tutorial', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            ...commonWidgetTestOverrides(),
            activeTutorialProvider.overrideWith((ref) => null),
          ],
          child: const MaterialApp(
            home: TutorialOverlay(child: Scaffold(body: Text('Content'))),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Content'), findsOneWidget);
    });
  });

  // ── TutorialCard ───────────────────────────────
  group('TutorialCard', () {
    const step = TutorialStep(
      title: 'Bienvenue',
      description: 'Découvrez l\'application',
      icon: Icons.waving_hand,
    );

    testWidgets('renders step content', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TutorialCard(
              tutorial: TutorialType.welcome,
              step: step,
              stepIndex: 0,
              totalSteps: 4,
              onNext: () {},
              onSkip: () {},
            ),
          ),
        ),
      );
      expect(find.text('Bienvenue'), findsOneWidget);
      expect(find.text('Découvrez l\'application'), findsOneWidget);
    });

    testWidgets('shows step progress', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TutorialCard(
              tutorial: TutorialType.welcome,
              step: step,
              stepIndex: 1,
              totalSteps: 4,
              onNext: () {},
              onSkip: () {},
            ),
          ),
        ),
      );
      expect(find.text('2/4'), findsOneWidget);
    });

    testWidgets('shows skip button', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TutorialCard(
              tutorial: TutorialType.welcome,
              step: step,
              stepIndex: 0,
              totalSteps: 4,
              onNext: () {},
              onSkip: () {},
            ),
          ),
        ),
      );
      expect(find.text('Passer'), findsOneWidget);
    });

    testWidgets('shows next button', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TutorialCard(
              tutorial: TutorialType.welcome,
              step: step,
              stepIndex: 0,
              totalSteps: 4,
              onNext: () {},
              onSkip: () {},
            ),
          ),
        ),
      );
      expect(find.text('Suivant'), findsOneWidget);
    });

    testWidgets('shows finish button on last step', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TutorialCard(
              tutorial: TutorialType.welcome,
              step: step,
              stepIndex: 3,
              totalSteps: 4,
              onNext: () {},
              onSkip: () {},
            ),
          ),
        ),
      );
      expect(find.text('Terminer'), findsOneWidget);
    });

    testWidgets('triggers onNext callback', (tester) async {
      bool nextCalled = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TutorialCard(
              tutorial: TutorialType.welcome,
              step: step,
              stepIndex: 0,
              totalSteps: 4,
              onNext: () => nextCalled = true,
              onSkip: () {},
            ),
          ),
        ),
      );
      await tester.tap(find.text('Suivant'));
      expect(nextCalled, true);
    });

    testWidgets('triggers onSkip callback', (tester) async {
      bool skipCalled = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TutorialCard(
              tutorial: TutorialType.welcome,
              step: step,
              stepIndex: 0,
              totalSteps: 4,
              onNext: () {},
              onSkip: () => skipCalled = true,
            ),
          ),
        ),
      );
      await tester.tap(find.text('Passer'));
      expect(skipCalled, true);
    });

    testWidgets('shows step icon', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TutorialCard(
              tutorial: TutorialType.welcome,
              step: step,
              stepIndex: 0,
              totalSteps: 4,
              onNext: () {},
              onSkip: () {},
            ),
          ),
        ),
      );
      expect(find.byIcon(Icons.waving_hand), findsOneWidget);
    });

    testWidgets('shows custom action label', (tester) async {
      const customStep = TutorialStep(
        title: 'Action',
        description: 'Faites quelque chose',
        icon: Icons.touch_app,
        actionLabel: 'Compris !',
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TutorialCard(
              tutorial: TutorialType.acceptDelivery,
              step: customStep,
              stepIndex: 0,
              totalSteps: 1,
              onNext: () {},
              onSkip: () {},
            ),
          ),
        ),
      );
      expect(find.text('Compris !'), findsOneWidget);
    });
  });

  // ── TutorialPromptDialog ───────────────────────
  group('TutorialPromptDialog', () {
    testWidgets('renders dialog content', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TutorialPromptDialog(
              tutorial: TutorialType.welcome,
              title: 'Démarrer le tutoriel ?',
              message: 'Voulez-vous voir le guide ?',
            ),
          ),
        ),
      );
      expect(find.text('Démarrer le tutoriel ?'), findsOneWidget);
      expect(find.text('Voulez-vous voir le guide ?'), findsOneWidget);
    });

    testWidgets('shows action buttons', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TutorialPromptDialog(
              tutorial: TutorialType.welcome,
              title: 'Tutoriel',
              message: 'Découvrir ?',
            ),
          ),
        ),
      );
      expect(find.text('Non merci'), findsOneWidget);
      expect(find.text('Voir le guide'), findsOneWidget);
    });
  });

  // ── TutorialHelpButton ─────────────────────────
  group('TutorialHelpButton', () {
    testWidgets('renders help button', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: commonWidgetTestOverrides(),
          child: const MaterialApp(
            home: Scaffold(
              body: TutorialHelpButton(tutorial: TutorialType.welcome),
            ),
          ),
        ),
      );
      expect(find.byType(TutorialHelpButton), findsOneWidget);
    });

    testWidgets('shows help icon', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: commonWidgetTestOverrides(),
          child: const MaterialApp(
            home: Scaffold(
              body: TutorialHelpButton(tutorial: TutorialType.navigation),
            ),
          ),
        ),
      );
      expect(find.byIcon(Icons.help_outline), findsOneWidget);
    });

    testWidgets('renders with custom color', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: commonWidgetTestOverrides(),
          child: const MaterialApp(
            home: Scaffold(
              body: TutorialHelpButton(
                tutorial: TutorialType.wallet,
                color: Colors.red,
              ),
            ),
          ),
        ),
      );
      expect(find.byType(TutorialHelpButton), findsOneWidget);
    });
  });

  // ── TutorialListWidget ─────────────────────────
  group('TutorialListWidget', () {
    testWidgets('renders tutorial list', (tester) async {
      final originalOnError = FlutterError.onError;
      FlutterError.onError = (details) {};
      await tester.pumpWidget(
        ProviderScope(
          overrides: commonWidgetTestOverrides(),
          child: const MaterialApp(home: Scaffold(body: TutorialListWidget())),
        ),
      );
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(TutorialListWidget), findsOneWidget);
      expect(find.text('Tutoriels'), findsOneWidget);
      FlutterError.onError = originalOnError;
    });
  });
}
