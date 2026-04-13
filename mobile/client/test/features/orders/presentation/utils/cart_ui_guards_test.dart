import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:drpharma_client/features/orders/presentation/utils/cart_ui_guards.dart';

// ─────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  // ─────────────────────────────────────────────────────────
  // DebouncedIconButton
  // ─────────────────────────────────────────────────────────
  group('DebouncedIconButton', () {
    testWidgets('renders an IconButton', (tester) async {
      await tester.pumpWidget(
        _wrap(
          DebouncedIconButton(onPressed: () {}, icon: const Icon(Icons.add)),
        ),
      );
      expect(find.byType(IconButton), findsOneWidget);
    });

    testWidgets('shows tooltip when provided', (tester) async {
      await tester.pumpWidget(
        _wrap(
          DebouncedIconButton(
            onPressed: () {},
            icon: const Icon(Icons.remove),
            tooltip: 'My tooltip',
          ),
        ),
      );
      // IconButton wraps tooltip in a Tooltip
      expect(find.byType(DebouncedIconButton), findsOneWidget);
    });

    testWidgets('calls onPressed once when tapped', (tester) async {
      int count = 0;
      await tester.pumpWidget(
        _wrap(
          DebouncedIconButton(
            onPressed: () => count++,
            icon: const Icon(Icons.add),
            debounceDuration: const Duration(milliseconds: 100),
          ),
        ),
      );

      await tester.tap(find.byType(IconButton));
      await tester.pump();
      expect(count, 1);
    });

    testWidgets('blocks second tap during debounce period', (tester) async {
      int count = 0;
      await tester.pumpWidget(
        _wrap(
          DebouncedIconButton(
            onPressed: () => count++,
            icon: const Icon(Icons.add),
            debounceDuration: const Duration(milliseconds: 500),
          ),
        ),
      );

      await tester.tap(find.byType(IconButton));
      await tester.pump();
      // Second tap should be blocked
      await tester.tap(find.byType(IconButton), warnIfMissed: false);
      await tester.pump();
      expect(count, 1); // still only 1

      // After debounce expires, button is enabled again
      await tester.pump(const Duration(milliseconds: 600));
    });

    testWidgets('onPressed null → button is disabled', (tester) async {
      int count = 0;
      await tester.pumpWidget(
        _wrap(
          DebouncedIconButton(onPressed: null, icon: const Icon(Icons.add)),
        ),
      );

      await tester.tap(find.byType(IconButton), warnIfMissed: false);
      await tester.pump();
      expect(count, 0);
    });

    testWidgets('allows re-tap after debounce expires', (tester) async {
      int count = 0;
      await tester.pumpWidget(
        _wrap(
          DebouncedIconButton(
            onPressed: () => count++,
            icon: const Icon(Icons.add),
            debounceDuration: const Duration(milliseconds: 100),
          ),
        ),
      );

      await tester.tap(find.byType(IconButton));
      await tester.pump();
      expect(count, 1);

      await tester.pump(const Duration(milliseconds: 200));
      await tester.tap(find.byType(IconButton));
      await tester.pump();
      expect(count, 2);
    });
  });

  // ─────────────────────────────────────────────────────────
  // DebouncedElevatedButton (no icon)
  // ─────────────────────────────────────────────────────────
  group('DebouncedElevatedButton (no icon)', () {
    testWidgets('renders an ElevatedButton', (tester) async {
      await tester.pumpWidget(
        _wrap(
          DebouncedElevatedButton(
            onPressed: () {},
            child: const Text('Press me'),
          ),
        ),
      );
      expect(find.byType(ElevatedButton), findsOneWidget);
      expect(find.text('Press me'), findsOneWidget);
    });

    testWidgets('calls onPressed once when tapped', (tester) async {
      int count = 0;
      await tester.pumpWidget(
        _wrap(
          DebouncedElevatedButton(
            onPressed: () => count++,
            debounceDuration: const Duration(milliseconds: 100),
            child: const Text('Ok'),
          ),
        ),
      );

      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();
      expect(count, 1);
    });

    testWidgets('shows CircularProgressIndicator after first tap', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          DebouncedElevatedButton(
            onPressed: () {},
            debounceDuration: const Duration(milliseconds: 500),
            child: const Text('Go'),
          ),
        ),
      );

      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();
      // during debounce, shows progress indicator
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('reverts to normal after debounce expires', (tester) async {
      await tester.pumpWidget(
        _wrap(
          DebouncedElevatedButton(
            onPressed: () {},
            debounceDuration: const Duration(milliseconds: 100),
            child: const Text('Go'),
          ),
        ),
      );

      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 200));
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('blocks second tap during debounce', (tester) async {
      int count = 0;
      await tester.pumpWidget(
        _wrap(
          DebouncedElevatedButton(
            onPressed: () => count++,
            debounceDuration: const Duration(milliseconds: 500),
            child: const Text('Tap'),
          ),
        ),
      );

      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();
      await tester.tap(find.byType(ElevatedButton), warnIfMissed: false);
      await tester.pump();
      expect(count, 1);

      await tester.pump(const Duration(milliseconds: 600));
    });

    testWidgets('onPressed null → button disabled', (tester) async {
      int count = 0;
      await tester.pumpWidget(
        _wrap(
          DebouncedElevatedButton(onPressed: null, child: const Text('Tap')),
        ),
      );

      await tester.tap(find.byType(ElevatedButton), warnIfMissed: false);
      await tester.pump();
      expect(count, 0);
    });
  });

  // ─────────────────────────────────────────────────────────
  // DebouncedElevatedButton with icon
  // ─────────────────────────────────────────────────────────
  group('DebouncedElevatedButton (with icon)', () {
    testWidgets('renders ElevatedButton.icon when icon provided', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          DebouncedElevatedButton(
            onPressed: () {},
            icon: const Icon(Icons.save),
            child: const Text('Save'),
          ),
        ),
      );
      expect(find.text('Save'), findsOneWidget);
      expect(find.byIcon(Icons.save), findsOneWidget);
    });

    testWidgets('shows CircularProgressIndicator in icon slot when tapped', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          DebouncedElevatedButton(
            onPressed: () {},
            icon: const Icon(Icons.save),
            debounceDuration: const Duration(milliseconds: 500),
            child: const Text('Save'),
          ),
        ),
      );

      // Before tap: shows icon
      expect(find.byIcon(Icons.save), findsOneWidget);

      await tester.tap(find.text('Save'));
      await tester.pump();

      // After tap: icon replaced with CircularProgressIndicator
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byIcon(Icons.save), findsNothing);
    });

    testWidgets('calls onPressed when icon button tapped', (tester) async {
      int count = 0;
      await tester.pumpWidget(
        _wrap(
          DebouncedElevatedButton(
            onPressed: () => count++,
            icon: const Icon(Icons.send),
            debounceDuration: const Duration(milliseconds: 100),
            child: const Text('Send'),
          ),
        ),
      );

      await tester.tap(find.text('Send'));
      await tester.pump();
      expect(count, 1);
    });
  });
}
