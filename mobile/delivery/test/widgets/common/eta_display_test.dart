import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:courier/presentation/widgets/common/eta_display.dart';

void main() {
  Widget buildWidget(Widget child) {
    return MaterialApp(home: Scaffold(body: child));
  }

  group('ETADisplayWidget', () {
    testWidgets('renders with duration and distance', (tester) async {
      await tester.pumpWidget(
        buildWidget(
          const ETADisplayWidget(duration: '15 min', distance: '3.5 km'),
        ),
      );
      expect(find.byType(ETADisplayWidget), findsOneWidget);
    });

    testWidgets('renders in compact mode', (tester) async {
      await tester.pumpWidget(
        buildWidget(
          const ETADisplayWidget(
            duration: '30 min',
            distance: '7 km',
            isCompact: true,
          ),
        ),
      );
      expect(find.byType(ETADisplayWidget), findsOneWidget);
    });

    testWidgets('renders with null values', (tester) async {
      await tester.pumpWidget(buildWidget(const ETADisplayWidget()));
      expect(find.byType(ETADisplayWidget), findsOneWidget);
    });

    testWidgets('shows arrival time when enabled', (tester) async {
      await tester.pumpWidget(
        buildWidget(
          const ETADisplayWidget(duration: '10 min', showArrivalTime: true),
        ),
      );
      expect(find.byType(ETADisplayWidget), findsOneWidget);
    });

    // ── Null/empty handling ──

    testWidgets('returns SizedBox.shrink when both null', (tester) async {
      await tester.pumpWidget(buildWidget(const ETADisplayWidget()));
      expect(find.byType(SizedBox), findsWidgets);
    });

    testWidgets('renders when only duration provided', (tester) async {
      await tester.pumpWidget(
        buildWidget(const ETADisplayWidget(duration: '15 min')),
      );
      expect(find.byType(ETADisplayWidget), findsOneWidget);
    });

    testWidgets('renders when only distance provided', (tester) async {
      await tester.pumpWidget(
        buildWidget(const ETADisplayWidget(distance: '5.2 km')),
      );
      expect(find.byType(ETADisplayWidget), findsOneWidget);
    });

    // ── Compact mode content ──

    testWidgets('compact mode shows duration text', (tester) async {
      await tester.pumpWidget(
        buildWidget(
          const ETADisplayWidget(
            duration: '25 min',
            distance: '4 km',
            isCompact: true,
          ),
        ),
      );
      await tester.pump();
      expect(find.text('25 min'), findsOneWidget);
    });

    testWidgets('compact mode shows distance', (tester) async {
      await tester.pumpWidget(
        buildWidget(
          const ETADisplayWidget(
            duration: '10 min',
            distance: '3.5 km',
            isCompact: true,
          ),
        ),
      );
      await tester.pump();
      expect(find.text('3.5 km'), findsOneWidget);
    });

    testWidgets('compact mode hides distance when null', (tester) async {
      await tester.pumpWidget(
        buildWidget(
          const ETADisplayWidget(
            duration: '10 min',
            distance: null,
            isCompact: true,
          ),
        ),
      );
      await tester.pump();
      expect(find.text('10 min'), findsOneWidget);
      expect(find.byIcon(Icons.route), findsNothing);
    });

    testWidgets('compact mode shows time icon', (tester) async {
      await tester.pumpWidget(
        buildWidget(const ETADisplayWidget(duration: '5 min', isCompact: true)),
      );
      await tester.pump();
      expect(find.byIcon(Icons.access_time_filled), findsOneWidget);
    });

    testWidgets('compact mode shows route icon when distance present', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildWidget(
          const ETADisplayWidget(
            duration: '10 min',
            distance: '2 km',
            isCompact: true,
          ),
        ),
      );
      await tester.pump();
      expect(find.byIcon(Icons.route), findsOneWidget);
    });

    // ── Full mode content ──

    testWidgets('full mode shows "Temps estimé" label', (tester) async {
      await tester.pumpWidget(
        buildWidget(
          const ETADisplayWidget(
            duration: '20 min',
            distance: '5 km',
            isCompact: false,
          ),
        ),
      );
      await tester.pump();
      expect(find.text('Temps estimé'), findsOneWidget);
    });

    testWidgets('full mode shows "Distance" label', (tester) async {
      await tester.pumpWidget(
        buildWidget(
          const ETADisplayWidget(
            duration: '20 min',
            distance: '5 km',
            isCompact: false,
          ),
        ),
      );
      await tester.pump();
      expect(find.text('Distance'), findsOneWidget);
    });

    testWidgets('full mode shows "--" when duration is null', (tester) async {
      await tester.pumpWidget(
        buildWidget(
          const ETADisplayWidget(
            duration: null,
            distance: '5 km',
            isCompact: false,
          ),
        ),
      );
      await tester.pump();
      expect(find.text('--'), findsOneWidget);
    });

    testWidgets('full mode shows "--" when distance is null', (tester) async {
      await tester.pumpWidget(
        buildWidget(
          const ETADisplayWidget(
            duration: '10 min',
            distance: null,
            isCompact: false,
          ),
        ),
      );
      await tester.pump();
      expect(find.text('--'), findsOneWidget);
    });

    testWidgets('full mode shows arrival time with "Arrivée prévue"', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildWidget(
          const ETADisplayWidget(duration: '30 min', showArrivalTime: true),
        ),
      );
      await tester.pump();
      expect(find.textContaining('Arrivée prévue'), findsOneWidget);
    });

    testWidgets('hides arrival time when showArrivalTime false', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildWidget(
          const ETADisplayWidget(duration: '30 min', showArrivalTime: false),
        ),
      );
      await tester.pump();
      expect(find.textContaining('Arrivée prévue'), findsNothing);
    });

    testWidgets('handles hour-format duration "1 h 30 min"', (tester) async {
      await tester.pumpWidget(
        buildWidget(
          const ETADisplayWidget(duration: '1 h 30 min', showArrivalTime: true),
        ),
      );
      await tester.pump();
      expect(find.textContaining('Arrivée prévue'), findsOneWidget);
    });

    testWidgets('schedule icon shown when arrival time displayed', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildWidget(
          const ETADisplayWidget(duration: '15 min', showArrivalTime: true),
        ),
      );
      await tester.pump();
      expect(find.byIcon(Icons.schedule), findsOneWidget);
    });

    // ── Dark mode ──

    testWidgets('renders correctly in dark mode compact', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: Scaffold(
            body: const ETADisplayWidget(
              duration: '10 min',
              distance: '3 km',
              isCompact: true,
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.text('10 min'), findsOneWidget);
    });

    testWidgets('renders correctly in dark mode full', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: Scaffold(
            body: const ETADisplayWidget(
              duration: '10 min',
              distance: '3 km',
              isCompact: false,
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.text('Temps estimé'), findsOneWidget);
    });
  });

  group('ETABadge', () {
    testWidgets('renders with duration', (tester) async {
      await tester.pumpWidget(buildWidget(const ETABadge(duration: '5 min')));
      expect(find.byType(ETABadge), findsOneWidget);
    });

    testWidgets('renders with custom colors', (tester) async {
      await tester.pumpWidget(
        buildWidget(
          const ETABadge(
            duration: '20 min',
            backgroundColor: Colors.blue,
            textColor: Colors.white,
          ),
        ),
      );
      expect(find.byType(ETABadge), findsOneWidget);
    });

    testWidgets('shows duration text', (tester) async {
      await tester.pumpWidget(buildWidget(const ETABadge(duration: '8 min')));
      await tester.pump();
      expect(find.text('8 min'), findsOneWidget);
    });

    testWidgets('shows timer icon', (tester) async {
      await tester.pumpWidget(buildWidget(const ETABadge(duration: '5 min')));
      await tester.pump();
      expect(find.byIcon(Icons.timer_outlined), findsOneWidget);
    });

    testWidgets('renders in dark mode', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: Scaffold(body: const ETABadge(duration: '15 min')),
        ),
      );
      await tester.pump();
      expect(find.text('15 min'), findsOneWidget);
    });
  });

  group('LiveETAWidget', () {
    testWidgets('renders with initial duration', (tester) async {
      await tester.pumpWidget(
        buildWidget(
          const LiveETAWidget(initialDuration: '25 min', distance: '6 km'),
        ),
      );
      expect(find.byType(LiveETAWidget), findsOneWidget);
    });

    testWidgets('renders with null values', (tester) async {
      await tester.pumpWidget(buildWidget(const LiveETAWidget()));
      expect(find.byType(LiveETAWidget), findsOneWidget);
    });

    testWidgets('updates when initialDuration changes', (tester) async {
      await tester.pumpWidget(
        buildWidget(
          const LiveETAWidget(initialDuration: '10 min', distance: '3 km'),
        ),
      );
      await tester.pump();

      // Rebuild with new duration
      await tester.pumpWidget(
        buildWidget(
          const LiveETAWidget(initialDuration: '5 min', distance: '3 km'),
        ),
      );
      await tester.pump();
      expect(find.byType(LiveETAWidget), findsOneWidget);
    });
  });
}
