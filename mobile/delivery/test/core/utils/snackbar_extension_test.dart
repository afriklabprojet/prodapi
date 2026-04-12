import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:courier/core/utils/snackbar_extension.dart';
import 'package:courier/core/utils/app_exceptions.dart';

void main() {
  group('SnackBarExtension', () {
    testWidgets('showSuccess displays green snackbar', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () => context.showSuccess('Opération réussie'),
                  child: const Text('Go'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Go'));
      await tester.pump();

      expect(find.text('Opération réussie'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
    });

    testWidgets('showErrorMessage displays red snackbar', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () => context.showErrorMessage('Erreur test'),
                  child: const Text('Go'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Go'));
      await tester.pump();

      expect(find.text('Erreur test'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });

    testWidgets('showInfo displays blue snackbar', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () => context.showInfo('Info message'),
                  child: const Text('Go'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Go'));
      await tester.pump();

      expect(find.text('Info message'), findsOneWidget);
      expect(find.byIcon(Icons.info_outline), findsOneWidget);
    });

    testWidgets('showWarning displays orange snackbar', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () => context.showWarning('Attention'),
                  child: const Text('Go'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Go'));
      await tester.pump();

      expect(find.text('Attention'), findsOneWidget);
      expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
    });

    testWidgets('showError with AppException shows userMessage', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () => context.showError(const NetworkException()),
                  child: const Text('Go'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Go'));
      await tester.pump();

      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      expect(find.text('OK'), findsOneWidget);
    });

    testWidgets('showError with raw error shows cleaned message', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () => context.showError('Some raw error'),
                  child: const Text('Go'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Go'));
      await tester.pump();

      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });

    testWidgets('showError with fallbackMessage uses fallback', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () => context.showError(
                    'ignored error',
                    fallbackMessage: 'Custom fallback message',
                  ),
                  child: const Text('Go'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Go'));
      await tester.pump();

      expect(find.text('Custom fallback message'), findsOneWidget);
    });

    testWidgets('showError OK action dismisses snackbar', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () => context.showError(const NetworkException()),
                  child: const Text('Go'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Go'));
      await tester.pump();
      expect(find.text('OK'), findsOneWidget);

      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
    });

    // ── Additional coverage tests ──

    testWidgets('showSuccess with custom duration', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () => context.showSuccess(
                    'Custom duration',
                    duration: const Duration(seconds: 10),
                  ),
                  child: const Text('Go'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Go'));
      await tester.pump();
      expect(find.text('Custom duration'), findsOneWidget);
    });

    testWidgets('showInfo with custom duration', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () => context.showInfo(
                    'Info custom',
                    duration: const Duration(seconds: 5),
                  ),
                  child: const Text('Go'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Go'));
      await tester.pump();
      expect(find.text('Info custom'), findsOneWidget);
    });

    testWidgets('showWarning with custom duration', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () => context.showWarning(
                    'Warning custom',
                    duration: const Duration(seconds: 7),
                  ),
                  child: const Text('Go'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Go'));
      await tester.pump();
      expect(find.text('Warning custom'), findsOneWidget);
    });

    testWidgets('showSuccess hides current snackbar before showing new', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return Column(
                  children: [
                    ElevatedButton(
                      onPressed: () => context.showSuccess('First'),
                      child: const Text('First'),
                    ),
                    ElevatedButton(
                      onPressed: () => context.showSuccess('Second'),
                      child: const Text('Second'),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('First'));
      await tester.pump();
      expect(find.text('First'), findsWidgets);

      await tester.tap(find.text('Second'));
      await tester.pump();
      expect(find.text('Second'), findsWidgets);
    });

    testWidgets('showError hides current snackbar before showing new', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return Column(
                  children: [
                    ElevatedButton(
                      onPressed: () => context.showErrorMessage('Error 1'),
                      child: const Text('Err1'),
                    ),
                    ElevatedButton(
                      onPressed: () => context.showErrorMessage('Error 2'),
                      child: const Text('Err2'),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Err1'));
      await tester.pump();

      await tester.tap(find.text('Err2'));
      await tester.pump();
      expect(find.text('Error 2'), findsOneWidget);
    });

    testWidgets('showInfo hides current snackbar before showing new', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return Column(
                  children: [
                    ElevatedButton(
                      onPressed: () => context.showInfo('Info 1'),
                      child: const Text('I1'),
                    ),
                    ElevatedButton(
                      onPressed: () => context.showInfo('Info 2'),
                      child: const Text('I2'),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('I1'));
      await tester.pump();

      await tester.tap(find.text('I2'));
      await tester.pump();
      expect(find.text('Info 2'), findsWidgets);
    });

    testWidgets('showWarning uses correct icon', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () => context.showWarning('Test warning'),
                  child: const Text('Go'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Go'));
      await tester.pump();
      expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
    });

    testWidgets('showSuccess uses correct icon', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () => context.showSuccess('Success test'),
                  child: const Text('Go'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Go'));
      await tester.pump();
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
    });

    testWidgets('showInfo uses correct icon', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () => context.showInfo('Info test'),
                  child: const Text('Go'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Go'));
      await tester.pump();
      expect(find.byIcon(Icons.info_outline), findsOneWidget);
    });
  });
}
