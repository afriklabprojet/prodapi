import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:drpharma_client/features/profile/presentation/pages/help_support_page.dart';
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
      child: const MaterialApp(
        home: HelpSupportPage(),
      ),
    );
  }

  group('HelpSupportPage Widget Tests', () {
    testWidgets('should render help support page', (tester) async {
      await tester.pumpWidget(createTestWidget());
      expect(find.byType(HelpSupportPage), findsOneWidget);
    });

    testWidgets('should display app bar with title', (tester) async {
      await tester.pumpWidget(createTestWidget());
      expect(find.text('Aide & Support'), findsOneWidget);
    });

    testWidgets('should display FAQ section', (tester) async {
      await tester.pumpWidget(createTestWidget());
      expect(find.text('Questions fréquentes'), findsOneWidget);
    });

    testWidgets('should display FAQ items', (tester) async {
      await tester.pumpWidget(createTestWidget());
      // Wait for the async customerFaqProvider to resolve and render FAQ items
      await tester.pumpAndSettle();
      expect(find.text('Comment suivre ma commande ?'), findsOneWidget);
      expect(find.text('Comment payer ?'), findsOneWidget);
    });

    testWidgets('should display contact section', (tester) async {
      await tester.pumpWidget(createTestWidget());
      expect(find.text('Contactez-nous'), findsOneWidget);
    });

    testWidgets('should have email contact option', (tester) async {
      await tester.pumpWidget(createTestWidget());
      expect(find.text('Email'), findsOneWidget);
    });

    testWidgets('should have phone contact option', (tester) async {
      await tester.pumpWidget(createTestWidget());
      expect(find.text('Téléphone'), findsOneWidget);
    });

    testWidgets('should have WhatsApp contact option', (tester) async {
      await tester.pumpWidget(createTestWidget());
      expect(find.text('WhatsApp'), findsOneWidget);
    });

    testWidgets('should be scrollable', (tester) async {
      await tester.pumpWidget(createTestWidget());
      expect(find.byType(ListView), findsOneWidget);
    });
  });
}
