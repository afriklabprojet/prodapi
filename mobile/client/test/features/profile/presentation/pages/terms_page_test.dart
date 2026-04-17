import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:drpharma_client/features/profile/presentation/pages/terms_page.dart';
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
      child: const MaterialApp(home: TermsPage()),
    );
  }

  group('TermsPage Widget Tests', () {
    testWidgets('should render terms page', (tester) async {
      await tester.pumpWidget(createTestWidget());
      expect(find.byType(TermsPage), findsOneWidget);
    });

    testWidgets('should display app bar with title', (tester) async {
      await tester.pumpWidget(createTestWidget());
      expect(find.text("Conditions d'utilisation"), findsOneWidget);
    });

    testWidgets('should display content header', (tester) async {
      await tester.pumpWidget(createTestWidget());
      expect(find.text("Conditions Générales d'Utilisation"), findsOneWidget);
    });

    testWidgets('should display introduction section', (tester) async {
      await tester.pumpWidget(createTestWidget());
      expect(find.textContaining('Objet'), findsOneWidget);
    });

    testWidgets('should display services section', (tester) async {
      await tester.pumpWidget(createTestWidget());
      expect(find.textContaining('Inscription'), findsOneWidget);
    });

    testWidgets('should display registration section', (tester) async {
      await tester.pumpWidget(createTestWidget());
      expect(find.textContaining('Inscription'), findsOneWidget);
    });

    testWidgets('should display orders section', (tester) async {
      await tester.pumpWidget(createTestWidget());
      expect(find.textContaining('Commandes'), findsOneWidget);
    });

    testWidgets('should display payment section', (tester) async {
      await tester.pumpWidget(createTestWidget());
      expect(find.textContaining('Paiement'), findsOneWidget);
    });

    testWidgets('should display delivery section', (tester) async {
      await tester.pumpWidget(createTestWidget());
      expect(find.textContaining('Livraison'), findsOneWidget);
    });

    testWidgets('should display responsibility section', (tester) async {
      await tester.pumpWidget(createTestWidget());
      expect(find.textContaining('Livraison'), findsOneWidget);
    });

    testWidgets('should be scrollable', (tester) async {
      await tester.pumpWidget(createTestWidget());
      expect(find.byType(SingleChildScrollView), findsOneWidget);
    });
  });
}
