import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dartz/dartz.dart';

import 'package:drpharma_client/features/orders/presentation/pages/tracking_page_wrapper.dart';
import 'package:drpharma_client/features/orders/presentation/pages/tracking_page.dart';
import 'package:drpharma_client/features/orders/domain/entities/delivery_address_entity.dart';
import 'package:drpharma_client/features/orders/domain/entities/order_entity.dart';
import 'package:drpharma_client/features/orders/domain/repositories/orders_repository.dart';
import 'package:drpharma_client/core/services/firestore_tracking_service.dart';
import 'package:drpharma_client/core/errors/failures.dart';
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

class MockOrdersRepositorySuccess extends Mock implements OrdersRepository {
  @override
  Future<Map<String, dynamic>?> getTrackingInfo(int orderId) async => null;

  @override
  Future<Either<Failure, OrderEntity>> getOrderDetails(int orderId) async {
    return Right(
      OrderEntity(
        id: orderId,
        reference: 'CMD-001',
        status: OrderStatus.delivering,
        paymentStatus: 'paid',
        paymentMode: PaymentMode.platform,
        pharmacyId: 1,
        pharmacyName: 'Pharmacie Test',
        items: const [],
        subtotal: 5000,
        deliveryFee: 500,
        totalAmount: 5500,
        deliveryAddress: const DeliveryAddressEntity(
          address: '10 Rue Test',
          city: 'Abidjan',
          phone: '0102030405',
        ),
        createdAt: DateTime(2024, 1, 15),
      ),
    );
  }
}

class MockOrdersRepositoryFailure extends Mock implements OrdersRepository {
  @override
  Future<Map<String, dynamic>?> getTrackingInfo(int orderId) async => null;

  @override
  Future<Either<Failure, OrderEntity>> getOrderDetails(int orderId) async {
    return const Left(ServerFailure(message: 'Commande introuvable'));
  }
}

const _testAddress = DeliveryAddressEntity(
  address: '123 Test Street',
  city: 'Abidjan',
  phone: '0123456789',
);

Widget _buildWrapper({
  DeliveryAddressEntity? deliveryAddress,
  OrdersRepository? repo,
}) {
  return ProviderScope(
    overrides: [
      apiClientProvider.overrideWithValue(FakeApiClient()),
      firestoreTrackingServiceProvider.overrideWithValue(
        MockFirestoreTrackingService(),
      ),
      if (repo != null) ordersRepositoryProvider.overrideWithValue(repo),
    ],
    child: MaterialApp(
      home: TrackingPageWrapper(orderId: 1, deliveryAddress: deliveryAddress),
    ),
  );
}

void main() {
  group('TrackingPageWrapper Tests', () {
    testWidgets('renders with deliveryAddress directly', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(_buildWrapper(deliveryAddress: _testAddress));
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byType(TrackingPageWrapper), findsOneWidget);
    });

    testWidgets('shows Suivi de livraison title with direct address', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(_buildWrapper(deliveryAddress: _testAddress));
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('Suivi de livraison'), findsOneWidget);
    });

    testWidgets('renders without address (fetches order details)', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        _buildWrapper(
          deliveryAddress: null,
          repo: MockOrdersRepositorySuccess(),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(TrackingPageWrapper), findsOneWidget);
    });

    testWidgets('shows Scaffold when fetching order details', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        _buildWrapper(
          deliveryAddress: null,
          repo: MockOrdersRepositorySuccess(),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(Scaffold), findsAtLeastNWidgets(1));
    });

    testWidgets('shows error when getOrderDetails fails', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        _buildWrapper(
          deliveryAddress: null,
          repo: MockOrdersRepositoryFailure(),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });

    testWidgets('shows Impossible de charger le suivi on error', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        _buildWrapper(
          deliveryAddress: null,
          repo: MockOrdersRepositoryFailure(),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Impossible de charger le suivi'),
        findsOneWidget,
      );
    });

    testWidgets('shows error failure message', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        _buildWrapper(
          deliveryAddress: null,
          repo: MockOrdersRepositoryFailure(),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('Commande introuvable'), findsOneWidget);
    });

    testWidgets('shows arrow_back icon in error AppBar', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        _buildWrapper(
          deliveryAddress: null,
          repo: MockOrdersRepositoryFailure(),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.arrow_back), findsAtLeastNWidgets(1));
    });

    testWidgets('shows Erreur AppBar title on failure', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        _buildWrapper(
          deliveryAddress: null,
          repo: MockOrdersRepositoryFailure(),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Erreur'), findsOneWidget);
    });

    testWidgets('shows TrackingPage after successful fetch', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        _buildWrapper(
          deliveryAddress: null,
          repo: MockOrdersRepositorySuccess(),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));
      // After fetch succeeds, renders TrackingPage
      expect(find.text('Suivi de livraison'), findsOneWidget);
    });
  });
}
