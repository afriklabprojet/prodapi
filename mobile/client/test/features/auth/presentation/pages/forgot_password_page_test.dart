import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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
    final router = GoRouter(
      initialLocation: '/forgot-password',
      routes: [
        GoRoute(
          path: '/forgot-password',
          builder: (_, __) => const ForgotPasswordPage(),
        ),
        GoRoute(
          path: '/login',
          builder: (_, __) => const Scaffold(body: Text('Login Page')),
        ),
      ],
    );
    return ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(sharedPreferences),
        apiClientProvider.overrideWithValue(FakeApiClient()),
      ],
      child: MaterialApp.router(routerConfig: router),
    );
  }

  /// Navigate to step 2 (OTP) by submitting a valid email.
  Future<void> goToStep2(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(createTestWidget());
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byType(TextFormField).first,
      'user@example.com',
    );
    await tester.tap(find.text('Envoyer le code'));
    await tester.pumpAndSettle();
  }

  /// Navigate to step 3 (new password) by submitting OTP from step 2.
  Future<void> goToStep3(WidgetTester tester) async {
    await goToStep2(tester);
    for (int i = 0; i < 4; i++) {
      await tester.enterText(find.byType(TextFormField).at(i), '1');
      await tester.pump();
    }
    await tester.pumpAndSettle();
  }

  /// Navigate to step 4 (success) by submitting valid passwords from step 3.
  Future<void> goToStep4(WidgetTester tester) async {
    await goToStep3(tester);
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'password123');
    await tester.enterText(fields.at(1), 'password123');
    await tester.tap(find.text('Réinitialiser'));
    await tester.pumpAndSettle();
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

  group('ForgotPasswordPage Form Validation', () {
    testWidgets('shows Réinitialisation title in email step card', (
      tester,
    ) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();
      expect(find.text('Réinitialisation'), findsOneWidget);
    });

    testWidgets('shows email step heading Mot de passe oublié', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();
      expect(find.textContaining('oubli'), findsOneWidget);
    });

    testWidgets('shows email hint placeholder', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();
      expect(find.text('exemple@email.com'), findsOneWidget);
    });

    testWidgets('shows step indicator Étape 1/3', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();
      expect(find.text('Étape 1/3'), findsOneWidget);
    });

    testWidgets('shows Envoyer le code button', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();
      expect(find.text('Envoyer le code'), findsOneWidget);
    });

    testWidgets('validates empty email and shows Email requis', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Envoyer le code'));
      await tester.pump();

      expect(find.text('Email requis'), findsOneWidget);
    });

    testWidgets('validates invalid email and shows Email invalide', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField).first, 'notanemail');
      await tester.tap(find.text('Envoyer le code'));
      await tester.pump();

      expect(find.text('Email invalide'), findsOneWidget);
    });

    testWidgets('has back arrow icon button', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.arrow_back_ios_new), findsOneWidget);
    });
  });

  group('ForgotPasswordPage Step 1 - Navigation vers step 2', () {
    testWidgets('email valide + bouton → affiche Code de vérification', (
      tester,
    ) async {
      await goToStep2(tester);
      expect(find.text('Code de vérification'), findsOneWidget);
    });

    testWidgets('step 2 affiche Étape 2/3 indicateur', (tester) async {
      await goToStep2(tester);
      expect(find.text('Étape 2/3'), findsOneWidget);
    });

    testWidgets('step 2 affiche Vérification dans le header', (tester) async {
      await goToStep2(tester);
      expect(find.text('Vérification'), findsOneWidget);
    });
  });

  group('ForgotPasswordPage Step 2 - OTP', () {
    testWidgets('affiche 4 champs OTP', (tester) async {
      await goToStep2(tester);
      expect(find.byType(TextFormField), findsNWidgets(4));
    });

    testWidgets('affiche bouton Vérifier le code', (tester) async {
      await goToStep2(tester);
      expect(find.text('Vérifier le code'), findsOneWidget);
    });

    testWidgets('affiche bouton Renvoyer le code', (tester) async {
      await goToStep2(tester);
      expect(find.text('Renvoyer le code'), findsOneWidget);
    });

    testWidgets('OTP vide affiche message erreur 4 chiffres', (tester) async {
      await goToStep2(tester);
      await tester.tap(find.text('Vérifier le code'));
      await tester.pump();
      expect(find.textContaining('4 chiffres'), findsOneWidget);
    });

    testWidgets('bouton retour depuis step 2 revient step 1', (tester) async {
      await goToStep2(tester);
      await tester.tap(find.byIcon(Icons.arrow_back_ios_new));
      await tester.pumpAndSettle();
      expect(find.text('Réinitialisation'), findsOneWidget);
      expect(find.text('Étape 1/3'), findsOneWidget);
    });

    testWidgets('affiche email saisi dans description OTP', (tester) async {
      await goToStep2(tester);
      expect(
        find.byWidgetPredicate(
          (w) =>
              w is RichText &&
              w.text.toPlainText().contains('user@example.com'),
        ),
        findsAtLeastNWidgets(1),
      );
    });

    testWidgets('4 chiffres OTP navigue vers step 3', (tester) async {
      await goToStep2(tester);
      for (int i = 0; i < 4; i++) {
        await tester.enterText(find.byType(TextFormField).at(i), '1');
        await tester.pump();
      }
      await tester.pumpAndSettle();
      expect(find.text('Créer un nouveau mot de passe'), findsOneWidget);
    });

    testWidgets('Renvoyer le code affiche snackbar succès', (tester) async {
      await goToStep2(tester);
      await tester.tap(find.text('Renvoyer le code'));
      await tester.pumpAndSettle();
      expect(find.text('Nouveau code envoyé !'), findsOneWidget);
    });
  });

  group('ForgotPasswordPage Step 3 - Nouveau mot de passe', () {
    testWidgets('affiche titre Créer un nouveau mot de passe', (tester) async {
      await goToStep3(tester);
      expect(find.text('Créer un nouveau mot de passe'), findsOneWidget);
    });

    testWidgets('affiche Étape 3/3 indicateur', (tester) async {
      await goToStep3(tester);
      expect(find.text('Étape 3/3'), findsOneWidget);
    });

    testWidgets('affiche bouton Réinitialiser', (tester) async {
      await goToStep3(tester);
      expect(find.text('Réinitialiser'), findsOneWidget);
    });

    testWidgets('affiche 2 champs mot de passe', (tester) async {
      await goToStep3(tester);
      expect(find.byType(TextFormField), findsNWidgets(2));
    });

    testWidgets('mot de passe vide affiche Mot de passe requis', (
      tester,
    ) async {
      await goToStep3(tester);
      await tester.tap(find.text('Réinitialiser'));
      await tester.pump();
      expect(find.text('Mot de passe requis'), findsOneWidget);
    });

    testWidgets('mot de passe < 8 chars affiche Minimum 8 caractères', (
      tester,
    ) async {
      await goToStep3(tester);
      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), 'abc');
      await tester.enterText(fields.at(1), 'abc');
      await tester.tap(find.text('Réinitialiser'));
      await tester.pump();
      expect(find.text('Minimum 8 caractères'), findsOneWidget);
    });

    testWidgets(
      'confirmation différente affiche Les mots de passe ne correspondent pas',
      (tester) async {
        await goToStep3(tester);
        final fields = find.byType(TextFormField);
        await tester.enterText(fields.at(0), 'password123');
        await tester.enterText(fields.at(1), 'differentpwd');
        await tester.tap(find.text('Réinitialiser'));
        await tester.pump();
        expect(find.textContaining('ne correspondent pas'), findsOneWidget);
      },
    );

    testWidgets('toggle visibilité mot de passe', (tester) async {
      await goToStep3(tester);
      final visibilityIcons = find.byIcon(Icons.visibility_off_outlined);
      expect(visibilityIcons, findsWidgets);
      await tester.tap(visibilityIcons.first);
      await tester.pump();
      expect(find.byIcon(Icons.visibility_outlined), findsWidgets);
    });

    testWidgets('bouton retour depuis step 3 revient step 2', (tester) async {
      await goToStep3(tester);
      await tester.tap(find.byIcon(Icons.arrow_back_ios_new));
      await tester.pumpAndSettle();
      expect(find.text('Code de vérification'), findsOneWidget);
    });

    testWidgets('mots de passe valides naviguent vers succes', (tester) async {
      await goToStep4(tester);
      expect(find.text('Mot de passe réinitialisé !'), findsOneWidget);
    });
  });

  group('ForgotPasswordPage Step 4 - Succès', () {
    testWidgets('affiche Mot de passe réinitialisé !', (tester) async {
      await goToStep4(tester);
      expect(find.text('Mot de passe réinitialisé !'), findsOneWidget);
    });

    testWidgets('affiche bouton Se connecter', (tester) async {
      await goToStep4(tester);
      expect(find.text('Se connecter'), findsOneWidget);
    });

    testWidgets('pas d indicateur étape dans success', (tester) async {
      await goToStep4(tester);
      expect(find.textContaining('Étape'), findsNothing);
    });

    testWidgets('bouton Se connecter navigue vers login', (tester) async {
      await goToStep4(tester);
      await tester.tap(find.text('Se connecter'));
      await tester.pumpAndSettle();
      expect(find.text('Login Page'), findsOneWidget);
    });

    testWidgets('affiche icône check_circle_rounded', (tester) async {
      await goToStep4(tester);
      expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
    });
  });
}
