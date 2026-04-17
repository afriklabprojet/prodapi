import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:courier/core/services/interactive_tutorial_service.dart';

void main() {
  group('SpotlightShape', () {
    test('has 3 values', () {
      expect(SpotlightShape.values.length, 3);
      expect(SpotlightShape.values, contains(SpotlightShape.circle));
      expect(SpotlightShape.values, contains(SpotlightShape.rectangle));
      expect(SpotlightShape.values, contains(SpotlightShape.roundedRectangle));
    });
  });

  group('InteractiveTutorialStep', () {
    test('creates with required fields', () {
      const step = InteractiveTutorialStep(
        id: 'test_step',
        title: 'Test Title',
        description: 'Test Description',
        icon: Icons.star,
      );
      expect(step.id, 'test_step');
      expect(step.title, 'Test Title');
      expect(step.description, 'Test Description');
      expect(step.icon, Icons.star);
    });

    test('has correct defaults', () {
      const step = InteractiveTutorialStep(
        id: 'test',
        title: 'Title',
        description: 'Desc',
        icon: Icons.star,
      );
      expect(step.targetWidgetKey, isNull);
      expect(step.spotlightShape, SpotlightShape.roundedRectangle);
      expect(step.spotlightPadding, 8.0);
      expect(step.tooltipAlignment, Alignment.bottomCenter);
      expect(step.actionLabel, isNull);
      expect(step.allowInteraction, false);
      expect(step.autoAdvanceDelay, isNull);
      expect(step.tips, isNull);
    });

    test('creates with all optional fields', () {
      const step = InteractiveTutorialStep(
        id: 'full',
        title: 'Full Step',
        description: 'Full Desc',
        icon: Icons.info,
        targetWidgetKey: 'widget_key',
        spotlightShape: SpotlightShape.circle,
        spotlightPadding: 16.0,
        tooltipAlignment: Alignment.topCenter,
        actionLabel: 'Next',
        allowInteraction: true,
        autoAdvanceDelay: Duration(seconds: 3),
        tips: ['Tip 1', 'Tip 2'],
      );
      expect(step.targetWidgetKey, 'widget_key');
      expect(step.spotlightShape, SpotlightShape.circle);
      expect(step.spotlightPadding, 16.0);
      expect(step.tooltipAlignment, Alignment.topCenter);
      expect(step.actionLabel, 'Next');
      expect(step.allowInteraction, true);
      expect(step.autoAdvanceDelay, const Duration(seconds: 3));
      expect(step.tips, ['Tip 1', 'Tip 2']);
    });
  });

  group('InteractiveTutorial', () {
    test('creates with required fields', () {
      const tutorial = InteractiveTutorial(
        id: 'test_tuto',
        name: 'Test Tutorial',
        description: 'Test Desc',
        icon: Icons.school,
        color: Colors.blue,
        steps: [],
      );
      expect(tutorial.id, 'test_tuto');
      expect(tutorial.name, 'Test Tutorial');
      expect(tutorial.estimatedMinutes, 2);
      expect(tutorial.prerequisites, isEmpty);
    });

    test('creates with custom estimated minutes and prerequisites', () {
      const tutorial = InteractiveTutorial(
        id: 'adv',
        name: 'Advanced',
        description: 'Advanced tutorial',
        icon: Icons.star,
        color: Colors.red,
        steps: [],
        estimatedMinutes: 5,
        prerequisites: ['basic_tour'],
      );
      expect(tutorial.estimatedMinutes, 5);
      expect(tutorial.prerequisites, ['basic_tour']);
    });
  });

  group('InteractiveTutorials catalog', () {
    test('all returns 6 tutorials', () {
      expect(InteractiveTutorials.all.length, 6);
    });

    test('welcomeTour has correct id and steps', () {
      expect(InteractiveTutorials.welcomeTour.id, 'welcome_tour');
      expect(InteractiveTutorials.welcomeTour.steps.length, greaterThan(0));
      expect(InteractiveTutorials.welcomeTour.estimatedMinutes, 3);
    });

    test('deliveryFlow has correct id', () {
      expect(InteractiveTutorials.deliveryFlow.id, 'delivery_flow');
      expect(InteractiveTutorials.deliveryFlow.steps.length, greaterThan(0));
    });

    test('walletGuide has correct id', () {
      expect(InteractiveTutorials.walletGuide.id, 'wallet_guide');
    });

    test('navigationTips has correct id', () {
      expect(InteractiveTutorials.navigationTips.id, 'navigation_tips');
    });

    test('gamificationGuide has correct id', () {
      expect(InteractiveTutorials.gamificationGuide.id, 'gamification_guide');
    });

    test('offlineModeGuide has correct id', () {
      expect(InteractiveTutorials.offlineModeGuide.id, 'offline_mode');
    });

    test('getById returns correct tutorial', () {
      final result = InteractiveTutorials.getById('welcome_tour');
      expect(result, isNotNull);
      expect(result!.id, 'welcome_tour');
    });

    test('getById returns null for unknown id', () {
      expect(InteractiveTutorials.getById('nonexistent'), isNull);
    });

    test('getById returns each tutorial', () {
      for (final t in InteractiveTutorials.all) {
        expect(InteractiveTutorials.getById(t.id), isNotNull);
        expect(InteractiveTutorials.getById(t.id)!.id, t.id);
      }
    });

    test('all tutorials have unique ids', () {
      final ids = InteractiveTutorials.all.map((t) => t.id).toSet();
      expect(ids.length, InteractiveTutorials.all.length);
    });

    test('all tutorials have at least one step', () {
      for (final t in InteractiveTutorials.all) {
        expect(t.steps, isNotEmpty, reason: '${t.id} has no steps');
      }
    });

    test('all tutorials have non-empty name and description', () {
      for (final t in InteractiveTutorials.all) {
        expect(t.name, isNotEmpty);
        expect(t.description, isNotEmpty);
      }
    });

    test('all tutorial steps have required fields', () {
      for (final t in InteractiveTutorials.all) {
        for (final s in t.steps) {
          expect(s.id, isNotEmpty, reason: 'Step in ${t.id} has empty id');
          expect(s.title, isNotEmpty, reason: 'Step ${s.id} has empty title');
          expect(
            s.description,
            isNotEmpty,
            reason: 'Step ${s.id} has empty description',
          );
        }
      }
    });
  });

  group('InteractiveTutorialState', () {
    test('default state has no active tutorial', () {
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

    test('currentStep returns correct step when active', () {
      final state = InteractiveTutorialState(
        activeTutorial: InteractiveTutorials.welcomeTour,
        currentStepIndex: 0,
      );
      expect(state.currentStep, isNotNull);
      expect(state.currentStep!.id, 'welcome_intro');
    });

    test('currentStep returns null when index out of range', () {
      final state = InteractiveTutorialState(
        activeTutorial: InteractiveTutorials.welcomeTour,
        currentStepIndex: 999,
      );
      expect(state.currentStep, isNull);
    });

    test('isActive is true when tutorial active and not paused', () {
      final state = InteractiveTutorialState(
        activeTutorial: InteractiveTutorials.welcomeTour,
      );
      expect(state.isActive, true);
    });

    test('isActive is false when paused', () {
      final state = InteractiveTutorialState(
        activeTutorial: InteractiveTutorials.welcomeTour,
        isPaused: true,
      );
      expect(state.isActive, false);
    });

    test('isActive is false when no tutorial', () {
      const state = InteractiveTutorialState();
      expect(state.isActive, false);
    });

    test('isLastStep when on last step', () {
      final tutorial = InteractiveTutorials.welcomeTour;
      final state = InteractiveTutorialState(
        activeTutorial: tutorial,
        currentStepIndex: tutorial.steps.length - 1,
      );
      expect(state.isLastStep, true);
    });

    test('isLastStep false when not last', () {
      final state = InteractiveTutorialState(
        activeTutorial: InteractiveTutorials.welcomeTour,
        currentStepIndex: 0,
      );
      expect(state.isLastStep, false);
    });

    test('isLastStep false when no tutorial', () {
      const state = InteractiveTutorialState();
      expect(state.isLastStep, false);
    });

    test('progress returns 0 when no tutorial', () {
      const state = InteractiveTutorialState();
      expect(state.progress, 0);
    });

    test('progress computes correctly', () {
      final tutorial = InteractiveTutorials.deliveryFlow;
      final state = InteractiveTutorialState(
        activeTutorial: tutorial,
        currentStepIndex: 0,
      );
      expect(state.progress, closeTo(1.0 / tutorial.steps.length, 0.001));
    });

    test('progress at last step is 1.0', () {
      final tutorial = InteractiveTutorials.offlineModeGuide;
      final state = InteractiveTutorialState(
        activeTutorial: tutorial,
        currentStepIndex: tutorial.steps.length - 1,
      );
      expect(state.progress, 1.0);
    });

    test('copyWith preserves fields', () {
      final original = InteractiveTutorialState(
        activeTutorial: InteractiveTutorials.welcomeTour,
        currentStepIndex: 2,
        isPaused: true,
        completedTutorials: {'test'},
      );
      final copy = original.copyWith();
      expect(copy.activeTutorial?.id, 'welcome_tour');
      expect(copy.currentStepIndex, 2);
      expect(copy.isPaused, true);
      expect(copy.completedTutorials, {'test'});
    });

    test('copyWith updates specific fields', () {
      final original = InteractiveTutorialState(
        activeTutorial: InteractiveTutorials.welcomeTour,
        currentStepIndex: 0,
      );
      final updated = original.copyWith(currentStepIndex: 3, isPaused: true);
      expect(updated.currentStepIndex, 3);
      expect(updated.isPaused, true);
      expect(updated.activeTutorial?.id, 'welcome_tour');
    });

    test('copyWith with clearActiveTutorial', () {
      final state = InteractiveTutorialState(
        activeTutorial: InteractiveTutorials.welcomeTour,
        currentStepIndex: 2,
      );
      final cleared = state.copyWith(clearActiveTutorial: true);
      expect(cleared.activeTutorial, isNull);
    });
  });

  group('registerTutorialTarget', () {
    test('returns GlobalKey', () {
      tutorialTargetKeys.clear();
      final key = registerTutorialTarget('test_widget');
      expect(key, isA<GlobalKey>());
    });

    test('returns same key for same id', () {
      tutorialTargetKeys.clear();
      final key1 = registerTutorialTarget('widget_a');
      final key2 = registerTutorialTarget('widget_a');
      expect(identical(key1, key2), true);
    });

    test('returns different keys for different ids', () {
      tutorialTargetKeys.clear();
      final key1 = registerTutorialTarget('widget_a');
      final key2 = registerTutorialTarget('widget_b');
      expect(identical(key1, key2), false);
    });
  });
}
