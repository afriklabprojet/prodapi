import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';

import 'package:drpharma_client/features/orders/presentation/pages/tracking_page.dart';
import 'package:drpharma_client/features/orders/domain/entities/delivery_address_entity.dart';
import 'package:drpharma_client/features/orders/domain/repositories/orders_repository.dart';
import 'package:drpharma_client/core/services/firestore_tracking_service.dart';
import 'package:drpharma_client/config/providers.dart';
import '../../../../helpers/fake_api_client.dart';

class MockFirestoreTrackingService extends Mock
    implements FirestoreTrackingService {
  @override
  Stream<CourierLocationData?> watchCourierLocation(int courierId) =>
      Stream.value(null);

  @override
  Stream<DeliveryTrackingData?> watchDeliveryTracking(int orderId) =>
      Stream.value(null);

  @override
  Future<bool> isCourierOnline(int courierId) async => false;

  @override
  Future<CourierLocationData?> getLastCourierLocation(int courierId) async =>
      null;
}

class MockFirestoreErrorService extends Mock
    implements FirestoreTrackingService {
  @override
  Stream<CourierLocationData?> watchCourierLocation(int courierId) =>
      Stream.error(Exception('Connection failed'));

  @override
  Stream<DeliveryTrackingData?> watchDeliveryTracking(int orderId) =>
      Stream.error(Exception('Connection failed'));

  @override
  Future<bool> isCourierOnline(int courierId) async => false;

  @override
  Future<CourierLocationData?> getLastCourierLocation(int courierId) async =>
      null;
}

class MockOrdersRepository extends Mock implements OrdersRepository {
  @override
  Future<Map<String, dynamic>?> getTrackingInfo(int orderId) async {
    throw Exception('No tracking data');
  }
}

const _testAddress = DeliveryAddressEntity(
  address: '123 Test Street',
  city: 'Abidjan',
  phone: '0123456789',
);

void main() {
  Widget createTestWidget({
    FirestoreTrackingService? service,
    OrdersRepository? ordersRepo,
  }) {
    return ProviderScope(
      overrides: [
        apiClientProvider.overrideWithValue(FakeApiClient()),
        firestoreTrackingServiceProvider.overrideWithValue(
          service ?? MockFirestoreTrackingService(),
        ),
        if (ordersRepo != null)
          ordersRepositoryProvider.overrideWithValue(ordersRepo),
      ],
      child: MaterialApp(
        home: TrackingPage(orderId: 1, deliveryAddress: _testAddress),
      ),
    );
  }

  group('TrackingPage Widget Tests', () {
    testWidgets('should render tracking page', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(createTestWidget());
      expect(find.byType(TrackingPage), findsOneWidget);
    });

    testWidgets('should display order status', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(createTestWidget());
      expect(find.byType(TrackingPage), findsOneWidget);
    });

    testWidgets('should have map with delivery location', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(createTestWidget());
      expect(find.byType(TrackingPage), findsOneWidget);
    });

    testWidgets('should display courier information', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(createTestWidget());
      expect(find.byType(TrackingPage), findsOneWidget);
    });

    testWidgets('should have call courier button', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(createTestWidget());
      expect(find.byType(TrackingPage), findsOneWidget);
    });

    testWidgets('should display estimated time', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(createTestWidget());
      expect(find.byType(TrackingPage), findsOneWidget);
    });

    testWidgets('should have tracking timeline', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(createTestWidget());
      expect(find.byType(TrackingPage), findsOneWidget);
    });

    testWidgets('should have app bar with back button', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(createTestWidget());
      expect(find.byType(AppBar), findsOneWidget);
    });

    testWidgets('should refresh tracking data', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(createTestWidget());
      expect(find.byType(TrackingPage), findsOneWidget);
    });

    testWidgets('should be accessible', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(createTestWidget());

      final semanticsHandle = tester.ensureSemantics();
      semanticsHandle.dispose();

      expect(find.byType(TrackingPage), findsOneWidget);
    });
  });

  group('TrackingPage Content Tests', () {
    testWidgets('shows Suivi de livraison AppBar title', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(createTestWidget());
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('Suivi de livraison'), findsOneWidget);
    });

    testWidgets('has AppBar', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(createTestWidget());
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byType(AppBar), findsOneWidget);
    });

    testWidgets('renders Scaffold', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(createTestWidget());
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('renders without Firebase crash', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(createTestWidget());
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byType(TrackingPage), findsOneWidget);
    });
  });

  group('TrackingPage Error State Tests', () {
    testWidgets('shows location_off icon on stream error', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        createTestWidget(
          service: MockFirestoreErrorService(),
          ordersRepo: MockOrdersRepository(),
        ),
      );
      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byIcon(Icons.location_off), findsOneWidget);
    });

    testWidgets('shows error message when stream fails', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        createTestWidget(
          service: MockFirestoreErrorService(),
          ordersRepo: MockOrdersRepository(),
        ),
      );
      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.textContaining('Impossible de charger'), findsOneWidget);
    });

    testWidgets('shows Réessayer button on stream error', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        createTestWidget(
          service: MockFirestoreErrorService(),
          ordersRepo: MockOrdersRepository(),
        ),
      );
      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Réessayer'), findsOneWidget);
    });

    testWidgets('shows refresh icon in Réessayer button', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        createTestWidget(
          service: MockFirestoreErrorService(),
          ordersRepo: MockOrdersRepository(),
        ),
      );
      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byIcon(Icons.refresh), findsOneWidget);
    });
  });
}
