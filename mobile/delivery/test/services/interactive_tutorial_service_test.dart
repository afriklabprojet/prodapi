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
    test('creates with required fields and defaults', () {
      const step = InteractiveTutorialStep(
        id: 'step_1',
        title: 'Test Step',
        description: 'Step description',
        icon: Icons.home,
      );
      expect(step.id, 'step_1');
      expect(step.title, 'Test Step');
      expect(step.description, 'Step description');
      expect(step.icon, Icons.home);
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
        id: 'step_2',
        title: 'Advanced',
        description: 'Desc',
        icon: Icons.star,
        targetWidgetKey: 'widget_key',
        spotlightShape: SpotlightShape.circle,
        spotlightPadding: 16.0,
        tooltipAlignment: Alignment.topCenter,
        actionLabel: 'Got it!',
        allowInteraction: true,
        autoAdvanceDelay: Duration(seconds: 3),
        tips: ['Tip 1', 'Tip 2'],
      );
      expect(step.targetWidgetKey, 'widget_key');
      expect(step.spotlightShape, SpotlightShape.circle);
      expect(step.spotlightPadding, 16.0);
      expect(step.tooltipAlignment, Alignment.topCenter);
      expect(step.actionLabel, 'Got it!');
      expect(step.allowInteraction, true);
      expect(step.autoAdvanceDelay, const Duration(seconds: 3));
      expect(step.tips, ['Tip 1', 'Tip 2']);
    });
  });

  group('InteractiveTutorial', () {
    test('creates with required fields and defaults', () {
      const tutorial = InteractiveTutorial(
        id: 'test_tutorial',
        name: 'Test',
        description: 'A test tutorial',
        icon: Icons.school,
        color: Colors.blue,
        steps: [],
      );
      expect(tutorial.id, 'test_tutorial');
      expect(tutorial.name, 'Test');
      expect(tutorial.description, 'A test tutorial');
      expect(tutorial.estimatedMinutes, 2);
      expect(tutorial.prerequisites, isEmpty);
      expect(tutorial.steps, isEmpty);
    });
  });

  group('InteractiveTutorials', () {
    test('welcomeTour has valid steps', () {
      expect(InteractiveTutorials.welcomeTour.id, 'welcome_tour');
      expect(InteractiveTutorials.welcomeTour.steps, isNotEmpty);
      for (final step in InteractiveTutorials.welcomeTour.steps) {
        expect(step.id, isNotEmpty);
        expect(step.title, isNotEmpty);
        expect(step.description, isNotEmpty);
      }
    });

    test('deliveryFlow has valid steps', () {
      expect(InteractiveTutorials.deliveryFlow.id, 'delivery_flow');
      expect(InteractiveTutorials.deliveryFlow.steps, isNotEmpty);
    });

    test('walletGuide has valid steps', () {
      expect(InteractiveTutorials.walletGuide.id, 'wallet_guide');
      expect(InteractiveTutorials.walletGuide.steps, isNotEmpty);
    });

    test('navigationTips has valid steps', () {
      expect(InteractiveTutorials.navigationTips.id, 'navigation_tips');
      expect(InteractiveTutorials.navigationTips.steps, isNotEmpty);
    });

    test('gamificationGuide has valid steps', () {
      expect(InteractiveTutorials.gamificationGuide.id, 'gamification_guide');
      expect(InteractiveTutorials.gamificationGuide.steps, isNotEmpty);
    });

    test('offlineModeGuide has valid steps', () {
      expect(InteractiveTutorials.offlineModeGuide.id, 'offline_mode');
      expect(InteractiveTutorials.offlineModeGuide.steps, isNotEmpty);
    });

    test('all returns all 6 tutorials', () {
      expect(InteractiveTutorials.all.length, 6);
    });
  });

  group('registerTutorialTarget', () {
    test('creates and stores a global key', () {
      final key = registerTutorialTarget('test_target');
      expect(key, isA<GlobalKey>());
      expect(tutorialTargetKeys['test_target'], key);
    });

    test('returns same key for same id', () {
      final key1 = registerTutorialTarget('same_id');
      final key2 = registerTutorialTarget('same_id');
      expect(key1, same(key2));
    });
  });

  group('InteractiveTutorialState', () {
    test('default state', () {
      const state = InteractiveTutorialState();
      expect(state.activeTutorial, isNull);
      expect(state.currentStepIndex, 0);
      expect(state.isPaused, false);
      expect(state.completedTutorials, isEmpty);
    });

    test('isActive true when tutorial set and not paused', () {
      final state = InteractiveTutorialState(
        activeTutorial: InteractiveTutorials.welcomeTour,
      );
      expect(state.isActive, true);
    });

    test('isActive false when no tutorial', () {
      const state = InteractiveTutorialState();
      expect(state.isActive, false);
    });

    test('isActive false when paused', () {
      final state = InteractiveTutorialState(
        activeTutorial: InteractiveTutorials.welcomeTour,
        isPaused: true,
      );
      expect(state.isActive, false);
    });

    test('currentStep returns step at index', () {
      final state = InteractiveTutorialState(
        activeTutorial: InteractiveTutorials.welcomeTour,
        currentStepIndex: 0,
      );
      expect(state.currentStep, isNotNull);
      expect(
        state.currentStep!.id,
        InteractiveTutorials.welcomeTour.steps[0].id,
      );
    });

    test('currentStep returns null if no active tutorial', () {
      const state = InteractiveTutorialState();
      expect(state.currentStep, isNull);
    });

    test('currentStep returns null if index out of bounds', () {
      final state = InteractiveTutorialState(
        activeTutorial: InteractiveTutorials.welcomeTour,
        currentStepIndex: 999,
      );
      expect(state.currentStep, isNull);
    });

    test('isLastStep true on last index', () {
      final steps = InteractiveTutorials.welcomeTour.steps;
      final state = InteractiveTutorialState(
        activeTutorial: InteractiveTutorials.welcomeTour,
        currentStepIndex: steps.length - 1,
      );
      expect(state.isLastStep, true);
    });

    test('isLastStep false on first index', () {
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

    test('progress is 0 without tutorial', () {
      const state = InteractiveTutorialState();
      expect(state.progress, 0);
    });

    test('progress on first step', () {
      final state = InteractiveTutorialState(
        activeTutorial: InteractiveTutorials.welcomeTour,
        currentStepIndex: 0,
      );
      final stepsCount = InteractiveTutorials.welcomeTour.steps.length;
      expect(state.progress, 1 / stepsCount);
    });

    test('progress on last step is 1.0', () {
      final steps = InteractiveTutorials.welcomeTour.steps;
      final state = InteractiveTutorialState(
        activeTutorial: InteractiveTutorials.welcomeTour,
        currentStepIndex: steps.length - 1,
      );
      expect(state.progress, 1.0);
    });

    test('copyWith preserves all when no args', () {
      final state = InteractiveTutorialState(
        activeTutorial: InteractiveTutorials.deliveryFlow,
        currentStepIndex: 2,
        isPaused: true,
        completedTutorials: {'welcome_tour'},
      );
      final copy = state.copyWith();
      expect(copy.activeTutorial?.id, 'delivery_flow');
      expect(copy.currentStepIndex, 2);
      expect(copy.isPaused, true);
      expect(copy.completedTutorials, {'welcome_tour'});
    });

    test('copyWith overrides currentStepIndex', () {
      final state = InteractiveTutorialState(
        activeTutorial: InteractiveTutorials.welcomeTour,
      );
      final copy = state.copyWith(currentStepIndex: 3);
      expect(copy.currentStepIndex, 3);
      expect(copy.activeTutorial?.id, 'welcome_tour');
    });

    test('copyWith overrides isPaused', () {
      final state = InteractiveTutorialState(
        activeTutorial: InteractiveTutorials.welcomeTour,
      );
      final copy = state.copyWith(isPaused: true);
      expect(copy.isPaused, true);
    });

    test('copyWith overrides completedTutorials', () {
      const state = InteractiveTutorialState();
      final copy = state.copyWith(completedTutorials: {'a', 'b', 'c'});
      expect(copy.completedTutorials, {'a', 'b', 'c'});
    });

    test('copyWith overrides activeTutorial', () {
      final state = InteractiveTutorialState(
        activeTutorial: InteractiveTutorials.welcomeTour,
      );
      final copy = state.copyWith(
        activeTutorial: InteractiveTutorials.deliveryFlow,
      );
      expect(copy.activeTutorial?.id, 'delivery_flow');
    });

    test('copyWith clearActiveTutorial sets tutorial to null', () {
      final state = InteractiveTutorialState(
        activeTutorial: InteractiveTutorials.welcomeTour,
      );
      final copy = state.copyWith(clearActiveTutorial: true);
      expect(copy.activeTutorial, isNull);
    });
  });

  group('InteractiveTutorials catalog details', () {
    test('welcomeTour step count', () {
      expect(
        InteractiveTutorials.welcomeTour.steps.length,
        greaterThanOrEqualTo(3),
      );
    });

    test('deliveryFlow step count', () {
      expect(
        InteractiveTutorials.deliveryFlow.steps.length,
        greaterThanOrEqualTo(3),
      );
    });

    test('all tutorials have unique ids', () {
      final ids = InteractiveTutorials.all.map((t) => t.id).toSet();
      expect(ids.length, InteractiveTutorials.all.length);
    });

    test('all tutorials have non-empty name and description', () {
      for (final tutorial in InteractiveTutorials.all) {
        expect(tutorial.name, isNotEmpty);
        expect(tutorial.description, isNotEmpty);
      }
    });

    test('all tutorial steps have unique ids within tutorial', () {
      for (final tutorial in InteractiveTutorials.all) {
        final stepIds = tutorial.steps.map((s) => s.id).toSet();
        expect(
          stepIds.length,
          tutorial.steps.length,
          reason: '${tutorial.id} has duplicate step ids',
        );
      }
    });

    test('getById returns correct tutorial', () {
      final found = InteractiveTutorials.getById('welcome_tour');
      expect(found, isNotNull);
      expect(found?.id, 'welcome_tour');
    });

    test('getById returns null for unknown id', () {
      final found = InteractiveTutorials.getById('nonexistent');
      expect(found, isNull);
    });

    test('all tutorials have positive estimatedMinutes', () {
      for (final tutorial in InteractiveTutorials.all) {
        expect(tutorial.estimatedMinutes, greaterThan(0));
      }
    });
  });

  group('InteractiveTutorialStep optional fields', () {
    test('step with tips list', () {
      const step = InteractiveTutorialStep(
        id: 'tips_step',
        title: 'Tips',
        description: 'Has tips',
        icon: Icons.info,
        tips: ['Tip 1', 'Tip 2', 'Tip 3'],
      );
      expect(step.tips, hasLength(3));
      expect(step.tips!.first, 'Tip 1');
    });

    test('step with targetWidgetKey', () {
      const step = InteractiveTutorialStep(
        id: 'targeted',
        title: 'Targeted',
        description: 'Has target',
        icon: Icons.gps_fixed,
        targetWidgetKey: 'my_button',
      );
      expect(step.targetWidgetKey, 'my_button');
    });

    test('step with actionLabel', () {
      const step = InteractiveTutorialStep(
        id: 'action',
        title: 'Action',
        description: 'Has action',
        icon: Icons.touch_app,
        actionLabel: 'Compris !',
      );
      expect(step.actionLabel, 'Compris !');
    });

    test('step with circle spotlight', () {
      const step = InteractiveTutorialStep(
        id: 'circle',
        title: 'Circle',
        description: 'Circle spotlight',
        icon: Icons.circle,
        spotlightShape: SpotlightShape.circle,
      );
      expect(step.spotlightShape, SpotlightShape.circle);
    });

    test('step with rectangle spotlight', () {
      const step = InteractiveTutorialStep(
        id: 'rect',
        title: 'Rect',
        description: 'Rect spotlight',
        icon: Icons.rectangle,
        spotlightShape: SpotlightShape.rectangle,
      );
      expect(step.spotlightShape, SpotlightShape.rectangle);
    });

    test('step with autoAdvanceDelay', () {
      const step = InteractiveTutorialStep(
        id: 'auto',
        title: 'Auto',
        description: 'Auto advance',
        icon: Icons.timer,
        autoAdvanceDelay: Duration(seconds: 5),
      );
      expect(step.autoAdvanceDelay, const Duration(seconds: 5));
    });

    test('step with allowInteraction true', () {
      const step = InteractiveTutorialStep(
        id: 'interact',
        title: 'Interact',
        description: 'Allow interaction',
        icon: Icons.touch_app,
        allowInteraction: true,
      );
      expect(step.allowInteraction, true);
    });
  });

  group('SpotlightShape indices', () {
    test('circle is 0', () => expect(SpotlightShape.circle.index, 0));
    test('rectangle is 1', () => expect(SpotlightShape.rectangle.index, 1));
    test(
      'roundedRectangle is 2',
      () => expect(SpotlightShape.roundedRectangle.index, 2),
    );
  });
}
