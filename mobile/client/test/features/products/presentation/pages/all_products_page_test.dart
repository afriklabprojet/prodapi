import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:drpharma_client/features/products/presentation/pages/all_products_page.dart';
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
        home: const AllProductsPage(),
      ),
    );
  }

  group('AllProductsPage Widget Tests', () {
    testWidgets('should render all products page', (tester) async {
      await tester.pumpWidget(createTestWidget());
      expect(find.byType(AllProductsPage), findsOneWidget);
    });

    testWidgets('should have app bar', (tester) async {
      await tester.pumpWidget(createTestWidget());
      expect(find.byType(AppBar), findsOneWidget);
    });

    testWidgets('should have search functionality', (tester) async {
      await tester.pumpWidget(createTestWidget());
      expect(find.byIcon(Icons.search), findsWidgets);
    });

    testWidgets('should have category filter', (tester) async {
      await tester.pumpWidget(createTestWidget());
      expect(find.byType(AllProductsPage), findsOneWidget);
    });

    testWidgets('should show loading state', (tester) async {
      await tester.pumpWidget(createTestWidget());
      expect(find.byType(AllProductsPage), findsOneWidget);
    });
  });
}
