import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:drpharma_client/features/profile/presentation/pages/legal_notices_page.dart';
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
        home: LegalNoticesPage(),
      ),
    );
  }

  group('LegalNoticesPage Widget Tests', () {
    testWidgets('should render legal notices page', (tester) async {
      await tester.pumpWidget(createTestWidget());
      expect(find.byType(LegalNoticesPage), findsOneWidget);
    });

    testWidgets('should display app bar with title', (tester) async {
      await tester.pumpWidget(createTestWidget());
      expect(find.text('Mentions Légales'), findsWidgets);
    });

    testWidgets('should display content header', (tester) async {
      await tester.pumpWidget(createTestWidget());
      expect(find.textContaining('Mentions Légales'), findsWidgets);
    });

    testWidgets('should display editor information', (tester) async {
      await tester.pumpWidget(createTestWidget());
      expect(find.textContaining('Éditeur'), findsOneWidget);
    });

    testWidgets('should display company information', (tester) async {
      await tester.pumpWidget(createTestWidget());
      expect(find.textContaining('AFRIK LAB'), findsOneWidget);
    });

    testWidgets('should display contact information', (tester) async {
      await tester.pumpWidget(createTestWidget());
      expect(find.textContaining('Contact'), findsOneWidget);
    });

    testWidgets('should display intellectual property section', (tester) async {
      await tester.pumpWidget(createTestWidget());
      expect(find.textContaining('Propriété intellectuelle'), findsOneWidget);
    });

    testWidgets('should be scrollable', (tester) async {
      await tester.pumpWidget(createTestWidget());
      expect(find.byType(SingleChildScrollView), findsOneWidget);
    });
  });
}
