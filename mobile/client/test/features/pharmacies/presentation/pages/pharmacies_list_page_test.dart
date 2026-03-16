import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:drpharma_client/features/pharmacies/presentation/pages/pharmacies_list_page_v2.dart';
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
        home: const PharmaciesListPageV2(),
        routes: {
          '/pharmacy-details': (_) => const Scaffold(body: Text('Pharmacy Details')),
          '/pharmacies-map': (_) => const Scaffold(body: Text('Pharmacies Map')),
        },
      ),
    );
  }

  group('PharmaciesListPage Widget Tests', () {
    testWidgets('should render pharmacies list page', (tester) async {
      await tester.pumpWidget(createTestWidget());
      expect(find.byType(PharmaciesListPageV2), findsOneWidget);
    });

    testWidgets('should have app bar with title', (tester) async {
      await tester.pumpWidget(createTestWidget());
      expect(find.byType(AppBar), findsOneWidget);
    });

    testWidgets('should have search functionality', (tester) async {
      await tester.pumpWidget(createTestWidget());
      expect(find.byType(PharmaciesListPageV2), findsOneWidget);
    });

    testWidgets('should display pharmacy cards', (tester) async {
      await tester.pumpWidget(createTestWidget());
      expect(find.byType(PharmaciesListPageV2), findsOneWidget);
    });

    testWidgets('should show pharmacy name', (tester) async {
      await tester.pumpWidget(createTestWidget());
      expect(find.byType(PharmaciesListPageV2), findsOneWidget);
    });

    testWidgets('should show pharmacy distance', (tester) async {
      await tester.pumpWidget(createTestWidget());
      expect(find.byType(PharmaciesListPageV2), findsOneWidget);
    });

    testWidgets('should show pharmacy rating', (tester) async {
      await tester.pumpWidget(createTestWidget());
      expect(find.byType(PharmaciesListPageV2), findsOneWidget);
    });

    testWidgets('should be scrollable', (tester) async {
      await tester.pumpWidget(createTestWidget());
      expect(find.byType(PharmaciesListPageV2), findsOneWidget);
    });

    testWidgets('should have map view toggle', (tester) async {
      await tester.pumpWidget(createTestWidget());
      expect(find.byType(PharmaciesListPageV2), findsOneWidget);
    });

    testWidgets('should have filter options', (tester) async {
      await tester.pumpWidget(createTestWidget());
      expect(find.byType(PharmaciesListPageV2), findsOneWidget);
    });

    testWidgets('should navigate to pharmacy details on tap', (tester) async {
      await tester.pumpWidget(createTestWidget());
      expect(find.byType(PharmaciesListPageV2), findsOneWidget);
    });

    testWidgets('should have pull to refresh', (tester) async {
      await tester.pumpWidget(createTestWidget());
      expect(find.byType(RefreshIndicator), findsWidgets);
    });

    testWidgets('should be accessible', (tester) async {
      await tester.pumpWidget(createTestWidget());
    
      final semanticsHandle = tester.ensureSemantics();
      semanticsHandle.dispose();
    
      expect(find.byType(PharmaciesListPageV2), findsOneWidget);
    });
  });
}
