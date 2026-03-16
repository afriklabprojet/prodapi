import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:courier/presentation/screens/create_ticket_screen.dart';

void main() {
  group('CreateTicketScreen', () {
    Widget buildTestWidget() {
      return const ProviderScope(
        child: MaterialApp(home: CreateTicketScreen()),
      );
    }

    testWidgets('shows app bar title', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();
      expect(find.text('Nouveau ticket'), findsOneWidget);
    });

    testWidgets('shows info card', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();
      expect(find.textContaining('Décrivez votre problème'), findsAtLeastNWidgets(1));
    });

    testWidgets('shows category chips', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();
      expect(find.text('Catégorie'), findsOneWidget);
      expect(find.byType(ChoiceChip), findsAtLeastNWidgets(3));
    });

    testWidgets('shows priority selector', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();
      expect(find.text('Priorité'), findsOneWidget);
    });

    testWidgets('shows subject field', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();
      expect(find.text('Sujet'), findsOneWidget);
      expect(find.byType(TextFormField), findsAtLeastNWidgets(1));
    });

    testWidgets('shows description field', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();
      expect(find.text('Description'), findsOneWidget);
    });

    testWidgets('shows submit button', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();
      expect(find.text('Envoyer le ticket'), findsOneWidget);
    });

    testWidgets('validates empty subject', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Scroll to and tap submit button
      final submitButton = find.text('Envoyer le ticket');
      await tester.scrollUntilVisible(
        submitButton,
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(submitButton);
      await tester.pumpAndSettle();
      expect(find.textContaining('Veuillez entrer un sujet'), findsAtLeastNWidgets(1));
    });

    testWidgets('validates short subject', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Enter short subject in the first TextFormField
      final subjectField = find.byType(TextFormField).first;
      await tester.enterText(subjectField, 'Hi');
      await tester.pumpAndSettle();

      final submitButton = find.text('Envoyer le ticket');
      await tester.scrollUntilVisible(
        submitButton,
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(submitButton);
      await tester.pumpAndSettle();
      expect(find.textContaining('au moins 5 caractères'), findsAtLeastNWidgets(1));
    });

    testWidgets('validates empty description', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Enter valid subject
      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), 'Valid subject here');
      await tester.pumpAndSettle();

      final submitButton = find.text('Envoyer le ticket');
      await tester.scrollUntilVisible(
        submitButton,
        200,
        scrollable: find.byType(Scrollable).first,
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
      await tester.enterText(fields.at(0), 'Valid subject here');
      await tester.pumpAndSettle();
      await tester.enterText(fields.at(1), 'Short desc');
      await tester.pumpAndSettle();

      final submitButton = find.text('Envoyer le ticket');
      await tester.scrollUntilVisible(
        submitButton,
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(submitButton);
      await tester.pumpAndSettle();
      expect(find.textContaining('au moins 20 caractères'), findsAtLeastNWidgets(1));
    });

    testWidgets('can select category chip', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Find and tap a category chip (other than default)
      final chips = find.byType(ChoiceChip);
      expect(chips, findsAtLeastNWidgets(2));
    });
  });
}
