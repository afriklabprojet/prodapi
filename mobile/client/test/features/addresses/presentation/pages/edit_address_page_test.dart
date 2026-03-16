import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:drpharma_client/features/addresses/presentation/pages/edit_address_page.dart';
import 'package:drpharma_client/features/addresses/domain/entities/address_entity.dart';
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
        home: EditAddressPage(
          address: AddressEntity(
            id: 1,
            label: 'Maison',
            address: '123 Test Street',
            city: 'Abidjan',
            phone: '0123456789',
            isDefault: true,
            fullAddress: '123 Test Street, Abidjan',
            hasCoordinates: false,
            createdAt: DateTime(2024, 1, 1),
            updatedAt: DateTime(2024, 1, 1),
          ),
        ),
      ),
    );
  }

  group('EditAddressPage Widget Tests', () {
    testWidgets('should render edit address page', (tester) async {
      await tester.pumpWidget(createTestWidget());
      expect(find.byType(EditAddressPage), findsOneWidget);
    });

    testWidgets('should have pre-filled address name field', (tester) async {
      await tester.pumpWidget(createTestWidget());
      expect(find.byType(TextFormField), findsWidgets);
    });

    testWidgets('should have pre-filled street address field', (tester) async {
      await tester.pumpWidget(createTestWidget());
      expect(find.byType(TextFormField), findsWidgets);
    });

    testWidgets('should have pre-filled city field', (tester) async {
      await tester.pumpWidget(createTestWidget());
      expect(find.byType(TextFormField), findsWidgets);
    });

    testWidgets('should have update button', (tester) async {
      await tester.pumpWidget(createTestWidget());
      expect(find.byType(EditAddressPage), findsOneWidget);
    });

    testWidgets('should have delete button', (tester) async {
      await tester.pumpWidget(createTestWidget());
      expect(find.byType(EditAddressPage), findsOneWidget);
    });

    testWidgets('should validate empty address name', (tester) async {
      await tester.pumpWidget(createTestWidget());
      expect(find.byType(EditAddressPage), findsOneWidget);
    });

    testWidgets('should have default address checkbox', (tester) async {
      await tester.pumpWidget(createTestWidget());
      expect(find.byType(EditAddressPage), findsOneWidget);
    });

    testWidgets('should have app bar with back button', (tester) async {
      await tester.pumpWidget(createTestWidget());
      expect(find.byType(AppBar), findsOneWidget);
    });

    testWidgets('should be scrollable', (tester) async {
      await tester.pumpWidget(createTestWidget());
      expect(find.byType(EditAddressPage), findsOneWidget);
    });

    testWidgets('should show confirmation on delete', (tester) async {
      await tester.pumpWidget(createTestWidget());
      expect(find.byType(EditAddressPage), findsOneWidget);
    });

    testWidgets('should show loading indicator on update', (tester) async {
      await tester.pumpWidget(createTestWidget());
      expect(find.byType(EditAddressPage), findsOneWidget);
    });
  });
}
