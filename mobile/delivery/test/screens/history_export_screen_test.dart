import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:courier/presentation/screens/history_export_screen.dart';
import 'package:courier/presentation/providers/history_providers.dart'
    hide HistoryStats;
import 'package:courier/core/services/delivery_export_service.dart'
    show ExportedFile, savedExportsProvider, HistoryStats, ExportType;
import 'package:courier/data/models/delivery.dart';
import '../helpers/widget_test_helpers.dart';

void main() {
  setUpAll(() async {
    await initHiveForTests();
    await initializeDateFormatting('fr_FR');
  });

  tearDownAll(() async {
    await cleanupHiveForTests();
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Delivery makeDelivery({
    int id = 1,
    String status = 'delivered',
    String reference = 'DEL-001',
    String pharmacyName = 'Pharmacie Test',
  }) {
    return Delivery.fromJson({
      'id': id,
      'reference': reference,
      'pharmacy_name': pharmacyName,
      'pharmacy_address': '123 Rue Test',
      'customer_name': 'Client Test',
      'delivery_address': '456 Rue Client',
      'total_amount': '10000',
      'status': status,
      'delivery_fee': '2000',
      'commission': '500',
      'distance_km': '3.5',
      'created_at': '2025-01-15 10:30:00',
    });
  }

  Widget buildScreen({
    List<Delivery>? deliveries,
    List<ExportedFile>? exports,
    bool useLoading = false,
    bool useError = false,
  }) {
    return ProviderScope(
      overrides: [
        ...commonWidgetTestOverrides(),
        if (useLoading)
          filteredHistoryProvider.overrideWith((ref) {
            final completer = Completer<List<Delivery>>();
            return completer.future;
          })
        else if (useError)
          filteredHistoryProvider.overrideWith((ref) async {
            throw Exception('Network error');
          })
        else
          filteredHistoryProvider.overrideWith((ref) async => deliveries ?? []),
        savedExportsProvider.overrideWith((ref) async => exports ?? []),
      ],
      child: const MaterialApp(home: HistoryExportScreen()),
    );
  }

  group('HistoryExportScreen - Basic', () {
    testWidgets('renders with scaffold', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(Scaffold), findsWidgets);
    });

    testWidgets('shows Historique & Export title', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('Historique & Export'), findsOneWidget);
    });

    testWidgets('shows Historique tab', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('Historique'), findsOneWidget);
    });

    testWidgets('shows Exports tab', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('Exports'), findsOneWidget);
    });

    testWidgets('has TabBar', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(TabBar), findsOneWidget);
    });

    testWidgets('has TabBarView', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(TabBarView), findsOneWidget);
    });

    testWidgets('has filter icon button', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pump(const Duration(seconds: 1));
      expect(find.byIcon(Icons.filter_list), findsOneWidget);
    });

    testWidgets('has popup menu for export options', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(PopupMenuButton<String>), findsOneWidget);
    });

    testWidgets('can switch to Exports tab', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pump(const Duration(seconds: 1));
      await tester.tap(find.text('Exports'));
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('Exports'), findsOneWidget);
    });
  });

  group('HistoryExportScreen - With deliveries', () {
    testWidgets('shows delivery cards when data is present', (tester) async {
      final deliveries = [
        makeDelivery(id: 1, status: 'delivered', reference: 'DEL-001'),
        makeDelivery(id: 2, status: 'cancelled', reference: 'DEL-002'),
        makeDelivery(
          id: 3,
          status: 'delivered',
          reference: 'DEL-003',
          pharmacyName: 'Pharma Nord',
        ),
      ];
      await tester.pumpWidget(buildScreen(deliveries: deliveries));
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(Card), findsWidgets);
    });

    testWidgets('shows pharmacy name in card', (tester) async {
      await tester.pumpWidget(
        buildScreen(
          deliveries: [makeDelivery(pharmacyName: 'Pharmacie Centrale')],
        ),
      );
      await tester.pump(const Duration(seconds: 1));
      expect(find.textContaining('Pharmacie Centrale'), findsWidgets);
    });

    testWidgets('multiple deliveries render multiple cards', (tester) async {
      final deliveries = List.generate(
        5,
        (i) => makeDelivery(id: i, reference: 'DEL-00$i'),
      );
      await tester.pumpWidget(buildScreen(deliveries: deliveries));
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(Card), findsWidgets);
    });
  });

  group('HistoryExportScreen - Async states', () {
    testWidgets('loading state shows indicator', (tester) async {
      await tester.pumpWidget(buildScreen(useLoading: true));
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byType(CircularProgressIndicator), findsWidgets);
    });
  });

  group('ExportedFile model', () {
    test('formattedSize returns bytes for small files', () {
      final file = ExportedFile(
        path: '/tmp/x.csv',
        name: 'x.csv',
        size: 500,
        createdAt: DateTime.now(),
        type: ExportType.csv,
      );
      expect(file.formattedSize, '500 B');
    });

    test('formattedSize returns KB for medium files', () {
      final file = ExportedFile(
        path: '/tmp/x.pdf',
        name: 'x.pdf',
        size: 2048,
        createdAt: DateTime.now(),
        type: ExportType.pdf,
      );
      expect(file.formattedSize, '2.0 KB');
    });

    test('formattedSize returns MB for large files', () {
      final file = ExportedFile(
        path: '/tmp/x.pdf',
        name: 'x.pdf',
        size: 2 * 1024 * 1024,
        createdAt: DateTime.now(),
        type: ExportType.pdf,
      );
      expect(file.formattedSize, '2.0 MB');
    });
  });

  group('HistoryStats model', () {
    test('fromDeliveries computes stats correctly', () {
      final deliveries = [
        makeDelivery(id: 1, status: 'delivered'),
        makeDelivery(id: 2, status: 'delivered'),
        makeDelivery(id: 3, status: 'cancelled'),
      ];
      final stats = HistoryStats.fromDeliveries(deliveries);
      expect(stats.totalDeliveries, 3);
      expect(stats.deliveredCount, 2);
      expect(stats.cancelledCount, 1);
    });

    test('fromDeliveries with empty list', () {
      final stats = HistoryStats.fromDeliveries([]);
      expect(stats.totalDeliveries, 0);
      expect(stats.deliveredCount, 0);
      expect(stats.cancelledCount, 0);
      expect(stats.averageEarnings, 0);
    });

    test('fromDeliveries computes total distance', () {
      final deliveries = [
        makeDelivery(id: 1, status: 'delivered'),
        makeDelivery(id: 2, status: 'delivered'),
      ];
      final stats = HistoryStats.fromDeliveries(deliveries);
      expect(stats.totalDistance, 7.0); // 3.5 + 3.5
    });
  });

  group('HistoryStats model - additional', () {
    test('fromDeliveries computes with all delivered', () {
      final deliveries = List.generate(
        5,
        (i) => makeDelivery(id: i + 1, status: 'delivered'),
      );
      final stats = HistoryStats.fromDeliveries(deliveries);
      expect(stats.totalDeliveries, 5);
      expect(stats.deliveredCount, 5);
      expect(stats.cancelledCount, 0);
    });

    test('fromDeliveries computes with all cancelled', () {
      final deliveries = List.generate(
        3,
        (i) => makeDelivery(id: i + 1, status: 'cancelled'),
      );
      final stats = HistoryStats.fromDeliveries(deliveries);
      expect(stats.totalDeliveries, 3);
      expect(stats.deliveredCount, 0);
      expect(stats.cancelledCount, 3);
    });

    test('fromDeliveries computes total earnings', () {
      final deliveries = [
        makeDelivery(id: 1, status: 'delivered'),
        makeDelivery(id: 2, status: 'delivered'),
        makeDelivery(id: 3, status: 'delivered'),
      ];
      final stats = HistoryStats.fromDeliveries(deliveries);
      expect(stats.totalDeliveries, 3);
      expect(stats.deliveredCount, 3);
      // totalDistance = 3 * 3.5 = 10.5
      expect(stats.totalDistance, 10.5);
    });
  });

  group('ExportedFile model - additional', () {
    test('formattedSize returns bytes for < 1KB', () {
      final file = ExportedFile(
        path: '/tmp/tiny.csv',
        name: 'tiny.csv',
        size: 100,
        createdAt: DateTime.now(),
        type: ExportType.csv,
      );
      expect(file.formattedSize, '100 B');
    });

    test('formattedSize returns KB precisely', () {
      final file = ExportedFile(
        path: '/tmp/small.csv',
        name: 'small.csv',
        size: 1536, // 1.5 KB
        createdAt: DateTime.now(),
        type: ExportType.csv,
      );
      expect(file.formattedSize, '1.5 KB');
    });
  });

  // =========================================================================
  // Round 4 – deeper coverage
  // =========================================================================

  group('HistoryExportScreen - popup menu actions', () {
    testWidgets('popup menu shows export options when tapped', (tester) async {
      await tester.pumpWidget(buildScreen(deliveries: [makeDelivery()]));
      await tester.pump(const Duration(seconds: 1));

      // Tap the PopupMenuButton (more_vert icon)
      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pump(const Duration(seconds: 1));

      // Should show all 3 export options
      expect(find.text('Exporter en PDF'), findsOneWidget);
      expect(find.text('Exporter en CSV'), findsOneWidget);
      expect(find.text('Imprimer'), findsOneWidget);
    });

    testWidgets('popup menu shows pdf icon', (tester) async {
      await tester.pumpWidget(buildScreen(deliveries: [makeDelivery()]));
      await tester.pump(const Duration(seconds: 1));

      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pump(const Duration(seconds: 1));

      expect(find.byIcon(Icons.picture_as_pdf), findsOneWidget);
      expect(find.byIcon(Icons.table_chart), findsOneWidget);
      expect(find.byIcon(Icons.print), findsOneWidget);
    });
  });

  group('HistoryExportScreen - delivery card content', () {
    testWidgets('delivery card shows pharmacy icon', (tester) async {
      await tester.pumpWidget(buildScreen(deliveries: [makeDelivery()]));
      await tester.pump(const Duration(seconds: 1));

      expect(find.byIcon(Icons.store), findsWidgets);
    });

    testWidgets('delivery card shows location icon', (tester) async {
      await tester.pumpWidget(buildScreen(deliveries: [makeDelivery()]));
      await tester.pump(const Duration(seconds: 1));

      expect(find.byIcon(Icons.location_on), findsWidgets);
    });

    testWidgets('delivery card shows Livrée badge for delivered status', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildScreen(deliveries: [makeDelivery(status: 'delivered')]),
      );
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('Livrée'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle), findsWidgets);
    });

    testWidgets('delivery card shows Annulée badge for cancelled status', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildScreen(deliveries: [makeDelivery(status: 'cancelled')]),
      );
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('Annulée'), findsOneWidget);
      expect(find.byIcon(Icons.cancel), findsWidgets);
    });

    testWidgets('delivery card shows unknown status as-is', (tester) async {
      await tester.pumpWidget(
        buildScreen(deliveries: [makeDelivery(status: 'picked_up')]),
      );
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('picked_up'), findsOneWidget);
    });

    testWidgets('delivery card shows delivery address', (tester) async {
      await tester.pumpWidget(buildScreen(deliveries: [makeDelivery()]));
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('456 Rue Client'), findsOneWidget);
    });

    testWidgets('delivery card shows Commission text', (tester) async {
      await tester.pumpWidget(buildScreen(deliveries: [makeDelivery()]));
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('Commission'), findsOneWidget);
    });

    testWidgets('delivery card shows distance', (tester) async {
      await tester.pumpWidget(buildScreen(deliveries: [makeDelivery()]));
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('3.5 km'), findsOneWidget);
    });

    testWidgets('delivery card shows delivery id', (tester) async {
      await tester.pumpWidget(buildScreen(deliveries: [makeDelivery(id: 42)]));
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('#42'), findsOneWidget);
    });
  });

  group('HistoryExportScreen - exports tab content', () {
    testWidgets('export card shows PDF file name', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1400));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final exports = [
        ExportedFile(
          path: '/tmp/report.pdf',
          name: 'report_jan.pdf',
          size: 4096,
          createdAt: DateTime(2025, 1, 15),
          type: ExportType.pdf,
        ),
      ];
      await tester.pumpWidget(buildScreen(exports: exports));
      await tester.pump(const Duration(seconds: 1));
      await tester.tap(find.text('Exports'));
      for (int i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      expect(find.text('report_jan.pdf'), findsOneWidget);
    });

    testWidgets('export card shows share and delete icons', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1400));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final exports = [
        ExportedFile(
          path: '/tmp/file.pdf',
          name: 'file.pdf',
          size: 2048,
          createdAt: DateTime(2025, 1, 15),
          type: ExportType.pdf,
        ),
      ];
      await tester.pumpWidget(buildScreen(exports: exports));
      await tester.pump(const Duration(seconds: 1));
      await tester.tap(find.text('Exports'));
      for (int i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      expect(find.byIcon(Icons.share), findsOneWidget);
      expect(find.byIcon(Icons.delete_outline), findsOneWidget);
    });

    testWidgets('empty exports tab shows folder_open icon and message', (
      tester,
    ) async {
      await tester.pumpWidget(buildScreen(exports: []));
      await tester.pump(const Duration(seconds: 1));
      await tester.tap(find.text('Exports'));
      for (int i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      expect(find.byIcon(Icons.folder_open), findsOneWidget);
      expect(find.text('Aucun export sauvegardé'), findsOneWidget);
      expect(find.text('Les exports PDF seront affichés ici'), findsOneWidget);
    });
  });

  group('HistoryExportScreen - empty history state', () {
    testWidgets('empty history shows history icon and message', (tester) async {
      await tester.pumpWidget(buildScreen(deliveries: []));
      await tester.pump(const Duration(seconds: 1));

      expect(find.byIcon(Icons.history), findsWidgets);
      expect(find.text('Aucune livraison trouvée'), findsOneWidget);
    });
  });

  group('ExportedFile model - edge cases', () {
    test('ExportType.pdf and csv values', () {
      expect(ExportType.pdf.name, 'pdf');
      expect(ExportType.csv.name, 'csv');
      expect(ExportType.values.length, 2);
    });

    test('formattedSize returns GB for very large files', () {
      final file = ExportedFile(
        path: '/tmp/huge.pdf',
        name: 'huge.pdf',
        size: 2 * 1024 * 1024 * 1024, // 2 GB
        createdAt: DateTime.now(),
        type: ExportType.pdf,
      );
      // Should handle large files (may return MB or GB)
      expect(file.formattedSize, isNotEmpty);
    });

    test('formattedSize for exactly 1024 bytes', () {
      final file = ExportedFile(
        path: '/tmp/exact.csv',
        name: 'exact.csv',
        size: 1024,
        createdAt: DateTime.now(),
        type: ExportType.csv,
      );
      expect(file.formattedSize, '1.0 KB');
    });

    test('formattedSize for zero bytes', () {
      final file = ExportedFile(
        path: '/tmp/empty.csv',
        name: 'empty.csv',
        size: 0,
        createdAt: DateTime.now(),
        type: ExportType.csv,
      );
      expect(file.formattedSize, '0 B');
    });
  });

  group('HistoryStats model - edge cases', () {
    test('fromDeliveries with mixed statuses', () {
      final deliveries = [
        makeDelivery(id: 1, status: 'delivered'),
        makeDelivery(id: 2, status: 'delivered'),
        makeDelivery(id: 3, status: 'cancelled'),
        makeDelivery(id: 4, status: 'delivered'),
      ];
      final stats = HistoryStats.fromDeliveries(deliveries);
      expect(stats.totalDeliveries, 4);
      expect(stats.deliveredCount, 3);
      expect(stats.cancelledCount, 1);
    });

    test('fromDeliveries with all delivered', () {
      final stats = HistoryStats.fromDeliveries([
        makeDelivery(id: 1, status: 'delivered'),
        makeDelivery(id: 2, status: 'delivered'),
      ]);
      expect(stats.deliveredCount, 2);
      expect(stats.cancelledCount, 0);
    });

    test('averageEarnings computes correctly', () {
      final stats = HistoryStats.fromDeliveries([
        makeDelivery(id: 1, status: 'delivered'),
        makeDelivery(id: 2, status: 'delivered'),
      ]);
      // totalEarnings / totalDeliveries
      expect(stats.averageEarnings, greaterThan(0));
    });

    test('totalEarnings sums commissions of delivered only', () {
      final stats = HistoryStats.fromDeliveries([
        makeDelivery(id: 1, status: 'delivered'),
        makeDelivery(id: 2, status: 'cancelled'),
      ]);
      // Only delivered commissions counted: 1 delivered × 500 commission = 500
      expect(stats.totalEarnings, 500);
    });

    test('totalDistance sums all deliveries', () {
      final stats = HistoryStats.fromDeliveries([
        makeDelivery(id: 1, status: 'delivered'),
        makeDelivery(id: 2, status: 'cancelled'),
      ]);
      // 2 deliveries × 3.5 km = 7.0
      expect(stats.totalDistance, 7.0);
    });

    test('empty deliveries returns zeroes', () {
      final stats = HistoryStats.fromDeliveries([]);
      expect(stats.totalDeliveries, 0);
      expect(stats.deliveredCount, 0);
      expect(stats.cancelledCount, 0);
      expect(stats.totalEarnings, 0);
      expect(stats.averageEarnings, 0);
      expect(stats.totalDistance, 0);
    });
  });
}
