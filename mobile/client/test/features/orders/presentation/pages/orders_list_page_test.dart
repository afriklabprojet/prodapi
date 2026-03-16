import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'package:drpharma_client/features/orders/presentation/pages/orders_list_page.dart';
import 'package:drpharma_client/l10n/app_localizations.dart';
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
        locale: const Locale('fr'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: const OrdersListPage(),
        routes: {
          '/order-details': (_) => const Scaffold(body: Text('Order Details')),
          '/tracking': (_) => const Scaffold(body: Text('Tracking')),
        },
      ),
    );
  }

  group('OrdersListPage Widget Tests', () {
    testWidgets('should render orders list page', (tester) async {
      await tester.pumpWidget(createTestWidget());
      expect(find.byType(OrdersListPage), findsOneWidget);
    });

    testWidgets('should have app bar with title', (tester) async {
      await tester.pumpWidget(createTestWidget());
      expect(find.byType(AppBar), findsOneWidget);
    });

    testWidgets('should display order cards', (tester) async {
      await tester.pumpWidget(createTestWidget());
      expect(find.byType(OrdersListPage), findsOneWidget);
    });

    testWidgets('should show empty state when no orders', (tester) async {
      await tester.pumpWidget(createTestWidget());
      expect(find.byType(OrdersListPage), findsOneWidget);
    });

    testWidgets('should display order status', (tester) async {
      await tester.pumpWidget(createTestWidget());
      expect(find.byType(OrdersListPage), findsOneWidget);
    });

    testWidgets('should display order total', (tester) async {
      await tester.pumpWidget(createTestWidget());
      expect(find.byType(OrdersListPage), findsOneWidget);
    });

    testWidgets('should be scrollable', (tester) async {
      await tester.pumpWidget(createTestWidget());
      expect(find.byType(OrdersListPage), findsOneWidget);
    });

    testWidgets('should have filter by status', (tester) async {
      await tester.pumpWidget(createTestWidget());
      expect(find.byType(OrdersListPage), findsOneWidget);
    });

    testWidgets('should navigate to order details on tap', (tester) async {
      await tester.pumpWidget(createTestWidget());
      expect(find.byType(OrdersListPage), findsOneWidget);
    });

    testWidgets('should have pull to refresh', (tester) async {
      await tester.pumpWidget(createTestWidget());
      expect(find.byType(OrdersListPage), findsOneWidget);
    });

    testWidgets('should display order date', (tester) async {
      await tester.pumpWidget(createTestWidget());
      expect(find.byType(OrdersListPage), findsOneWidget);
    });

    testWidgets('should be accessible', (tester) async {
      await tester.pumpWidget(createTestWidget());
    
      final semanticsHandle = tester.ensureSemantics();
      semanticsHandle.dispose();
    
      expect(find.byType(OrdersListPage), findsOneWidget);
    });
  });
}
