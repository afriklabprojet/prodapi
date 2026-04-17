import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:courier/core/services/tutorial_service.dart';

void main() {
  group('TutorialType', () {
    test('has 7 values', () {
      expect(TutorialType.values.length, 7);
    });

    test('contains all expected types', () {
      expect(TutorialType.values, contains(TutorialType.welcome));
      expect(TutorialType.values, contains(TutorialType.acceptDelivery));
      expect(TutorialType.values, contains(TutorialType.navigation));
      expect(TutorialType.values, contains(TutorialType.completeDelivery));
      expect(TutorialType.values, contains(TutorialType.wallet));
      expect(TutorialType.values, contains(TutorialType.challenges));
      expect(TutorialType.values, contains(TutorialType.offlineMode));
    });
  });

  group('TutorialStep', () {
    test('creates with required fields', () {
      const step = TutorialStep(
        title: 'Test Title',
        description: 'Test Description',
        icon: Icons.home,
      );
      expect(step.title, 'Test Title');
      expect(step.description, 'Test Description');
      expect(step.icon, Icons.home);
      expect(step.targetKey, isNull);
      expect(step.tooltipAlignment, isNull);
      expect(step.actionLabel, isNull);
      expect(step.onAction, isNull);
    });

    test('creates with optional fields', () {
      const step = TutorialStep(
        title: 'Title',
        description: 'Desc',
        icon: Icons.star,
        targetKey: 'my_widget',
        actionLabel: 'Got it!',
      );
      expect(step.targetKey, 'my_widget');
      expect(step.actionLabel, 'Got it!');
    });
  });

  group('Tutorials', () {
    test('welcome has 4 steps', () {
      expect(Tutorials.welcome.length, 4);
    });

    test('acceptDelivery has 3 steps', () {
      expect(Tutorials.acceptDelivery.length, 3);
    });

    test('navigation has 3 steps', () {
      expect(Tutorials.navigation.length, 3);
    });

    test('completeDelivery has 4 steps', () {
      expect(Tutorials.completeDelivery.length, 4);
    });

    test('wallet has 4 steps', () {
      expect(Tutorials.wallet.length, 4);
    });

    test('challenges has 3 steps', () {
      expect(Tutorials.challenges.length, 3);
    });

    test('offlineMode has 3 steps', () {
      expect(Tutorials.offlineMode.length, 3);
    });

    test('getSteps returns correct steps for each type', () {
      expect(Tutorials.getSteps(TutorialType.welcome), Tutorials.welcome);
      expect(
        Tutorials.getSteps(TutorialType.acceptDelivery),
        Tutorials.acceptDelivery,
      );
      expect(Tutorials.getSteps(TutorialType.navigation), Tutorials.navigation);
      expect(
        Tutorials.getSteps(TutorialType.completeDelivery),
        Tutorials.completeDelivery,
      );
      expect(Tutorials.getSteps(TutorialType.wallet), Tutorials.wallet);
      expect(Tutorials.getSteps(TutorialType.challenges), Tutorials.challenges);
      expect(
        Tutorials.getSteps(TutorialType.offlineMode),
        Tutorials.offlineMode,
      );
    });

    test('all steps have non-empty title and description', () {
      for (final type in TutorialType.values) {
        for (final step in Tutorials.getSteps(type)) {
          expect(
            step.title,
            isNotEmpty,
            reason: 'Step in $type has empty title',
          );
          expect(
            step.description,
            isNotEmpty,
            reason: 'Step in $type has empty description',
          );
        }
      }
    });
  });
}
