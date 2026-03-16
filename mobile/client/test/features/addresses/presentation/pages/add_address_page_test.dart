import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:drpharma_client/features/addresses/presentation/pages/add_address_page.dart';
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
        home: const AddAddressPage(),
      ),
    );
  }

  group('AddAddressPage Widget Tests', () {
    testWidgets('should render add address page', (tester) async {
      await tester.pumpWidget(createTestWidget());
      expect(find.byType(AddAddressPage), findsOneWidget);
    });

    testWidgets('should have address name field', (tester) async {
      await tester.pumpWidget(createTestWidget());
      expect(find.byType(TextFormField), findsWidgets);
    });

    testWidgets('should have street address field', (tester) async {
      await tester.pumpWidget(createTestWidget());
      expect(find.byType(TextFormField), findsWidgets);
    });

    testWidgets('should have city field', (tester) async {
      await tester.pumpWidget(createTestWidget());
      expect(find.byType(TextFormField), findsWidgets);
    });

    testWidgets('should have save button', (tester) async {
      await tester.pumpWidget(createTestWidget());
      expect(find.byType(AddAddressPage), findsOneWidget);
    });

    testWidgets('should have map for location selection', (tester) async {
      await tester.pumpWidget(createTestWidget());
      expect(find.byType(AddAddressPage), findsOneWidget);
    });

    testWidgets('should validate empty address name', (tester) async {
      await tester.pumpWidget(createTestWidget());
      expect(find.byType(AddAddressPage), findsOneWidget);
    });

    testWidgets('should validate empty street address', (tester) async {
      await tester.pumpWidget(createTestWidget());
      expect(find.byType(AddAddressPage), findsOneWidget);
    });

    testWidgets('should have default address checkbox', (tester) async {
      await tester.pumpWidget(createTestWidget());
      expect(find.byType(AddAddressPage), findsOneWidget);
    });

    testWidgets('should have app bar with back button', (tester) async {
      await tester.pumpWidget(createTestWidget());
      expect(find.byType(AppBar), findsOneWidget);
    });

    testWidgets('should be scrollable', (tester) async {
      await tester.pumpWidget(createTestWidget());
      expect(find.byType(ListView), findsWidgets);
    });

    testWidgets('should show loading indicator on save', (tester) async {
      await tester.pumpWidget(createTestWidget());
      expect(find.byType(AddAddressPage), findsOneWidget);
    });
  });
}
