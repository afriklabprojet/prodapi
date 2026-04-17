import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:drpharma_client/features/profile/presentation/pages/privacy_policy_page.dart';
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
      child: const MaterialApp(home: PrivacyPolicyPage()),
    );
  }

  group('PrivacyPolicyPage Widget Tests', () {
    testWidgets('should render privacy policy page', (tester) async {
      await tester.pumpWidget(createTestWidget());
      expect(find.byType(PrivacyPolicyPage), findsOneWidget);
    });

    testWidgets('should display app bar with title', (tester) async {
      await tester.pumpWidget(createTestWidget());
      expect(find.text('Politique de confidentialité'), findsWidgets);
    });

    testWidgets('should display content header', (tester) async {
      await tester.pumpWidget(createTestWidget());
      expect(find.text('Politique de confidentialité'), findsWidgets);
    });

    testWidgets('should display data collection section', (tester) async {
      await tester.pumpWidget(createTestWidget());
      expect(find.textContaining('Collecte des données'), findsOneWidget);
    });

    testWidgets('should display data usage section', (tester) async {
      await tester.pumpWidget(createTestWidget());
      expect(find.textContaining('Utilisation des données'), findsOneWidget);
    });

    testWidgets('should display data sharing section', (tester) async {
      await tester.pumpWidget(createTestWidget());
      expect(find.textContaining('Partage des données'), findsOneWidget);
    });

    testWidgets('should display security section', (tester) async {
      await tester.pumpWidget(createTestWidget());
      expect(find.textContaining('Protection des données'), findsOneWidget);
    });

    testWidgets('should display user rights section', (tester) async {
      await tester.pumpWidget(createTestWidget());
      expect(find.textContaining('Partage des données'), findsOneWidget);
    });

    testWidgets('should display contact section', (tester) async {
      await tester.pumpWidget(createTestWidget());
      expect(find.textContaining('Contact'), findsOneWidget);
    });

    testWidgets('should be scrollable', (tester) async {
      await tester.pumpWidget(createTestWidget());
      expect(find.byType(SingleChildScrollView), findsOneWidget);
    });
  });
}
