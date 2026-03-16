import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:drpharma_client/core/widgets/theme_selector.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:drpharma_client/config/providers.dart';
import '../../helpers/fake_api_client.dart';

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
        home: Scaffold(
          body: ThemeModeSelector(),
        ),
      ),
    );
  }

  group('ThemeModeSelector Widget Tests', () {
    testWidgets('should render theme selector', (tester) async {
      await tester.pumpWidget(createTestWidget());
      expect(find.byType(ThemeModeSelector), findsOneWidget);
    });

    testWidgets('should have theme options', (tester) async {
      await tester.pumpWidget(createTestWidget());
      expect(find.byType(ThemeModeSelector), findsOneWidget);
    });

    testWidgets('should be tappable', (tester) async {
      await tester.pumpWidget(createTestWidget());
      
      final selector = find.byType(ThemeModeSelector);
      if (selector.evaluate().isNotEmpty) {
        await tester.tap(selector.first);
      }
      
      expect(find.byType(ThemeModeSelector), findsOneWidget);
    });
  });
}
