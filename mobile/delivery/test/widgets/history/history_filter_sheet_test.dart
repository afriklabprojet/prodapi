import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:courier/presentation/widgets/history/history_filter_sheet.dart';
import '../../helpers/widget_test_helpers.dart';

void main() {
  Widget buildWidget() {
    return ProviderScope(
      overrides: commonWidgetTestOverrides(),
      child: const MaterialApp(home: Scaffold(body: HistoryFilterSheet())),
    );
  }

  group('HistoryFilterSheet', () {
    testWidgets('renders filter sheet', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(HistoryFilterSheet), findsOneWidget);
    });

    testWidgets('contains Text widgets', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(Text), findsWidgets);
    });

    testWidgets('contains Column widgets', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(Column), findsWidgets);
    });

    testWidgets('contains Container widgets', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(Container), findsWidgets);
    });

    testWidgets('contains Icon widgets', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(Icon), findsWidgets);
    });

    testWidgets('contains SizedBox widgets', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(SizedBox), findsWidgets);
    });

    testWidgets('contains Padding widgets', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(Padding), findsWidgets);
    });

    // ── Content assertions ──

    testWidgets('shows "Filtres" header title', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('Filtres'), findsOneWidget);
    });

    testWidgets('shows "Réinitialiser" reset button', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('Réinitialiser'), findsOneWidget);
    });

    testWidgets('shows "Période rapide" section title', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('Période rapide'), findsOneWidget);
    });

    testWidgets('shows "Statut" section title', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('Statut'), findsOneWidget);
    });

    testWidgets('shows "Pharmacie" section title', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('Pharmacie'), findsOneWidget);
    });

    testWidgets('shows "Tri" section title', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('Tri'), findsOneWidget);
    });

    testWidgets('shows "Aujourd\'hui" period chip', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('Aujourd\'hui'), findsOneWidget);
    });

    testWidgets('shows "Cette semaine" period chip', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('Cette semaine'), findsOneWidget);
    });

    testWidgets('shows "Ce mois" period chip', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('Ce mois'), findsOneWidget);
    });

    testWidgets('shows status chips "Tous"', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('Tous'), findsOneWidget);
    });

    testWidgets('shows status chip "Livrées"', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('Livrées'), findsOneWidget);
    });

    testWidgets('shows status chip "Annulées"', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('Annulées'), findsOneWidget);
    });

    testWidgets('shows "Annuler" cancel button', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('Annuler'), findsOneWidget);
    });

    testWidgets('shows "Appliquer" apply button', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('Appliquer'), findsOneWidget);
    });
  });
}
