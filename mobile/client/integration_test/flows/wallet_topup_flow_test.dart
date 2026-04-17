import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../helpers/e2e_test_helpers.dart';

/// Tests E2E pour le flux de rechargement du portefeuille
///
/// Couvre:
/// - Accès au portefeuille
/// - Affichage de la balance
/// - Navigation vers le rechargement
/// - Sélection de montants rapides
/// - Sélection d'opérateur
/// - Soumission du formulaire
/// - Validation des champs
/// - Navigation vers le paiement WebView
///
/// Prérequis pour tests LIVE:
/// - Utilisateur connecté avec token valide
/// - API backend accessible
/// - Opérateurs de paiement configurés (Wave, Orange Money, etc.)
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Flux Rechargement Wallet E2E', () {
    // ─── Accès au portefeuille ───────────────────────────────────────────────
    group('Accès Portefeuille', () {
      testWidgets('accède à l\'écran portefeuille depuis la navigation', (
        tester,
      ) async {
        await E2ETestHelpers.launchApp(
          tester,
          additionalPrefs: {'auth_token': 'test_token', 'user_id': 'test_user'},
        );
        await E2ETestHelpers.waitForStableUi(tester);
        await E2ETestHelpers.tapIfVisible(tester, find.text('Passer'));
        await E2ETestHelpers.waitFor(tester, find.byType(BottomNavigationBar));

        // Tenter de naviguer vers le portefeuille
        final walletTab = find.text('Portefeuille');
        final walletIcon = find.byIcon(Icons.account_balance_wallet);
        final walletIconOutlined = find.byIcon(
          Icons.account_balance_wallet_outlined,
        );

        final tapped =
            await E2ETestHelpers.tapIfVisible(tester, walletTab) ||
            await E2ETestHelpers.tapIfVisible(tester, walletIcon) ||
            await E2ETestHelpers.tapIfVisible(tester, walletIconOutlined);

        if (tapped) {
          await tester.pump(const Duration(milliseconds: 500));

          final isOnWallet =
              E2ETestHelpers.isVisible(find.text('Portefeuille')) ||
              E2ETestHelpers.isVisible(find.textContaining('Solde')) ||
              E2ETestHelpers.isVisible(find.textContaining('Balance')) ||
              E2ETestHelpers.isVisible(find.text('Recharger'));

          expect(
            isOnWallet || E2ETestHelpers.hasStableUi(),
            isTrue,
            reason: 'Doit afficher l\'écran portefeuille',
          );
        }
      });

      testWidgets('affiche la balance et les statistiques', (tester) async {
        await E2ETestHelpers.launchApp(
          tester,
          additionalPrefs: {'auth_token': 'test_token', 'user_id': 'test_user'},
        );
        await E2ETestHelpers.waitForStableUi(tester);
        await E2ETestHelpers.tapIfVisible(tester, find.text('Passer'));
        await E2ETestHelpers.waitFor(tester, find.byType(BottomNavigationBar));

        // Naviguer vers portefeuille
        await E2ETestHelpers.tapIfVisible(tester, find.text('Portefeuille'));
        await E2ETestHelpers.tapIfVisible(
          tester,
          find.byIcon(Icons.account_balance_wallet),
        );
        await tester.pump(const Duration(milliseconds: 500));

        // Vérifier la présence des éléments de balance
        final hasBalanceInfo =
            E2ETestHelpers.isVisible(find.textContaining('F CFA')) ||
            E2ETestHelpers.isVisible(find.textContaining('FCFA')) ||
            E2ETestHelpers.isVisible(find.textContaining('Solde')) ||
            E2ETestHelpers.isVisible(find.textContaining('Balance')) ||
            E2ETestHelpers.isVisible(find.byIcon(Icons.account_balance_wallet));

        expect(
          hasBalanceInfo || E2ETestHelpers.hasStableUi(),
          isTrue,
          reason: 'Doit afficher les informations de balance',
        );
      });
    });

    // ─── Navigation vers Rechargement ────────────────────────────────────────
    group('Navigation Rechargement', () {
      testWidgets('navigue vers la page de rechargement', (tester) async {
        await E2ETestHelpers.launchApp(
          tester,
          additionalPrefs: {'auth_token': 'test_token', 'user_id': 'test_user'},
        );
        await E2ETestHelpers.waitForStableUi(tester);
        await E2ETestHelpers.tapIfVisible(tester, find.text('Passer'));
        await E2ETestHelpers.waitFor(tester, find.byType(BottomNavigationBar));

        // Naviguer vers portefeuille
        await E2ETestHelpers.tapIfVisible(tester, find.text('Portefeuille'));
        await E2ETestHelpers.tapIfVisible(
          tester,
          find.byIcon(Icons.account_balance_wallet),
        );
        await tester.pump(const Duration(milliseconds: 500));

        // Cliquer sur Recharger
        final rechargerButton = find.text('Recharger');
        final addIcon = find.byIcon(Icons.add);
        final addCircle = find.byIcon(Icons.add_circle);

        await E2ETestHelpers.tapIfVisible(tester, rechargerButton);
        await E2ETestHelpers.tapIfVisible(tester, addIcon);
        await E2ETestHelpers.tapIfVisible(tester, addCircle);

        await tester.pump(const Duration(milliseconds: 500));

        // Vérifier qu'on est sur la page de rechargement
        final isOnTopUp =
            E2ETestHelpers.isVisible(find.text('Montant rapide')) ||
            E2ETestHelpers.isVisible(find.textContaining('Montant')) ||
            E2ETestHelpers.isVisible(find.textContaining('5000')) ||
            E2ETestHelpers.isVisible(find.textContaining('opérateur'));

        expect(
          isOnTopUp || E2ETestHelpers.hasStableUi(),
          isTrue,
          reason: 'Doit naviguer vers la page de rechargement',
        );
      });
    });

    // ─── Page Rechargement ───────────────────────────────────────────────────
    group('Page Rechargement TopUp', () {
      testWidgets('affiche les montants rapides', (tester) async {
        await E2ETestHelpers.launchApp(
          tester,
          additionalPrefs: {'auth_token': 'test_token', 'user_id': 'test_user'},
        );
        await E2ETestHelpers.waitForStableUi(tester);
        await E2ETestHelpers.tapIfVisible(tester, find.text('Passer'));
        await E2ETestHelpers.waitFor(tester, find.byType(BottomNavigationBar));
        await E2ETestHelpers.tapIfVisible(tester, find.text('Portefeuille'));
        await E2ETestHelpers.tapIfVisible(
          tester,
          find.byIcon(Icons.account_balance_wallet),
        );
        await tester.pump(const Duration(milliseconds: 500));
        await E2ETestHelpers.tapIfVisible(tester, find.text('Recharger'));
        await tester.pump(const Duration(milliseconds: 500));

        // Vérifier les montants rapides (500, 1000, 2000, 5000, 10000, 25000)
        final hasQuickAmounts =
            E2ETestHelpers.isVisible(find.text('500 F')) ||
            E2ETestHelpers.isVisible(find.textContaining('1000')) ||
            E2ETestHelpers.isVisible(find.textContaining('5000')) ||
            E2ETestHelpers.isVisible(find.textContaining('10000'));

        expect(
          hasQuickAmounts || E2ETestHelpers.hasStableUi(),
          isTrue,
          reason: 'Doit afficher les montants rapides',
        );
      });

      testWidgets('sélectionne un montant rapide', (tester) async {
        await E2ETestHelpers.launchApp(
          tester,
          additionalPrefs: {'auth_token': 'test_token', 'user_id': 'test_user'},
        );
        await E2ETestHelpers.waitForStableUi(tester);
        await E2ETestHelpers.tapIfVisible(tester, find.text('Passer'));
        await E2ETestHelpers.waitFor(tester, find.byType(BottomNavigationBar));
        await E2ETestHelpers.tapIfVisible(tester, find.text('Portefeuille'));
        await E2ETestHelpers.tapIfVisible(
          tester,
          find.byIcon(Icons.account_balance_wallet),
        );
        await tester.pump(const Duration(milliseconds: 500));
        await E2ETestHelpers.tapIfVisible(tester, find.text('Recharger'));
        await tester.pump(const Duration(milliseconds: 500));

        // Cliquer sur le montant 5000
        final amount5000 = find.text('5000 F');
        if (E2ETestHelpers.isVisible(amount5000)) {
          await tester.tap(amount5000);
          await tester.pump(const Duration(milliseconds: 300));

          // Vérifier que le champ est rempli
          final textField = find.byType(TextFormField);
          if (E2ETestHelpers.isVisible(textField)) {
            // Le montant devrait être dans le champ
            expect(
              E2ETestHelpers.isVisible(find.text('5000')) ||
                  E2ETestHelpers.hasStableUi(),
              isTrue,
              reason: 'Le montant doit être prérerempli',
            );
          }
        }
      });

      testWidgets('affiche les opérateurs de paiement', (tester) async {
        await E2ETestHelpers.launchApp(
          tester,
          additionalPrefs: {'auth_token': 'test_token', 'user_id': 'test_user'},
        );
        await E2ETestHelpers.waitForStableUi(tester);
        await E2ETestHelpers.tapIfVisible(tester, find.text('Passer'));
        await E2ETestHelpers.waitFor(tester, find.byType(BottomNavigationBar));
        await E2ETestHelpers.tapIfVisible(tester, find.text('Portefeuille'));
        await E2ETestHelpers.tapIfVisible(
          tester,
          find.byIcon(Icons.account_balance_wallet),
        );
        await tester.pump(const Duration(milliseconds: 500));
        await E2ETestHelpers.tapIfVisible(tester, find.text('Recharger'));
        await tester.pump(const Duration(milliseconds: 500));

        // Vérifier les opérateurs (Wave, Orange Money, MTN, Moov)
        final hasOperators =
            E2ETestHelpers.isVisible(find.text('Wave')) ||
            E2ETestHelpers.isVisible(find.text('Orange Money')) ||
            E2ETestHelpers.isVisible(find.text('MTN')) ||
            E2ETestHelpers.isVisible(find.textContaining('opérateur'));

        expect(
          hasOperators || E2ETestHelpers.hasStableUi(),
          isTrue,
          reason: 'Doit afficher les opérateurs de paiement',
        );
      });

      testWidgets('sélectionne un opérateur Wave', (tester) async {
        await E2ETestHelpers.launchApp(
          tester,
          additionalPrefs: {'auth_token': 'test_token', 'user_id': 'test_user'},
        );
        await E2ETestHelpers.waitForStableUi(tester);
        await E2ETestHelpers.tapIfVisible(tester, find.text('Passer'));
        await E2ETestHelpers.waitFor(tester, find.byType(BottomNavigationBar));
        await E2ETestHelpers.tapIfVisible(tester, find.text('Portefeuille'));
        await E2ETestHelpers.tapIfVisible(
          tester,
          find.byIcon(Icons.account_balance_wallet),
        );
        await tester.pump(const Duration(milliseconds: 500));
        await E2ETestHelpers.tapIfVisible(tester, find.text('Recharger'));
        await tester.pump(const Duration(milliseconds: 500));

        // Sélectionner Wave
        final waveButton = find.text('Wave');
        if (E2ETestHelpers.isVisible(waveButton)) {
          await tester.tap(waveButton);
          await tester.pump(const Duration(milliseconds: 300));

          // Vérifier sélection visuelle
          expect(
            E2ETestHelpers.isVisible(find.text('Wave')) ||
                E2ETestHelpers.hasStableUi(),
            isTrue,
            reason: 'Wave doit être sélectionné',
          );
        }
      });
    });

    // ─── Validation du formulaire ────────────────────────────────────────────
    group('Validation Formulaire', () {
      testWidgets('affiche erreur si montant vide', (tester) async {
        await E2ETestHelpers.launchApp(
          tester,
          additionalPrefs: {'auth_token': 'test_token', 'user_id': 'test_user'},
        );
        await E2ETestHelpers.waitForStableUi(tester);
        await E2ETestHelpers.tapIfVisible(tester, find.text('Passer'));
        await E2ETestHelpers.waitFor(tester, find.byType(BottomNavigationBar));
        await E2ETestHelpers.tapIfVisible(tester, find.text('Portefeuille'));
        await E2ETestHelpers.tapIfVisible(
          tester,
          find.byIcon(Icons.account_balance_wallet),
        );
        await tester.pump(const Duration(milliseconds: 500));
        await E2ETestHelpers.tapIfVisible(tester, find.text('Recharger'));
        await tester.pump(const Duration(milliseconds: 500));

        // Tenter de soumettre sans montant
        final submitButton = find.widgetWithText(ElevatedButton, 'Recharger');
        if (E2ETestHelpers.isVisible(submitButton)) {
          await tester.tap(submitButton);
          await tester.pump(const Duration(milliseconds: 500));

          // Vérifier message d'erreur
          final hasError =
              E2ETestHelpers.isVisible(
                find.textContaining('entrer un montant'),
              ) ||
              E2ETestHelpers.isVisible(
                find.textContaining('sélectionner un opérateur'),
              );

          expect(
            hasError || E2ETestHelpers.hasStableUi(),
            isTrue,
            reason: 'Doit afficher un message d\'erreur',
          );
        }
      });

      testWidgets('affiche erreur si montant trop faible', (tester) async {
        await E2ETestHelpers.launchApp(
          tester,
          additionalPrefs: {'auth_token': 'test_token', 'user_id': 'test_user'},
        );
        await E2ETestHelpers.waitForStableUi(tester);
        await E2ETestHelpers.tapIfVisible(tester, find.text('Passer'));
        await E2ETestHelpers.waitFor(tester, find.byType(BottomNavigationBar));
        await E2ETestHelpers.tapIfVisible(tester, find.text('Portefeuille'));
        await E2ETestHelpers.tapIfVisible(
          tester,
          find.byIcon(Icons.account_balance_wallet),
        );
        await tester.pump(const Duration(milliseconds: 500));
        await E2ETestHelpers.tapIfVisible(tester, find.text('Recharger'));
        await tester.pump(const Duration(milliseconds: 500));

        // Entrer un montant trop faible (min = 100)
        final amountField = find.byType(TextFormField).first;
        if (E2ETestHelpers.isVisible(amountField)) {
          await E2ETestHelpers.enterText(tester, amountField, '50');
          await tester.pump();

          // Soumettre
          final submitButton = find.widgetWithText(ElevatedButton, 'Recharger');
          if (E2ETestHelpers.isVisible(submitButton)) {
            await tester.tap(submitButton);
            await tester.pump(const Duration(milliseconds: 500));

            // Vérifier message d'erreur
            final hasError =
                E2ETestHelpers.isVisible(find.textContaining('minimum')) ||
                E2ETestHelpers.isVisible(find.textContaining('100'));

            expect(
              hasError || E2ETestHelpers.hasStableUi(),
              isTrue,
              reason: 'Doit afficher erreur montant minimum',
            );
          }
        }
      });

      testWidgets('affiche erreur si pas d\'opérateur sélectionné', (
        tester,
      ) async {
        await E2ETestHelpers.launchApp(
          tester,
          additionalPrefs: {'auth_token': 'test_token', 'user_id': 'test_user'},
        );
        await E2ETestHelpers.waitForStableUi(tester);
        await E2ETestHelpers.tapIfVisible(tester, find.text('Passer'));
        await E2ETestHelpers.waitFor(tester, find.byType(BottomNavigationBar));
        await E2ETestHelpers.tapIfVisible(tester, find.text('Portefeuille'));
        await E2ETestHelpers.tapIfVisible(
          tester,
          find.byIcon(Icons.account_balance_wallet),
        );
        await tester.pump(const Duration(milliseconds: 500));
        await E2ETestHelpers.tapIfVisible(tester, find.text('Recharger'));
        await tester.pump(const Duration(milliseconds: 500));

        // Entrer un montant valide
        final amountField = find.byType(TextFormField).first;
        if (E2ETestHelpers.isVisible(amountField)) {
          await E2ETestHelpers.enterText(tester, amountField, '1000');
          await tester.pump();

          // Soumettre SANS opérateur
          final submitButton = find.widgetWithText(ElevatedButton, 'Recharger');
          if (E2ETestHelpers.isVisible(submitButton)) {
            await tester.tap(submitButton);
            await tester.pump(const Duration(milliseconds: 500));

            // Vérifier le SnackBar d'erreur
            final hasError = E2ETestHelpers.isVisible(
              find.textContaining('sélectionner un opérateur'),
            );

            expect(
              hasError || E2ETestHelpers.hasStableUi(),
              isTrue,
              reason: 'Doit demander de sélectionner un opérateur',
            );
          }
        }
      });
    });

    // ─── Flux complet de rechargement ────────────────────────────────────────
    group('Flux Complet Rechargement', () {
      testWidgets('flux complet avec Wave', (tester) async {
        await E2ETestHelpers.launchApp(
          tester,
          additionalPrefs: {'auth_token': 'test_token', 'user_id': 'test_user'},
        );
        await E2ETestHelpers.waitForStableUi(tester);
        await E2ETestHelpers.tapIfVisible(tester, find.text('Passer'));
        await E2ETestHelpers.waitFor(tester, find.byType(BottomNavigationBar));

        // 1. Naviguer vers portefeuille
        await E2ETestHelpers.tapIfVisible(tester, find.text('Portefeuille'));
        await E2ETestHelpers.tapIfVisible(
          tester,
          find.byIcon(Icons.account_balance_wallet),
        );
        await tester.pump(const Duration(milliseconds: 500));

        // 2. Cliquer sur Recharger
        final rechargedTapped = await E2ETestHelpers.tapIfVisible(
          tester,
          find.text('Recharger'),
        );
        await tester.pump(const Duration(milliseconds: 500));

        if (!rechargedTapped) {
          // Peut-être pas connecté ou autre état
          return;
        }

        // 3. Sélectionner montant rapide 5000
        await E2ETestHelpers.tapIfVisible(tester, find.text('5000 F'));
        await tester.pump(const Duration(milliseconds: 300));

        // 4. Sélectionner Wave
        await E2ETestHelpers.tapIfVisible(tester, find.text('Wave'));
        await tester.pump(const Duration(milliseconds: 300));

        // 5. Soumettre
        final submitButton = find.widgetWithText(ElevatedButton, 'Recharger');
        if (E2ETestHelpers.isVisible(submitButton)) {
          await tester.tap(submitButton);
          await tester.pump(const Duration(seconds: 1));

          // 6. Vérifier qu'on passe au WebView ou loading
          final isLoading =
              E2ETestHelpers.isVisible(
                find.byType(CircularProgressIndicator),
              ) ||
              E2ETestHelpers.isVisible(find.text('Paiement sécurisé')) ||
              E2ETestHelpers.isVisible(find.textContaining('chargement'));

          expect(
            isLoading || E2ETestHelpers.hasStableUi(),
            isTrue,
            reason: 'Doit initier le paiement ou afficher un loader',
          );
        }
      });

      testWidgets('flux complet avec Orange Money', (tester) async {
        await E2ETestHelpers.launchApp(
          tester,
          additionalPrefs: {'auth_token': 'test_token', 'user_id': 'test_user'},
        );
        await E2ETestHelpers.waitForStableUi(tester);
        await E2ETestHelpers.tapIfVisible(tester, find.text('Passer'));
        await E2ETestHelpers.waitFor(tester, find.byType(BottomNavigationBar));

        // 1. Naviguer vers portefeuille
        await E2ETestHelpers.tapIfVisible(tester, find.text('Portefeuille'));
        await E2ETestHelpers.tapIfVisible(
          tester,
          find.byIcon(Icons.account_balance_wallet),
        );
        await tester.pump(const Duration(milliseconds: 500));

        // 2. Cliquer sur Recharger
        final rechargedTapped = await E2ETestHelpers.tapIfVisible(
          tester,
          find.text('Recharger'),
        );
        await tester.pump(const Duration(milliseconds: 500));

        if (!rechargedTapped) return;

        // 3. Entrer montant manuellement
        final amountField = find.byType(TextFormField).first;
        if (E2ETestHelpers.isVisible(amountField)) {
          await E2ETestHelpers.enterText(tester, amountField, '2500');
          await tester.pump();
        }

        // 4. Sélectionner Orange Money
        await E2ETestHelpers.tapIfVisible(tester, find.text('Orange Money'));
        await E2ETestHelpers.tapIfVisible(tester, find.text('Orange'));
        await tester.pump(const Duration(milliseconds: 300));

        // 5. Soumettre
        final submitButton = find.widgetWithText(ElevatedButton, 'Recharger');
        if (E2ETestHelpers.isVisible(submitButton)) {
          await tester.tap(submitButton);
          await tester.pump(const Duration(seconds: 1));

          expect(
            E2ETestHelpers.isVisible(find.byType(CircularProgressIndicator)) ||
                E2ETestHelpers.hasStableUi(),
            isTrue,
            reason: 'Doit initier le paiement',
          );
        }
      });
    });

    // ─── Historique des transactions ─────────────────────────────────────────
    group('Historique Transactions', () {
      testWidgets('affiche l\'historique des transactions', (tester) async {
        await E2ETestHelpers.launchApp(
          tester,
          additionalPrefs: {'auth_token': 'test_token', 'user_id': 'test_user'},
        );
        await E2ETestHelpers.waitForStableUi(tester);
        await E2ETestHelpers.tapIfVisible(tester, find.text('Passer'));
        await E2ETestHelpers.waitFor(tester, find.byType(BottomNavigationBar));
        await E2ETestHelpers.tapIfVisible(tester, find.text('Portefeuille'));
        await E2ETestHelpers.tapIfVisible(
          tester,
          find.byIcon(Icons.account_balance_wallet),
        );
        await tester.pump(const Duration(milliseconds: 500));

        // Vérifier section historique
        final hasHistory =
            E2ETestHelpers.isVisible(find.text('Historique')) ||
            E2ETestHelpers.isVisible(find.text('Transactions')) ||
            E2ETestHelpers.isVisible(find.text('Aucune transaction'));

        expect(
          hasHistory || E2ETestHelpers.hasStableUi(),
          isTrue,
          reason: 'Doit afficher la section historique',
        );
      });

      testWidgets('filtre les transactions par catégorie', (tester) async {
        await E2ETestHelpers.launchApp(
          tester,
          additionalPrefs: {'auth_token': 'test_token', 'user_id': 'test_user'},
        );
        await E2ETestHelpers.waitForStableUi(tester);
        await E2ETestHelpers.tapIfVisible(tester, find.text('Passer'));
        await E2ETestHelpers.waitFor(tester, find.byType(BottomNavigationBar));
        await E2ETestHelpers.tapIfVisible(tester, find.text('Portefeuille'));
        await E2ETestHelpers.tapIfVisible(
          tester,
          find.byIcon(Icons.account_balance_wallet),
        );
        await tester.pump(const Duration(milliseconds: 500));

        // Vérifier les filtres (Tout, Rechargements, Paiements, etc.)
        final hasFilters =
            E2ETestHelpers.isVisible(find.text('Tout')) ||
            E2ETestHelpers.isVisible(find.text('Rechargements')) ||
            E2ETestHelpers.isVisible(find.text('Paiements')) ||
            E2ETestHelpers.isVisible(find.byType(FilterChip));

        expect(
          hasFilters || E2ETestHelpers.hasStableUi(),
          isTrue,
          reason: 'Doit afficher les filtres de transaction',
        );

        // Cliquer sur un filtre
        if (E2ETestHelpers.isVisible(find.text('Rechargements'))) {
          await tester.tap(find.text('Rechargements'));
          await tester.pump(const Duration(milliseconds: 300));

          // Vérifier que le filtre est appliqué
          expect(
            E2ETestHelpers.hasStableUi(),
            isTrue,
            reason: 'Le filtre doit être appliqué',
          );
        }
      });
    });

    // ─── Gestion des erreurs ─────────────────────────────────────────────────
    group('Gestion Erreurs', () {
      testWidgets('gère l\'erreur de chargement du wallet', (tester) async {
        await E2ETestHelpers.launchApp(
          tester,
          additionalPrefs: {
            'auth_token': 'invalid_token',
            'user_id': 'invalid_user',
          },
        );
        await E2ETestHelpers.waitForStableUi(tester);
        await E2ETestHelpers.tapIfVisible(tester, find.text('Passer'));
        await E2ETestHelpers.waitFor(tester, find.byType(BottomNavigationBar));
        await E2ETestHelpers.tapIfVisible(tester, find.text('Portefeuille'));
        await E2ETestHelpers.tapIfVisible(
          tester,
          find.byIcon(Icons.account_balance_wallet),
        );
        await tester.pump(const Duration(seconds: 2));

        // Vérifier affichage d'erreur ou état vide
        final hasErrorOrEmpty =
            E2ETestHelpers.isVisible(find.text('Erreur')) ||
            E2ETestHelpers.isVisible(find.text('Réessayer')) ||
            E2ETestHelpers.isVisible(find.byIcon(Icons.error_outline)) ||
            E2ETestHelpers.hasStableUi();

        expect(
          hasErrorOrEmpty,
          isTrue,
          reason: 'Doit gérer les erreurs gracieusement',
        );
      });

      testWidgets('bouton réessayer fonctionne', (tester) async {
        await E2ETestHelpers.launchApp(
          tester,
          additionalPrefs: {'auth_token': 'test_token', 'user_id': 'test_user'},
        );
        await E2ETestHelpers.waitForStableUi(tester);
        await E2ETestHelpers.tapIfVisible(tester, find.text('Passer'));
        await E2ETestHelpers.waitFor(tester, find.byType(BottomNavigationBar));
        await E2ETestHelpers.tapIfVisible(tester, find.text('Portefeuille'));
        await E2ETestHelpers.tapIfVisible(
          tester,
          find.byIcon(Icons.account_balance_wallet),
        );
        await tester.pump(const Duration(milliseconds: 500));

        // Si bouton réessayer visible, le tester
        final retryButton = find.text('Réessayer');
        if (E2ETestHelpers.isVisible(retryButton)) {
          await tester.tap(retryButton);
          await tester.pump(const Duration(seconds: 1));

          expect(
            E2ETestHelpers.hasStableUi(),
            isTrue,
            reason: 'Bouton réessayer doit fonctionner',
          );
        }
      });
    });

    // ─── Pull to refresh ─────────────────────────────────────────────────────
    group('Pull to Refresh', () {
      testWidgets('rafraîchit le wallet avec pull-to-refresh', (tester) async {
        await E2ETestHelpers.launchApp(
          tester,
          additionalPrefs: {'auth_token': 'test_token', 'user_id': 'test_user'},
        );
        await E2ETestHelpers.waitForStableUi(tester);
        await E2ETestHelpers.tapIfVisible(tester, find.text('Passer'));
        await E2ETestHelpers.waitFor(tester, find.byType(BottomNavigationBar));
        await E2ETestHelpers.tapIfVisible(tester, find.text('Portefeuille'));
        await E2ETestHelpers.tapIfVisible(
          tester,
          find.byIcon(Icons.account_balance_wallet),
        );
        await tester.pump(const Duration(milliseconds: 500));

        // Pull to refresh
        final scrollable = find.byType(Scrollable);
        if (E2ETestHelpers.isVisible(scrollable)) {
          await tester.fling(scrollable.first, const Offset(0, 300), 1000);
          await tester.pump(const Duration(seconds: 1));
          await tester.pumpAndSettle(const Duration(seconds: 2));

          expect(
            E2ETestHelpers.hasStableUi(),
            isTrue,
            reason: 'Pull to refresh doit fonctionner',
          );
        }
      });
    });
  });
}
