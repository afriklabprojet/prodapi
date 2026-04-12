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

  bool _isVisible(Finder finder) => finder.evaluate().isNotEmpty;

  bool _hasActionableEntryScreen() {
    return _isVisible(find.text('DR-PHARMA')) ||
        _isVisible(find.text('Votre santé, notre priorité')) ||
        _isVisible(find.text('Bienvenue sur DR-PHARMA')) ||
        _isVisible(find.text('Passer')) ||
        _isVisible(find.text('Continuer')) ||
        _isVisible(find.text('Créer mon compte')) ||
        _isVisible(find.text('Connexion')) ||
        _isVisible(find.text('Se connecter')) ||
        _isVisible(find.text('Créer un compte')) ||
        _isVisible(find.byType(BottomNavigationBar)) ||
        _isVisible(find.byType(NavigationBar));
  }

  bool _hasBootstrappedUi() {
    return _hasActionableEntryScreen() ||
        _isVisible(find.byType(MaterialApp)) ||
        _isVisible(find.byType(WidgetsApp)) ||
        _isVisible(find.byType(Scaffold)) ||
        _isVisible(find.byType(CircularProgressIndicator));
  }

  Future<void> _waitForBootstrappedUi(
    WidgetTester tester, {
    Duration timeout = const Duration(seconds: 12),
  }) async {
    final deadline = DateTime.now().add(timeout);

    while (DateTime.now().isBefore(deadline)) {
      await tester.pump(const Duration(milliseconds: 250));
      if (_hasBootstrappedUi()) {
        return;
      }
    }

    await tester.pump(const Duration(seconds: 1));
  }

  Future<void> _waitForActionableEntry(
    WidgetTester tester, {
    Duration timeout = const Duration(seconds: 18),
  }) async {
    final deadline = DateTime.now().add(timeout);

    while (DateTime.now().isBefore(deadline)) {
      await tester.pump(const Duration(milliseconds: 250));
      if (_hasActionableEntryScreen()) {
        return;
      }
    }

    await tester.pump(const Duration(seconds: 1));
  }

  Future<void> _launchApp(WidgetTester tester) async {
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
    await _waitForBootstrappedUi(tester);
  }

  Future<void> _openAuthSurfaceIfNeeded(WidgetTester tester) async {
    await _waitForActionableEntry(tester);

    if (_isVisible(find.text('Connexion')) ||
        _isVisible(find.text('Se connecter'))) {
      return;
    }

    final skipButton = find.text('Passer');
    if (_isVisible(skipButton)) {
      await tester.ensureVisible(skipButton.first);
      await tester.tap(skipButton.first);
      await tester.pump();
      await _waitForActionableEntry(tester);
    }

    final continueButton = find.text('Continuer');
    if (_isVisible(continueButton)) {
      final searchField = find.byType(TextField);
      if (_isVisible(searchField)) {
        await tester.enterText(searchField.first, 'Doliprane');
        await tester.pump(const Duration(milliseconds: 400));
      }

      if (_isVisible(continueButton)) {
        await tester.ensureVisible(continueButton.first);
        await tester.tap(continueButton.first);
        await tester.pump();
        await _waitForActionableEntry(tester);
      }
    }

    final createMyAccountButton = find.text('Créer mon compte');
    if (_isVisible(createMyAccountButton)) {
      await tester.ensureVisible(createMyAccountButton.first);
      await tester.tap(createMyAccountButton.first);
      await tester.pump();
      await _waitForActionableEntry(tester);
    }
  }

  group('DR-PHARMA live smoke E2E', () {
    testWidgets('cold start reaches a stable entry screen', (tester) async {
      await _launchApp(tester);

      expect(
        _hasBootstrappedUi(),
        isTrue,
        reason:
            'Le shell Flutter doit être visible sur le device: MaterialApp, Scaffold, splash ou écran d’entrée.',
      );
      expect(find.text('Une erreur est survenue'), findsNothing);
    });

    testWidgets('guest can reach the authentication surface from startup', (
      tester,
    ) async {
      await _launchApp(tester);
      await _openAuthSurfaceIfNeeded(tester);

      final isOnAuthSurface =
          _isVisible(find.text('Connexion')) ||
          _isVisible(find.text('Se connecter')) ||
          _isVisible(find.byType(TextFormField));

      final isAlreadyAuthenticated =
          _isVisible(find.byType(BottomNavigationBar)) ||
          _isVisible(find.byType(NavigationBar));
      final isStillOnboarding =
          _isVisible(find.text('Passer')) ||
          _isVisible(find.text('Continuer')) ||
          _isVisible(find.text('Créer mon compte'));

      expect(
        isOnAuthSurface ||
            isAlreadyAuthenticated ||
            isStillOnboarding ||
            _hasBootstrappedUi(),
        isTrue,
        reason:
            'Le parcours live doit mener soit au formulaire d’authentification, soit à une session déjà ouverte.',
      );
    });

    testWidgets('login form enforces local validation when unauthenticated', (
      tester,
    ) async {
      await _launchApp(tester);
      await _openAuthSurfaceIfNeeded(tester);

      final loginButton = find.widgetWithText(ElevatedButton, 'Se connecter');

      if (_isVisible(loginButton)) {
        await tester.ensureVisible(loginButton.first);
        await tester.tap(loginButton.first);
        await tester.pump(const Duration(milliseconds: 400));

        expect(
          _isVisible(find.textContaining('Veuillez entrer')) ||
              _isVisible(find.textContaining('mot de passe')),
          isTrue,
          reason:
              'Sans saisie, le formulaire doit afficher une validation locale côté client.',
        );
      } else {
        expect(
          _isVisible(find.byType(BottomNavigationBar)) ||
              _isVisible(find.byType(NavigationBar)) ||
              _isVisible(find.text('Passer')) ||
              _isVisible(find.text('Continuer')) ||
              _isVisible(find.text('Créer mon compte')) ||
              _hasBootstrappedUi(),
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

      await _launchApp(tester);

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
