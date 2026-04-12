import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:courier/presentation/widgets/common/signature_pad.dart';

void main() {
  group('SignaturePad', () {
    testWidgets('renders placeholder text when empty', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: SignaturePad())),
      );
      expect(find.text('Signez ici'), findsOneWidget);
      expect(find.byIcon(Icons.draw_outlined), findsOneWidget);
    });

    testWidgets('renders with custom dimensions', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SignaturePad(
              width: 300,
              height: 150,
              penColor: Colors.blue,
              penWidth: 2.0,
            ),
          ),
        ),
      );
      expect(find.byType(SignaturePad), findsOneWidget);
    });

    testWidgets('isEmpty true initially, clear keeps it true', (tester) async {
      final key = GlobalKey<SignaturePadState>();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: SignaturePad(key: key, height: 200)),
        ),
      );
      expect(key.currentState!.isEmpty, isTrue);
      expect(key.currentState!.points, isEmpty);

      // Clear on empty pad should remain empty
      key.currentState!.clear();
      await tester.pump();
      expect(key.currentState!.isEmpty, isTrue);
    });

    testWidgets('clear button not visible when pad is empty', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: SignaturePad(height: 200))),
      );
      expect(find.byIcon(Icons.clear), findsNothing);
      expect(find.byIcon(Icons.draw_outlined), findsOneWidget);
    });

    testWidgets('clear method on empty pad does not crash', (tester) async {
      final key = GlobalKey<SignaturePadState>();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: SignaturePad(key: key, height: 200)),
        ),
      );

      // Should not throw
      key.currentState!.clear();
      await tester.pump();

      expect(key.currentState!.isEmpty, isTrue);
      expect(key.currentState!.points, isEmpty);
    });

    testWidgets('isEmpty is true initially via GlobalKey', (tester) async {
      final key = GlobalKey<SignaturePadState>();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: SignaturePad(key: key, width: 300, height: 200)),
        ),
      );
      expect(key.currentState!.isEmpty, isTrue);
    });

    testWidgets('points returns empty unmodifiable list initially', (
      tester,
    ) async {
      final key = GlobalKey<SignaturePadState>();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: SignaturePad(key: key, height: 200)),
        ),
      );

      final points = key.currentState!.points;
      expect(points, isEmpty);
      expect(
        () => (points as List).add(const Offset(0, 0)),
        throwsA(isA<UnsupportedError>()),
      );
    });

    testWidgets('points list is unmodifiable', (tester) async {
      final key = GlobalKey<SignaturePadState>();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: SignaturePad(key: key, height: 200)),
        ),
      );

      final points = key.currentState!.points;
      expect(
        () => (points as List).add(const Offset(0, 0)),
        throwsA(isA<UnsupportedError>()),
      );
    });

    testWidgets('clear on empty pad does not change state', (tester) async {
      final key = GlobalKey<SignaturePadState>();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: SignaturePad(key: key, height: 200)),
        ),
      );

      key.currentState!.clear();
      await tester.pump();

      expect(key.currentState!.isEmpty, isTrue);
      expect(key.currentState!.points, isEmpty);
    });

    testWidgets('onChanged called with null on clear from empty', (
      tester,
    ) async {
      Uint8List? lastValue = Uint8List(1); // non-null sentinel
      final key = GlobalKey<SignaturePadState>();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SignaturePad(
              key: key,
              height: 200,
              onChanged: (bytes) => lastValue = bytes,
            ),
          ),
        ),
      );

      key.currentState!.clear();
      await tester.pump();

      expect(lastValue, isNull);
    });

    testWidgets('toImage returns null when empty', (tester) async {
      final key = GlobalKey<SignaturePadState>();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: SignaturePad(key: key, height: 200)),
        ),
      );

      final image = await key.currentState!.toImage();
      expect(image, isNull);
    });

    testWidgets('backgroundColor is applied', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SignaturePad(
              width: 300,
              height: 200,
              backgroundColor: Colors.yellow,
            ),
          ),
        ),
      );
      // Find the Container that has the yellow background
      final container = tester.widget<Container>(
        find.descendant(
          of: find.byType(SignaturePad),
          matching: find.byType(Container).first,
        ),
      );
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.color, Colors.yellow);
    });
  });

  group('SignatureDialog', () {
    testWidgets('renders title and subtitle', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (_) => const SignatureDialog(
                    title: 'Sign here',
                    subtitle: 'Please sign below',
                  ),
                );
              },
              child: const Text('Open'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('Sign here'), findsOneWidget);
      expect(find.text('Please sign below'), findsOneWidget);
    });

    testWidgets('renders default title', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (_) => const SignatureDialog(),
                );
              },
              child: const Text('Open'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('Signature du client'), findsOneWidget);
    });

    testWidgets('Annuler button closes dialog', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (_) => const SignatureDialog(),
                );
              },
              child: const Text('Open'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('Annuler'), findsOneWidget);
      await tester.tap(find.text('Annuler'));
      await tester.pumpAndSettle();

      expect(find.text('Signature du client'), findsNothing);
    });

    testWidgets('Effacer button is rendered', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (_) => const SignatureDialog(),
                );
              },
              child: const Text('Open'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('Effacer'), findsOneWidget);
    });

    testWidgets('Valider button is disabled initially', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (_) => const SignatureDialog(),
                );
              },
              child: const Text('Open'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      final validerButton = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Valider'),
      );
      expect(validerButton.onPressed, isNull);
    });

    testWidgets('shows info text about signing', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (_) => const SignatureDialog(),
                );
              },
              child: const Text('Open'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(
        find.text('Demandez au client de signer avec le doigt'),
        findsOneWidget,
      );
    });

    testWidgets('no subtitle renders without subtitle text', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (_) => const SignatureDialog(title: 'No sub'),
                );
              },
              child: const Text('Open'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('No sub'), findsOneWidget);
    });
  });
}
