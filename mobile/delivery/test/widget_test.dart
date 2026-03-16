// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:courier/presentation/screens/splash_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:courier/core/services/secure_token_service.dart';
import 'helpers/widget_test_helpers.dart';

void main() {
  setUpAll(() async {
    await initHiveForTests();
  });

  tearDownAll(() async {
    await cleanupHiveForTests();
  });

  testWidgets('App renders splash screen on launch', (WidgetTester tester) async {
    // Initialiser les mocks nécessaires pour éviter les erreurs de platform channels
    SharedPreferences.setMockInitialValues({});
    SecureTokenService.enableTestMode();

    await tester.pumpWidget(
      ProviderScope(
        overrides: commonWidgetTestOverrides(),
        child: const MaterialApp(home: SplashScreen()),
      ),
    );

    // Pump one frame to render initial state
    await tester.pump();

    // Le splash screen affiche le logo DR-PHARMA et LIVREUR
    expect(find.text('DR-PHARMA'), findsOneWidget);
    expect(find.text('LIVREUR'), findsOneWidget);

    // Advance past all pending timers:
    // - Firebase.initializeApp().timeout(4s) resolves at t=4s
    // - _routeUser 800ms delay fires at ~t=4.8s → navigates → dispose cancels remaining timers
    await tester.pump(const Duration(seconds: 6));
  });
}
