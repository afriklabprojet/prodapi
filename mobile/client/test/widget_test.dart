// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:drpharma_client/main.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:drpharma_client/config/providers.dart';
import 'helpers/fake_api_client.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Mock SharedPreferences
    SharedPreferences.setMockInitialValues({});
    final sharedPreferences = await SharedPreferences.getInstance();

    // Create a ProviderContainer for overrides
    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(sharedPreferences),
        apiClientProvider.overrideWithValue(FakeApiClient()),
      ],
    );

    // Build our app and trigger a frame.
    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const MyApp()),
    );

    // Use pump with duration instead of pumpAndSettle to avoid timeout with infinite animations
    // Pump enough time to complete splash page timer (2 seconds) and navigation
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(seconds: 2));
    await tester.pump(const Duration(milliseconds: 500));

    // Verify that the app starts (finds at least one Scaffold or Material app structure)
    expect(find.byType(MaterialApp), findsOneWidget);

    // Clean up container
    container.dispose();
  });
}
