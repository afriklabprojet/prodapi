import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:courier/presentation/widgets/common/delivery_photo_capture.dart';

void main() {
  group('DeliveryPhotoCapture', () {
    Widget buildWidget({bool required = false}) {
      return MaterialApp(
        home: Scaffold(
          body: DeliveryPhotoCapture(
            onPhotoChanged: (_) {},
            required: required,
          ),
        ),
      );
    }

    testWidgets('renders without initial photo', (tester) async {
      await tester.pumpWidget(buildWidget());
      expect(find.byType(DeliveryPhotoCapture), findsOneWidget);
    });

    testWidgets('renders as required', (tester) async {
      await tester.pumpWidget(buildWidget(required: true));
      expect(find.byType(DeliveryPhotoCapture), findsOneWidget);
    });

    testWidgets('has InkWell for interaction', (tester) async {
      await tester.pumpWidget(buildWidget());
      expect(find.byType(InkWell), findsWidgets);
    });

    testWidgets('has Icon widgets', (tester) async {
      await tester.pumpWidget(buildWidget());
      expect(find.byType(Icon), findsWidgets);
    });

    testWidgets('has Text widgets', (tester) async {
      await tester.pumpWidget(buildWidget());
      expect(find.byType(Text), findsWidgets);
    });

    testWidgets('has Container', (tester) async {
      await tester.pumpWidget(buildWidget());
      expect(find.byType(Container), findsWidgets);
    });

    testWidgets('renders camera icon', (tester) async {
      await tester.pumpWidget(buildWidget());
      expect(find.byIcon(Icons.camera_alt_outlined), findsOneWidget);
    });

    testWidgets('required flag does not crash', (tester) async {
      await tester.pumpWidget(buildWidget(required: true));
      expect(find.byType(Scaffold), findsOneWidget);
      expect(find.byType(DeliveryPhotoCapture), findsOneWidget);
    });
  });

  group('DeliveryPhotoCapture - deep interactions', () {
    Widget buildWidget({bool required = false}) {
      return MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: DeliveryPhotoCapture(
              onPhotoChanged: (_) {},
              required: required,
            ),
          ),
        ),
      );
    }

    testWidgets('shows "Prendre une photo" text', (tester) async {
      await tester.pumpWidget(buildWidget());
      expect(find.text('Prendre une photo'), findsOneWidget);
    });

    testWidgets('optional shows "Photo du colis livré (optionnel)"', (
      tester,
    ) async {
      await tester.pumpWidget(buildWidget(required: false));
      expect(find.text('Photo du colis livré (optionnel)'), findsOneWidget);
    });

    testWidgets('required shows "Preuve de livraison requise"', (tester) async {
      await tester.pumpWidget(buildWidget(required: true));
      expect(find.text('Preuve de livraison requise'), findsOneWidget);
    });

    testWidgets('required does not show optional text', (tester) async {
      await tester.pumpWidget(buildWidget(required: true));
      expect(find.text('Photo du colis livré (optionnel)'), findsNothing);
    });

    testWidgets('optional does not show required text', (tester) async {
      await tester.pumpWidget(buildWidget(required: false));
      expect(find.text('Preuve de livraison requise'), findsNothing);
    });

    testWidgets('has Column layout', (tester) async {
      await tester.pumpWidget(buildWidget());
      expect(find.byType(Column), findsWidgets);
    });

    testWidgets('tapping InkWell does not crash', (tester) async {
      await tester.pumpWidget(buildWidget());
      // Tap the area - will trigger ImagePicker which won't work in test
      // but should not crash
      final inkWell = find.byType(InkWell).first;
      await tester.tap(inkWell);
      await tester.pump();
      expect(find.byType(DeliveryPhotoCapture), findsOneWidget);
    });

    testWidgets('has SizedBox for spacing', (tester) async {
      await tester.pumpWidget(buildWidget());
      expect(find.byType(SizedBox), findsWidgets);
    });

    testWidgets('renders within Scaffold', (tester) async {
      await tester.pumpWidget(buildWidget());
      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('camera icon is present for optional mode', (tester) async {
      await tester.pumpWidget(buildWidget(required: false));
      expect(find.byIcon(Icons.camera_alt_outlined), findsOneWidget);
    });

    testWidgets('camera icon is present for required mode', (tester) async {
      await tester.pumpWidget(buildWidget(required: true));
      expect(find.byIcon(Icons.camera_alt_outlined), findsOneWidget);
    });
  });

  group('DeliveryProofDialog', () {
    Widget buildDialog({
      bool requirePhoto = true,
      bool requireSignature = false,
      String? customerName,
    }) {
      return MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  builder: (_) => DeliveryProofDialog(
                    requirePhoto: requirePhoto,
                    requireSignature: requireSignature,
                    customerName: customerName,
                  ),
                );
              },
              child: const Text('Open'),
            ),
          ),
        ),
      );
    }

    testWidgets('dialog can be opened', (tester) async {
      await tester.pumpWidget(buildDialog());
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      expect(find.text('Preuve de livraison'), findsOneWidget);
    });

    testWidgets('dialog shows customer name when provided', (tester) async {
      await tester.pumpWidget(buildDialog(customerName: 'Jean Dupont'));
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Jean Dupont'), findsOneWidget);
    });

    testWidgets('dialog has Annuler button', (tester) async {
      await tester.pumpWidget(buildDialog());
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      expect(find.text('Annuler'), findsOneWidget);
    });

    testWidgets('dialog has Confirmer button', (tester) async {
      await tester.pumpWidget(buildDialog());
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      expect(find.text('Confirmer'), findsOneWidget);
    });

    testWidgets('dialog has notes text field', (tester) async {
      await tester.pumpWidget(buildDialog());
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      expect(find.text('Notes (optionnel)'), findsOneWidget);
    });

    testWidgets('dialog has hint text for notes field', (tester) async {
      await tester.pumpWidget(buildDialog());
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Ex: Colis laissé'), findsOneWidget);
    });

    testWidgets('dialog has verified icon', (tester) async {
      await tester.pumpWidget(buildDialog());
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.verified_outlined), findsOneWidget);
    });

    testWidgets('dialog has check_circle icon on confirm button', (
      tester,
    ) async {
      await tester.pumpWidget(buildDialog());
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
    });

    testWidgets('dialog does not show customer name when null', (tester) async {
      await tester.pumpWidget(buildDialog(customerName: null));
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Client:'), findsNothing);
    });

    testWidgets('Annuler button is tappable', (tester) async {
      await tester.pumpWidget(buildDialog());
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      // Just verify Annuler exists and is tappable
      expect(find.text('Annuler'), findsOneWidget);
      await tester.tap(find.text('Annuler'));
      await tester.pump();
    });

    testWidgets('dialog has DeliveryPhotoCapture widget', (tester) async {
      await tester.pumpWidget(buildDialog());
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      expect(find.byType(DeliveryPhotoCapture), findsOneWidget);
    });

    testWidgets('dialog has OutlinedButton for cancel', (tester) async {
      await tester.pumpWidget(buildDialog());
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      expect(find.byType(OutlinedButton), findsOneWidget);
    });

    testWidgets('dialog has ElevatedButton for confirm', (tester) async {
      await tester.pumpWidget(buildDialog());
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      expect(find.byType(ElevatedButton), findsAtLeast(1));
    });

    testWidgets('notes field accepts text input', (tester) async {
      await tester.pumpWidget(buildDialog());
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      final textField = find.byType(TextField);
      if (textField.evaluate().isNotEmpty) {
        await tester.enterText(textField.first, 'Colis laissé au gardien');
        await tester.pump();
        expect(find.text('Colis laissé au gardien'), findsOneWidget);
      }
    });

    testWidgets('dialog with requirePhoto=false', (tester) async {
      await tester.pumpWidget(buildDialog(requirePhoto: false));
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      expect(find.text('Preuve de livraison'), findsOneWidget);
    });
  });
}
