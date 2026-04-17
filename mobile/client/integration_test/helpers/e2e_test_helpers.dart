import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:drpharma_client/config/providers.dart';
import 'package:drpharma_client/main.dart' as app;

/// Helpers partagés pour les tests d'intégration E2E
class E2ETestHelpers {
  /// Vérifie si un finder est visible
  static bool isVisible(Finder finder) => finder.evaluate().isNotEmpty;

  /// Lance l'application avec SharedPreferences configurées
  static Future<void> launchApp(
    WidgetTester tester, {
    bool skipOnboarding = true,
    bool clearAuth = true,
    Map<String, Object>? additionalPrefs,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    if (skipOnboarding) {
      await prefs.setBool('onboarding_completed', true);
    }

    if (clearAuth) {
      await prefs.remove('auth_token');
      await prefs.remove('user_data');
      await prefs.remove('access_token');
      await prefs.remove('user_id');
      await prefs.remove('user_email');
      await prefs.remove('user_name');
      await prefs.remove('user_phone');
    }

    if (additionalPrefs != null) {
      for (final entry in additionalPrefs.entries) {
        if (entry.value is String) {
          await prefs.setString(entry.key, entry.value as String);
        } else if (entry.value is bool) {
          await prefs.setBool(entry.key, entry.value as bool);
        } else if (entry.value is int) {
          await prefs.setInt(entry.key, entry.value as int);
        }
      }
    }

    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        child: const app.MyApp(),
      ),
    );
    await tester.pump();
    await waitForStableUi(tester);
  }

  /// Attend que l'UI soit stable
  static Future<void> waitForStableUi(
    WidgetTester tester, {
    Duration timeout = const Duration(seconds: 15),
  }) async {
    final deadline = DateTime.now().add(timeout);

    while (DateTime.now().isBefore(deadline)) {
      await tester.pump(const Duration(milliseconds: 250));
      if (hasStableUi()) {
        return;
      }
    }
    await tester.pump(const Duration(seconds: 1));
  }

  /// Vérifie si l'UI est dans un état stable
  static bool hasStableUi() {
    return isVisible(find.byType(Scaffold)) ||
        isVisible(find.byType(MaterialApp)) ||
        isVisible(find.byType(BottomNavigationBar)) ||
        isVisible(find.byType(NavigationBar));
  }

  /// Vérifie si on est sur l'écran d'accueil
  static bool isOnHomeScreen() {
    return isVisible(find.byType(BottomNavigationBar)) ||
        isVisible(find.byType(NavigationBar)) ||
        isVisible(find.text('Accueil')) ||
        isVisible(find.text('DR-PHARMA'));
  }

  /// Vérifie si on est sur l'écran de connexion
  static bool isOnLoginScreen() {
    return isVisible(find.text('Se connecter')) ||
        isVisible(find.text('Connexion')) ||
        isVisible(find.textContaining('numéro de téléphone'));
  }

  /// Attend un élément spécifique
  static Future<bool> waitFor(
    WidgetTester tester,
    Finder finder, {
    Duration timeout = const Duration(seconds: 10),
  }) async {
    final deadline = DateTime.now().add(timeout);

    while (DateTime.now().isBefore(deadline)) {
      await tester.pump(const Duration(milliseconds: 200));
      if (isVisible(finder)) {
        return true;
      }
    }
    return false;
  }

  /// Tap sur un élément s'il est visible
  static Future<bool> tapIfVisible(
    WidgetTester tester,
    Finder finder, {
    bool scrollIntoView = true,
  }) async {
    if (!isVisible(finder)) {
      return false;
    }

    if (scrollIntoView) {
      await tester.ensureVisible(finder.first);
    }
    await tester.tap(finder.first);
    await tester.pump(const Duration(milliseconds: 300));
    return true;
  }

  /// Entre du texte dans un champ
  static Future<void> enterText(
    WidgetTester tester,
    Finder finder,
    String text,
  ) async {
    await tester.ensureVisible(finder.first);
    await tester.tap(finder.first);
    await tester.pump();
    await tester.enterText(finder.first, text);
    await tester.pump(const Duration(milliseconds: 200));
  }

  /// Fait défiler pour trouver un élément
  static Future<bool> scrollToFind(
    WidgetTester tester,
    Finder finder, {
    Finder? scrollable,
    int maxScrolls = 10,
  }) async {
    final scroll = scrollable ?? find.byType(Scrollable).first;

    for (var i = 0; i < maxScrolls; i++) {
      if (isVisible(finder)) {
        return true;
      }
      await tester.drag(scroll, const Offset(0, -200));
      await tester.pump(const Duration(milliseconds: 200));
    }
    return isVisible(finder);
  }

  /// Navigue vers un onglet spécifique
  static Future<void> navigateToTab(WidgetTester tester, int tabIndex) async {
    final bottomNav = find.byType(BottomNavigationBar);
    final navBar = find.byType(NavigationBar);

    if (isVisible(bottomNav)) {
      final icons = find.descendant(of: bottomNav, matching: find.byType(Icon));
      if (icons.evaluate().length > tabIndex) {
        await tester.tap(icons.at(tabIndex));
        await tester.pump(const Duration(milliseconds: 300));
      }
    } else if (isVisible(navBar)) {
      final destinations = find.descendant(
        of: navBar,
        matching: find.byType(NavigationDestination),
      );
      if (destinations.evaluate().length > tabIndex) {
        await tester.tap(destinations.at(tabIndex));
        await tester.pump(const Duration(milliseconds: 300));
      }
    }
  }

  /// Attend la disparition d'un loader
  static Future<void> waitForLoaderToDisappear(
    WidgetTester tester, {
    Duration timeout = const Duration(seconds: 10),
  }) async {
    final deadline = DateTime.now().add(timeout);

    while (DateTime.now().isBefore(deadline)) {
      await tester.pump(const Duration(milliseconds: 200));
      if (!isVisible(find.byType(CircularProgressIndicator))) {
        return;
      }
    }
  }

  /// Prend un screenshot (pour debug)
  static Future<void> takeScreenshot(WidgetTester tester, String name) async {
    // En mode debug, on peut utiliser cette fonction pour capturer l'état
    // L'implémentation dépend de la configuration de test
    await tester.pump();
  }
}

/// Matchers personnalisés pour les tests E2E
class E2EMatchers {
  /// Vérifie qu'aucune erreur n'est affichée
  static Matcher get noErrorDisplayed =>
      isNot(find.text('Une erreur est survenue'));

  /// Vérifie qu'un loader n'est pas présent
  static Matcher get noLoaderDisplayed => findsNothing;
}

/// Configuration des timeouts pour les tests E2E
class E2ETimeouts {
  static const Duration shortAction = Duration(seconds: 3);
  static const Duration mediumAction = Duration(seconds: 8);
  static const Duration longAction = Duration(seconds: 15);
  static const Duration networkCall = Duration(seconds: 20);
  static const Duration appStartup = Duration(seconds: 12);
}
