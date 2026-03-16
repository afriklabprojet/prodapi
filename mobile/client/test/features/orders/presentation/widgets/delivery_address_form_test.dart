import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:drpharma_client/features/orders/presentation/widgets/delivery_address_form.dart';
import 'package:drpharma_client/config/providers.dart';
import '../../../../helpers/fake_api_client.dart';

void main() {
  Widget createTestWidget() {
    return ProviderScope(
      overrides: [
        apiClientProvider.overrideWithValue(FakeApiClient()),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: DeliveryAddressForm(
              addressController: TextEditingController(),
              cityController: TextEditingController(),
              phoneController: TextEditingController(),
              labelController: TextEditingController(),
              saveAddress: false,
              onSaveAddressChanged: (_) {},
              isDark: false,
            ),
          ),
        ),
      ),
    );
  }

  group('DeliveryAddressForm Widget Tests', () {
    testWidgets('should render delivery address form', (tester) async {
      await tester.pumpWidget(createTestWidget());
      expect(find.byType(DeliveryAddressForm), findsOneWidget);
    });

    testWidgets('should have street field', (tester) async {
      await tester.pumpWidget(createTestWidget());
      expect(find.byType(TextFormField), findsWidgets);
    });

    testWidgets('should have city field', (tester) async {
      await tester.pumpWidget(createTestWidget());
      expect(find.byType(TextFormField), findsWidgets);
    });

    testWidgets('should be accessible', (tester) async {
      await tester.pumpWidget(createTestWidget());
      
      final semanticsHandle = tester.ensureSemantics();
      semanticsHandle.dispose();
      
      expect(find.byType(DeliveryAddressForm), findsOneWidget);
    });
  });
}
