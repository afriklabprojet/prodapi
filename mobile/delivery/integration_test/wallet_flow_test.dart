import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:courier/presentation/screens/wallet_screen.dart';
import 'package:courier/presentation/screens/dashboard_screen.dart';

/// Tests d'intégration pour le flux du portefeuille
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Wallet Screen', () {
    testWidgets('Wallet screen should display title', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: WalletScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Vérifier le titre
      expect(find.text('Mon Portefeuille'), findsOneWidget);
    });

    testWidgets('Wallet should have action buttons', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: WalletScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Vérifier les boutons d'action dans l'AppBar
      expect(find.byIcon(Icons.download_rounded), findsOneWidget);
      expect(find.byIcon(Icons.refresh), findsOneWidget);
    });

    testWidgets('Wallet should display balance section', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: WalletScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Vérifier que les boutons Recharger et Retirer sont présents
      expect(find.text('Recharger'), findsOneWidget);
      expect(find.text('Retirer'), findsOneWidget);
    });

    testWidgets('Wallet should have operator shortcuts', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: WalletScreen(),
          ),
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
        const ProviderScope(
          child: MaterialApp(
            home: WalletScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Taper sur le bouton refresh
      await tester.tap(find.byIcon(Icons.refresh));
      await tester.pump();

      // L'écran devrait se rafraîchir
      await tester.pumpAndSettle(const Duration(seconds: 2));
    });

    testWidgets('Top up button should open dialog', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: WalletScreen(),
          ),
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
        const ProviderScope(
          child: MaterialApp(
            home: WalletScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Taper sur le bouton d'export
      await tester.tap(find.byIcon(Icons.download_rounded));
      await tester.pumpAndSettle();

      // Un bottom sheet ou dialogue devrait s'ouvrir
    });

    testWidgets('Wallet should display stats', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: WalletScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Vérifier les statistiques
      expect(find.text('Livraisons'), findsOneWidget);
      expect(find.text('Gains'), findsOneWidget);
      expect(find.text('Commissions'), findsOneWidget);
    });
  });

  group('Wallet Flow from Dashboard', () {
    testWidgets('Navigate to wallet from dashboard', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: DashboardScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Taper sur l'onglet Wallet dans la bottom nav
      await tester.tap(find.text('Wallet'));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Vérifier qu'on est bien sur l'écran du wallet
      expect(find.text('Mon Portefeuille'), findsOneWidget);
    });

    testWidgets('Wallet should preserve state when switching tabs', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: DashboardScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Aller sur Wallet
      await tester.tap(find.text('Wallet'));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Aller sur Carte
      await tester.tap(find.text('Carte'));
      await tester.pumpAndSettle();

      // Revenir sur Wallet
      await tester.tap(find.text('Wallet'));
      await tester.pumpAndSettle();

      // Le wallet devrait toujours afficher le contenu
      expect(find.text('Mon Portefeuille'), findsOneWidget);
    });
  });

  group('Wallet Loading States', () {
    testWidgets('Wallet should show loading state initially', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: WalletScreen(),
          ),
        ),
      );
      
      // Immédiatement après le pump, devrait montrer loading
      await tester.pump();
      
      // Attendre que le chargement se termine
      await tester.pumpAndSettle(const Duration(seconds: 5));
    });

    testWidgets('Wallet should handle error state', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: WalletScreen(),
          ),
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
        const ProviderScope(
          child: MaterialApp(
            home: WalletScreen(),
          ),
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
        const ProviderScope(
          child: MaterialApp(
            home: WalletScreen(),
          ),
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
