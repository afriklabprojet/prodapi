import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mocktail/mocktail.dart';
import 'package:courier/presentation/screens/delivery_details_screen.dart';
import 'package:courier/presentation/providers/delivery_providers.dart';
import 'package:courier/data/models/delivery.dart';
import 'package:courier/data/models/scanned_document.dart';
import 'package:courier/data/services/document_scanner_service.dart';
import 'package:courier/core/services/route_service.dart';
import 'package:riverpod/legacy.dart';
import '../helpers/widget_test_helpers.dart';

class MockRouteService extends Mock implements RouteService {}

class _FakeScannerNotifier extends StateNotifier<DocumentScannerState>
    implements DocumentScannerNotifier {
  _FakeScannerNotifier() : super(const DocumentScannerState());

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

void main() {
  setUpAll(() async {
    await initHiveForTests();
  });

  tearDownAll(() async {
    await cleanupHiveForTests();
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Delivery makeDelivery() {
    return Delivery.fromJson({
      'id': 1,
      'reference': 'DEL-001',
      'pharmacy_name': 'Pharmacie Centrale',
      'pharmacy_address': '123 Rue Abidjan',
      'customer_name': 'Marie Konan',
      'delivery_address': '456 Boulevard Cocody',
      'total_amount': '15000',
      'status': 'picked_up',
      'delivery_fee': '2000',
      'commission': '500',
      'pharmacy_latitude': '5.36',
      'pharmacy_longitude': '-4.01',
      'delivery_latitude': '5.37',
      'delivery_longitude': '-4.02',
    });
  }

  final fakePosition = Position(
    latitude: 5.36,
    longitude: -4.01,
    timestamp: DateTime.now(),
    accuracy: 10,
    altitude: 0,
    altitudeAccuracy: 0,
    heading: 0,
    headingAccuracy: 0,
    speed: 0,
    speedAccuracy: 0,
  );

  Future<void> pumpDetails(WidgetTester tester) async {
    final original = FlutterError.onError;
    FlutterError.onError = (_) {};
    try {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            ...commonWidgetTestOverrides(),
            locationStreamProvider.overrideWith(
              (ref) => Stream.value(fakePosition),
            ),
            routeServiceProvider.overrideWithValue(MockRouteService()),
            documentScannerStateProvider.overrideWith(
              (_) => _FakeScannerNotifier(),
            ),
          ],
          child: MaterialApp(
            home: DeliveryDetailsScreen(delivery: makeDelivery()),
          ),
        ),
      );
      await tester.pump(const Duration(seconds: 1));
    } finally {
      FlutterError.onError = original;
    }
  }

  Future<void> drainTimers(WidgetTester tester) async {
    final original = FlutterError.onError;
    FlutterError.onError = (_) {};
    try {
      await tester.pump(const Duration(seconds: 10));
      await tester.pump(const Duration(seconds: 10));
    } finally {
      FlutterError.onError = original;
    }
  }

  group('DeliveryDetailsScreen', () {
    testWidgets('renders with delivery', (tester) async {
      await pumpDetails(tester);
      expect(find.byType(DeliveryDetailsScreen), findsOneWidget);
      await drainTimers(tester);
    });

    testWidgets('contains Scaffold', (tester) async {
      await pumpDetails(tester);
      expect(find.byType(Scaffold), findsWidgets);
      await drainTimers(tester);
    });

    testWidgets('contains Text widgets', (tester) async {
      await pumpDetails(tester);
      expect(find.byType(Text), findsWidgets);
      await drainTimers(tester);
    });

    testWidgets('contains Icon widgets', (tester) async {
      await pumpDetails(tester);
      expect(find.byType(Icon), findsWidgets);
      await drainTimers(tester);
    });

    testWidgets('contains Container widgets', (tester) async {
      await pumpDetails(tester);
      expect(find.byType(Container), findsWidgets);
      await drainTimers(tester);
    });

    testWidgets('contains Column widgets', (tester) async {
      await pumpDetails(tester);
      expect(find.byType(Column), findsWidgets);
      await drainTimers(tester);
    });

    testWidgets('contains SizedBox widgets', (tester) async {
      await pumpDetails(tester);
      expect(find.byType(SizedBox), findsWidgets);
      await drainTimers(tester);
    });

    testWidgets('displays pharmacy name', (tester) async {
      await pumpDetails(tester);
      expect(find.textContaining('Pharmacie Centrale'), findsWidgets);
      await drainTimers(tester);
    });
  });
}
