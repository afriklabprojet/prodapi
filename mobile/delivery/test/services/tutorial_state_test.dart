import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:courier/core/services/interactive_tutorial_service.dart';

void main() {
  final testStep1 = InteractiveTutorialStep(
    id: 'step1',
    title: 'Welcome',
    description: 'First step',
    icon: Icons.home,
  );
  final testStep2 = InteractiveTutorialStep(
    id: 'step2',
    title: 'Navigate',
    description: 'Second step',
    icon: Icons.navigation,
    targetWidgetKey: 'nav_button',
    spotlightShape: SpotlightShape.circle,
    spotlightPadding: 16.0,
    tooltipAlignment: Alignment.topCenter,
    actionLabel: 'Next',
    allowInteraction: true,
    autoAdvanceDelay: const Duration(seconds: 3),
    tips: ['Tip 1', 'Tip 2'],
  );
  final testStep3 = InteractiveTutorialStep(
    id: 'step3',
    title: 'Done',
    description: 'Last step',
    icon: Icons.check,
  );

  final testTutorial = InteractiveTutorial(
    id: 'tutorial1',
    name: 'Getting Started',
    description: 'A basic tutorial',
    icon: Icons.school,
    color: Colors.blue,
    steps: [testStep1, testStep2, testStep3],
    estimatedMinutes: 5,
    prerequisites: ['login'],
  );

  group('SpotlightShape', () {
    test('has all values', () {
      expect(SpotlightShape.values.length, 3);
      expect(SpotlightShape.values, contains(SpotlightShape.circle));
      expect(SpotlightShape.values, contains(SpotlightShape.rectangle));
      expect(SpotlightShape.values, contains(SpotlightShape.roundedRectangle));
    });
  });

  group('InteractiveTutorialStep', () {
    test('has required fields', () {
      expect(testStep1.id, 'step1');
      expect(testStep1.title, 'Welcome');
      expect(testStep1.description, 'First step');
      expect(testStep1.icon, Icons.home);
    });

    test('has default values', () {
      expect(testStep1.targetWidgetKey, isNull);
      expect(testStep1.spotlightShape, SpotlightShape.roundedRectangle);
      expect(testStep1.spotlightPadding, 8.0);
      expect(testStep1.tooltipAlignment, Alignment.bottomCenter);
      expect(testStep1.actionLabel, isNull);
      expect(testStep1.allowInteraction, false);
      expect(testStep1.autoAdvanceDelay, isNull);
      expect(testStep1.tips, isNull);
    });

    test('has custom values', () {
      expect(testStep2.targetWidgetKey, 'nav_button');
      expect(testStep2.spotlightShape, SpotlightShape.circle);
      expect(testStep2.spotlightPadding, 16.0);
      expect(testStep2.tooltipAlignment, Alignment.topCenter);
      expect(testStep2.actionLabel, 'Next');
      expect(testStep2.allowInteraction, true);
      expect(testStep2.autoAdvanceDelay, const Duration(seconds: 3));
      expect(testStep2.tips, ['Tip 1', 'Tip 2']);
    });
  });

  group('InteractiveTutorial', () {
    test('has required fields', () {
      expect(testTutorial.id, 'tutorial1');
      expect(testTutorial.name, 'Getting Started');
      expect(testTutorial.description, 'A basic tutorial');
      expect(testTutorial.icon, Icons.school);
      expect(testTutorial.color, Colors.blue);
      expect(testTutorial.steps.length, 3);
    });

    test('has custom optional fields', () {
      expect(testTutorial.estimatedMinutes, 5);
      expect(testTutorial.prerequisites, ['login']);
    });

    test('default optional fields', () {
      final t = InteractiveTutorial(
        id: 'x',
        name: 'x',
        description: 'x',
        icon: Icons.abc,
        color: Colors.red,
        steps: [],
      );
      expect(t.estimatedMinutes, 2);
      expect(t.prerequisites, isEmpty);
    });
  });

  group('InteractiveTutorialState', () {
    test('default constructor', () {
      const state = InteractiveTutorialState();
      expect(state.activeTutorial, isNull);
      expect(state.currentStepIndex, 0);
      expect(state.isPaused, false);
      expect(state.completedTutorials, isEmpty);
    });

    test('currentStep returns null when no active tutorial', () {
      const state = InteractiveTutorialState();
      expect(state.currentStep, isNull);
    });

    test('currentStep returns correct step', () {
      final state = InteractiveTutorialState(
        activeTutorial: testTutorial,
        currentStepIndex: 1,
      );
      expect(state.currentStep, testStep2);
    });

    test('currentStep returns null when index out of bounds', () {
      final state = InteractiveTutorialState(
        activeTutorial: testTutorial,
        currentStepIndex: 10,
      );
      expect(state.currentStep, isNull);
    });

    test('isActive is false when no tutorial', () {
      const state = InteractiveTutorialState();
      expect(state.isActive, false);
    });

    test('isActive is true when tutorial and not paused', () {
      final state = InteractiveTutorialState(activeTutorial: testTutorial);
      expect(state.isActive, true);
    });

    test('isActive is false when paused', () {
      final state = InteractiveTutorialState(
        activeTutorial: testTutorial,
        isPaused: true,
      );
      expect(state.isActive, false);
    });

    test('isLastStep is false when no tutorial', () {
      const state = InteractiveTutorialState();
      expect(state.isLastStep, false);
    });

    test('isLastStep is false on first step', () {
      final state = InteractiveTutorialState(
        activeTutorial: testTutorial,
        currentStepIndex: 0,
      );
      expect(state.isLastStep, false);
    });

    test('isLastStep is true on last step', () {
      final state = InteractiveTutorialState(
        activeTutorial: testTutorial,
        currentStepIndex: 2,
      );
      expect(state.isLastStep, true);
    });

    test('progress is 0 when no tutorial', () {
      const state = InteractiveTutorialState();
      expect(state.progress, 0);
    });

    test('progress is 1/3 on first step', () {
      final state = InteractiveTutorialState(
        activeTutorial: testTutorial,
        currentStepIndex: 0,
      );
      expect(state.progress, closeTo(1 / 3, 0.001));
    });

    test('progress is 2/3 on second step', () {
      final state = InteractiveTutorialState(
        activeTutorial: testTutorial,
        currentStepIndex: 1,
      );
      expect(state.progress, closeTo(2 / 3, 0.001));
    });

    test('progress is 1.0 on last step', () {
      final state = InteractiveTutorialState(
        activeTutorial: testTutorial,
        currentStepIndex: 2,
      );
      expect(state.progress, 1.0);
    });

    test('copyWith preserves fields', () {
      final state = InteractiveTutorialState(
        activeTutorial: testTutorial,
        currentStepIndex: 1,
        isPaused: true,
        completedTutorials: {'a'},
      );
      final copy = state.copyWith();
      expect(copy.activeTutorial, testTutorial);
      expect(copy.currentStepIndex, 1);
      expect(copy.isPaused, true);
      expect(copy.completedTutorials, {'a'});
    });

    test('copyWith changes specific fields', () {
      final state = InteractiveTutorialState(
        activeTutorial: testTutorial,
        currentStepIndex: 0,
      );
      final copy = state.copyWith(currentStepIndex: 2, isPaused: true);
      expect(copy.currentStepIndex, 2);
      expect(copy.isPaused, true);
      expect(copy.activeTutorial, testTutorial);
    });

    test('copyWith clearActiveTutorial', () {
      final state = InteractiveTutorialState(activeTutorial: testTutorial);
      final copy = state.copyWith(clearActiveTutorial: true);
      expect(copy.activeTutorial, isNull);
    });

    test('copyWith sets completedTutorials', () {
      const state = InteractiveTutorialState();
      final copy = state.copyWith(
        completedTutorials: {'tutorial1', 'tutorial2'},
      );
      expect(copy.completedTutorials, {'tutorial1', 'tutorial2'});
    });
  });
}
