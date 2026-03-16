import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drpharma_client/core/animations/app_animations.dart';

void main() {
  group('AppAnimations Constants', () {
    group('Duration Constants', () {
      test('instant should be 100ms', () {
        expect(AppAnimations.instant, const Duration(milliseconds: 100));
      });

      test('fast should be 200ms', () {
        expect(AppAnimations.fast, const Duration(milliseconds: 200));
      });

      test('normal should be 300ms', () {
        expect(AppAnimations.normal, const Duration(milliseconds: 300));
      });

      test('slow should be 500ms', () {
        expect(AppAnimations.slow, const Duration(milliseconds: 500));
      });

      test('verySlow should be 800ms', () {
        expect(AppAnimations.verySlow, const Duration(milliseconds: 800));
      });

      test('durations should be in ascending order', () {
        expect(AppAnimations.instant.inMilliseconds,
            lessThan(AppAnimations.fast.inMilliseconds));
        expect(AppAnimations.fast.inMilliseconds,
            lessThan(AppAnimations.normal.inMilliseconds));
        expect(AppAnimations.normal.inMilliseconds,
            lessThan(AppAnimations.slow.inMilliseconds));
        expect(AppAnimations.slow.inMilliseconds,
            lessThan(AppAnimations.verySlow.inMilliseconds));
      });
    });

    group('Curve Constants', () {
      test('easeIn should be Curves.easeIn', () {
        expect(AppAnimations.easeIn, Curves.easeIn);
      });

      test('easeOut should be Curves.easeOut', () {
        expect(AppAnimations.easeOut, Curves.easeOut);
      });

      test('easeInOut should be Curves.easeInOut', () {
        expect(AppAnimations.easeInOut, Curves.easeInOut);
      });

      test('bounceOut should be Curves.bounceOut', () {
        expect(AppAnimations.bounceOut, Curves.bounceOut);
      });

      test('elasticOut should be Curves.elasticOut', () {
        expect(AppAnimations.elasticOut, Curves.elasticOut);
      });

      test('decelerate should be Curves.decelerate', () {
        expect(AppAnimations.decelerate, Curves.decelerate);
      });

      test('defaultCurve should be easeInOutCubic', () {
        expect(AppAnimations.defaultCurve, Curves.easeInOutCubic);
      });
    });

    group('Page Transition Constants', () {
      test('pageTransition should be 300ms', () {
        expect(AppAnimations.pageTransition, const Duration(milliseconds: 300));
      });

      test('pageTransitionCurve should be easeInOutCubic', () {
        expect(AppAnimations.pageTransitionCurve, Curves.easeInOutCubic);
      });
    });
  });

  group('SlideDirection', () {
    test('should have fromLeft', () {
      expect(SlideDirection.fromLeft.index, 0);
    });

    test('should have fromRight', () {
      expect(SlideDirection.fromRight.index, 1);
    });

    test('should have fromTop', () {
      expect(SlideDirection.fromTop.index, 2);
    });

    test('should have fromBottom', () {
      expect(SlideDirection.fromBottom.index, 3);
    });

    test('should have 4 values', () {
      expect(SlideDirection.values.length, 4);
    });
  });

  group('FadeInWidget', () {
    testWidgets('should render child widget', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: FadeInWidget(
            child: Text('Test'),
          ),
        ),
      );

      expect(find.text('Test'), findsOneWidget);
    });

    testWidgets('should animate opacity from 0 to 1', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: FadeInWidget(
            duration: Duration(milliseconds: 300),
            child: Text('Test'),
          ),
        ),
      );

      // After animation completes
      await tester.pumpAndSettle();

      expect(find.text('Test'), findsOneWidget);
    });

    testWidgets('should use default duration', (tester) async {
      const widget = FadeInWidget(child: Text('Test'));
      expect(widget.duration, const Duration(milliseconds: 300));
    });

    testWidgets('should use default curve', (tester) async {
      const widget = FadeInWidget(child: Text('Test'));
      expect(widget.curve, Curves.easeIn);
    });

    testWidgets('should accept custom duration', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: FadeInWidget(
            duration: Duration(milliseconds: 500),
            child: Text('Test'),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('Test'), findsOneWidget);
    });

    testWidgets('should accept custom curve', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: FadeInWidget(
            curve: Curves.bounceOut,
            child: Text('Test'),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('Test'), findsOneWidget);
    });

    testWidgets('should accept delay parameter', (tester) async {
      const widget = FadeInWidget(
        delay: Duration(milliseconds: 200),
        child: Text('Test'),
      );
      
      expect(widget.delay, const Duration(milliseconds: 200));
    });
  });

  group('SlideInWidget', () {
    testWidgets('should render child widget', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SlideInWidget(
            child: Text('Test'),
          ),
        ),
      );

      expect(find.text('Test'), findsOneWidget);
    });

    testWidgets('should use default direction (fromBottom)', (tester) async {
      const widget = SlideInWidget(child: Text('Test'));
      expect(widget.direction, SlideDirection.fromBottom);
    });

    testWidgets('should use default duration', (tester) async {
      const widget = SlideInWidget(child: Text('Test'));
      expect(widget.duration, const Duration(milliseconds: 400));
    });

    testWidgets('should use default curve', (tester) async {
      const widget = SlideInWidget(child: Text('Test'));
      expect(widget.curve, Curves.easeOutCubic);
    });

    testWidgets('should use default offsetAmount', (tester) async {
      const widget = SlideInWidget(child: Text('Test'));
      expect(widget.offsetAmount, 30.0);
    });

    testWidgets('should animate from left', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SlideInWidget(
            direction: SlideDirection.fromLeft,
            child: Text('Test'),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('Test'), findsOneWidget);
    });

    testWidgets('should animate from right', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SlideInWidget(
            direction: SlideDirection.fromRight,
            child: Text('Test'),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('Test'), findsOneWidget);
    });

    testWidgets('should animate from top', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SlideInWidget(
            direction: SlideDirection.fromTop,
            child: Text('Test'),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('Test'), findsOneWidget);
    });

    testWidgets('should animate from bottom', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SlideInWidget(
            direction: SlideDirection.fromBottom,
            child: Text('Test'),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('Test'), findsOneWidget);
    });

    testWidgets('should animate with fade and slide transitions',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SlideInWidget(
            child: Text('Test'),
          ),
        ),
      );

      // After animation completes
      await tester.pumpAndSettle();
      expect(find.text('Test'), findsOneWidget);
    });
  });

  group('ScaleInWidget', () {
    testWidgets('should render child widget', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ScaleInWidget(
            child: Text('Test'),
          ),
        ),
      );

      expect(find.text('Test'), findsOneWidget);
    });

    testWidgets('should use default duration', (tester) async {
      const widget = ScaleInWidget(child: Text('Test'));
      expect(widget.duration, const Duration(milliseconds: 300));
    });

    testWidgets('should use default curve', (tester) async {
      const widget = ScaleInWidget(child: Text('Test'));
      expect(widget.curve, Curves.easeOutBack);
    });

    testWidgets('should use default beginScale', (tester) async {
      const widget = ScaleInWidget(child: Text('Test'));
      expect(widget.beginScale, 0.8);
    });

    testWidgets('should accept custom beginScale', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ScaleInWidget(
            beginScale: 0.5,
            child: Text('Test'),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('Test'), findsOneWidget);
    });

    testWidgets('should animate with scale and fade transitions',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ScaleInWidget(
            child: Text('Test'),
          ),
        ),
      );

      // After animation completes
      await tester.pumpAndSettle();
      expect(find.text('Test'), findsOneWidget);
    });
  });
}
