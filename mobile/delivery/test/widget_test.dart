// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

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

    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const SplashScreen(),
        ),
        GoRoute(
          path: '/login',
          builder: (context, state) => const SizedBox.shrink(),
        ),
        GoRoute(
          path: '/dashboard',
          builder: (context, state) => const SizedBox.shrink(),
        ),
        GoRoute(
          path: '/onboarding',
          builder: (context, state) => const SizedBox.shrink(),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: commonWidgetTestOverrides(),
        child: MaterialApp.router(routerConfig: router),
      ),
    );

    await tester.pump();

    expect(find.text('DR-PHARMA'), findsOneWidget);
    expect(find.text('LIVREUR'), findsOneWidget);

    await tester.pump(const Duration(seconds: 6));
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 4));
  });
}
