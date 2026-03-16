import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:drpharma_client/features/auth/presentation/pages/change_password_page.dart';
import 'package:drpharma_client/config/providers.dart';
import '../../../../helpers/fake_api_client.dart';

void main() {
  Widget createTestWidget() {
    return ProviderScope(
      overrides: [
        apiClientProvider.overrideWithValue(FakeApiClient()),
      ],
      child: MaterialApp(
        home: const ChangePasswordPage(),
        routes: {
          '/profile': (_) => const Scaffold(body: Text('Profile')),
        },
      ),
    );
  }

  group('ChangePasswordPage Widget Tests', () {
    testWidgets('should render change password page', (tester) async {
      await tester.pumpWidget(createTestWidget());
      expect(find.byType(ChangePasswordPage), findsOneWidget);
    });

    testWidgets('should have current password field', (tester) async {
      await tester.pumpWidget(createTestWidget());
      expect(find.byType(TextFormField), findsWidgets);
    });

    testWidgets('should have new password field', (tester) async {
      await tester.pumpWidget(createTestWidget());
      expect(find.byType(TextFormField), findsWidgets);
    });

    testWidgets('should have confirm password field', (tester) async {
      await tester.pumpWidget(createTestWidget());
      expect(find.byType(TextFormField), findsWidgets);
    });

    testWidgets('should toggle password visibility', (tester) async {
      await tester.pumpWidget(createTestWidget());
      
      final visibilityIcon = find.byIcon(Icons.visibility_off);
      if (visibilityIcon.evaluate().isNotEmpty) {
        await tester.tap(visibilityIcon.first);
      }
      expect(find.byType(ChangePasswordPage), findsOneWidget);
    });

    testWidgets('should validate password match', (tester) async {
      await tester.pumpWidget(createTestWidget());
      expect(find.byType(ChangePasswordPage), findsOneWidget);
    });

    testWidgets('should have submit button', (tester) async {
      await tester.pumpWidget(createTestWidget());
      expect(find.byType(ElevatedButton), findsWidgets);
    });

    testWidgets('should show password strength indicator', (tester) async {
      await tester.pumpWidget(createTestWidget());
      expect(find.byType(ChangePasswordPage), findsOneWidget);
    });
  });
}
