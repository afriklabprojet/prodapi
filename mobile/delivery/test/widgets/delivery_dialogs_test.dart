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
                  onPressed: () => DeliveryDialogs.showConfirmation(context, ref, 1),
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
                  onPressed: () => DeliveryDialogs.showConfirmation(context, ref, 1),
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

      expect(find.text('Demandez le code au client pour valider la livraison.'), findsOneWidget);
    });

    testWidgets('displays OTP text field', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Builder(
              builder: (context) => Consumer(
                builder: (context, ref, _) => ElevatedButton(
                  onPressed: () => DeliveryDialogs.showConfirmation(context, ref, 1),
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
                  onPressed: () => DeliveryDialogs.showConfirmation(context, ref, 1),
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
                  onPressed: () => DeliveryDialogs.showConfirmation(context, ref, 1),
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

      expect(find.text('Commission: -200 FCFA'), findsOneWidget);
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

      expect(find.textContaining('Excellent travail'), findsOneWidget);
    });
  });
}
