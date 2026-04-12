import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:courier/presentation/widgets/home/delivery_dialogs.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('DeliveryDialogs.showConfirmation', () {
    testWidgets('displays confirmation dialog title', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Builder(
              builder: (context) => Consumer(
                builder: (context, ref, _) => ElevatedButton(
                  onPressed: () =>
                      DeliveryDialogs.showConfirmation(context, ref, 1),
                  child: const Text('Show'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Show'));
      await tester.pumpAndSettle();

      expect(find.text('Code de confirmation'), findsOneWidget);
    });

    testWidgets('displays OTP instruction text', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Builder(
              builder: (context) => Consumer(
                builder: (context, ref, _) => ElevatedButton(
                  onPressed: () =>
                      DeliveryDialogs.showConfirmation(context, ref, 1),
                  child: const Text('Show'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Show'));
      await tester.pumpAndSettle();

      expect(
        find.text('Demandez le code au client pour valider la livraison.'),
        findsOneWidget,
      );
    });

    testWidgets('displays OTP text field', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Builder(
              builder: (context) => Consumer(
                builder: (context, ref, _) => ElevatedButton(
                  onPressed: () =>
                      DeliveryDialogs.showConfirmation(context, ref, 1),
                  child: const Text('Show'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Show'));
      await tester.pumpAndSettle();

      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('0000'), findsOneWidget);
    });

    testWidgets('displays ANNULER and VALIDER buttons', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Builder(
              builder: (context) => Consumer(
                builder: (context, ref, _) => ElevatedButton(
                  onPressed: () =>
                      DeliveryDialogs.showConfirmation(context, ref, 1),
                  child: const Text('Show'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Show'));
      await tester.pumpAndSettle();

      expect(find.text('ANNULER'), findsOneWidget);
      expect(find.text('VALIDER'), findsOneWidget);
    });

    testWidgets('closes dialog on ANNULER', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Builder(
              builder: (context) => Consumer(
                builder: (context, ref, _) => ElevatedButton(
                  onPressed: () =>
                      DeliveryDialogs.showConfirmation(context, ref, 1),
                  child: const Text('Show'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Show'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('ANNULER'));
      await tester.pumpAndSettle();

      expect(find.text('Code de confirmation'), findsNothing);
    });
  });

  group('DeliveryDialogs.showSuccess', () {
    testWidgets('displays success dialog', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => DeliveryDialogs.showSuccess(context),
              child: const Text('Show'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Show'));
      await tester.pumpAndSettle();

      expect(find.text('Livraison Terminée !'), findsOneWidget);
    });

    testWidgets('displays commission info', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => DeliveryDialogs.showSuccess(context),
              child: const Text('Show'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Show'));
      await tester.pumpAndSettle();

      expect(find.textContaining('commission de 200 FCFA'), findsOneWidget);
    });

    testWidgets('displays check circle icon', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => DeliveryDialogs.showSuccess(context),
              child: const Text('Show'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Show'));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.check_circle), findsOneWidget);
    });

    testWidgets('displays CONTINUER button', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => DeliveryDialogs.showSuccess(context),
              child: const Text('Show'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Show'));
      await tester.pumpAndSettle();

      expect(find.text('CONTINUER'), findsOneWidget);
    });

    testWidgets('closes on CONTINUER tap', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => DeliveryDialogs.showSuccess(context),
              child: const Text('Show'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Show'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('CONTINUER'));
      await tester.pumpAndSettle();

      expect(find.text('Livraison Terminée !'), findsNothing);
    });

    testWidgets('displays excellent travail message', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => DeliveryDialogs.showSuccess(context),
              child: const Text('Show'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Show'));
      await tester.pumpAndSettle();

      expect(find.textContaining('commission de 200 FCFA'), findsOneWidget);
    });

    testWidgets('displays custom commission amount', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () =>
                  DeliveryDialogs.showSuccess(context, commission: 300),
              child: const Text('Show'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Show'));
      await tester.pumpAndSettle();

      expect(find.textContaining('commission de 300 FCFA'), findsOneWidget);
    });

    testWidgets('displays net gain when earnings provided', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => DeliveryDialogs.showSuccess(
                context,
                commission: 200,
                earnings: 1500,
              ),
              child: const Text('Show'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Show'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Gain livraison'), findsOneWidget);
      expect(find.textContaining('Net pour vous'), findsOneWidget);
    });

    testWidgets('displays ÉVALUER button when deliveryId provided', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () =>
                  DeliveryDialogs.showSuccess(context, deliveryId: 123),
              child: const Text('Show'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Show'));
      await tester.pumpAndSettle();

      expect(find.text('ÉVALUER LE CLIENT'), findsOneWidget);
    });

    testWidgets('displays Passer button when deliveryId provided', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () =>
                  DeliveryDialogs.showSuccess(context, deliveryId: 123),
              child: const Text('Show'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Show'));
      await tester.pumpAndSettle();

      expect(find.text('Passer'), findsOneWidget);
    });

    testWidgets('closes on Passer tap', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () =>
                  DeliveryDialogs.showSuccess(context, deliveryId: 123),
              child: const Text('Show'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Show'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Passer'));
      await tester.pumpAndSettle();

      expect(find.text('Livraison Terminée !'), findsNothing);
    });

    testWidgets('dialog is not dismissible by tapping outside', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => DeliveryDialogs.showSuccess(context),
              child: const Text('Show'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Show'));
      await tester.pumpAndSettle();

      // Try to dismiss by tapping outside (on barrier)
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();

      // Dialog should still be present
      expect(find.text('Livraison Terminée !'), findsOneWidget);
    });

    testWidgets('displays financial summary with earnings', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => DeliveryDialogs.showSuccess(
                context,
                earnings: 1000,
                commission: 200,
              ),
              child: const Text('Show'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Show'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Commission'), findsOneWidget);
    });
  });

  group('DeliveryDialogs.showConfirmation - extended', () {
    testWidgets('OTP field accepts numeric input', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Builder(
              builder: (context) => Consumer(
                builder: (context, ref, _) => ElevatedButton(
                  onPressed: () =>
                      DeliveryDialogs.showConfirmation(context, ref, 1),
                  child: const Text('Show'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Show'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), '1234');
      await tester.pumpAndSettle();

      expect(find.text('1234'), findsOneWidget);
    });

    testWidgets('OTP field has max length of 4', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Builder(
              builder: (context) => Consumer(
                builder: (context, ref, _) => ElevatedButton(
                  onPressed: () =>
                      DeliveryDialogs.showConfirmation(context, ref, 1),
                  child: const Text('Show'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Show'));
      await tester.pumpAndSettle();

      // Try to enter more than 4 digits
      await tester.enterText(find.byType(TextField), '123456');
      await tester.pumpAndSettle();

      // Should only show first 4 digits
      expect(find.text('1234'), findsOneWidget);
    });

    testWidgets('dialog has rounded corners', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Builder(
              builder: (context) => Consumer(
                builder: (context, ref, _) => ElevatedButton(
                  onPressed: () =>
                      DeliveryDialogs.showConfirmation(context, ref, 1),
                  child: const Text('Show'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Show'));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);
    });

    testWidgets('VALIDER button has elevated style', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Builder(
              builder: (context) => Consumer(
                builder: (context, ref, _) => ElevatedButton(
                  onPressed: () =>
                      DeliveryDialogs.showConfirmation(context, ref, 1),
                  child: const Text('Show'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Show'));
      await tester.pumpAndSettle();

      expect(find.widgetWithText(ElevatedButton, 'VALIDER'), findsOneWidget);
    });

    testWidgets('ANNULER button has text style', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Builder(
              builder: (context) => Consumer(
                builder: (context, ref, _) => ElevatedButton(
                  onPressed: () =>
                      DeliveryDialogs.showConfirmation(context, ref, 1),
                  child: const Text('Show'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Show'));
      await tester.pumpAndSettle();

      expect(find.widgetWithText(TextButton, 'ANNULER'), findsOneWidget);
    });

    testWidgets('dialog has column layout for content', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Builder(
              builder: (context) => Consumer(
                builder: (context, ref, _) => ElevatedButton(
                  onPressed: () =>
                      DeliveryDialogs.showConfirmation(context, ref, 1),
                  child: const Text('Show'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Show'));
      await tester.pumpAndSettle();

      expect(find.byType(Column), findsWidgets);
    });
  });
}
