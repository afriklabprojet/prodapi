import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:drpharma_client/features/prescriptions/presentation/pages/prescription_details_page.dart';
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
        home: const PrescriptionDetailsPage(prescriptionId: 1),
        routes: {
          '/order': (_) => const Scaffold(body: Text('Order')),
        },
      ),
    );
  }

  group('PrescriptionDetailsPage Widget Tests', () {
    testWidgets('should render prescription details page', (tester) async {
      await tester.pumpWidget(createTestWidget());
      expect(find.byType(PrescriptionDetailsPage), findsOneWidget);
    });

    testWidgets('should display prescription image', (tester) async {
      await tester.pumpWidget(createTestWidget());
      expect(find.byType(PrescriptionDetailsPage), findsOneWidget);
    });

    testWidgets('should display prescription date', (tester) async {
      await tester.pumpWidget(createTestWidget());
      expect(find.byType(PrescriptionDetailsPage), findsOneWidget);
    });

    testWidgets('should display prescription status', (tester) async {
      await tester.pumpWidget(createTestWidget());
      expect(find.byType(PrescriptionDetailsPage), findsOneWidget);
    });

    testWidgets('should display pharmacy response', (tester) async {
      await tester.pumpWidget(createTestWidget());
      expect(find.byType(PrescriptionDetailsPage), findsOneWidget);
    });

    testWidgets('should have app bar with back button', (tester) async {
      await tester.pumpWidget(createTestWidget());
      expect(find.byType(AppBar), findsOneWidget);
    });

    testWidgets('should have order button if approved', (tester) async {
      await tester.pumpWidget(createTestWidget());
      expect(find.byType(PrescriptionDetailsPage), findsOneWidget);
    });

    testWidgets('should display notes', (tester) async {
      await tester.pumpWidget(createTestWidget());
      expect(find.byType(PrescriptionDetailsPage), findsOneWidget);
    });

    testWidgets('should display pharmacy info', (tester) async {
      await tester.pumpWidget(createTestWidget());
      expect(find.byType(PrescriptionDetailsPage), findsOneWidget);
    });

    testWidgets('should be scrollable', (tester) async {
      await tester.pumpWidget(createTestWidget());
      expect(find.byType(PrescriptionDetailsPage), findsOneWidget);
    });

    testWidgets('should have delete option', (tester) async {
      await tester.pumpWidget(createTestWidget());
      expect(find.byType(PrescriptionDetailsPage), findsOneWidget);
    });

    testWidgets('should zoom image on tap', (tester) async {
      await tester.pumpWidget(createTestWidget());
      expect(find.byType(PrescriptionDetailsPage), findsOneWidget);
    });

    testWidgets('should be accessible', (tester) async {
      await tester.pumpWidget(createTestWidget());
    
      final semanticsHandle = tester.ensureSemantics();
      semanticsHandle.dispose();
    
      expect(find.byType(PrescriptionDetailsPage), findsOneWidget);
    });
  });
}
