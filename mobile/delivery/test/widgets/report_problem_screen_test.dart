import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:courier/presentation/screens/create_ticket_screen.dart';
import '../helpers/widget_test_helpers.dart';

void main() {
  setUpAll(() async {
    await initHiveForTests();
  });

  tearDownAll(() async {
    await cleanupHiveForTests();
  });

  group('CreateTicketScreen', () {
    Widget buildTestWidget() {
      return ProviderScope(
        overrides: commonWidgetTestOverrides(),
        child: const MaterialApp(home: CreateTicketScreen()),
      );
    }

    testWidgets('shows app bar title', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();
      expect(find.text('Nouveau ticket'), findsOneWidget);
    });

    testWidgets('shows category section', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();
      expect(find.text('Catégorie'), findsOneWidget);
    });

    testWidgets('shows priority section', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();
      expect(find.text('Priorité'), findsOneWidget);
    });

    testWidgets('shows subject and description fields', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();
      expect(find.text('Sujet'), findsOneWidget);
      expect(find.text('Description'), findsOneWidget);
    });

    testWidgets('shows submit button', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();
      final scrollable = find.byType(Scrollable).first;
      await tester.scrollUntilVisible(
        find.text('Envoyer le ticket'),
        200,
        scrollable: scrollable,
      );
      expect(find.text('Envoyer le ticket'), findsOneWidget);
    });

    testWidgets('validates empty subject', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      final submitButton = find.text('Envoyer le ticket');
      final scrollable = find.byType(Scrollable).first;
      await tester.scrollUntilVisible(
        submitButton,
        200,
        scrollable: scrollable,
      );
      await tester.pumpAndSettle();
      await tester.tap(submitButton);
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Veuillez entrer un sujet'),
        findsAtLeastNWidgets(1),
      );
    });

    testWidgets('validates short subject', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      final fields = find.byType(TextFormField);
      await tester.enterText(fields.first, 'Hi');
      await tester.pumpAndSettle();

      final submitButton = find.text('Envoyer le ticket');
      final scrollable = find.byType(Scrollable).first;
      await tester.scrollUntilVisible(
        submitButton,
        200,
        scrollable: scrollable,
      );
      await tester.pumpAndSettle();
      await tester.tap(submitButton);
      await tester.pumpAndSettle();
      expect(
        find.textContaining('au moins 5 caractères'),
        findsAtLeastNWidgets(1),
      );
    });

    testWidgets('validates empty description', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), 'Valid subject text here');
      await tester.pumpAndSettle();

      final submitButton = find.text('Envoyer le ticket');
      final scrollable = find.byType(Scrollable).first;
      await tester.scrollUntilVisible(
        submitButton,
        200,
        scrollable: scrollable,
      );
      await tester.pumpAndSettle();
      await tester.tap(submitButton);
      await tester.pumpAndSettle();
      expect(find.textContaining('Veuillez décrire'), findsAtLeastNWidgets(1));
    });

    testWidgets('validates short description', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), 'Valid subject text here');
      await tester.pumpAndSettle();
      await tester.enterText(fields.at(1), 'Short');
      await tester.pumpAndSettle();

      final submitButton = find.text('Envoyer le ticket');
      final scrollable = find.byType(Scrollable).first;
      await tester.scrollUntilVisible(
        submitButton,
        200,
        scrollable: scrollable,
      );
      await tester.pumpAndSettle();
      await tester.tap(submitButton);
      await tester.pumpAndSettle();
      expect(
        find.textContaining('au moins 20 caractères'),
        findsAtLeastNWidgets(1),
      );
    });

    testWidgets('shows info message', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Décrivez votre problème en détail'),
        findsAtLeastNWidgets(1),
      );
    });

    testWidgets('shows send icon in button', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();
      final scrollable = find.byType(Scrollable).first;
      await tester.scrollUntilVisible(
        find.byIcon(Icons.send),
        200,
        scrollable: scrollable,
      );
      expect(find.byIcon(Icons.send), findsOneWidget);
    });
  });
}
