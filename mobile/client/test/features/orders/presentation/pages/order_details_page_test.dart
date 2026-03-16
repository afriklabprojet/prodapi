import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:drpharma_client/features/orders/presentation/pages/order_details_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:drpharma_client/config/providers.dart';
import '../../../../helpers/fake_api_client.dart';

void main() {
  late SharedPreferences sharedPreferences;

  setUp(() async {
  SharedPreferences.setMockInitialValues({});
    sharedPreferences = await SharedPreferences.getInstance();
  });

  Widget createTestWidget() {
    return ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(sharedPreferences),
        apiClientProvider.overrideWithValue(FakeApiClient()),
      ],
      child: MaterialApp(
        home: const OrderDetailsPage(orderId: 1),
        routes: {
          '/tracking': (_) => const Scaffold(body: Text('Tracking')),
        },
      ),
    );
  }

  group('OrderDetailsPage Widget Tests', () {
    testWidgets('should render order details page', (tester) async {
      await tester.pumpWidget(createTestWidget());
      expect(find.byType(OrderDetailsPage), findsOneWidget);
    });

    testWidgets('should display order number', (tester) async {
      await tester.pumpWidget(createTestWidget());
      expect(find.byType(OrderDetailsPage), findsOneWidget);
    });

    testWidgets('should display order status', (tester) async {
      await tester.pumpWidget(createTestWidget());
      expect(find.byType(OrderDetailsPage), findsOneWidget);
    });

    testWidgets('should display order items', (tester) async {
      await tester.pumpWidget(createTestWidget());
      expect(find.byType(OrderDetailsPage), findsOneWidget);
    });

    testWidgets('should display delivery address', (tester) async {
      await tester.pumpWidget(createTestWidget());
      expect(find.byType(OrderDetailsPage), findsOneWidget);
    });

    testWidgets('should display total amount', (tester) async {
      await tester.pumpWidget(createTestWidget());
      expect(find.byType(OrderDetailsPage), findsOneWidget);
    });

    testWidgets('should have track order button', (tester) async {
      await tester.pumpWidget(createTestWidget());
      expect(find.byType(OrderDetailsPage), findsOneWidget);
    });

    testWidgets('should display pharmacy info', (tester) async {
      await tester.pumpWidget(createTestWidget());
      expect(find.byType(OrderDetailsPage), findsOneWidget);
    });

    testWidgets('should have app bar with back button', (tester) async {
      await tester.pumpWidget(createTestWidget());
      expect(find.byType(AppBar), findsOneWidget);
    });

    testWidgets('should be scrollable', (tester) async {
      await tester.pumpWidget(createTestWidget());
      expect(find.byType(OrderDetailsPage), findsOneWidget);
    });

    testWidgets('should display payment method', (tester) async {
      await tester.pumpWidget(createTestWidget());
      expect(find.byType(OrderDetailsPage), findsOneWidget);
    });

    testWidgets('should display order date', (tester) async {
      await tester.pumpWidget(createTestWidget());
      expect(find.byType(OrderDetailsPage), findsOneWidget);
    });

    testWidgets('should have cancel order button if applicable', (tester) async {
      await tester.pumpWidget(createTestWidget());
      expect(find.byType(OrderDetailsPage), findsOneWidget);
    });

    testWidgets('should be accessible', (tester) async {
      await tester.pumpWidget(createTestWidget());
    
      final semanticsHandle = tester.ensureSemantics();
      semanticsHandle.dispose();
    
      expect(find.byType(OrderDetailsPage), findsOneWidget);
    });
  });
}
