import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:courier/presentation/screens/history_export_screen.dart';
import 'package:courier/data/models/delivery.dart';
import 'package:courier/presentation/providers/history_providers.dart';
import 'package:courier/core/services/delivery_export_service.dart'
    show ExportedFile, savedExportsProvider;
import '../helpers/widget_test_helpers.dart';

Delivery _delivery({
  int id = 1,
  String reference = 'REF-001',
  String status = 'delivered',
  double totalAmount = 5000,
}) {
  return Delivery(
    id: id,
    reference: reference,
    pharmacyName: 'Pharmacie Test',
    pharmacyAddress: '123 Rue Test',
    customerName: 'Client Test',
    deliveryAddress: '456 Avenue Test',
    totalAmount: totalAmount,
    status: status,
    createdAt: DateTime.now()
        .subtract(const Duration(hours: 2))
        .toIso8601String(),
  );
}

Widget buildTestWidget({List<Delivery> deliveries = const []}) {
  return ProviderScope(
    overrides: commonWidgetTestOverrides(
      extra: [
        filteredHistoryProvider.overrideWith((ref) async => deliveries),
        historyStatsProvider.overrideWith(
          (ref) async => HistoryStats(
            totalDeliveries: deliveries.length,
            delivered: deliveries.length,
            cancelled: 0,
            totalEarnings: deliveries.fold<double>(
              0.0,
              (sum, d) => sum + d.totalAmount,
            ),
          ),
        ),
        savedExportsProvider.overrideWith(
          (ref) => Future.value(<ExportedFile>[]),
        ),
      ],
    ),
    child: const MaterialApp(home: HistoryExportScreen()),
  );
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('fr_FR', null);
    await initHiveForTests();
  });

  tearDownAll(() async {
    await cleanupHiveForTests();
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('HistoryExportScreen', () {
    testWidgets('shows app bar title', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();
      expect(find.textContaining('Historique'), findsAtLeastNWidgets(1));
    });

    testWidgets('shows filter icon in app bar', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.filter_list), findsOneWidget);
    });

    testWidgets('shows more options menu', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.more_vert), findsOneWidget);
    });

    testWidgets('shows empty state when no deliveries', (tester) async {
      await tester.pumpWidget(buildTestWidget(deliveries: []));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.history), findsAtLeastNWidgets(1));
    });

    testWidgets('renders with deliveries override', (tester) async {
      final deliveries = [
        _delivery(id: 1, reference: 'REF-001', totalAmount: 5000),
        _delivery(id: 2, reference: 'REF-002', totalAmount: 3000),
      ];
      await tester.pumpWidget(buildTestWidget(deliveries: deliveries));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      // The screen should render a TabBar with Historique/Exports tabs
      expect(find.byType(TabBar), findsOneWidget);
    });

    testWidgets('shows TabBar', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();
      expect(find.byType(TabBar), findsOneWidget);
    });

    testWidgets('shows export options in menu', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();

      expect(find.text('Exporter en PDF'), findsOneWidget);
      expect(find.text('Exporter en CSV'), findsOneWidget);
    });
  });
}
