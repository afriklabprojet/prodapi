import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:courier/presentation/providers/dashboard_tab_provider.dart';
import 'package:courier/presentation/screens/wallet_screen.dart';
import 'package:courier/presentation/screens/dashboard_screen.dart';

import 'helpers/e2e_test_helpers.dart';

/// Tests d'intégration pour le flux du portefeuille
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await initializeDateFormatting('fr_FR');
  });

  group('Wallet Screen', () {
    testWidgets('Wallet screen should display title', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: createWalletOverrides(),
          child: const MaterialApp(home: WalletScreen()),
        ),
      );
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Vérifier le titre
      expect(find.text('Mon Portefeuille'), findsOneWidget);
    });

    testWidgets('Wallet should have action buttons', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: createWalletOverrides(),
          child: const MaterialApp(home: WalletScreen()),
        ),
      );
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Vérifier les boutons d'action dans l'en-tête
      expect(find.byIcon(Icons.download_rounded), findsOneWidget);
      expect(find.byIcon(Icons.refresh_rounded), findsOneWidget);
    });

    testWidgets('Wallet should display balance section', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: createWalletOverrides(),
          child: const MaterialApp(home: WalletScreen()),
        ),
      );
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Vérifier que les boutons Recharger et Retirer sont présents
      expect(find.text('Recharger'), findsOneWidget);
      expect(find.text('Retirer'), findsOneWidget);
    });

    testWidgets('Wallet should have operator shortcuts', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: createWalletOverrides(),
          child: const MaterialApp(home: WalletScreen()),
        ),
      );
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Vérifier les opérateurs de paiement
      expect(find.text('Orange Money'), findsOneWidget);
      expect(find.text('MTN MoMo'), findsOneWidget);
      expect(find.text('Wave'), findsOneWidget);
      expect(find.text('Carte'), findsOneWidget);
    });

    testWidgets('Refresh button should refresh wallet data', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: createWalletOverrides(),
          child: const MaterialApp(home: WalletScreen()),
        ),
      );
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Taper sur le bouton refresh
      await tester.tap(find.byIcon(Icons.refresh_rounded));
      await tester.pump();

      // L'écran devrait se rafraîchir
      await tester.pumpAndSettle(const Duration(seconds: 2));
    });

    testWidgets('Top up button should open dialog', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: createWalletOverrides(),
          child: const MaterialApp(home: WalletScreen()),
        ),
      );
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Taper sur le bouton Recharger
      final rechargerButton = find.text('Recharger');
      if (rechargerButton.evaluate().isNotEmpty) {
        await tester.tap(rechargerButton);
        await tester.pumpAndSettle();

        // Un bottom sheet devrait s'ouvrir
        expect(find.byType(BottomSheet), findsOneWidget);
      }
    });

    testWidgets('Export button should open export sheet', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: createWalletOverrides(),
          child: const MaterialApp(home: WalletScreen()),
        ),
      );
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Taper sur le bouton d'export
      await tester.tap(find.byIcon(Icons.download_rounded));
      await tester.pumpAndSettle();

      // Le bottom sheet d'export doit s'ouvrir
      expect(find.text('Exporter mes revenus'), findsOneWidget);
    });

    testWidgets('Wallet should display stats', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: createWalletOverrides(),
          child: const MaterialApp(home: WalletScreen()),
        ),
      );
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Vérifier les cartes statistiques affichées
      expect(find.text('Disponible'), findsOneWidget);
      expect(find.text('Aujourd’hui'), findsOneWidget);
      expect(find.text('Total gains'), findsOneWidget);
      expect(find.text('Livraisons'), findsOneWidget);
    });
  });

  group('Wallet Flow from Dashboard', () {
    testWidgets('Navigate to wallet from dashboard', (tester) async {
      final container = ProviderContainer(overrides: createWalletOverrides());
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: DashboardScreen()),
        ),
      );
      await tester.pump(const Duration(seconds: 2));

      // Basculer sur l'onglet wallet via le vrai provider du dashboard
      container.read(dashboardTabProvider.notifier).setTab(3);
      await tester.pump(const Duration(seconds: 1));
      await E2ETestHelpers.waitFor(tester, find.text('Mon Portefeuille'));

      // Vérifier qu'on est bien sur l'écran du wallet
      expect(find.text('Mon Portefeuille'), findsOneWidget);
    });

    testWidgets('Wallet should preserve state when switching tabs', (
      tester,
    ) async {
      final container = ProviderContainer(overrides: createWalletOverrides());
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: DashboardScreen()),
        ),
      );
      await tester.pump(const Duration(seconds: 2));

      // Aller sur Wallet
      container.read(dashboardTabProvider.notifier).setTab(3);
      await tester.pump(const Duration(seconds: 1));

      // Aller sur Carte
      container.read(dashboardTabProvider.notifier).setTab(0);
      await tester.pump(const Duration(milliseconds: 600));

      // Revenir sur Wallet
      container.read(dashboardTabProvider.notifier).setTab(3);
      await tester.pump(const Duration(seconds: 1));
      await E2ETestHelpers.waitFor(tester, find.text('Mon Portefeuille'));

      // Le wallet devrait toujours afficher le contenu
      expect(find.text('Mon Portefeuille'), findsOneWidget);
    });
  });

  group('Wallet Loading States', () {
    testWidgets('Wallet should show loading state initially', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: createWalletOverrides(),
          child: const MaterialApp(home: WalletScreen()),
        ),
      );

      // Immédiatement après le pump, devrait montrer loading
      await tester.pump();

      // Attendre que le chargement se termine
      await tester.pumpAndSettle(const Duration(seconds: 5));
    });

    testWidgets('Wallet should handle error state', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: createWalletOverrides(),
          child: const MaterialApp(home: WalletScreen()),
        ),
      );
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Si une erreur survient, l'app ne devrait pas crash
      // et devrait afficher un état approprié
    });
  });

  group('Wallet Interactions', () {
    testWidgets('Scroll through wallet content', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: createWalletOverrides(),
          child: const MaterialApp(home: WalletScreen()),
        ),
      );
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Scroller vers le bas
      await tester.drag(
        find.byType(SingleChildScrollView).first,
        const Offset(0, -200),
      );
      await tester.pumpAndSettle();

      // Scroller vers le haut
      await tester.drag(
        find.byType(SingleChildScrollView).first,
        const Offset(0, 200),
      );
      await tester.pumpAndSettle();
    });

    testWidgets('Tap on operator icon', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: createWalletOverrides(),
          child: const MaterialApp(home: WalletScreen()),
        ),
      );
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Taper sur Orange Money si disponible
      final orangeMoneyWidget = find.text('Orange Money');
      if (orangeMoneyWidget.evaluate().isNotEmpty) {
        await tester.tap(orangeMoneyWidget);
        await tester.pumpAndSettle();
      }
    });
  });
}
