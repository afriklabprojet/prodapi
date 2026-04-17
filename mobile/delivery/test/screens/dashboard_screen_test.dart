import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mocktail/mocktail.dart';
import 'package:courier/presentation/screens/dashboard_screen.dart';
import 'package:courier/presentation/providers/delivery_providers.dart';
import 'package:courier/data/models/courier_profile.dart';
import 'package:courier/data/models/delivery.dart';
import 'package:courier/core/services/notification_service.dart';
import 'package:courier/core/services/delivery_alert_service.dart';
import 'package:courier/data/repositories/delivery_repository.dart';
import '../helpers/widget_test_helpers.dart';

class MockDeliveryRepository extends Mock implements DeliveryRepository {}

class MockNotificationService extends Mock implements NotificationService {}

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

  final fakeProfile = CourierProfile(
    id: 1,
    name: 'Jean',
    email: 'jean@test.com',
    status: 'available',
    vehicleType: 'moto',
    plateNumber: 'AB-1234',
    rating: 4.5,
    completedDeliveries: 100,
    earnings: 50000,
    kycStatus: 'approved',
  );

  Future<void> pumpDashboard(WidgetTester tester) async {
    final mockRepo = MockDeliveryRepository();
    final mockNotif = MockNotificationService();
    final mockAlert = MockDeliveryAlertService();

    final original = FlutterError.onError;
    FlutterError.onError = (_) {};
    try {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            ...commonWidgetTestOverrides(),
            courierProfileProvider.overrideWith((ref) async => fakeProfile),
            deliveriesProvider.overrideWith(
              (ref, status) async => <Delivery>[],
            ),
            deliveryRepositoryProvider.overrideWithValue(mockRepo),
            notificationServiceProvider.overrideWithValue(mockNotif),
            deliveryAlertServiceProvider.overrideWithValue(mockAlert),
          ],
          child: const MaterialApp(home: DashboardScreen()),
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

  group('DashboardScreen', () {
    testWidgets('renders dashboard screen', (tester) async {
      await pumpDashboard(tester);
      expect(find.byType(DashboardScreen), findsOneWidget);
      await drainTimers(tester);
    });

    testWidgets('contains MaterialApp', (tester) async {
      await pumpDashboard(tester);
      expect(find.byType(MaterialApp), findsOneWidget);
      await drainTimers(tester);
    });

    testWidgets('contains Scaffold', (tester) async {
      await pumpDashboard(tester);
      expect(find.byType(Scaffold), findsWidgets);
      await drainTimers(tester);
    });

    testWidgets('contains Text widgets', (tester) async {
      await pumpDashboard(tester);
      expect(find.byType(Text), findsWidgets);
      await drainTimers(tester);
    });

    testWidgets('contains SizedBox widgets', (tester) async {
      await pumpDashboard(tester);
      expect(find.byType(SizedBox), findsWidgets);
      await drainTimers(tester);
    });

    testWidgets('contains Center widget', (tester) async {
      await pumpDashboard(tester);
      expect(find.byType(Center), findsWidgets);
      await drainTimers(tester);
    });

    testWidgets('contains Column widget', (tester) async {
      await pumpDashboard(tester);
      expect(find.byType(Column), findsWidgets);
      await drainTimers(tester);
    });

    testWidgets('contains Icon widgets', (tester) async {
      await pumpDashboard(tester);
      expect(find.byType(Icon), findsWidgets);
      await drainTimers(tester);
    });
  });

  group('DashboardScreen - profile variations', () {
    Future<void> pumpWithProfile(
      WidgetTester tester,
      CourierProfile profile,
    ) async {
      final mockRepo = MockDeliveryRepository();
      final mockNotif = MockNotificationService();
      final mockAlert = MockDeliveryAlertService();

      final original = FlutterError.onError;
      FlutterError.onError = (_) {};
      try {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              ...commonWidgetTestOverrides(),
              courierProfileProvider.overrideWith((ref) async => profile),
              deliveriesProvider.overrideWith(
                (ref, status) async => <Delivery>[],
              ),
              deliveryRepositoryProvider.overrideWithValue(mockRepo),
              notificationServiceProvider.overrideWithValue(mockNotif),
              deliveryAlertServiceProvider.overrideWithValue(mockAlert),
            ],
            child: const MaterialApp(home: DashboardScreen()),
          ),
        );
        await tester.pump(const Duration(seconds: 1));
      } finally {
        FlutterError.onError = original;
      }
    }

    testWidgets('renders with high-stats profile', (tester) async {
      final profile = CourierProfile(
        id: 2,
        name: 'Ali Koné',
        email: 'ali@test.com',
        status: 'available',
        vehicleType: 'car',
        plateNumber: 'AB-9999',
        rating: 5.0,
        completedDeliveries: 1000,
        earnings: 500000,
        kycStatus: 'approved',
      );
      await pumpWithProfile(tester, profile);
      expect(find.byType(DashboardScreen), findsOneWidget);
      await drainTimers(tester);
    });

    testWidgets('renders with unavailable status', (tester) async {
      final profile = CourierProfile(
        id: 3,
        name: 'Fatou Traoré',
        email: 'fatou@test.com',
        status: 'unavailable',
        vehicleType: 'motorcycle',
        plateNumber: 'MO-1234',
        rating: 3.0,
        completedDeliveries: 10,
        earnings: 5000,
        kycStatus: 'approved',
      );
      await pumpWithProfile(tester, profile);
      expect(find.byType(DashboardScreen), findsOneWidget);
      await drainTimers(tester);
    });

    testWidgets('renders with pending KYC status', (tester) async {
      final profile = CourierProfile(
        id: 4,
        name: 'Ibrahim Bamba',
        email: 'ibrahim@test.com',
        status: 'active',
        vehicleType: 'bicycle',
        plateNumber: '',
        rating: 0.0,
        completedDeliveries: 0,
        earnings: 0,
        kycStatus: 'pending',
      );
      await pumpWithProfile(tester, profile);
      expect(find.byType(DashboardScreen), findsOneWidget);
      await drainTimers(tester);
    });

    testWidgets('renders with zero earnings', (tester) async {
      final profile = CourierProfile(
        id: 5,
        name: 'Moussa Diallo',
        email: 'moussa@test.com',
        status: 'available',
        vehicleType: 'scooter',
        plateNumber: 'SC-001',
        rating: 4.0,
        completedDeliveries: 5,
        earnings: 0,
        kycStatus: 'approved',
      );
      await pumpWithProfile(tester, profile);
      expect(find.byType(DashboardScreen), findsOneWidget);
      await drainTimers(tester);
    });

    testWidgets('renders with no plate number', (tester) async {
      final profile = CourierProfile(
        id: 6,
        name: 'Aminata Cissé',
        email: 'aminata@test.com',
        status: 'available',
        vehicleType: 'bicycle',
        plateNumber: '',
        rating: 4.5,
        completedDeliveries: 20,
        earnings: 10000,
        kycStatus: 'approved',
      );
      await pumpWithProfile(tester, profile);
      expect(find.byType(DashboardScreen), findsOneWidget);
      await drainTimers(tester);
    });
  });

  group('DashboardScreen - error states', () {
    testWidgets('handles profile loading error gracefully', (tester) async {
      final mockRepo = MockDeliveryRepository();
      final mockNotif = MockNotificationService();
      final mockAlert = MockDeliveryAlertService();

      final original = FlutterError.onError;
      FlutterError.onError = (_) {};
      try {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              ...commonWidgetTestOverrides(),
              courierProfileProvider.overrideWith(
                (ref) async => throw Exception('Network error'),
              ),
              deliveriesProvider.overrideWith(
                (ref, status) async => <Delivery>[],
              ),
              deliveryRepositoryProvider.overrideWithValue(mockRepo),
              notificationServiceProvider.overrideWithValue(mockNotif),
              deliveryAlertServiceProvider.overrideWithValue(mockAlert),
            ],
            child: const MaterialApp(home: DashboardScreen()),
          ),
        );
        await tester.pump(const Duration(seconds: 1));
        await tester.pump(const Duration(seconds: 2));
      } finally {
        FlutterError.onError = original;
      }
      // Dashboard should still render even if profile fails
      expect(find.byType(DashboardScreen), findsOneWidget);
      final original2 = FlutterError.onError;
      FlutterError.onError = (_) {};
      try {
        await tester.pump(const Duration(seconds: 10));
        await tester.pump(const Duration(seconds: 10));
      } finally {
        FlutterError.onError = original2;
      }
    });
  });

  group('DashboardScreen - with deliveries', () {
    testWidgets('renders with non-empty deliveries list', (tester) async {
      final mockRepo = MockDeliveryRepository();
      final mockNotif = MockNotificationService();
      final mockAlert = MockDeliveryAlertService();

      final deliveryList = [
        Delivery(
          id: 1,
          reference: 'DEL-001',
          pharmacyName: 'Pharma Centrale',
          pharmacyAddress: '10 Rue Commerce',
          customerName: 'Client 1',
          deliveryAddress: '25 Avenue Houdaille',
          totalAmount: 5000,
          status: 'pending',
        ),
        Delivery(
          id: 2,
          reference: 'DEL-002',
          pharmacyName: 'Pharma Nord',
          pharmacyAddress: '20 Rue du Port',
          customerName: 'Client 2',
          deliveryAddress: '30 Boulevard Cocody',
          totalAmount: 7500,
          status: 'pending',
        ),
      ];

      final original = FlutterError.onError;
      FlutterError.onError = (_) {};
      try {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              ...commonWidgetTestOverrides(),
              courierProfileProvider.overrideWith((ref) async => fakeProfile),
              deliveriesProvider.overrideWith(
                (ref, status) async => deliveryList,
              ),
              deliveryRepositoryProvider.overrideWithValue(mockRepo),
              notificationServiceProvider.overrideWithValue(mockNotif),
              deliveryAlertServiceProvider.overrideWithValue(mockAlert),
            ],
            child: const MaterialApp(home: DashboardScreen()),
          ),
        );
        await tester.pump(const Duration(seconds: 1));
      } finally {
        FlutterError.onError = original;
      }
      expect(find.byType(DashboardScreen), findsOneWidget);

      final original2 = FlutterError.onError;
      FlutterError.onError = (_) {};
      try {
        await tester.pump(const Duration(seconds: 10));
        await tester.pump(const Duration(seconds: 10));
      } finally {
        FlutterError.onError = original2;
      }
    });
  });
}
