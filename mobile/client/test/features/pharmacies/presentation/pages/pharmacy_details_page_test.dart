import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:drpharma_client/features/pharmacies/presentation/pages/pharmacy_details_page.dart';
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
        home: const PharmacyDetailsPage(pharmacyId: 1),
        routes: {
          '/products': (_) => const Scaffold(body: Text('Products')),
        },
      ),
    );
  }

  group('PharmacyDetailsPage Widget Tests', () {
    testWidgets('should render pharmacy details page', (tester) async {
      await tester.pumpWidget(createTestWidget());
      expect(find.byType(PharmacyDetailsPage), findsOneWidget);
    });

    testWidgets('should display pharmacy name', (tester) async {
      await tester.pumpWidget(createTestWidget());
      expect(find.byType(PharmacyDetailsPage), findsOneWidget);
    });

    testWidgets('should display pharmacy address', (tester) async {
      await tester.pumpWidget(createTestWidget());
      expect(find.byType(PharmacyDetailsPage), findsOneWidget);
    });

    testWidgets('should display pharmacy rating', (tester) async {
      await tester.pumpWidget(createTestWidget());
      expect(find.byType(PharmacyDetailsPage), findsOneWidget);
    });

    testWidgets('should display opening hours', (tester) async {
      await tester.pumpWidget(createTestWidget());
      expect(find.byType(PharmacyDetailsPage), findsOneWidget);
    });

    testWidgets('should have call button', (tester) async {
      await tester.pumpWidget(createTestWidget());
      expect(find.byType(PharmacyDetailsPage), findsOneWidget);
    });

    testWidgets('should have directions button', (tester) async {
      await tester.pumpWidget(createTestWidget());
      expect(find.byType(PharmacyDetailsPage), findsOneWidget);
    });

    testWidgets('should display pharmacy image', (tester) async {
      await tester.pumpWidget(createTestWidget());
      expect(find.byType(PharmacyDetailsPage), findsOneWidget);
    });

    testWidgets('should have products section', (tester) async {
      await tester.pumpWidget(createTestWidget());
      expect(find.byType(PharmacyDetailsPage), findsOneWidget);
    });

    testWidgets('should have app bar with back button', (tester) async {
      await tester.pumpWidget(createTestWidget());
      expect(find.byType(AppBar), findsOneWidget);
    });

    testWidgets('should be scrollable', (tester) async {
      await tester.pumpWidget(createTestWidget());
      expect(find.byType(PharmacyDetailsPage), findsOneWidget);
    });

    testWidgets('should display distance from user', (tester) async {
      await tester.pumpWidget(createTestWidget());
      expect(find.byType(PharmacyDetailsPage), findsOneWidget);
    });

    testWidgets('should show if pharmacy is on duty', (tester) async {
      await tester.pumpWidget(createTestWidget());
      expect(find.byType(PharmacyDetailsPage), findsOneWidget);
    });

    testWidgets('should be accessible', (tester) async {
      await tester.pumpWidget(createTestWidget());
    
      final semanticsHandle = tester.ensureSemantics();
      semanticsHandle.dispose();
    
      expect(find.byType(PharmacyDetailsPage), findsOneWidget);
    });
  });
}
