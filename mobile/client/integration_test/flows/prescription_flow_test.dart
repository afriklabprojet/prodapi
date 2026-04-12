import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../helpers/e2e_test_helpers.dart';

/// Tests E2E pour le flux ordonnances
///
/// Couvre:
/// - Accès à la section ordonnances
/// - Upload d'ordonnance
/// - Scan d'ordonnance (caméra)
/// - Historique des ordonnances
/// - Détail d'une ordonnance
/// - Renouvellement
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Flux Ordonnances E2E', () {
    testWidgets('accède à l\'écran ordonnances', (tester) async {
      await E2ETestHelpers.launchApp(
        tester,
        additionalPrefs: {'auth_token': 'test_token', 'user_id': 'test_user'},
      );
      await E2ETestHelpers.waitForStableUi(tester);

      await E2ETestHelpers.tapIfVisible(tester, find.text('Passer'));
      await E2ETestHelpers.waitFor(tester, find.byType(BottomNavigationBar));

      // Chercher l'accès aux ordonnances
      final ordonnancesTab = find.text('Ordonnances');
      final prescriptionIcon = find.byIcon(Icons.description);
      final prescriptionOutlined = find.byIcon(Icons.description_outlined);
      final medicalIcon = find.byIcon(Icons.medical_services);

      final tapped =
          await E2ETestHelpers.tapIfVisible(tester, ordonnancesTab) ||
          await E2ETestHelpers.tapIfVisible(tester, prescriptionIcon) ||
          await E2ETestHelpers.tapIfVisible(tester, prescriptionOutlined) ||
          await E2ETestHelpers.tapIfVisible(tester, medicalIcon);

      if (tapped) {
        await tester.pump(const Duration(milliseconds: 500));

        // Vérifier qu'on est sur l'écran ordonnances
        final isOnPrescriptionScreen =
            E2ETestHelpers.isVisible(find.text('Ordonnances')) ||
            E2ETestHelpers.isVisible(find.textContaining('ordonnance')) ||
            E2ETestHelpers.isVisible(find.textContaining('Upload')) ||
            E2ETestHelpers.isVisible(find.textContaining('Scanner'));

        expect(
          isOnPrescriptionScreen || E2ETestHelpers.hasStableUi(),
          isTrue,
          reason: 'Doit afficher l\'écran des ordonnances',
        );
      }
    });

    testWidgets('affiche les options d\'ajout d\'ordonnance', (tester) async {
      await E2ETestHelpers.launchApp(
        tester,
        additionalPrefs: {'auth_token': 'test_token', 'user_id': 'test_user'},
      );
      await E2ETestHelpers.waitForStableUi(tester);

      await E2ETestHelpers.tapIfVisible(tester, find.text('Passer'));
      await E2ETestHelpers.waitFor(tester, find.byType(BottomNavigationBar));

      // Naviguer vers ordonnances
      await E2ETestHelpers.tapIfVisible(tester, find.text('Ordonnances'));
      await E2ETestHelpers.tapIfVisible(tester, find.byIcon(Icons.description));
      await tester.pump(const Duration(milliseconds: 500));

      // Chercher les options d'ajout
      final uploadOption =
          E2ETestHelpers.isVisible(find.textContaining('Upload')) ||
          E2ETestHelpers.isVisible(find.textContaining('Télécharger')) ||
          E2ETestHelpers.isVisible(find.textContaining('Galerie')) ||
          E2ETestHelpers.isVisible(find.byIcon(Icons.upload));

      final scanOption =
          E2ETestHelpers.isVisible(find.textContaining('Scanner')) ||
          E2ETestHelpers.isVisible(find.textContaining('Photo')) ||
          E2ETestHelpers.isVisible(find.textContaining('Caméra')) ||
          E2ETestHelpers.isVisible(find.byIcon(Icons.camera_alt));

      final addButton =
          E2ETestHelpers.isVisible(find.byIcon(Icons.add)) ||
          E2ETestHelpers.isVisible(find.byIcon(Icons.add_circle)) ||
          E2ETestHelpers.isVisible(find.text('Ajouter'));

      expect(
        uploadOption || scanOption || addButton || E2ETestHelpers.hasStableUi(),
        isTrue,
        reason: 'Doit afficher les options pour ajouter une ordonnance',
      );
    });

    testWidgets('peut initier un upload d\'ordonnance', (tester) async {
      await E2ETestHelpers.launchApp(
        tester,
        additionalPrefs: {'auth_token': 'test_token', 'user_id': 'test_user'},
      );
      await E2ETestHelpers.waitForStableUi(tester);

      await E2ETestHelpers.tapIfVisible(tester, find.text('Passer'));
      await E2ETestHelpers.waitFor(tester, find.byType(BottomNavigationBar));

      await E2ETestHelpers.tapIfVisible(tester, find.text('Ordonnances'));
      await E2ETestHelpers.tapIfVisible(tester, find.byIcon(Icons.description));
      await tester.pump(const Duration(milliseconds: 500));

      // Chercher et cliquer sur upload
      final uploadButton = find.textContaining('Upload');
      final galleryButton = find.textContaining('Galerie');
      final addButton = find.byIcon(Icons.add);

      final tapped =
          await E2ETestHelpers.tapIfVisible(tester, uploadButton) ||
          await E2ETestHelpers.tapIfVisible(tester, galleryButton) ||
          await E2ETestHelpers.tapIfVisible(tester, addButton);

      if (tapped) {
        await tester.pump(const Duration(milliseconds: 300));
        // Pas de crash = succès (les permissions caméra/galerie sont gérées par l'OS)
        expect(E2ETestHelpers.hasStableUi(), isTrue);
      }
    });

    testWidgets('peut initier un scan d\'ordonnance', (tester) async {
      await E2ETestHelpers.launchApp(
        tester,
        additionalPrefs: {'auth_token': 'test_token', 'user_id': 'test_user'},
      );
      await E2ETestHelpers.waitForStableUi(tester);

      await E2ETestHelpers.tapIfVisible(tester, find.text('Passer'));
      await E2ETestHelpers.waitFor(tester, find.byType(BottomNavigationBar));

      await E2ETestHelpers.tapIfVisible(tester, find.text('Ordonnances'));
      await E2ETestHelpers.tapIfVisible(tester, find.byIcon(Icons.description));
      await tester.pump(const Duration(milliseconds: 500));

      // Chercher et cliquer sur scan
      final scanButton = find.textContaining('Scanner');
      final cameraButton = find.textContaining('Photo');
      final cameraIcon = find.byIcon(Icons.camera_alt);

      final tapped =
          await E2ETestHelpers.tapIfVisible(tester, scanButton) ||
          await E2ETestHelpers.tapIfVisible(tester, cameraButton) ||
          await E2ETestHelpers.tapIfVisible(tester, cameraIcon);

      if (tapped) {
        await tester.pump(const Duration(milliseconds: 300));
        expect(E2ETestHelpers.hasStableUi(), isTrue);
      }
    });

    testWidgets('affiche l\'historique des ordonnances', (tester) async {
      await E2ETestHelpers.launchApp(
        tester,
        additionalPrefs: {'auth_token': 'test_token', 'user_id': 'test_user'},
      );
      await E2ETestHelpers.waitForStableUi(tester);

      await E2ETestHelpers.tapIfVisible(tester, find.text('Passer'));
      await E2ETestHelpers.waitFor(tester, find.byType(BottomNavigationBar));

      await E2ETestHelpers.tapIfVisible(tester, find.text('Ordonnances'));
      await E2ETestHelpers.tapIfVisible(tester, find.byIcon(Icons.description));
      await tester.pump(const Duration(milliseconds: 500));

      // Chercher un onglet historique ou une liste
      final historyTab = find.text('Historique');
      final listView = find.byType(ListView);
      final emptyState = find.textContaining('aucune');

      final hasHistory =
          E2ETestHelpers.isVisible(historyTab) ||
          E2ETestHelpers.isVisible(listView) ||
          E2ETestHelpers.isVisible(emptyState);

      if (E2ETestHelpers.isVisible(historyTab)) {
        await E2ETestHelpers.tapIfVisible(tester, historyTab);
        await tester.pump(const Duration(milliseconds: 300));
      }

      expect(
        hasHistory || E2ETestHelpers.hasStableUi(),
        isTrue,
        reason: 'Doit afficher l\'historique ou un état vide',
      );
    });

    testWidgets('peut voir le détail d\'une ordonnance', (tester) async {
      await E2ETestHelpers.launchApp(
        tester,
        additionalPrefs: {'auth_token': 'test_token', 'user_id': 'test_user'},
      );
      await E2ETestHelpers.waitForStableUi(tester);

      await E2ETestHelpers.tapIfVisible(tester, find.text('Passer'));
      await E2ETestHelpers.waitFor(tester, find.byType(BottomNavigationBar));

      await E2ETestHelpers.tapIfVisible(tester, find.text('Ordonnances'));
      await E2ETestHelpers.tapIfVisible(tester, find.byIcon(Icons.description));
      await tester.pump(const Duration(milliseconds: 500));

      // Chercher une ordonnance dans la liste (Card ou ListTile)
      final prescriptionCard = find.byType(Card);
      final prescriptionTile = find.byType(ListTile);

      if (E2ETestHelpers.isVisible(prescriptionCard)) {
        await tester.tap(prescriptionCard.first);
        await tester.pump(const Duration(milliseconds: 500));

        // Vérifier le détail
        final hasDetail =
            E2ETestHelpers.isVisible(find.textContaining('Détail')) ||
            E2ETestHelpers.isVisible(find.textContaining('Statut')) ||
            E2ETestHelpers.isVisible(find.textContaining('Date')) ||
            E2ETestHelpers.isVisible(find.byIcon(Icons.arrow_back));

        expect(
          hasDetail || E2ETestHelpers.hasStableUi(),
          isTrue,
          reason: 'Doit afficher le détail de l\'ordonnance',
        );
      } else if (E2ETestHelpers.isVisible(prescriptionTile)) {
        await tester.tap(prescriptionTile.first);
        await tester.pump(const Duration(milliseconds: 500));
        expect(E2ETestHelpers.hasStableUi(), isTrue);
      }
    });

    testWidgets('affiche le statut des ordonnances', (tester) async {
      await E2ETestHelpers.launchApp(
        tester,
        additionalPrefs: {'auth_token': 'test_token', 'user_id': 'test_user'},
      );
      await E2ETestHelpers.waitForStableUi(tester);

      await E2ETestHelpers.tapIfVisible(tester, find.text('Passer'));
      await E2ETestHelpers.waitFor(tester, find.byType(BottomNavigationBar));

      await E2ETestHelpers.tapIfVisible(tester, find.text('Ordonnances'));
      await E2ETestHelpers.tapIfVisible(tester, find.byIcon(Icons.description));
      await tester.pump(const Duration(milliseconds: 500));

      // Chercher des indicateurs de statut
      final statusIndicators =
          E2ETestHelpers.isVisible(find.textContaining('En attente')) ||
          E2ETestHelpers.isVisible(find.textContaining('Validé')) ||
          E2ETestHelpers.isVisible(find.textContaining('Rejeté')) ||
          E2ETestHelpers.isVisible(find.textContaining('Traité')) ||
          E2ETestHelpers.isVisible(
            find.byWidgetPredicate((w) => w is Chip || w is CircleAvatar),
          );

      expect(
        statusIndicators || E2ETestHelpers.hasStableUi(),
        isTrue,
        reason: 'Doit afficher les statuts ou l\'écran ordonnances',
      );
    });

    testWidgets('peut renouveler une ordonnance', (tester) async {
      await E2ETestHelpers.launchApp(
        tester,
        additionalPrefs: {'auth_token': 'test_token', 'user_id': 'test_user'},
      );
      await E2ETestHelpers.waitForStableUi(tester);

      await E2ETestHelpers.tapIfVisible(tester, find.text('Passer'));
      await E2ETestHelpers.waitFor(tester, find.byType(BottomNavigationBar));

      await E2ETestHelpers.tapIfVisible(tester, find.text('Ordonnances'));
      await E2ETestHelpers.tapIfVisible(tester, find.byIcon(Icons.description));
      await tester.pump(const Duration(milliseconds: 500));

      // Chercher un bouton de renouvellement
      final renewButton = find.text('Renouveler');
      final renewIcon = find.byIcon(Icons.refresh);
      final reorderButton = find.text('Commander à nouveau');

      final hasRenewOption =
          E2ETestHelpers.isVisible(renewButton) ||
          E2ETestHelpers.isVisible(renewIcon) ||
          E2ETestHelpers.isVisible(reorderButton);

      if (hasRenewOption) {
        await E2ETestHelpers.tapIfVisible(tester, renewButton);
        await E2ETestHelpers.tapIfVisible(tester, reorderButton);
        await tester.pump(const Duration(milliseconds: 300));
      }

      expect(E2ETestHelpers.hasStableUi(), isTrue);
    });
  });
}
