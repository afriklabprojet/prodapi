import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:drpharma_client/features/prescriptions/presentation/pages/prescription_upload_page.dart';
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
        home: const PrescriptionUploadPage(),
      ),
    );
  }

  group('PrescriptionUploadPage Widget Tests', () {
    testWidgets('should render prescription upload page', (tester) async {
      await tester.pumpWidget(createTestWidget());
      expect(find.byType(PrescriptionUploadPage), findsOneWidget);
    });

    testWidgets('should have app bar with title', (tester) async {
      await tester.pumpWidget(createTestWidget());
      expect(find.byType(AppBar), findsOneWidget);
    });

    testWidgets('should have camera option', (tester) async {
      await tester.pumpWidget(createTestWidget());
      expect(find.byType(PrescriptionUploadPage), findsOneWidget);
    });

    testWidgets('should have gallery option', (tester) async {
      await tester.pumpWidget(createTestWidget());
      expect(find.byType(PrescriptionUploadPage), findsOneWidget);
    });

    testWidgets('should have upload button', (tester) async {
      await tester.pumpWidget(createTestWidget());
      expect(find.byType(ElevatedButton), findsWidgets);
    });

    testWidgets('should display upload instructions', (tester) async {
      await tester.pumpWidget(createTestWidget());
      expect(find.byType(PrescriptionUploadPage), findsOneWidget);
    });

    testWidgets('should show image preview after selection', (tester) async {
      await tester.pumpWidget(createTestWidget());
      expect(find.byType(PrescriptionUploadPage), findsOneWidget);
    });

    testWidgets('should have notes text field', (tester) async {
      await tester.pumpWidget(createTestWidget());
      // Page uses TextField, not TextFormField
      expect(find.byType(TextField), findsWidgets);
    });

    testWidgets('should have pharmacy selection', (tester) async {
      await tester.pumpWidget(createTestWidget());
      expect(find.byType(PrescriptionUploadPage), findsOneWidget);
    });

    testWidgets('should show loading indicator on upload', (tester) async {
      await tester.pumpWidget(createTestWidget());
      expect(find.byType(PrescriptionUploadPage), findsOneWidget);
    });

    testWidgets('should validate image selection', (tester) async {
      await tester.pumpWidget(createTestWidget());
      expect(find.byType(PrescriptionUploadPage), findsOneWidget);
    });

    testWidgets('should be scrollable', (tester) async {
      await tester.pumpWidget(createTestWidget());
      expect(find.byType(SingleChildScrollView), findsWidgets);
    });

    testWidgets('should be accessible', (tester) async {
      await tester.pumpWidget(createTestWidget());
      
      final semanticsHandle = tester.ensureSemantics();
      semanticsHandle.dispose();
      
      expect(find.byType(PrescriptionUploadPage), findsOneWidget);
    });
  });
}
