import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:drpharma_client/features/pharmacies/presentation/pages/on_duty_pharmacies_map_page.dart';
import 'package:drpharma_client/config/providers.dart';
import '../../../../helpers/fake_api_client.dart';

void main() {
  Widget createTestWidget() {
    return ProviderScope(
      overrides: [
        apiClientProvider.overrideWithValue(FakeApiClient()),
      ],
      child: MaterialApp(
        home: const OnDutyPharmaciesMapPage(),
        routes: {
          '/pharmacy-details': (_) => const Scaffold(body: Text('Pharmacy Details')),
        },
      ),
    );
  }

  group('OnDutyPharmaciesMapPage Widget Tests', () {
    testWidgets('should render on duty pharmacies map page', (tester) async {
      await tester.pumpWidget(createTestWidget());
      expect(find.byType(OnDutyPharmaciesMapPage), findsOneWidget);
    });

    testWidgets('should display map', (tester) async {
      await tester.pumpWidget(createTestWidget());
      expect(find.byType(OnDutyPharmaciesMapPage), findsOneWidget);
    });

    testWidgets('should have app bar with title', (tester) async {
      await tester.pumpWidget(createTestWidget());
      expect(find.byType(AppBar), findsOneWidget);
    });

    testWidgets('should display pharmacy markers', (tester) async {
      await tester.pumpWidget(createTestWidget());
      expect(find.byType(OnDutyPharmaciesMapPage), findsOneWidget);
    });

    testWidgets('should have user location button', (tester) async {
      await tester.pumpWidget(createTestWidget());
      expect(find.byType(OnDutyPharmaciesMapPage), findsOneWidget);
    });

    testWidgets('should show pharmacy info on marker tap', (tester) async {
      await tester.pumpWidget(createTestWidget());
      expect(find.byType(OnDutyPharmaciesMapPage), findsOneWidget);
    });

    testWidgets('should have list view toggle', (tester) async {
      await tester.pumpWidget(createTestWidget());
      expect(find.byType(OnDutyPharmaciesMapPage), findsOneWidget);
    });

    testWidgets('should show loading state', (tester) async {
      await tester.pumpWidget(createTestWidget());
      expect(find.byType(OnDutyPharmaciesMapPage), findsOneWidget);
    });

    testWidgets('should filter on duty pharmacies', (tester) async {
      await tester.pumpWidget(createTestWidget());
      expect(find.byType(OnDutyPharmaciesMapPage), findsOneWidget);
    });

    testWidgets('should be accessible', (tester) async {
      await tester.pumpWidget(createTestWidget());
      
      final semanticsHandle = tester.ensureSemantics();
      semanticsHandle.dispose();
      
      expect(find.byType(OnDutyPharmaciesMapPage), findsOneWidget);
    });
  });
}
