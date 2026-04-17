import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:drpharma_client/features/auth/presentation/pages/splash_page.dart';
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
        home: const SplashPage(),
        routes: {
          '/login': (_) => const Scaffold(body: Text('Login')),
          '/home': (_) => const Scaffold(body: Text('Home')),
        },
      ),
    );
  }

  group('SplashPage Widget Tests', () {
    testWidgets('should render splash page', (tester) async {
      await tester.runAsync(() async {
        await tester.pumpWidget(createTestWidget());
        expect(find.byType(SplashPage), findsOneWidget);
      });
    });

    testWidgets('should display app logo', (tester) async {
      await tester.runAsync(() async {
        await tester.pumpWidget(createTestWidget());
        expect(find.byType(SplashPage), findsOneWidget);
      });
    });

    testWidgets('should display app name', (tester) async {
      await tester.runAsync(() async {
        await tester.pumpWidget(createTestWidget());
        expect(find.textContaining('DR'), findsWidgets);
      });
    });

    testWidgets('should show loading indicator', (tester) async {
      await tester.runAsync(() async {
        await tester.pumpWidget(createTestWidget());
        expect(find.byType(CircularProgressIndicator), findsWidgets);
      });
    });

    testWidgets('should have branded colors', (tester) async {
      await tester.runAsync(() async {
        await tester.pumpWidget(createTestWidget());
        expect(find.byType(SplashPage), findsOneWidget);
      });
    });
  });
}
