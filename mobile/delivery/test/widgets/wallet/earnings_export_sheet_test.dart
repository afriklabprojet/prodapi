import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:courier/presentation/widgets/wallet/earnings_export_sheet.dart';
import 'package:courier/data/repositories/delivery_repository.dart';
import 'package:mocktail/mocktail.dart';
import '../../helpers/widget_test_helpers.dart';

class MockDeliveryRepository extends Mock implements DeliveryRepository {}

void main() {
  Widget buildWidget() {
    final mockRepo = MockDeliveryRepository();
    return ProviderScope(
      overrides: [
        ...commonWidgetTestOverrides(),
        deliveryRepositoryProvider.overrideWithValue(mockRepo),
      ],
      child: const MaterialApp(
        home: Scaffold(body: EarningsExportSheet(courierName: 'Jean Dupont')),
      ),
    );
  }

  group('EarningsExportSheet', () {
    testWidgets('renders with courier name', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(EarningsExportSheet), findsOneWidget);
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

    testWidgets('shows "Exporter mes revenus" title', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('Exporter mes revenus'), findsOneWidget);
    });

    testWidgets('shows subtitle about gains', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pump(const Duration(seconds: 1));
      expect(find.textContaining('relevé'), findsWidgets);
    });

    testWidgets('shows "Période" section', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('Période'), findsOneWidget);
    });

    testWidgets('shows "Données" section', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('Données'), findsOneWidget);
    });

    testWidgets('shows "Format" section', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('Format'), findsOneWidget);
    });

    testWidgets('shows "Ce mois" period option', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('Ce mois'), findsOneWidget);
    });

    testWidgets('shows "Mois dernier" period option', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('Mois dernier'), findsOneWidget);
    });

    testWidgets('shows "Livraisons" data option', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('Livraisons'), findsOneWidget);
    });

    testWidgets('shows "Transactions" data option', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('Transactions'), findsOneWidget);
    });

    testWidgets('shows "CSV" format option', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('CSV'), findsOneWidget);
    });

    testWidgets('shows "Texte" format option', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('Texte'), findsOneWidget);
    });

    testWidgets('shows "Exporter" button', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('Exporter'), findsOneWidget);
    });

    testWidgets('shows download icon', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pump(const Duration(seconds: 1));
      expect(find.byIcon(Icons.download_rounded), findsWidgets);
    });

    testWidgets('shows "Du" date label', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('Du'), findsOneWidget);
    });

    testWidgets('shows "Au" date label', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('Au'), findsOneWidget);
    });
  });
}
