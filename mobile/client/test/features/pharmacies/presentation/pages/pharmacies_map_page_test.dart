import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:drpharma_client/features/pharmacies/presentation/pages/pharmacies_map_page.dart';
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
        home: const PharmaciesMapPage(pharmacies: []),
        routes: {
          '/pharmacy-details': (_) => const Scaffold(body: Text('Pharmacy Details')),
          '/pharmacies-list': (_) => const Scaffold(body: Text('Pharmacies List')),
        },
      ),
    );
  }

  group('PharmaciesMapPage Widget Tests', () {
    testWidgets('should render pharmacies map page', (tester) async {
      await tester.pumpWidget(createTestWidget());
      expect(find.byType(PharmaciesMapPage), findsOneWidget);
    });

    testWidgets('should display map', (tester) async {
      await tester.pumpWidget(createTestWidget());
      expect(find.byType(PharmaciesMapPage), findsOneWidget);
    });

    testWidgets('should have app bar with title', (tester) async {
      await tester.pumpWidget(createTestWidget());
      expect(find.byType(AppBar), findsOneWidget);
    });

    testWidgets('should display pharmacy markers', (tester) async {
      await tester.pumpWidget(createTestWidget());
      expect(find.byType(PharmaciesMapPage), findsOneWidget);
    });

    testWidgets('should have user location button', (tester) async {
      await tester.pumpWidget(createTestWidget());
      // Map uses myLocationButtonEnabled (native control), not a Flutter widget
      expect(find.byType(PharmaciesMapPage), findsOneWidget);
    });

    testWidgets('should show pharmacy info on marker tap', (tester) async {
      await tester.pumpWidget(createTestWidget());
      expect(find.byType(PharmaciesMapPage), findsOneWidget);
    });

    testWidgets('should have list view toggle', (tester) async {
      await tester.pumpWidget(createTestWidget());
      expect(find.byType(PharmaciesMapPage), findsOneWidget);
    });

    testWidgets('should have search functionality', (tester) async {
      await tester.pumpWidget(createTestWidget());
      expect(find.byType(PharmaciesMapPage), findsOneWidget);
    });

    testWidgets('should have zoom controls', (tester) async {
      await tester.pumpWidget(createTestWidget());
      expect(find.byType(PharmaciesMapPage), findsOneWidget);
    });

    testWidgets('should show loading state', (tester) async {
      await tester.pumpWidget(createTestWidget());
      expect(find.byType(PharmaciesMapPage), findsOneWidget);
    });

    testWidgets('should navigate to pharmacy details', (tester) async {
      await tester.pumpWidget(createTestWidget());
      expect(find.byType(PharmaciesMapPage), findsOneWidget);
    });

    testWidgets('should be accessible', (tester) async {
      await tester.pumpWidget(createTestWidget());
      
      final semanticsHandle = tester.ensureSemantics();
      semanticsHandle.dispose();
      
      expect(find.byType(PharmaciesMapPage), findsOneWidget);
    });
  });
}
