import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:courier/core/services/tutorial_service.dart';
import 'package:courier/presentation/widgets/tutorial/tutorial_widgets.dart';
import '../helpers/widget_test_helpers.dart';

void main() {
  group('TutorialCard', () {
    Widget buildCard({
      required TutorialType tutorial,
      int stepIndex = 0,
      int totalSteps = 3,
      VoidCallback? onNext,
      VoidCallback? onSkip,
    }) {
      final steps = Tutorials.getSteps(tutorial);
      return ProviderScope(
        overrides: commonWidgetTestOverrides(),
        child: MaterialApp(
          home: Scaffold(
            body: TutorialCard(
              tutorial: tutorial,
              step: steps[stepIndex],
              stepIndex: stepIndex,
              totalSteps: totalSteps,
              onNext: onNext ?? () {},
              onSkip: onSkip ?? () {},
            ),
          ),
        ),
      );
    }

    testWidgets('shows tutorial title and description', (tester) async {
      await tester.pumpWidget(buildCard(tutorial: TutorialType.welcome));
      await tester.pumpAndSettle();

      expect(find.text('Bienvenue sur DR-PHARMA Coursier !'), findsOneWidget);
    });

    testWidgets('shows step indicator (1/3)', (tester) async {
      await tester.pumpWidget(
        buildCard(tutorial: TutorialType.welcome, stepIndex: 0, totalSteps: 3),
      );
      await tester.pumpAndSettle();

      expect(find.text('1/3'), findsOneWidget);
    });

    testWidgets('shows Suivant button for non-last step', (tester) async {
      await tester.pumpWidget(
        buildCard(tutorial: TutorialType.welcome, stepIndex: 0, totalSteps: 3),
      );
      await tester.pumpAndSettle();

      expect(find.text('Suivant'), findsOneWidget);
    });

    testWidgets('shows Terminer button for last step', (tester) async {
      await tester.pumpWidget(
        buildCard(tutorial: TutorialType.welcome, stepIndex: 2, totalSteps: 3),
      );
      await tester.pumpAndSettle();

      expect(find.text('Terminer'), findsOneWidget);
    });

    testWidgets('shows Passer button for non-first step', (tester) async {
      await tester.pumpWidget(
        buildCard(tutorial: TutorialType.welcome, stepIndex: 1, totalSteps: 4),
      );
      await tester.pumpAndSettle();

      expect(find.text('Passer'), findsOneWidget);
    });

    testWidgets('calls onNext when Suivant is tapped', (tester) async {
      bool nextCalled = false;
      await tester.pumpWidget(
        buildCard(
          tutorial: TutorialType.welcome,
          stepIndex: 0,
          totalSteps: 3,
          onNext: () => nextCalled = true,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Suivant'));
      await tester.pump();

      expect(nextCalled, isTrue);
    });

    testWidgets('shows custom actionLabel when provided', (tester) async {
      // TutorialType.acceptDelivery step 2 has actionLabel 'Compris !'
      final steps = Tutorials.getSteps(TutorialType.acceptDelivery);
      await tester.pumpWidget(
        ProviderScope(
          overrides: commonWidgetTestOverrides(),
          child: MaterialApp(
            home: Scaffold(
              body: TutorialCard(
                tutorial: TutorialType.acceptDelivery,
                step: steps[2], // has actionLabel 'Compris !'
                stepIndex: 2,
                totalSteps: 3,
                onNext: () {},
                onSkip: () {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Compris !'), findsOneWidget);
    });
  });

  group('TutorialOverlay', () {
    testWidgets('shows child when no active tutorial', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: commonWidgetTestOverrides(),
          child: const MaterialApp(
            home: TutorialOverlay(child: Scaffold(body: Text('Mon contenu'))),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Mon contenu'), findsOneWidget);
    });

    testWidgets('shows overlay when tutorial active', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: commonWidgetTestOverrides(
            extra: [
              activeTutorialProvider.overrideWith(
                (ref) => TutorialType.welcome,
              ),
              tutorialStepProvider.overrideWith((ref) => 0),
            ],
          ),
          child: const MaterialApp(
            home: TutorialOverlay(child: Scaffold(body: Text('Mon contenu'))),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Bienvenue sur DR-PHARMA Coursier !'), findsOneWidget);
    });
  });

  group('TutorialHelpButton', () {
    testWidgets('shows help icon button', (tester) async {
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
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.help_outline), findsOneWidget);
    });
  });

  group('TutorialPromptDialog', () {
    testWidgets('shows title and message', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: commonWidgetTestOverrides(),
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) {
                  return ElevatedButton(
                    onPressed: () => TutorialPromptDialog.show(
                      context,
                      tutorial: TutorialType.welcome,
                      title: 'Découvrir l\'app ?',
                      message: 'Voulez-vous voir le guide de démarrage ?',
                    ),
                    child: const Text('btn'),
                  );
                },
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('btn'));
      await tester.pumpAndSettle();

      expect(find.text('Découvrir l\'app ?'), findsOneWidget);
      expect(find.text('Non merci'), findsOneWidget);
      expect(find.text('Voir le guide'), findsOneWidget);
    });

    testWidgets('Non merci dismisses dialog with false', (tester) async {
      bool? result;
      await tester.pumpWidget(
        ProviderScope(
          overrides: commonWidgetTestOverrides(),
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) {
                  return ElevatedButton(
                    onPressed: () async {
                      result = await TutorialPromptDialog.show(
                        context,
                        tutorial: TutorialType.welcome,
                        title: 'Test',
                        message: 'Message',
                      );
                    },
                    child: const Text('btn'),
                  );
                },
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('btn'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Non merci'));
      await tester.pumpAndSettle();

      expect(result, isFalse);
    });
  });

  group('TutorialListWidget', () {
    testWidgets('shows Tutoriels header and reset button', (tester) async {
      tester.view.physicalSize = const Size(1080, 4000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          overrides: commonWidgetTestOverrides(
            extra: [
              tutorialCompletedProvider.overrideWith(
                (ref, type) async => false,
              ),
            ],
          ),
          child: const MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(child: TutorialListWidget()),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Tutoriels'), findsOneWidget);
      expect(find.text('Réinitialiser tous les tutoriels'), findsOneWidget);
    });

    testWidgets('shows all tutorial entries', (tester) async {
      tester.view.physicalSize = const Size(1080, 4000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          overrides: commonWidgetTestOverrides(
            extra: [
              tutorialCompletedProvider.overrideWith(
                (ref, type) async => false,
              ),
            ],
          ),
          child: const MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(child: TutorialListWidget()),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Bienvenue'), findsOneWidget);
      expect(find.text('Navigation'), findsOneWidget);
    });

    testWidgets('shows completed icon for completed tutorial', (tester) async {
      tester.view.physicalSize = const Size(1080, 4000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          overrides: commonWidgetTestOverrides(
            extra: [
              tutorialCompletedProvider.overrideWith(
                (ref, type) async => true, // all completed
              ),
            ],
          ),
          child: const MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(child: TutorialListWidget()),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.check_circle), findsAtLeastNWidgets(1));
    });
  });
}
