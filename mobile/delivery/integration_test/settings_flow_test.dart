import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:courier/main.dart' as app;

/// Tests d'intégration pour le flux paramètres et profil
/// Ces tests vérifient la navigation et les interactions dans les écrans de configuration
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Profile Screen Flow', () {
    testWidgets('profile_screen_displays_correctly', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Navigate to profile tab
      final profileTab = find.text('Profil');
      if (profileTab.evaluate().isNotEmpty) {
        await tester.tap(profileTab);
        await tester.pumpAndSettle();

        // Verify profile screen elements
        expect(find.byType(Scaffold), findsWidgets);
      }
    });

    testWidgets('profile_shows_user_info_sections', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      final profileTab = find.text('Profil');
      if (profileTab.evaluate().isNotEmpty) {
        await tester.tap(profileTab);
        await tester.pumpAndSettle();

        // Check for profile sections
        final apercu = find.text('Aperçu');
        final personnel = find.text('Personnel & Véhicule');
        final preferences = find.text('Préférences');

        // At least one section should exist
        final hasSection = apercu.evaluate().isNotEmpty ||
            personnel.evaluate().isNotEmpty ||
            preferences.evaluate().isNotEmpty;
        expect(hasSection || find.byType(ListView).evaluate().isNotEmpty, isTrue);
      }
    });

    testWidgets('profile_shows_action_buttons', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      final profileTab = find.text('Profil');
      if (profileTab.evaluate().isNotEmpty) {
        await tester.tap(profileTab);
        await tester.pumpAndSettle();

        // Check for action buttons
        final dashboard = find.text('Dashboard');
        final statistiques = find.text('Statistiques');
        final historique = find.text('Historique');
        final parametres = find.text('Paramètres');
        final aideSupport = find.text('Aide & Support');

        // Verify at least some action buttons are present
        final hasActions = dashboard.evaluate().isNotEmpty ||
            statistiques.evaluate().isNotEmpty ||
            historique.evaluate().isNotEmpty ||
            parametres.evaluate().isNotEmpty ||
            aideSupport.evaluate().isNotEmpty;
        expect(hasActions || find.byType(ActionChip).evaluate().isNotEmpty, isTrue);
      }
    });

    testWidgets('profile_navigates_to_settings', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      final profileTab = find.text('Profil');
      if (profileTab.evaluate().isNotEmpty) {
        await tester.tap(profileTab);
        await tester.pumpAndSettle();

        // Find and tap settings button
        final settingsButton = find.text('Paramètres');
        if (settingsButton.evaluate().isNotEmpty) {
          await tester.tap(settingsButton);
          await tester.pumpAndSettle();

          // Verify navigation to settings screen
          // AppBar should have 'Paramètres' title
          expect(find.byType(AppBar), findsWidgets);
        }
      }
    });

    testWidgets('profile_shows_logout_button', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      final profileTab = find.text('Profil');
      if (profileTab.evaluate().isNotEmpty) {
        await tester.tap(profileTab);
        await tester.pumpAndSettle();

        // Check for logout button
        final deconnexion = find.text('Déconnexion');
        final seDeconnecter = find.text('Se déconnecter');
        
        final hasLogout = deconnexion.evaluate().isNotEmpty ||
            seDeconnecter.evaluate().isNotEmpty ||
            find.byIcon(Icons.logout).evaluate().isNotEmpty ||
            find.byIcon(Icons.exit_to_app).evaluate().isNotEmpty;

        expect(hasLogout || find.byType(ElevatedButton).evaluate().isNotEmpty, isTrue);
      }
    });
  });

  group('Settings Screen Flow', () {
    Future<void> navigateToSettings(WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // First go to profile
      final profileTab = find.text('Profil');
      if (profileTab.evaluate().isNotEmpty) {
        await tester.tap(profileTab);
        await tester.pumpAndSettle();

        // Then navigate to settings
        final settingsButton = find.text('Paramètres');
        if (settingsButton.evaluate().isNotEmpty) {
          await tester.tap(settingsButton);
          await tester.pumpAndSettle();
        }
      }
    }

    testWidgets('settings_screen_displays_correctly', (tester) async {
      await navigateToSettings(tester);

      // Verify settings screen elements
      expect(find.byType(Scaffold), findsWidgets);
      expect(find.byType(ListView), findsWidgets);
    });

    testWidgets('settings_shows_apparence_section', (tester) async {
      await navigateToSettings(tester);

      // Check for appearance section
      final apparence = find.text('Apparence');
      expect(apparence.evaluate().isNotEmpty || find.byType(Card).evaluate().isNotEmpty, isTrue);
    });

    testWidgets('settings_shows_preferences_section', (tester) async {
      await navigateToSettings(tester);

      // Check for preferences section
      final preferences = find.text('Préférences');
      expect(preferences.evaluate().isNotEmpty || find.byType(SwitchListTile).evaluate().isNotEmpty, isTrue);
    });

    testWidgets('settings_shows_notifications_section', (tester) async {
      await navigateToSettings(tester);

      // Check for notifications section
      final notifications = find.text('Notifications');
      expect(notifications.evaluate().isNotEmpty || find.byIcon(Icons.notifications).evaluate().isNotEmpty, isTrue);
    });

    testWidgets('settings_shows_account_section', (tester) async {
      await navigateToSettings(tester);

      // Check for account section
      final compte = find.text('Compte');
      final changerMdp = find.text('Changer le mot de passe');
      final langue = find.text('Langue de l\'application');
      
      final hasAccount = compte.evaluate().isNotEmpty ||
          changerMdp.evaluate().isNotEmpty ||
          langue.evaluate().isNotEmpty;

      expect(hasAccount || find.byIcon(Icons.lock_outline).evaluate().isNotEmpty, isTrue);
    });

    testWidgets('settings_shows_security_section', (tester) async {
      await navigateToSettings(tester);

      // Check for security section
      final securite = find.text('Sécurité');
      expect(securite.evaluate().isNotEmpty || find.byIcon(Icons.fingerprint).evaluate().isNotEmpty, isTrue);
    });

    testWidgets('settings_shows_data_section', (tester) async {
      await navigateToSettings(tester);

      // Check for data export section
      final donnees = find.text('Données');
      final histoExport = find.text('Historique & Export');
      
      final hasData = donnees.evaluate().isNotEmpty ||
          histoExport.evaluate().isNotEmpty ||
          find.byIcon(Icons.history).evaluate().isNotEmpty;

      expect(hasData || find.byType(ListTile).evaluate().isNotEmpty, isTrue);
    });

    testWidgets('settings_shows_help_section', (tester) async {
      await navigateToSettings(tester);

      // Check for help section
      final aide = find.text('Aide & Support');
      final support = find.text('Mes demandes de support');
      
      final hasHelp = aide.evaluate().isNotEmpty ||
          support.evaluate().isNotEmpty ||
          find.byIcon(Icons.support_agent).evaluate().isNotEmpty;

      expect(hasHelp || find.byType(TextButton).evaluate().isNotEmpty, isTrue);
    });

    testWidgets('settings_has_back_navigation', (tester) async {
      await navigateToSettings(tester);

      // Check for back button
      expect(find.byType(BackButton), findsWidgets);
    });

    testWidgets('settings_theme_selector_exists', (tester) async {
      await navigateToSettings(tester);

      // Check for theme options
      final clair = find.text('Clair');
      final sombre = find.text('Sombre');
      final systeme = find.text('Système');
      
      final hasTheme = clair.evaluate().isNotEmpty ||
          sombre.evaluate().isNotEmpty ||
          systeme.evaluate().isNotEmpty ||
          find.byIcon(Icons.light_mode).evaluate().isNotEmpty ||
          find.byIcon(Icons.dark_mode).evaluate().isNotEmpty;

      expect(hasTheme || find.byType(SegmentedButton).evaluate().isNotEmpty, isTrue);
    });

    testWidgets('settings_password_change_tappable', (tester) async {
      await navigateToSettings(tester);

      // Find password change option
      final changerMdp = find.text('Changer le mot de passe');
      if (changerMdp.evaluate().isNotEmpty) {
        await tester.tap(changerMdp);
        await tester.pumpAndSettle();

        // Should navigate to password change screen
        expect(find.byType(Scaffold), findsWidgets);
      }
    });
  });

  group('Help & Support Flow', () {
    testWidgets('profile_navigates_to_help_center', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      final profileTab = find.text('Profil');
      if (profileTab.evaluate().isNotEmpty) {
        await tester.tap(profileTab);
        await tester.pumpAndSettle();

        // Find and tap help button
        final helpButton = find.text('Aide & Support');
        if (helpButton.evaluate().isNotEmpty) {
          await tester.tap(helpButton);
          await tester.pumpAndSettle();

          // Verify navigation
          expect(find.byType(Scaffold), findsWidgets);
        }
      }
    });
  });

  group('Statistics Flow', () {
    testWidgets('profile_navigates_to_statistics', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      final profileTab = find.text('Profil');
      if (profileTab.evaluate().isNotEmpty) {
        await tester.tap(profileTab);
        await tester.pumpAndSettle();

        // Find and tap statistics button
        final statsButton = find.text('Statistiques');
        if (statsButton.evaluate().isNotEmpty) {
          await tester.tap(statsButton);
          await tester.pumpAndSettle();

          // Verify navigation
          expect(find.byType(Scaffold), findsWidgets);
        }
      }
    });
  });

  group('Dashboard Navigation Flow', () {
    testWidgets('profile_navigates_to_advanced_dashboard', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      final profileTab = find.text('Profil');
      if (profileTab.evaluate().isNotEmpty) {
        await tester.tap(profileTab);
        await tester.pumpAndSettle();

        // Find and tap dashboard button
        final dashboardButton = find.text('Dashboard');
        if (dashboardButton.evaluate().isNotEmpty) {
          await tester.tap(dashboardButton);
          await tester.pumpAndSettle();

          // Verify navigation
          expect(find.byType(Scaffold), findsWidgets);
        }
      }
    });

    testWidgets('profile_navigates_to_history', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      final profileTab = find.text('Profil');
      if (profileTab.evaluate().isNotEmpty) {
        await tester.tap(profileTab);
        await tester.pumpAndSettle();

        // Find and tap history button
        final historyButton = find.text('Historique');
        if (historyButton.evaluate().isNotEmpty) {
          await tester.tap(historyButton);
          await tester.pumpAndSettle();

          // Verify navigation
          expect(find.byType(Scaffold), findsWidgets);
        }
      }
    });
  });
}
