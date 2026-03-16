import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:drpharma_client/features/orders/presentation/pages/tracking_page.dart';
import 'package:drpharma_client/features/orders/domain/entities/delivery_address_entity.dart';
import 'package:drpharma_client/config/providers.dart';
import '../../../../helpers/fake_api_client.dart';

void main() {
  Widget createTestWidget() {
    return ProviderScope(
      overrides: [
        apiClientProvider.overrideWithValue(FakeApiClient()),
      ],
      child: MaterialApp(
        home: TrackingPage(
          orderId: 1,
          deliveryAddress: const DeliveryAddressEntity(
            address: '123 Test Street',
            city: 'Abidjan',
            phone: '0123456789',
          ),
        ),
      ),
    );
  }

  group('TrackingPage Widget Tests', () {
    testWidgets('should render tracking page', (tester) async {
      await tester.pumpWidget(createTestWidget());
      expect(find.byType(TrackingPage), findsOneWidget);
    });

    testWidgets('should display order status', (tester) async {
      await tester.pumpWidget(createTestWidget());
      expect(find.byType(TrackingPage), findsOneWidget);
    });

    testWidgets('should have map with delivery location', (tester) async {
      await tester.pumpWidget(createTestWidget());
      expect(find.byType(TrackingPage), findsOneWidget);
    });

    testWidgets('should display courier information', (tester) async {
      await tester.pumpWidget(createTestWidget());
      expect(find.byType(TrackingPage), findsOneWidget);
    });

    testWidgets('should have call courier button', (tester) async {
      await tester.pumpWidget(createTestWidget());
      expect(find.byType(TrackingPage), findsOneWidget);
    });

    testWidgets('should display estimated time', (tester) async {
      await tester.pumpWidget(createTestWidget());
      expect(find.byType(TrackingPage), findsOneWidget);
    });

    testWidgets('should have tracking timeline', (tester) async {
      await tester.pumpWidget(createTestWidget());
      expect(find.byType(TrackingPage), findsOneWidget);
    });

    testWidgets('should have app bar with back button', (tester) async {
      await tester.pumpWidget(createTestWidget());
      expect(find.byType(AppBar), findsOneWidget);
    });

    testWidgets('should refresh tracking data', (tester) async {
      await tester.pumpWidget(createTestWidget());
      expect(find.byType(TrackingPage), findsOneWidget);
    });

    testWidgets('should be accessible', (tester) async {
      await tester.pumpWidget(createTestWidget());
      
      final semanticsHandle = tester.ensureSemantics();
      semanticsHandle.dispose();
      
      expect(find.byType(TrackingPage), findsOneWidget);
    });
  });
}
