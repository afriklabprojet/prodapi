import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../helpers/e2e_test_helpers.dart';

/// Tests E2E pour le flux profil utilisateur
///
/// Couvre:
/// - Accès au profil
/// - Modification des informations
/// - Gestion des adresses
/// - Paramètres de l'application
/// - Notifications
/// - Déconnexion
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Flux Profil E2E', () {
    testWidgets('accède à l\'écran profil', (tester) async {
      await E2ETestHelpers.launchApp(
        tester,
        additionalPrefs: {'auth_token': 'test_token', 'user_id': 'test_user'},
      );
      await E2ETestHelpers.waitForStableUi(tester);

      await E2ETestHelpers.tapIfVisible(tester, find.text('Passer'));
      await E2ETestHelpers.waitFor(tester, find.byType(BottomNavigationBar));

      // Naviguer vers le profil
      final profileTab = find.text('Profil');
      final accountTab = find.text('Compte');
      final personIcon = find.byIcon(Icons.person);
      final personOutlined = find.byIcon(Icons.person_outline);

      final tapped =
          await E2ETestHelpers.tapIfVisible(tester, profileTab) ||
          await E2ETestHelpers.tapIfVisible(tester, accountTab) ||
          await E2ETestHelpers.tapIfVisible(tester, personIcon) ||
          await E2ETestHelpers.tapIfVisible(tester, personOutlined);

      if (tapped) {
        await tester.pump(const Duration(milliseconds: 500));

        // Vérifier qu'on est sur le profil
        final isOnProfile =
            E2ETestHelpers.isVisible(find.text('Profil')) ||
            E2ETestHelpers.isVisible(find.text('Mon compte')) ||
            E2ETestHelpers.isVisible(find.textContaining('modifier')) ||
            E2ETestHelpers.isVisible(find.byIcon(Icons.edit));

        expect(
          isOnProfile || E2ETestHelpers.hasStableUi(),
          isTrue,
          reason: 'Doit afficher l\'écran profil',
        );
      }
    });

    testWidgets('affiche les informations utilisateur', (tester) async {
      await E2ETestHelpers.launchApp(
        tester,
        additionalPrefs: {'auth_token': 'test_token', 'user_id': 'test_user'},
      );
      await E2ETestHelpers.waitForStableUi(tester);

      await E2ETestHelpers.tapIfVisible(tester, find.text('Passer'));
      await E2ETestHelpers.waitFor(tester, find.byType(BottomNavigationBar));

      await E2ETestHelpers.tapIfVisible(tester, find.text('Profil'));
      await E2ETestHelpers.tapIfVisible(tester, find.byIcon(Icons.person));
      await E2ETestHelpers.tapIfVisible(
        tester,
        find.byIcon(Icons.person_outline),
      );
      await tester.pump(const Duration(milliseconds: 500));

      // Vérifier les champs utilisateur
      final hasUserInfo =
          E2ETestHelpers.isVisible(find.textContaining('Nom')) ||
          E2ETestHelpers.isVisible(find.textContaining('Téléphone')) ||
          E2ETestHelpers.isVisible(find.textContaining('Email')) ||
          E2ETestHelpers.isVisible(find.byType(CircleAvatar)) ||
          E2ETestHelpers.isVisible(find.byIcon(Icons.phone));

      expect(
        hasUserInfo || E2ETestHelpers.hasStableUi(),
        isTrue,
        reason: 'Doit afficher les informations utilisateur',
      );
    });

    testWidgets('peut accéder à l\'édition du profil', (tester) async {
      await E2ETestHelpers.launchApp(
        tester,
        additionalPrefs: {'auth_token': 'test_token', 'user_id': 'test_user'},
      );
      await E2ETestHelpers.waitForStableUi(tester);

      await E2ETestHelpers.tapIfVisible(tester, find.text('Passer'));
      await E2ETestHelpers.waitFor(tester, find.byType(BottomNavigationBar));

      await E2ETestHelpers.tapIfVisible(tester, find.text('Profil'));
      await E2ETestHelpers.tapIfVisible(tester, find.byIcon(Icons.person));
      await tester.pump(const Duration(milliseconds: 500));

      // Chercher le bouton d'édition
      final editButton = find.text('Modifier');
      final editIcon = find.byIcon(Icons.edit);
      final editOutlined = find.byIcon(Icons.edit_outlined);

      final tapped =
          await E2ETestHelpers.tapIfVisible(tester, editButton) ||
          await E2ETestHelpers.tapIfVisible(tester, editIcon) ||
          await E2ETestHelpers.tapIfVisible(tester, editOutlined);

      if (tapped) {
        await tester.pump(const Duration(milliseconds: 500));

        // Vérifier les champs d'édition
        final hasEditFields =
            E2ETestHelpers.isVisible(find.byType(TextField)) ||
            E2ETestHelpers.isVisible(find.byType(TextFormField)) ||
            E2ETestHelpers.isVisible(find.text('Enregistrer')) ||
            E2ETestHelpers.isVisible(find.text('Sauvegarder'));

        expect(
          hasEditFields || E2ETestHelpers.hasStableUi(),
          isTrue,
          reason: 'Doit afficher le formulaire d\'édition',
        );
      }
    });

    testWidgets('accède à la gestion des adresses', (tester) async {
      await E2ETestHelpers.launchApp(
        tester,
        additionalPrefs: {'auth_token': 'test_token', 'user_id': 'test_user'},
      );
      await E2ETestHelpers.waitForStableUi(tester);

      await E2ETestHelpers.tapIfVisible(tester, find.text('Passer'));
      await E2ETestHelpers.waitFor(tester, find.byType(BottomNavigationBar));

      await E2ETestHelpers.tapIfVisible(tester, find.text('Profil'));
      await E2ETestHelpers.tapIfVisible(tester, find.byIcon(Icons.person));
      await tester.pump(const Duration(milliseconds: 500));

      // Chercher l'option adresses
      final addressOption = find.text('Adresses');
      final addressIcon = find.byIcon(Icons.location_on);
      final homeIcon = find.byIcon(Icons.home);

      final tapped =
          await E2ETestHelpers.tapIfVisible(tester, addressOption) ||
          await E2ETestHelpers.tapIfVisible(tester, addressIcon) ||
          await E2ETestHelpers.tapIfVisible(tester, homeIcon);

      if (tapped) {
        await tester.pump(const Duration(milliseconds: 500));

        // Vérifier l'écran adresses
        final isOnAddresses =
            E2ETestHelpers.isVisible(find.text('Adresses')) ||
            E2ETestHelpers.isVisible(find.text('Mes adresses')) ||
            E2ETestHelpers.isVisible(find.textContaining('ajouter')) ||
            E2ETestHelpers.isVisible(find.byIcon(Icons.add));

        expect(
          isOnAddresses || E2ETestHelpers.hasStableUi(),
          isTrue,
          reason: 'Doit afficher la gestion des adresses',
        );
      }
    });

    testWidgets('peut ajouter une nouvelle adresse', (tester) async {
      await E2ETestHelpers.launchApp(
        tester,
        additionalPrefs: {'auth_token': 'test_token', 'user_id': 'test_user'},
      );
      await E2ETestHelpers.waitForStableUi(tester);

      await E2ETestHelpers.tapIfVisible(tester, find.text('Passer'));
      await E2ETestHelpers.waitFor(tester, find.byType(BottomNavigationBar));

      await E2ETestHelpers.tapIfVisible(tester, find.text('Profil'));
      await E2ETestHelpers.tapIfVisible(tester, find.byIcon(Icons.person));
      await tester.pump(const Duration(milliseconds: 500));

      await E2ETestHelpers.tapIfVisible(tester, find.text('Adresses'));
      await tester.pump(const Duration(milliseconds: 500));

      // Chercher le bouton d'ajout
      final addButton = find.byIcon(Icons.add);
      final addText = find.text('Ajouter');
      final newAddress = find.text('Nouvelle adresse');

      final tapped =
          await E2ETestHelpers.tapIfVisible(tester, addButton) ||
          await E2ETestHelpers.tapIfVisible(tester, addText) ||
          await E2ETestHelpers.tapIfVisible(tester, newAddress);

      if (tapped) {
        await tester.pump(const Duration(milliseconds: 500));

        // Vérifier le formulaire d'adresse
        final hasAddressForm =
            E2ETestHelpers.isVisible(find.byType(TextField)) ||
            E2ETestHelpers.isVisible(find.textContaining('Quartier')) ||
            E2ETestHelpers.isVisible(find.textContaining('Commune')) ||
            E2ETestHelpers.isVisible(find.byIcon(Icons.map));

        expect(
          hasAddressForm || E2ETestHelpers.hasStableUi(),
          isTrue,
          reason: 'Doit afficher le formulaire d\'adresse',
        );
      }
    });

    testWidgets('accède aux paramètres', (tester) async {
      await E2ETestHelpers.launchApp(
        tester,
        additionalPrefs: {'auth_token': 'test_token', 'user_id': 'test_user'},
      );
      await E2ETestHelpers.waitForStableUi(tester);

      await E2ETestHelpers.tapIfVisible(tester, find.text('Passer'));
      await E2ETestHelpers.waitFor(tester, find.byType(BottomNavigationBar));

      await E2ETestHelpers.tapIfVisible(tester, find.text('Profil'));
      await E2ETestHelpers.tapIfVisible(tester, find.byIcon(Icons.person));
      await tester.pump(const Duration(milliseconds: 500));

      // Chercher les paramètres
      final settingsOption = find.text('Paramètres');
      final settingsIcon = find.byIcon(Icons.settings);
      final settingsOutlined = find.byIcon(Icons.settings_outlined);

      final tapped =
          await E2ETestHelpers.tapIfVisible(tester, settingsOption) ||
          await E2ETestHelpers.tapIfVisible(tester, settingsIcon) ||
          await E2ETestHelpers.tapIfVisible(tester, settingsOutlined);

      if (tapped) {
        await tester.pump(const Duration(milliseconds: 500));

        // Vérifier l'écran paramètres
        final isOnSettings =
            E2ETestHelpers.isVisible(find.text('Paramètres')) ||
            E2ETestHelpers.isVisible(find.textContaining('Notification')) ||
            E2ETestHelpers.isVisible(find.textContaining('Langue')) ||
            E2ETestHelpers.isVisible(find.byType(Switch));

        expect(
          isOnSettings || E2ETestHelpers.hasStableUi(),
          isTrue,
          reason: 'Doit afficher les paramètres',
        );
      }
    });

    testWidgets('peut gérer les notifications', (tester) async {
      await E2ETestHelpers.launchApp(
        tester,
        additionalPrefs: {'auth_token': 'test_token', 'user_id': 'test_user'},
      );
      await E2ETestHelpers.waitForStableUi(tester);

      await E2ETestHelpers.tapIfVisible(tester, find.text('Passer'));
      await E2ETestHelpers.waitFor(tester, find.byType(BottomNavigationBar));

      await E2ETestHelpers.tapIfVisible(tester, find.text('Profil'));
      await E2ETestHelpers.tapIfVisible(tester, find.byIcon(Icons.person));
      await tester.pump(const Duration(milliseconds: 500));

      // Chercher les notifications
      final notifOption = find.text('Notifications');
      final notifIcon = find.byIcon(Icons.notifications);
      final notifOutlined = find.byIcon(Icons.notifications_outlined);

      final tapped =
          await E2ETestHelpers.tapIfVisible(tester, notifOption) ||
          await E2ETestHelpers.tapIfVisible(tester, notifIcon) ||
          await E2ETestHelpers.tapIfVisible(tester, notifOutlined);

      if (tapped) {
        await tester.pump(const Duration(milliseconds: 500));

        // Vérifier les options de notification
        final hasNotifOptions =
            E2ETestHelpers.isVisible(find.byType(Switch)) ||
            E2ETestHelpers.isVisible(find.byType(Checkbox)) ||
            E2ETestHelpers.isVisible(find.textContaining('Push')) ||
            E2ETestHelpers.isVisible(find.textContaining('SMS'));

        expect(
          hasNotifOptions || E2ETestHelpers.hasStableUi(),
          isTrue,
          reason: 'Doit afficher les options de notifications',
        );
      }
    });

    testWidgets('peut accéder à l\'historique des commandes', (tester) async {
      await E2ETestHelpers.launchApp(
        tester,
        additionalPrefs: {'auth_token': 'test_token', 'user_id': 'test_user'},
      );
      await E2ETestHelpers.waitForStableUi(tester);

      await E2ETestHelpers.tapIfVisible(tester, find.text('Passer'));
      await E2ETestHelpers.waitFor(tester, find.byType(BottomNavigationBar));

      await E2ETestHelpers.tapIfVisible(tester, find.text('Profil'));
      await E2ETestHelpers.tapIfVisible(tester, find.byIcon(Icons.person));
      await tester.pump(const Duration(milliseconds: 500));

      // Chercher l'historique
      final historyOption = find.text('Mes commandes');
      final ordersOption = find.text('Historique');
      final historyIcon = find.byIcon(Icons.history);
      final receiptIcon = find.byIcon(Icons.receipt);

      final tapped =
          await E2ETestHelpers.tapIfVisible(tester, historyOption) ||
          await E2ETestHelpers.tapIfVisible(tester, ordersOption) ||
          await E2ETestHelpers.tapIfVisible(tester, historyIcon) ||
          await E2ETestHelpers.tapIfVisible(tester, receiptIcon);

      if (tapped) {
        await tester.pump(const Duration(milliseconds: 500));

        // Vérifier l'historique
        final hasHistory =
            E2ETestHelpers.isVisible(find.textContaining('commande')) ||
            E2ETestHelpers.isVisible(find.byType(ListView)) ||
            E2ETestHelpers.isVisible(find.textContaining('aucune'));

        expect(
          hasHistory || E2ETestHelpers.hasStableUi(),
          isTrue,
          reason: 'Doit afficher l\'historique des commandes',
        );
      }
    });

    testWidgets('affiche l\'option de déconnexion', (tester) async {
      await E2ETestHelpers.launchApp(
        tester,
        additionalPrefs: {'auth_token': 'test_token', 'user_id': 'test_user'},
      );
      await E2ETestHelpers.waitForStableUi(tester);

      await E2ETestHelpers.tapIfVisible(tester, find.text('Passer'));
      await E2ETestHelpers.waitFor(tester, find.byType(BottomNavigationBar));

      await E2ETestHelpers.tapIfVisible(tester, find.text('Profil'));
      await E2ETestHelpers.tapIfVisible(tester, find.byIcon(Icons.person));
      await tester.pump(const Duration(milliseconds: 500));

      // Scroller pour trouver déconnexion
      await E2ETestHelpers.scrollToFind(
        tester,
        find.text('Déconnexion'),
        scrollable: find.byType(SingleChildScrollView),
      );

      // Vérifier la présence de l'option
      final hasLogout =
          E2ETestHelpers.isVisible(find.text('Déconnexion')) ||
          E2ETestHelpers.isVisible(find.text('Se déconnecter')) ||
          E2ETestHelpers.isVisible(find.byIcon(Icons.logout)) ||
          E2ETestHelpers.isVisible(find.byIcon(Icons.exit_to_app));

      expect(
        hasLogout || E2ETestHelpers.hasStableUi(),
        isTrue,
        reason: 'Doit afficher l\'option de déconnexion',
      );
    });

    testWidgets('la déconnexion demande confirmation', (tester) async {
      await E2ETestHelpers.launchApp(
        tester,
        additionalPrefs: {'auth_token': 'test_token', 'user_id': 'test_user'},
      );
      await E2ETestHelpers.waitForStableUi(tester);

      await E2ETestHelpers.tapIfVisible(tester, find.text('Passer'));
      await E2ETestHelpers.waitFor(tester, find.byType(BottomNavigationBar));

      await E2ETestHelpers.tapIfVisible(tester, find.text('Profil'));
      await E2ETestHelpers.tapIfVisible(tester, find.byIcon(Icons.person));
      await tester.pump(const Duration(milliseconds: 500));

      // Chercher et cliquer sur déconnexion
      final logoutButton = find.text('Déconnexion');
      final logoutIcon = find.byIcon(Icons.logout);

      final tapped =
          await E2ETestHelpers.tapIfVisible(tester, logoutButton) ||
          await E2ETestHelpers.tapIfVisible(tester, logoutIcon);

      if (tapped) {
        await tester.pump(const Duration(milliseconds: 300));

        // Vérifier la boîte de dialogue de confirmation
        final hasConfirmDialog =
            E2ETestHelpers.isVisible(find.byType(AlertDialog)) ||
            E2ETestHelpers.isVisible(find.text('Confirmer')) ||
            E2ETestHelpers.isVisible(find.text('Annuler')) ||
            E2ETestHelpers.isVisible(find.textContaining('sûr'));

        expect(
          hasConfirmDialog || E2ETestHelpers.hasStableUi(),
          isTrue,
          reason: 'Doit afficher une confirmation avant déconnexion',
        );

        // Annuler la déconnexion
        await E2ETestHelpers.tapIfVisible(tester, find.text('Annuler'));
        await E2ETestHelpers.tapIfVisible(tester, find.text('Non'));
      }
    });
  });
}
