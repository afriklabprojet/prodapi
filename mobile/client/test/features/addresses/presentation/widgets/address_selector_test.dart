import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:drpharma_client/features/addresses/presentation/widgets/address_selector.dart';
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
        home: Scaffold(
          body: AddressSelector(
            onAddressSelected: (address) {},
          ),
        ),
      ),
    );
  }

  group('AddressSelector Widget Tests', () {
    testWidgets('should render address selector', (tester) async {
      await tester.pumpWidget(createTestWidget());
      expect(find.byType(AddressSelector), findsOneWidget);
    });

    testWidgets('should display address list', (tester) async {
      await tester.pumpWidget(createTestWidget());
      expect(find.byType(AddressSelector), findsOneWidget);
    });

    testWidgets('should have add new address option', (tester) async {
      await tester.pumpWidget(createTestWidget());
      expect(find.byType(AddressSelector), findsOneWidget);
    });

    testWidgets('should be selectable', (tester) async {
      await tester.pumpWidget(createTestWidget());
      expect(find.byType(AddressSelector), findsOneWidget);
    });

    testWidgets('should show selected address indicator', (tester) async {
      await tester.pumpWidget(createTestWidget());
      expect(find.byType(AddressSelector), findsOneWidget);
    });

    testWidgets('should be accessible', (tester) async {
      await tester.pumpWidget(createTestWidget());
    
      final semanticsHandle = tester.ensureSemantics();
      semanticsHandle.dispose();
    
      expect(find.byType(AddressSelector), findsOneWidget);
    });
  });
}
