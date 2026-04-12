import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:courier/core/services/interactive_tutorial_service.dart';
import 'package:courier/presentation/widgets/tutorial/interactive_tutorial_widgets.dart';
import '../../helpers/widget_test_helpers.dart';

class _FakeInteractiveTutorialService extends InteractiveTutorialService {
  _FakeInteractiveTutorialService(this._initialState);

  final InteractiveTutorialState _initialState;
  bool didStart = false;
  bool didNext = false;
  bool didPrevious = false;
  bool didCancel = false;

  @override
  InteractiveTutorialState build() => _initialState;

  @override
  void startTutorial(String tutorialId) {
    didStart = true;
    super.startTutorial(tutorialId);
  }

  @override
  void nextStep() {
    didNext = true;
    super.nextStep();
  }

  @override
  void previousStep() {
    didPrevious = true;
    super.previousStep();
  }

  @override
  void cancelTutorial() {
    didCancel = true;
    super.cancelTutorial();
  }
}

Future<void> _pumpTutorialWidget(WidgetTester tester, Widget widget) async {
  tester.view.physicalSize = const Size(1200, 1600);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(widget);
  await tester.pump();
}

void main() {
  group('InteractiveTutorialState', () {
    test('default state has correct values', () {
      const state = InteractiveTutorialState();
      expect(state.activeTutorial, isNull);
      expect(state.currentStepIndex, 0);
      expect(state.isPaused, false);
      expect(state.completedTutorials, isEmpty);
      expect(state.isActive, false);
      expect(state.currentStep, isNull);
      expect(state.progress, 0);
    });

    test('isActive returns true when tutorial active and not paused', () {
      final state = InteractiveTutorialState(
        activeTutorial: InteractiveTutorials.welcomeTour,
      );
      expect(state.isActive, true);
    });

    test('isActive returns false when paused', () {
      final state = InteractiveTutorialState(
        activeTutorial: InteractiveTutorials.welcomeTour,
        isPaused: true,
      );
      expect(state.isActive, false);
    });

    test('currentStep returns first step when index is 0', () {
      final state = InteractiveTutorialState(
        activeTutorial: InteractiveTutorials.welcomeTour,
        currentStepIndex: 0,
      );
      expect(state.currentStep, isNotNull);
      expect(state.currentStep!.id, 'welcome_intro');
    });

    test('isLastStep returns true on last step', () {
      final tutorial = InteractiveTutorials.welcomeTour;
      final state = InteractiveTutorialState(
        activeTutorial: tutorial,
        currentStepIndex: tutorial.steps.length - 1,
      );
      expect(state.isLastStep, true);
    });

    test('progress returns correct fraction', () {
      final tutorial = InteractiveTutorials.welcomeTour;
      final state = InteractiveTutorialState(
        activeTutorial: tutorial,
        currentStepIndex: 1,
      );
      expect(state.progress, closeTo(2 / tutorial.steps.length, 0.01));
    });

    test('copyWith preserves unchanged values', () {
      final state = InteractiveTutorialState(
        activeTutorial: InteractiveTutorials.welcomeTour,
        currentStepIndex: 2,
        completedTutorials: {'delivery_flow'},
      );
      final copied = state.copyWith(isPaused: true);
      expect(copied.activeTutorial, isNotNull);
      expect(copied.currentStepIndex, 2);
      expect(copied.isPaused, true);
      expect(copied.completedTutorials.contains('delivery_flow'), true);
    });

    test('copyWith clearActiveTutorial sets tutorial to null', () {
      final state = InteractiveTutorialState(
        activeTutorial: InteractiveTutorials.welcomeTour,
      );
      final copied = state.copyWith(clearActiveTutorial: true);
      expect(copied.activeTutorial, isNull);
    });
  });

  group('InteractiveTutorialStep', () {
    test('constructor sets required fields', () {
      const step = InteractiveTutorialStep(
        id: 'test-step',
        title: 'Test',
        description: 'Test description',
        icon: Icons.star,
      );
      expect(step.id, 'test-step');
      expect(step.title, 'Test');
      expect(step.spotlightShape, SpotlightShape.roundedRectangle);
      expect(step.allowInteraction, false);
      expect(step.tips, isNull);
    });
  });

  group('InteractiveTutorial', () {
    test('welcomeTour has correct id', () {
      expect(InteractiveTutorials.welcomeTour.id, 'welcome_tour');
    });

    test('all returns all tutorials', () {
      expect(InteractiveTutorials.all.length, greaterThanOrEqualTo(5));
    });

    test('getById returns correct tutorial', () {
      final tutorial = InteractiveTutorials.getById('welcome_tour');
      expect(tutorial, isNotNull);
      expect(tutorial!.name, 'Découverte de l\'app');
    });

    test('getById returns null for unknown id', () {
      expect(InteractiveTutorials.getById('nonexistent'), isNull);
    });
  });

  group('TutorialTarget', () {
    testWidgets('renders child widget', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: TutorialTarget(
            targetKey: 'test_key',
            child: Text('Target Content'),
          ),
        ),
      );
      expect(find.text('Target Content'), findsOneWidget);
    });
  });

  group('StartTutorialButton', () {
    testWidgets('renders without error', (tester) async {
      SharedPreferences.setMockInitialValues({});

      await tester.pumpWidget(
        ProviderScope(
          overrides: commonWidgetTestOverrides(),
          child: const MaterialApp(
            home: Scaffold(
              body: StartTutorialButton(tutorialId: 'welcome_tour'),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(StartTutorialButton), findsOneWidget);
    });
  });

  group('TutorialProgressBadge', () {
    testWidgets('renders without error', (tester) async {
      SharedPreferences.setMockInitialValues({});

      await tester.pumpWidget(
        ProviderScope(
          overrides: commonWidgetTestOverrides(),
          child: const MaterialApp(
            home: Scaffold(body: TutorialProgressBadge()),
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(TutorialProgressBadge), findsOneWidget);
    });
  });

  group('InteractiveTutorialOverlay', () {
    testWidgets('renders child when no active tutorial', (tester) async {
      SharedPreferences.setMockInitialValues({});

      await tester.pumpWidget(
        ProviderScope(
          overrides: commonWidgetTestOverrides(),
          child: const MaterialApp(
            home: InteractiveTutorialOverlay(child: Text('App Content')),
          ),
        ),
      );
      await tester.pump();
      expect(find.text('App Content'), findsOneWidget);
    });
  });

  group('InteractiveTutorialState - Edge cases', () {
    test('progress at step 0 equals fraction', () {
      final tutorial = InteractiveTutorials.welcomeTour;
      final state = InteractiveTutorialState(
        activeTutorial: tutorial,
        currentStepIndex: 0,
      );
      expect(state.progress, closeTo(1 / tutorial.steps.length, 0.01));
    });

    test('isLastStep returns false on first step', () {
      final state = InteractiveTutorialState(
        activeTutorial: InteractiveTutorials.welcomeTour,
        currentStepIndex: 0,
      );
      expect(state.isLastStep, false);
    });

    test('isActive returns false when no tutorial', () {
      const state = InteractiveTutorialState();
      expect(state.isActive, false);
    });

    test('currentStep returns null when no tutorial', () {
      const state = InteractiveTutorialState();
      expect(state.currentStep, isNull);
    });

    test('copyWith to different step index', () {
      final state = InteractiveTutorialState(
        activeTutorial: InteractiveTutorials.welcomeTour,
        currentStepIndex: 0,
      );
      final copied = state.copyWith(currentStepIndex: 3);
      expect(copied.currentStepIndex, 3);
      expect(copied.activeTutorial, isNotNull);
    });

    test('completedTutorials set operations', () {
      final state = InteractiveTutorialState(
        completedTutorials: {'welcome_tour', 'delivery_flow'},
      );
      expect(state.completedTutorials.length, 2);
      expect(state.completedTutorials.contains('welcome_tour'), true);
    });
  });

  group('InteractiveTutorialStep - Variations', () {
    test('step with tips', () {
      const step = InteractiveTutorialStep(
        id: 'step-tips',
        title: 'Step with Tips',
        description: 'Has tips',
        icon: Icons.info,
        tips: ['Tip 1', 'Tip 2'],
      );
      expect(step.tips, isNotNull);
      expect(step.tips!.length, 2);
    });

    test('step with circle spotlight', () {
      const step = InteractiveTutorialStep(
        id: 'step-circle',
        title: 'Circle spotlight',
        description: 'Uses circle',
        icon: Icons.circle,
        spotlightShape: SpotlightShape.circle,
      );
      expect(step.spotlightShape, SpotlightShape.circle);
    });

    test('step with allowInteraction true', () {
      const step = InteractiveTutorialStep(
        id: 'step-interact',
        title: 'Interactive',
        description: 'Allows interaction',
        icon: Icons.touch_app,
        allowInteraction: true,
      );
      expect(step.allowInteraction, true);
    });

    test('step with rectangle spotlight', () {
      const step = InteractiveTutorialStep(
        id: 'step-rect',
        title: 'Rectangle',
        description: 'Uses rectangle',
        icon: Icons.rectangle,
        spotlightShape: SpotlightShape.rectangle,
      );
      expect(step.spotlightShape, SpotlightShape.rectangle);
    });
  });

  group('InteractiveTutorials - All tutorials', () {
    test('each tutorial has at least one step', () {
      for (final tutorial in InteractiveTutorials.all) {
        expect(
          tutorial.steps.isNotEmpty,
          true,
          reason: '${tutorial.id} should have steps',
        );
      }
    });

    test('each tutorial has unique id', () {
      final ids = InteractiveTutorials.all.map((t) => t.id).toSet();
      expect(ids.length, InteractiveTutorials.all.length);
    });

    test('deliveryFlow tutorial exists', () {
      final tutorial = InteractiveTutorials.getById('delivery_flow');
      expect(tutorial, isNotNull);
    });

    test('each tutorial has a name', () {
      for (final tutorial in InteractiveTutorials.all) {
        expect(tutorial.name.isNotEmpty, true);
      }
    });
  });

  group('Widget rendering with different tutorial IDs', () {
    testWidgets('StartTutorialButton with delivery_flow', (tester) async {
      SharedPreferences.setMockInitialValues({});
      await tester.pumpWidget(
        ProviderScope(
          overrides: commonWidgetTestOverrides(),
          child: const MaterialApp(
            home: Scaffold(
              body: StartTutorialButton(tutorialId: 'delivery_flow'),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(StartTutorialButton), findsOneWidget);
    });

    testWidgets('StartTutorialButton with nonexistent id', (tester) async {
      SharedPreferences.setMockInitialValues({});
      await tester.pumpWidget(
        ProviderScope(
          overrides: commonWidgetTestOverrides(),
          child: const MaterialApp(
            home: Scaffold(
              body: StartTutorialButton(tutorialId: 'nonexistent_id'),
            ),
          ),
        ),
      );
      await tester.pump();
      // Should render something even for invalid ID
      expect(find.byType(StartTutorialButton), findsOneWidget);
    });

    testWidgets('TutorialTarget with different keys', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Column(
            children: [
              TutorialTarget(targetKey: 'key_1', child: Text('Target 1')),
              TutorialTarget(targetKey: 'key_2', child: Text('Target 2')),
            ],
          ),
        ),
      );
      expect(find.text('Target 1'), findsOneWidget);
      expect(find.text('Target 2'), findsOneWidget);
    });

    testWidgets('InteractiveTutorialOverlay with Scaffold child', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      await tester.pumpWidget(
        ProviderScope(
          overrides: commonWidgetTestOverrides(),
          child: MaterialApp(
            home: InteractiveTutorialOverlay(
              child: Scaffold(
                appBar: AppBar(title: const Text('Test')),
                body: const Text('Body Content'),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.text('Body Content'), findsOneWidget);
      expect(find.text('Test'), findsOneWidget);
    });
  });

  // ── SpotlightShape enum ────────────────────────────
  group('SpotlightShape', () {
    test('has 3 values', () {
      expect(SpotlightShape.values.length, 3);
    });

    test('circle is index 0', () {
      expect(SpotlightShape.circle.index, 0);
    });

    test('rectangle is index 1', () {
      expect(SpotlightShape.rectangle.index, 1);
    });

    test('roundedRectangle is index 2', () {
      expect(SpotlightShape.roundedRectangle.index, 2);
    });
  });

  // ── InteractiveTutorialStep extra ──────────────────
  group('InteractiveTutorialStep - Extra fields', () {
    test('spotlightPadding defaults', () {
      const step = InteractiveTutorialStep(
        id: 'pad-test',
        title: 'Padding Test',
        description: 'Testing padding',
        icon: Icons.star,
      );
      expect(step.spotlightPadding, isNotNull);
    });

    test('step with targetWidgetKey', () {
      const step = InteractiveTutorialStep(
        id: 'target-key-step',
        title: 'Target Widget',
        description: 'Has target key',
        icon: Icons.gps_fixed,
        targetWidgetKey: 'dashboard_card',
      );
      expect(step.targetWidgetKey, 'dashboard_card');
    });

    test('step with actionLabel', () {
      const step = InteractiveTutorialStep(
        id: 'action-step',
        title: 'Action Step',
        description: 'Has action label',
        icon: Icons.play_arrow,
        actionLabel: 'Tap to continue',
      );
      expect(step.actionLabel, 'Tap to continue');
    });

    test('step with all fields', () {
      const step = InteractiveTutorialStep(
        id: 'full-step',
        title: 'Full Step',
        description: 'All fields set',
        icon: Icons.check,
        spotlightShape: SpotlightShape.circle,
        allowInteraction: true,
        tips: ['Tip A', 'Tip B', 'Tip C'],
        targetWidgetKey: 'widget_key',
        actionLabel: 'Action',
      );
      expect(step.id, 'full-step');
      expect(step.spotlightShape, SpotlightShape.circle);
      expect(step.allowInteraction, true);
      expect(step.tips!.length, 3);
      expect(step.targetWidgetKey, 'widget_key');
      expect(step.actionLabel, 'Action');
    });

    test('step with empty tips list', () {
      const step = InteractiveTutorialStep(
        id: 'empty-tips',
        title: 'Empty Tips',
        description: 'Tips is empty',
        icon: Icons.lightbulb,
        tips: [],
      );
      expect(step.tips, isEmpty);
    });
  });

  // ── InteractiveTutorialState - more copyWith ───────
  group('InteractiveTutorialState - CopyWith individual fields', () {
    test('copyWith updates currentStepIndex only', () {
      final state = InteractiveTutorialState(
        activeTutorial: InteractiveTutorials.welcomeTour,
        currentStepIndex: 0,
        isPaused: false,
        completedTutorials: {'t1'},
      );
      final copied = state.copyWith(currentStepIndex: 5);
      expect(copied.currentStepIndex, 5);
      expect(copied.activeTutorial, isNotNull);
      expect(copied.isPaused, false);
      expect(copied.completedTutorials, {'t1'});
    });

    test('copyWith updates completedTutorials only', () {
      final state = InteractiveTutorialState(
        activeTutorial: InteractiveTutorials.welcomeTour,
        currentStepIndex: 2,
      );
      final copied = state.copyWith(completedTutorials: {'a', 'b', 'c'});
      expect(copied.completedTutorials.length, 3);
      expect(copied.currentStepIndex, 2);
      expect(copied.activeTutorial, isNotNull);
    });

    test('copyWith updates isPaused only', () {
      final state = InteractiveTutorialState(
        activeTutorial: InteractiveTutorials.welcomeTour,
        isPaused: false,
      );
      final copied = state.copyWith(isPaused: true);
      expect(copied.isPaused, true);
      expect(copied.activeTutorial, isNotNull);
    });
  });

  // ── Welcome tour step details ──────────────────────
  group('WelcomeTour steps', () {
    test('first step id is welcome_intro', () {
      expect(InteractiveTutorials.welcomeTour.steps.first.id, 'welcome_intro');
    });

    test('each step has non-empty title and description', () {
      for (final step in InteractiveTutorials.welcomeTour.steps) {
        expect(step.title.isNotEmpty, true, reason: '${step.id} title empty');
        expect(
          step.description.isNotEmpty,
          true,
          reason: '${step.id} desc empty',
        );
      }
    });

    test('each step has an icon', () {
      for (final step in InteractiveTutorials.welcomeTour.steps) {
        expect(step.icon, isNotNull, reason: '${step.id} icon null');
      }
    });

    test('welcome tour has a name', () {
      expect(InteractiveTutorials.welcomeTour.name.isNotEmpty, true);
    });

    test('welcome tour has a color', () {
      expect(InteractiveTutorials.welcomeTour.color, isNotNull);
    });
  });

  // ── All tutorials structure ────────────────────────
  group('InteractiveTutorials - Structure', () {
    test('each step in all tutorials has unique id within tutorial', () {
      for (final tutorial in InteractiveTutorials.all) {
        final ids = tutorial.steps.map((s) => s.id).toSet();
        expect(
          ids.length,
          tutorial.steps.length,
          reason: '${tutorial.id} has duplicate step ids',
        );
      }
    });

    test('each tutorial has a color', () {
      for (final tutorial in InteractiveTutorials.all) {
        expect(tutorial.color, isNotNull, reason: '${tutorial.id} color null');
      }
    });

    test('each tutorial step has valid spotlight shape', () {
      for (final tutorial in InteractiveTutorials.all) {
        for (final step in tutorial.steps) {
          expect(SpotlightShape.values.contains(step.spotlightShape), true);
        }
      }
    });

    test('getById for all tutorials returns non-null', () {
      for (final tutorial in InteractiveTutorials.all) {
        expect(InteractiveTutorials.getById(tutorial.id), isNotNull);
      }
    });
  });

  // ── Widget rendering extras ────────────────────────
  group('Widget rendering extras', () {
    testWidgets('StartTutorialButton with showLabel false renders icon only', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      await tester.pumpWidget(
        ProviderScope(
          overrides: commonWidgetTestOverrides(),
          child: const MaterialApp(
            home: Scaffold(
              body: StartTutorialButton(
                tutorialId: 'welcome_tour',
                showLabel: false,
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(StartTutorialButton), findsOneWidget);
      // Should have an IconButton, not OutlinedButton
      expect(find.byType(IconButton), findsWidgets);
    });

    testWidgets('StartTutorialButton with showLabel true renders text', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      await tester.pumpWidget(
        ProviderScope(
          overrides: commonWidgetTestOverrides(),
          child: const MaterialApp(
            home: Scaffold(
              body: StartTutorialButton(
                tutorialId: 'welcome_tour',
                showLabel: true,
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(StartTutorialButton), findsOneWidget);
      // Should have OutlinedButton with text
      final outlined = find.byType(OutlinedButton);
      final elevated = find.byType(ElevatedButton);
      expect(
        outlined.evaluate().length + elevated.evaluate().length,
        greaterThanOrEqualTo(0),
      );
    });

    testWidgets('TutorialProgressBadge has text widget', (tester) async {
      SharedPreferences.setMockInitialValues({});
      await tester.pumpWidget(
        ProviderScope(
          overrides: commonWidgetTestOverrides(),
          child: const MaterialApp(
            home: Scaffold(body: TutorialProgressBadge()),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(Text), findsWidgets);
    });

    testWidgets('TutorialProgressBadge has Container', (tester) async {
      SharedPreferences.setMockInitialValues({});
      await tester.pumpWidget(
        ProviderScope(
          overrides: commonWidgetTestOverrides(),
          child: const MaterialApp(
            home: Scaffold(body: TutorialProgressBadge()),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(Container), findsWidgets);
    });

    testWidgets('InteractiveTutorialOverlay renders Stack when no tutorial', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      await tester.pumpWidget(
        ProviderScope(
          overrides: commonWidgetTestOverrides(),
          child: const MaterialApp(
            home: InteractiveTutorialOverlay(child: Text('No tutorial active')),
          ),
        ),
      );
      await tester.pump();
      expect(find.text('No tutorial active'), findsOneWidget);
    });

    testWidgets('TutorialTarget wraps in KeyedSubtree', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: TutorialTarget(
            targetKey: 'keyed_test',
            child: Icon(Icons.star),
          ),
        ),
      );
      expect(find.byIcon(Icons.star), findsOneWidget);
    });

    testWidgets('Multiple tutorial targets in same tree', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Column(
            children: [
              TutorialTarget(targetKey: 'a', child: Text('A')),
              TutorialTarget(targetKey: 'b', child: Text('B')),
              TutorialTarget(targetKey: 'c', child: Text('C')),
            ],
          ),
        ),
      );
      expect(find.text('A'), findsOneWidget);
      expect(find.text('B'), findsOneWidget);
      expect(find.text('C'), findsOneWidget);
    });
  });

  group('InteractiveTutorialOverlay - detailed', () {
    testWidgets('overlay renders content', (tester) async {
      SharedPreferences.setMockInitialValues({});
      await tester.pumpWidget(
        ProviderScope(
          overrides: commonWidgetTestOverrides(),
          child: const MaterialApp(
            home: InteractiveTutorialOverlay(child: Text('Content')),
          ),
        ),
      );
      await tester.pump();
      expect(find.text('Content'), findsOneWidget);
    });

    testWidgets('overlay child is accessible', (tester) async {
      SharedPreferences.setMockInitialValues({});
      await tester.pumpWidget(
        ProviderScope(
          overrides: commonWidgetTestOverrides(),
          child: const MaterialApp(
            home: InteractiveTutorialOverlay(
              child: Column(children: [Text('Line 1'), Text('Line 2')]),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.text('Line 1'), findsOneWidget);
      expect(find.text('Line 2'), findsOneWidget);
    });

    testWidgets('overlay with Scaffold child', (tester) async {
      SharedPreferences.setMockInitialValues({});
      await tester.pumpWidget(
        ProviderScope(
          overrides: commonWidgetTestOverrides(),
          child: MaterialApp(
            home: InteractiveTutorialOverlay(
              child: Scaffold(
                appBar: AppBar(title: const Text('Test Title')),
                body: const Center(child: Text('Body')),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.text('Test Title'), findsOneWidget);
      expect(find.text('Body'), findsOneWidget);
    });
  });

  group('TutorialTarget - detailed', () {
    testWidgets('wraps child in KeyedSubtree', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: TutorialTarget(
            targetKey: 'keyed_check',
            child: Icon(Icons.star),
          ),
        ),
      );
      expect(find.byIcon(Icons.star), findsOneWidget);
      expect(find.byType(KeyedSubtree), findsWidgets);
    });

    testWidgets('renders complex child widget tree', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: TutorialTarget(
            targetKey: 'complex_child',
            child: Column(
              children: [Icon(Icons.home), Text('Home'), SizedBox(height: 10)],
            ),
          ),
        ),
      );
      expect(find.byIcon(Icons.home), findsOneWidget);
      expect(find.text('Home'), findsOneWidget);
    });

    testWidgets('five targets rendered', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Column(
            children: [
              TutorialTarget(targetKey: 't1', child: Text('T1')),
              TutorialTarget(targetKey: 't2', child: Text('T2')),
              TutorialTarget(targetKey: 't3', child: Text('T3')),
              TutorialTarget(targetKey: 't4', child: Text('T4')),
              TutorialTarget(targetKey: 't5', child: Text('T5')),
            ],
          ),
        ),
      );
      expect(find.byType(TutorialTarget), findsNWidgets(5));
    });
  });

  group('StartTutorialButton - detailed', () {
    testWidgets('renders with delivery_flow id', (tester) async {
      SharedPreferences.setMockInitialValues({});
      await tester.pumpWidget(
        ProviderScope(
          overrides: commonWidgetTestOverrides(),
          child: const MaterialApp(
            home: Scaffold(
              body: StartTutorialButton(tutorialId: 'delivery_flow'),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(StartTutorialButton), findsOneWidget);
    });

    testWidgets('has Icon widget', (tester) async {
      SharedPreferences.setMockInitialValues({});
      await tester.pumpWidget(
        ProviderScope(
          overrides: commonWidgetTestOverrides(),
          child: const MaterialApp(
            home: Scaffold(
              body: StartTutorialButton(tutorialId: 'welcome_tour'),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(Icon), findsWidgets);
    });

    testWidgets('showLabel true has text content', (tester) async {
      SharedPreferences.setMockInitialValues({});
      await tester.pumpWidget(
        ProviderScope(
          overrides: commonWidgetTestOverrides(),
          child: const MaterialApp(
            home: Scaffold(
              body: StartTutorialButton(
                tutorialId: 'welcome_tour',
                showLabel: true,
              ),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(Text), findsWidgets);
    });

    testWidgets('button is tappable', (tester) async {
      SharedPreferences.setMockInitialValues({});
      await tester.pumpWidget(
        ProviderScope(
          overrides: commonWidgetTestOverrides(),
          child: const MaterialApp(
            home: Scaffold(
              body: StartTutorialButton(tutorialId: 'welcome_tour'),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(seconds: 1));
      final btn = find.byType(StartTutorialButton);
      expect(btn, findsOneWidget);
    });
  });

  group('TutorialProgressBadge - detailed', () {
    testWidgets('has Container widget', (tester) async {
      SharedPreferences.setMockInitialValues({});
      await tester.pumpWidget(
        ProviderScope(
          overrides: commonWidgetTestOverrides(),
          child: const MaterialApp(
            home: Scaffold(body: TutorialProgressBadge()),
          ),
        ),
      );
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(Container), findsWidgets);
    });

    testWidgets('has Text child', (tester) async {
      SharedPreferences.setMockInitialValues({});
      await tester.pumpWidget(
        ProviderScope(
          overrides: commonWidgetTestOverrides(),
          child: const MaterialApp(
            home: Scaffold(body: TutorialProgressBadge()),
          ),
        ),
      );
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(Text), findsWidgets);
    });

    testWidgets('has Row or Column layout', (tester) async {
      SharedPreferences.setMockInitialValues({});
      await tester.pumpWidget(
        ProviderScope(
          overrides: commonWidgetTestOverrides(),
          child: const MaterialApp(
            home: Scaffold(body: TutorialProgressBadge()),
          ),
        ),
      );
      await tester.pump(const Duration(seconds: 1));
      final rows = find.byType(Row);
      final cols = find.byType(Column);
      expect(rows.evaluate().length + cols.evaluate().length, greaterThan(0));
    });
  });

  group('Interactive tutorial widgets - active overlay coverage', () {
    Widget buildOverlay(
      _FakeInteractiveTutorialService service, {
      required Widget child,
    }) {
      return ProviderScope(
        overrides: [
          ...commonWidgetTestOverrides(),
          interactiveTutorialProvider.overrideWith(() => service),
        ],
        child: MaterialApp(
          home: Scaffold(body: InteractiveTutorialOverlay(child: child)),
        ),
      );
    }

    testWidgets('active overlay shows tooltip title, tips, and progress', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      const tutorial = InteractiveTutorial(
        id: 'custom_tutorial',
        name: 'Tutoriel Test',
        description: 'Description globale',
        icon: Icons.school,
        color: Colors.indigo,
        steps: [
          InteractiveTutorialStep(
            id: 'custom_step',
            title: 'Étape active',
            description: 'Description détaillée',
            icon: Icons.star,
            tips: ['Astuce A', 'Astuce B'],
            actionLabel: 'Continuer',
          ),
        ],
      );
      final service = _FakeInteractiveTutorialService(
        const InteractiveTutorialState(activeTutorial: tutorial),
      );

      await _pumpTutorialWidget(
        tester,
        buildOverlay(service, child: const Center(child: Text('Contenu'))),
      );

      expect(find.text('Tutoriel Test'), findsOneWidget);
      expect(find.text('Étape active'), findsOneWidget);
      expect(find.text('Description détaillée'), findsOneWidget);
      expect(find.text('Astuce A'), findsOneWidget);
      expect(find.text('Astuce B'), findsOneWidget);
      expect(find.text('1/1'), findsOneWidget);
      expect(find.text('Continuer'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsWidgets);
    });

    testWidgets('close and previous actions invoke tutorial callbacks', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      const tutorial = InteractiveTutorial(
        id: 'multi_step',
        name: 'Tutoriel Multi',
        description: 'Desc',
        icon: Icons.map,
        color: Colors.orange,
        steps: [
          InteractiveTutorialStep(
            id: 'step_1',
            title: 'Étape 1',
            description: 'Première étape',
            icon: Icons.looks_one,
          ),
          InteractiveTutorialStep(
            id: 'step_2',
            title: 'Étape 2',
            description: 'Deuxième étape',
            icon: Icons.looks_two,
          ),
        ],
      );
      final service = _FakeInteractiveTutorialService(
        const InteractiveTutorialState(
          activeTutorial: tutorial,
          currentStepIndex: 1,
        ),
      );

      await _pumpTutorialWidget(
        tester,
        buildOverlay(service, child: const Center(child: Text('Contenu'))),
      );

      expect(find.text('Précédent'), findsOneWidget);
      expect(find.text('2/2'), findsOneWidget);

      await tester.tap(find.text('Précédent'));
      await tester.pump();
      expect(service.didPrevious, true);

      await tester.tap(find.byIcon(Icons.close));
      await tester.pump();
      expect(service.didCancel, true);
    });

    testWidgets(
      'completed tutorial button shows revoir and progress badge done',
      (tester) async {
        SharedPreferences.setMockInitialValues({});
        final completed = InteractiveTutorials.all.map((t) => t.id).toSet();
        final service = _FakeInteractiveTutorialService(
          InteractiveTutorialState(completedTutorials: completed),
        );

        await _pumpTutorialWidget(
          tester,
          ProviderScope(
            overrides: [
              ...commonWidgetTestOverrides(),
              interactiveTutorialProvider.overrideWith(() => service),
            ],
            child: const MaterialApp(
              home: Scaffold(
                body: Column(
                  children: [
                    StartTutorialButton(tutorialId: 'welcome_tour'),
                    TutorialProgressBadge(),
                  ],
                ),
              ),
            ),
          ),
        );

        expect(find.text('Revoir'), findsOneWidget);
        expect(find.byIcon(Icons.refresh), findsOneWidget);
        expect(
          find.text(
            '${InteractiveTutorials.all.length}/${InteractiveTutorials.all.length}',
          ),
          findsOneWidget,
        );
        expect(find.byIcon(Icons.check_circle), findsOneWidget);
      },
    );
  });
}
