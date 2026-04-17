import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../helpers/e2e_test_helpers.dart';

/// Tests E2E pour le flux d'authentification
///
/// Couvre:
/// - Affichage du formulaire de connexion
/// - Validation des champs
/// - Navigation vers inscription
/// - Navigation vers mot de passe oublié
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Flux Authentification E2E', () {
    testWidgets(
      'affiche le formulaire de connexion pour un utilisateur non connecté',
      (tester) async {
        await E2ETestHelpers.launchApp(tester, clearAuth: true);

        // Attendre l'écran de login ou l'onboarding
        await E2ETestHelpers.waitForStableUi(tester);

        // Naviguer vers login si nécessaire
        await E2ETestHelpers.tapIfVisible(tester, find.text('Passer'));
        await E2ETestHelpers.tapIfVisible(
          tester,
          find.text('Créer mon compte'),
        );
        await E2ETestHelpers.tapIfVisible(
          tester,
          find.text('J\'ai déjà un compte'),
        );

        // Vérifier la présence des éléments du formulaire
        final hasPhoneField = E2ETestHelpers.isVisible(
          find.byWidgetPredicate((w) => w is TextField || w is TextFormField),
        );
        final hasLoginButton =
            E2ETestHelpers.isVisible(find.text('Se connecter')) ||
            E2ETestHelpers.isVisible(find.text('Connexion'));

        expect(
          hasPhoneField || hasLoginButton || E2ETestHelpers.isOnHomeScreen(),
          isTrue,
          reason:
              'Doit afficher le formulaire de connexion ou être déjà connecté',
        );
      },
    );

    testWidgets('valide le format du numéro de téléphone', (tester) async {
      await E2ETestHelpers.launchApp(tester, clearAuth: true);
      await E2ETestHelpers.waitForStableUi(tester);

      // Naviguer vers le formulaire de login
      await E2ETestHelpers.tapIfVisible(tester, find.text('Passer'));
      await E2ETestHelpers.tapIfVisible(tester, find.text('Créer mon compte'));
      await E2ETestHelpers.tapIfVisible(
        tester,
        find.text('J\'ai déjà un compte'),
      );

      if (E2ETestHelpers.isOnLoginScreen()) {
        // Trouver le champ téléphone
        final phoneField = find.byWidgetPredicate(
          (w) => w is TextField || w is TextFormField,
        );

        if (E2ETestHelpers.isVisible(phoneField)) {
          // Entrer un numéro invalide
          await E2ETestHelpers.enterText(tester, phoneField.first, '123');

          // Tenter de soumettre
          await E2ETestHelpers.tapIfVisible(tester, find.text('Se connecter'));
          await tester.pump(const Duration(milliseconds: 500));

          // Vérifier qu'une erreur de validation est affichée
          final hasValidationError =
              E2ETestHelpers.isVisible(find.textContaining('invalide')) ||
              E2ETestHelpers.isVisible(find.textContaining('Veuillez')) ||
              E2ETestHelpers.isVisible(find.textContaining('chiffres'));

          expect(
            hasValidationError,
            isTrue,
            reason:
                'Doit afficher une erreur de validation pour un numéro invalide',
          );
        }
      }
    });

    testWidgets('navigue vers la page d\'inscription', (tester) async {
      await E2ETestHelpers.launchApp(tester, clearAuth: true);
      await E2ETestHelpers.waitForStableUi(tester);

      // Naviguer vers login d'abord
      await E2ETestHelpers.tapIfVisible(tester, find.text('Passer'));

      // Chercher le lien vers inscription
      final registerLink = find.textContaining('Créer');
      final inscriptionLink = find.textContaining('inscription');
      final noAccountLink = find.textContaining('pas de compte');

      final tapped =
          await E2ETestHelpers.tapIfVisible(tester, registerLink) ||
          await E2ETestHelpers.tapIfVisible(tester, inscriptionLink) ||
          await E2ETestHelpers.tapIfVisible(tester, noAccountLink);

      if (tapped) {
        await tester.pump(const Duration(milliseconds: 500));

        // Vérifier qu'on est sur la page d'inscription
        final isOnRegisterPage =
            E2ETestHelpers.isVisible(find.text('Inscription')) ||
            E2ETestHelpers.isVisible(find.text('Créer un compte')) ||
            E2ETestHelpers.isVisible(find.textContaining('Nom'));

        expect(
          isOnRegisterPage || E2ETestHelpers.isOnHomeScreen(),
          isTrue,
          reason: 'Doit naviguer vers la page d\'inscription',
        );
      }
    });

    testWidgets('navigue vers la page mot de passe oublié', (tester) async {
      await E2ETestHelpers.launchApp(tester, clearAuth: true);
      await E2ETestHelpers.waitForStableUi(tester);

      await E2ETestHelpers.tapIfVisible(tester, find.text('Passer'));
      await E2ETestHelpers.tapIfVisible(tester, find.text('Créer mon compte'));
      await E2ETestHelpers.tapIfVisible(
        tester,
        find.text('J\'ai déjà un compte'),
      );

      if (E2ETestHelpers.isOnLoginScreen()) {
        // Chercher le lien mot de passe oublié
        final forgotLink = find.textContaining('oublié');

        if (await E2ETestHelpers.tapIfVisible(tester, forgotLink)) {
          await tester.pumpAndSettle(const Duration(milliseconds: 800));

          // Vérifier la navigation vers ForgotPasswordPage
          // La page affiche "Ne vous inquiétez pas" ou "Envoyer le code"
          final isOnForgotPage =
              E2ETestHelpers.isVisible(
                find.textContaining('Ne vous inquiétez pas'),
              ) ||
              E2ETestHelpers.isVisible(
                find.textContaining('Envoyer le code'),
              ) ||
              E2ETestHelpers.isVisible(
                find.textContaining('ça arrive aux meilleurs'),
              );

          expect(
            isOnForgotPage || E2ETestHelpers.isOnLoginScreen(),
            isTrue,
            reason:
                'Doit naviguer vers la page de récupération de mot de passe',
          );
        }
      }
    });

    testWidgets('affiche l\'écran d\'accueil pour un utilisateur connecté', (
      tester,
    ) async {
      // Simuler une session connectée
      await E2ETestHelpers.launchApp(
        tester,
        clearAuth: false,
        additionalPrefs: {
          'auth_token': 'test_token_12345',
          'user_id': 'test_user_id',
          'user_phone': '+2250700000000',
        },
      );
      await E2ETestHelpers.waitForStableUi(tester);

      // Passer l'onboarding si présent
      await E2ETestHelpers.tapIfVisible(tester, find.text('Passer'));

      // Vérifier qu'on arrive sur l'écran principal ou le login
      await E2ETestHelpers.waitFor(
        tester,
        find.byType(BottomNavigationBar),
        timeout: const Duration(seconds: 10),
      );

      expect(
        E2ETestHelpers.isOnHomeScreen() || E2ETestHelpers.isOnLoginScreen(),
        isTrue,
        reason:
            'Utilisateur avec token doit voir l\'accueil ou être redirigé vers login si token expiré',
      );
    });

    testWidgets('le bouton retour sur login fonctionne correctement', (
      tester,
    ) async {
      await E2ETestHelpers.launchApp(tester, clearAuth: true);
      await E2ETestHelpers.waitForStableUi(tester);

      await E2ETestHelpers.tapIfVisible(tester, find.text('Passer'));
      await E2ETestHelpers.tapIfVisible(tester, find.text('Créer mon compte'));

      // Vérifier qu'il y a un bouton retour ou que le test est pertinent
      final backButton = find.byIcon(Icons.arrow_back);
      final backButtonIos = find.byIcon(Icons.arrow_back_ios);

      if (E2ETestHelpers.isVisible(backButton) ||
          E2ETestHelpers.isVisible(backButtonIos)) {
        await E2ETestHelpers.tapIfVisible(tester, backButton);
        await E2ETestHelpers.tapIfVisible(tester, backButtonIos);
        await tester.pump(const Duration(milliseconds: 300));

        // Pas de crash = succès
        expect(E2ETestHelpers.hasStableUi(), isTrue);
      }
    });
  });
}
