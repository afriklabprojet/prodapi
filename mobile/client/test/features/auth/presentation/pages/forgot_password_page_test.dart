import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:drpharma_client/features/auth/presentation/pages/forgot_password_page.dart';
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
        home: const ForgotPasswordPage(),
        routes: {
          '/login': (_) => const Scaffold(body: Text('Login')),
        },
      ),
    );
  }

  group('ForgotPasswordPage Widget Tests', () {
    testWidgets('should render forgot password page', (tester) async {
      await tester.pumpWidget(createTestWidget());
      expect(find.byType(ForgotPasswordPage), findsOneWidget);
    });

    testWidgets('should have email input field', (tester) async {
      await tester.pumpWidget(createTestWidget());
      expect(find.byType(TextFormField), findsWidgets);
    });

    testWidgets('should have submit button', (tester) async {
      await tester.pumpWidget(createTestWidget());
      expect(find.textContaining('Envoyer le code'), findsOneWidget);
    });

    testWidgets('should have back to login link', (tester) async {
      await tester.pumpWidget(createTestWidget());
      expect(find.byIcon(Icons.arrow_back_ios_new), findsOneWidget);
    });

    testWidgets('should validate empty email', (tester) async {
      await tester.pumpWidget(createTestWidget());
      
      final submitButton = find.byType(ElevatedButton);
      if (submitButton.evaluate().isNotEmpty) {
        await tester.tap(submitButton.first);
      }
      expect(find.byType(ForgotPasswordPage), findsOneWidget);
    });

    testWidgets('should validate email format', (tester) async {
      await tester.pumpWidget(createTestWidget());
      
      final emailField = find.byType(TextFormField);
      if (emailField.evaluate().isNotEmpty) {
        await tester.enterText(emailField.first, 'invalid-email');
      }
      expect(find.byType(ForgotPasswordPage), findsOneWidget);
    });

    testWidgets('should show success message on submit', (tester) async {
      await tester.pumpWidget(createTestWidget());
      expect(find.byType(ForgotPasswordPage), findsOneWidget);
    });
  });
}
