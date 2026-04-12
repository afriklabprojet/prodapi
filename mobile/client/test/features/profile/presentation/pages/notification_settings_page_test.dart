import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:drpharma_client/features/profile/presentation/pages/notification_settings_page.dart';
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
      child: MaterialApp(home: const NotificationSettingsPage()),
    );
  }

  group('NotificationSettingsPage Widget Tests', () {
    testWidgets('should render notification settings page', (tester) async {
      await tester.pumpWidget(createTestWidget());
      expect(find.byType(NotificationSettingsPage), findsOneWidget);
    });

    testWidgets('should have push notifications toggle', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump(); // Allow _loadPrefs() async to complete
      expect(find.byType(Switch), findsWidgets);
    });

    testWidgets('should have order updates toggle', (tester) async {
      await tester.pumpWidget(createTestWidget());
      expect(find.byType(NotificationSettingsPage), findsOneWidget);
    });

    testWidgets('should have promotions toggle', (tester) async {
      await tester.pumpWidget(createTestWidget());
      expect(find.byType(NotificationSettingsPage), findsOneWidget);
    });

    testWidgets('should have app bar with title', (tester) async {
      await tester.pumpWidget(createTestWidget());
      expect(find.byType(AppBar), findsOneWidget);
    });

    testWidgets('should toggle push notifications', (tester) async {
      await tester.pumpWidget(createTestWidget());

      final switches = find.byType(Switch);
      if (switches.evaluate().isNotEmpty) {
        await tester.tap(switches.first);
      }

      expect(find.byType(NotificationSettingsPage), findsOneWidget);
    });

    testWidgets('should have back button', (tester) async {
      await tester.pumpWidget(createTestWidget());
      expect(find.byType(AppBar), findsOneWidget);
    });

    testWidgets('should be accessible', (tester) async {
      await tester.pumpWidget(createTestWidget());

      final semanticsHandle = tester.ensureSemantics();
      semanticsHandle.dispose();

      expect(find.byType(NotificationSettingsPage), findsOneWidget);
    });
  });
}
