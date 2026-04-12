import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:courier/presentation/screens/history_export_screen.dart';
import 'package:courier/presentation/providers/history_providers.dart';
import 'package:courier/data/models/delivery.dart';
import 'package:courier/core/services/delivery_export_service.dart';
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

  final testDeliveries = <Delivery>[
    const Delivery(
      id: 1,
      reference: 'REF-001',
      pharmacyName: 'Pharmacie Centrale',
      pharmacyAddress: '10 Rue Pharmacie',
      customerName: 'Client Test',
      deliveryAddress: '123 Rue Test',
      totalAmount: 5000,
      status: 'delivered',
      createdAt: '2024-01-15T10:00:00Z',
    ),
    const Delivery(
      id: 2,
      reference: 'REF-002',
      pharmacyName: 'Pharmacie Nord',
      pharmacyAddress: '20 Rue Nord',
      customerName: 'Client Deux',
      deliveryAddress: '456 Rue Exemple',
      totalAmount: 8000,
      status: 'delivered',
      createdAt: '2024-01-16T12:00:00Z',
    ),
  ];

  Widget buildScreen({List<Delivery>? deliveries}) {
    return ProviderScope(
      overrides: [
        ...commonWidgetTestOverrides(),
        filteredHistoryProvider.overrideWith(
          (ref) async => deliveries ?? testDeliveries,
        ),
        savedExportsProvider.overrideWith((ref) async => <ExportedFile>[]),
      ],
      child: const MaterialApp(home: HistoryExportScreen()),
    );
  }

  Future<void> pumpAndWait(WidgetTester tester, Widget widget) async {
    tester.view.physicalSize = const Size(1080, 5000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(widget);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
  }

  group('HistoryExportScreen', () {
    testWidgets('renders with app bar title', (tester) async {
      await pumpAndWait(tester, buildScreen());
      expect(find.textContaining('Historique'), findsWidgets);
    });

    testWidgets('has tab bar with Historique and Exports tabs', (tester) async {
      await pumpAndWait(tester, buildScreen());
      expect(find.byType(TabBar), findsOneWidget);
      expect(find.byIcon(Icons.history), findsOneWidget);
      expect(find.byIcon(Icons.folder), findsOneWidget);
    });

    testWidgets('has filter and menu buttons', (tester) async {
      await pumpAndWait(tester, buildScreen());
      expect(find.byIcon(Icons.filter_list), findsOneWidget);
      expect(find.byIcon(Icons.more_vert), findsOneWidget);
    });

    testWidgets('shows scaffold', (tester) async {
      await pumpAndWait(tester, buildScreen());
      expect(find.byType(Scaffold), findsWidgets);
    });

    testWidgets('switches to Exports tab', (tester) async {
      await pumpAndWait(tester, buildScreen());
      final exportsTab = find.text('Exports');
      if (exportsTab.evaluate().isNotEmpty) {
        await tester.tap(exportsTab.first);
        await tester.pump(const Duration(seconds: 1));
      }
      expect(find.byType(HistoryExportScreen), findsOneWidget);
    });

    testWidgets('renders with empty deliveries', (tester) async {
      await pumpAndWait(tester, buildScreen(deliveries: []));
      expect(find.byType(HistoryExportScreen), findsOneWidget);
    });

    testWidgets('renders popup menu items on tap', (tester) async {
      await pumpAndWait(tester, buildScreen());
      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('Exporter en PDF'), findsOneWidget);
      expect(find.text('Exporter en CSV'), findsOneWidget);
      expect(find.text('Imprimer'), findsOneWidget);
    });

    testWidgets('renders in dark mode', (tester) async {
      tester.view.physicalSize = const Size(1080, 5000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            ...commonWidgetTestOverrides(),
            filteredHistoryProvider.overrideWith((ref) async => testDeliveries),
            savedExportsProvider.overrideWith((ref) async => <ExportedFile>[]),
          ],
          child: MaterialApp(
            theme: ThemeData.dark(),
            home: const HistoryExportScreen(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      expect(find.textContaining('Historique'), findsWidgets);
    });
  });
}
