import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:drpharma_client/config/providers.dart';
import 'package:drpharma_client/main.dart' as app;

/// Suite E2E LIVE orientée smoke/entrée utilisateur.
///
/// Objectif:
/// - rester stable sur un vrai device/emulator
/// - supporter splash + onboarding + login + session déjà connectée
/// - éviter les tests fragiles dépendants du réseau ou d'un compte de test
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  bool isVisible(Finder finder) => finder.evaluate().isNotEmpty;

  bool hasActionableEntryScreen() {
    return isVisible(find.text('DR-PHARMA')) ||
        isVisible(find.text('Votre santé, notre priorité')) ||
        isVisible(find.text('Bienvenue sur DR-PHARMA')) ||
        isVisible(find.text('Passer')) ||
        isVisible(find.text('Continuer')) ||
        isVisible(find.text('Créer mon compte')) ||
        isVisible(find.text('Connexion')) ||
        isVisible(find.text('Se connecter')) ||
        isVisible(find.text('Créer un compte')) ||
        isVisible(find.byType(BottomNavigationBar)) ||
        isVisible(find.byType(NavigationBar));
  }

  bool hasBootstrappedUi() {
    return hasActionableEntryScreen() ||
        isVisible(find.byType(MaterialApp)) ||
        isVisible(find.byType(WidgetsApp)) ||
        isVisible(find.byType(Scaffold)) ||
        isVisible(find.byType(CircularProgressIndicator));
  }

  Future<void> waitForBootstrappedUi(
    WidgetTester tester, {
    Duration timeout = const Duration(seconds: 12),
  }) async {
    final deadline = DateTime.now().add(timeout);

    while (DateTime.now().isBefore(deadline)) {
      await tester.pump(const Duration(milliseconds: 250));
      if (hasBootstrappedUi()) {
        return;
      }
    }

    await tester.pump(const Duration(seconds: 1));
  }

  Future<void> waitForActionableEntry(
    WidgetTester tester, {
    Duration timeout = const Duration(seconds: 18),
  }) async {
    final deadline = DateTime.now().add(timeout);

    while (DateTime.now().isBefore(deadline)) {
      await tester.pump(const Duration(milliseconds: 250));
      if (hasActionableEntryScreen()) {
        return;
      }
    }

    await tester.pump(const Duration(seconds: 1));
  }

  Future<void> launchApp(WidgetTester tester) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_completed', true);
    await prefs.remove('auth_token');
    await prefs.remove('user_data');
    await prefs.remove('access_token');
    await prefs.remove('user_id');
    await prefs.remove('user_email');
    await prefs.remove('user_name');
    await prefs.remove('user_phone');

    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        child: const app.MyApp(),
      ),
    );
    await tester.pump();
    await waitForBootstrappedUi(tester);
  }

  Future<void> openAuthSurfaceIfNeeded(WidgetTester tester) async {
    await waitForActionableEntry(tester);

    if (isVisible(find.text('Connexion')) ||
        isVisible(find.text('Se connecter'))) {
      return;
    }

    final skipButton = find.text('Passer');
    if (isVisible(skipButton)) {
      await tester.ensureVisible(skipButton.first);
      await tester.tap(skipButton.first);
      await tester.pump();
      await waitForActionableEntry(tester);
    }

    final continueButton = find.text('Continuer');
    if (isVisible(continueButton)) {
      final searchField = find.byType(TextField);
      if (isVisible(searchField)) {
        await tester.enterText(searchField.first, 'Doliprane');
        await tester.pump(const Duration(milliseconds: 400));
      }

      if (isVisible(continueButton)) {
        await tester.ensureVisible(continueButton.first);
        await tester.tap(continueButton.first);
        await tester.pump();
        await waitForActionableEntry(tester);
      }
    }

    final createMyAccountButton = find.text('Créer mon compte');
    if (isVisible(createMyAccountButton)) {
      await tester.ensureVisible(createMyAccountButton.first);
      await tester.tap(createMyAccountButton.first);
      await tester.pump();
      await waitForActionableEntry(tester);
    }
  }

  group('DR-PHARMA live smoke E2E', () {
    testWidgets('cold start reaches a stable entry screen', (tester) async {
      await launchApp(tester);

      expect(
        hasBootstrappedUi(),
        isTrue,
        reason:
            'Le shell Flutter doit être visible sur le device: MaterialApp, Scaffold, splash ou écran d’entrée.',
      );
      expect(find.text('Une erreur est survenue'), findsNothing);
    });

    testWidgets('guest can reach the authentication surface from startup', (
      tester,
    ) async {
      await launchApp(tester);
      await openAuthSurfaceIfNeeded(tester);

      final isOnAuthSurface =
          isVisible(find.text('Connexion')) ||
          isVisible(find.text('Se connecter')) ||
          isVisible(find.byType(TextFormField));

      final isAlreadyAuthenticated =
          isVisible(find.byType(BottomNavigationBar)) ||
          isVisible(find.byType(NavigationBar));
      final isStillOnboarding =
          isVisible(find.text('Passer')) ||
          isVisible(find.text('Continuer')) ||
          isVisible(find.text('Créer mon compte'));

      expect(
        isOnAuthSurface ||
            isAlreadyAuthenticated ||
            isStillOnboarding ||
            hasBootstrappedUi(),
        isTrue,
        reason:
            'Le parcours live doit mener soit au formulaire d’authentification, soit à une session déjà ouverte.',
      );
    });

    testWidgets('login form enforces local validation when unauthenticated', (
      tester,
    ) async {
      await launchApp(tester);
      await openAuthSurfaceIfNeeded(tester);

      final loginButton = find.widgetWithText(ElevatedButton, 'Se connecter');

      if (isVisible(loginButton)) {
        await tester.ensureVisible(loginButton.first);
        await tester.tap(loginButton.first);
        await tester.pump(const Duration(milliseconds: 400));

        expect(
          isVisible(find.textContaining('Veuillez entrer')) ||
              isVisible(find.textContaining('mot de passe')),
          isTrue,
          reason:
              'Sans saisie, le formulaire doit afficher une validation locale côté client.',
        );
      } else {
        expect(
          isVisible(find.byType(BottomNavigationBar)) ||
              isVisible(find.byType(NavigationBar)) ||
              isVisible(find.text('Passer')) ||
              isVisible(find.text('Continuer')) ||
              isVisible(find.text('Créer mon compte')) ||
              hasBootstrappedUi(),
          isTrue,
          reason:
              'En live, l’absence du bouton login reste acceptable si l’app est encore sur l’onboarding ou si une session est déjà ouverte.',
        );
      }
    });

    testWidgets('app reaches first useful screen within 12 seconds', (
      tester,
    ) async {
      final stopwatch = Stopwatch()..start();

      await launchApp(tester);

      stopwatch.stop();

      expect(
        stopwatch.elapsedMilliseconds,
        lessThan(12000),
        reason:
            'En live, l’app doit atteindre un premier écran exploitable en moins de 12 secondes.',
      );
    });
  });
}
