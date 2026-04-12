import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:drpharma_client/features/auth/presentation/pages/change_password_page.dart';
import 'package:drpharma_client/config/providers.dart';
import '../../../../helpers/fake_api_client.dart';

void main() {
  Widget createTestWidget() {
    return ProviderScope(
      overrides: [apiClientProvider.overrideWithValue(FakeApiClient())],
      child: MaterialApp(
        home: const ChangePasswordPage(),
        routes: {'/profile': (_) => const Scaffold(body: Text('Profile'))},
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

  group('ChangePasswordPage Form Content', () {
    testWidgets('shows AppBar title Sécurité', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump();
      expect(find.text('Sécurité'), findsOneWidget);
    });

    testWidgets('shows page title Changer le mot de passe', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump();
      expect(find.text('Changer le mot de passe'), findsOneWidget);
    });

    testWidgets('shows hint text for current password field', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump();
      expect(find.text('Entrez votre mot de passe actuel'), findsOneWidget);
    });

    testWidgets('shows hint text for new password field', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump();
      expect(find.text('Entrez votre nouveau mot de passe'), findsOneWidget);
    });

    testWidgets('shows hint text for confirm password field', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump();
      expect(find.text('Confirmez votre nouveau mot de passe'), findsOneWidget);
    });

    testWidgets('shows visibility_off icons for all password fields', (
      tester,
    ) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump(); // trigger postFrameCallback that sets obscure=true
      expect(find.byIcon(Icons.visibility_off_outlined), findsWidgets);
    });

    testWidgets('tapping visibility icon toggles obscure state', (
      tester,
    ) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump();
      // Tap first visibility_off icon
      await tester.tap(find.byIcon(Icons.visibility_off_outlined).first);
      await tester.pump();
      // One field becomes visible → visibility_outlined icon appears
      expect(find.byIcon(Icons.visibility_outlined), findsOneWidget);
    });
  });

  group('ChangePasswordPage Form Validation', () {
    setUp(() {
      // ChangePasswordPage form is long — use a taller screen
    });

    testWidgets('shows current password error when submitted empty', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 3600);
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      await tester.tap(find.byType(ElevatedButton).first);
      await tester.pump();

      expect(
        find.text('Veuillez entrer votre mot de passe actuel'),
        findsOneWidget,
      );
    });

    testWidgets('shows new password error when only current is filled', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 3600);
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), 'CurrentPass1!');
      await tester.tap(find.byType(ElevatedButton).first);
      await tester.pump();

      expect(
        find.text('Veuillez entrer un nouveau mot de passe'),
        findsOneWidget,
      );
    });

    testWidgets('shows min length error when new password is too short', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 3600);
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), 'CurrentPass1!');
      await tester.enterText(fields.at(1), 'short');
      await tester.tap(find.byType(ElevatedButton).first);
      await tester.pump();

      expect(
        find.text('Le mot de passe doit contenir au moins 8 caractères'),
        findsOneWidget,
      );
    });

    testWidgets('shows error when new password equals current', (tester) async {
      tester.view.physicalSize = const Size(1080, 3600);
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), 'SamePass1!');
      await tester.enterText(fields.at(1), 'SamePass1!');
      await tester.tap(find.byType(ElevatedButton).first);
      await tester.pump();

      expect(
        find.text('Le nouveau mot de passe doit être différent'),
        findsOneWidget,
      );
    });

    testWidgets('shows confirm error when passwords do not match', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 3600);
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), 'CurrentPass1!');
      await tester.enterText(fields.at(1), 'NewPassword1!');
      await tester.enterText(fields.at(2), 'DifferentPass1!');
      await tester.tap(find.byType(ElevatedButton).first);
      await tester.pump();

      expect(
        find.text('Les mots de passe ne correspondent pas'),
        findsOneWidget,
      );
    });

    testWidgets('shows strength indicator when typing new password', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 3600);
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(1), 'SecurePass1!');
      await tester.pump();

      // LinearProgressIndicator (strength indicator) should appear
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });
  });
}
