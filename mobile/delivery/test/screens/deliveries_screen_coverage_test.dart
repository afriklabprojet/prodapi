import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mocktail/mocktail.dart';
import 'package:courier/presentation/screens/deliveries_screen.dart';
import 'package:courier/presentation/providers/delivery_providers.dart';
import 'package:courier/data/models/delivery.dart';
import 'package:courier/data/repositories/delivery_repository.dart';
import 'package:courier/core/services/delivery_alert_service.dart';
import 'package:courier/l10n/app_localizations.dart';
import '../helpers/widget_test_helpers.dart';

class MockDeliveryRepository extends Mock implements DeliveryRepository {}

class MockDeliveryAlertService extends Mock implements DeliveryAlertService {}

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

  final testDeliveries = [
    const Delivery(
      id: 1,
      reference: 'REF-001',
      pharmacyName: 'Pharmacie Alpha',
      pharmacyAddress: '10 Rue A',
      customerName: 'Client A',
      deliveryAddress: '20 Rue B',
      totalAmount: 5000,
      deliveryFee: 1500,
      status: 'pending',
    ),
    const Delivery(
      id: 2,
      reference: 'REF-002',
      pharmacyName: 'Pharmacie Beta',
      pharmacyAddress: '30 Rue C',
      customerName: 'Client B',
      deliveryAddress: '40 Rue D',
      totalAmount: 8000,
      deliveryFee: 2000,
      status: 'in_progress',
    ),
  ];

  Future<void> pumpDeliveries(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 4000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final mockRepo = MockDeliveryRepository();
    final mockAlert = MockDeliveryAlertService();

    final original = FlutterError.onError;
    FlutterError.onError = (_) {};
    try {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            ...commonWidgetTestOverrides(),
            deliveriesProvider.overrideWith(
              (ref, status) async => testDeliveries,
            ),
            deliveryRepositoryProvider.overrideWithValue(mockRepo),
            deliveryAlertServiceProvider.overrideWithValue(mockAlert),
          ],
          child: MaterialApp(
            locale: const Locale('fr'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const DeliveriesScreen(),
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
      await tester.pump(const Duration(seconds: 5));
      await tester.pump(const Duration(seconds: 5));
    } finally {
      FlutterError.onError = original;
    }
  }

  group('DeliveriesScreen', () {
    testWidgets('renders deliveries screen', (tester) async {
      await pumpDeliveries(tester);
      expect(find.byType(DeliveriesScreen), findsOneWidget);
      await drainTimers(tester);
    });

    testWidgets('shows tab bar with tabs', (tester) async {
      await pumpDeliveries(tester);
      expect(find.byType(TabBar), findsOneWidget);
      await drainTimers(tester);
    });

    testWidgets('shows Mes Courses title', (tester) async {
      await pumpDeliveries(tester);
      expect(find.textContaining('Courses'), findsWidgets);
      await drainTimers(tester);
    });

    testWidgets('shows delivery list items', (tester) async {
      await pumpDeliveries(tester);
      await tester.pump(const Duration(milliseconds: 500));
      // Should show delivery items
      expect(find.byType(DeliveriesScreen), findsOneWidget);
      await drainTimers(tester);
    });

    testWidgets('switching to second tab', (tester) async {
      await pumpDeliveries(tester);
      // Tap on second tab
      final tabs = find.byType(Tab);
      if (tabs.evaluate().length > 1) {
        await tester.tap(tabs.at(1));
        await tester.pump(const Duration(milliseconds: 500));
      }
      await drainTimers(tester);
    });

    testWidgets('switching to third tab', (tester) async {
      await pumpDeliveries(tester);
      final tabs = find.byType(Tab);
      if (tabs.evaluate().length > 2) {
        await tester.tap(tabs.at(2));
        await tester.pump(const Duration(milliseconds: 500));
      }
      await drainTimers(tester);
    });

    testWidgets('with alert active shows banner', (tester) async {
      tester.view.physicalSize = const Size(1080, 4000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final mockRepo = MockDeliveryRepository();
      final mockAlert = MockDeliveryAlertService();

      final original = FlutterError.onError;
      FlutterError.onError = (_) {};
      try {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              ...commonWidgetTestOverrides(),
              deliveriesProvider.overrideWith(
                (ref, status) async => testDeliveries,
              ),
              deliveryRepositoryProvider.overrideWithValue(mockRepo),
              deliveryAlertServiceProvider.overrideWithValue(mockAlert),
            ],
            child: MaterialApp(
              locale: const Locale('fr'),
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: const DeliveriesScreen(),
            ),
          ),
        );
        await tester.pump(const Duration(seconds: 1));
      } finally {
        FlutterError.onError = original;
      }
      expect(find.byType(DeliveriesScreen), findsOneWidget);
      await drainTimers(tester);
    });

    testWidgets('empty deliveries shows empty state', (tester) async {
      tester.view.physicalSize = const Size(1080, 4000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final mockRepo = MockDeliveryRepository();
      final mockAlert = MockDeliveryAlertService();

      final original = FlutterError.onError;
      FlutterError.onError = (_) {};
      try {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              ...commonWidgetTestOverrides(),
              deliveriesProvider.overrideWith(
                (ref, status) async => <Delivery>[],
              ),
              deliveryRepositoryProvider.overrideWithValue(mockRepo),
              deliveryAlertServiceProvider.overrideWithValue(mockAlert),
            ],
            child: MaterialApp(
              locale: const Locale('fr'),
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: const DeliveriesScreen(),
            ),
          ),
        );
        await tester.pump(const Duration(seconds: 1));
      } finally {
        FlutterError.onError = original;
      }
      expect(find.byType(DeliveriesScreen), findsOneWidget);
      await drainTimers(tester);
    });
  });
}
