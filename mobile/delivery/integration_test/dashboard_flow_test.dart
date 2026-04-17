import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:courier/presentation/screens/dashboard_screen.dart';

/// Tests d'intégration pour le flux du dashboard
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Dashboard Navigation', () {
    testWidgets('Dashboard should display with bottom navigation', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: DashboardScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Vérifier que le bottom navigation bar est affiché
      expect(find.byType(BottomNavigationBar), findsOneWidget);
      
      // Vérifier que les 5 onglets sont présents
      expect(find.text('Carte'), findsOneWidget);
      expect(find.text('Livraisons'), findsOneWidget);
      expect(find.text('Défis'), findsOneWidget);
      expect(find.text('Wallet'), findsOneWidget);
      expect(find.text('Profil'), findsOneWidget);
    });

    testWidgets('Default tab should be Carte (Home)', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: DashboardScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Le premier onglet (Carte/Home) devrait être sélectionné par défaut
      final bottomNav = tester.widget<BottomNavigationBar>(
        find.byType(BottomNavigationBar),
      );
      expect(bottomNav.currentIndex, 0);
    });

    testWidgets('Tap on Livraisons tab should navigate', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: DashboardScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Taper sur l'onglet Livraisons
      await tester.tap(find.text('Livraisons'));
      await tester.pumpAndSettle();

      // Vérifier que l'index a changé
      final bottomNav = tester.widget<BottomNavigationBar>(
        find.byType(BottomNavigationBar),
      );
      expect(bottomNav.currentIndex, 1);
    });

    testWidgets('Tap on Défis tab should navigate', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: DashboardScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Taper sur l'onglet Défis
      await tester.tap(find.text('Défis'));
      await tester.pumpAndSettle();

      // Vérifier que l'index a changé
      final bottomNav = tester.widget<BottomNavigationBar>(
        find.byType(BottomNavigationBar),
      );
      expect(bottomNav.currentIndex, 2);
    });

    testWidgets('Tap on Wallet tab should navigate', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: DashboardScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Taper sur l'onglet Wallet
      await tester.tap(find.text('Wallet'));
      await tester.pumpAndSettle();

      // Vérifier que l'index a changé
      final bottomNav = tester.widget<BottomNavigationBar>(
        find.byType(BottomNavigationBar),
      );
      expect(bottomNav.currentIndex, 3);
    });

    testWidgets('Tap on Profil tab should navigate', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: DashboardScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Taper sur l'onglet Profil
      await tester.tap(find.text('Profil'));
      await tester.pumpAndSettle();

      // Vérifier que l'index a changé
      final bottomNav = tester.widget<BottomNavigationBar>(
        find.byType(BottomNavigationBar),
      );
      expect(bottomNav.currentIndex, 4);
    });

    testWidgets('Navigate through all tabs', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: DashboardScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Navigation circulaire entre tous les onglets
      final tabs = ['Carte', 'Livraisons', 'Défis', 'Wallet', 'Profil'];
      
      for (var i = 0; i < tabs.length; i++) {
        await tester.tap(find.text(tabs[i]));
        await tester.pumpAndSettle();
        
        final bottomNav = tester.widget<BottomNavigationBar>(
          find.byType(BottomNavigationBar),
        );
        expect(bottomNav.currentIndex, i);
      }
    });

    testWidgets('IndexedStack should preserve state when switching tabs', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: DashboardScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // IndexedStack garde tous les widgets en mémoire
      expect(find.byType(IndexedStack), findsOneWidget);
      
      // Naviguer vers Wallet puis revenir à Carte
      await tester.tap(find.text('Wallet'));
      await tester.pumpAndSettle();
      
      await tester.tap(find.text('Carte'));
      await tester.pumpAndSettle();
      
      // Vérifier qu'on est bien revenu sur le premier onglet
      final bottomNav = tester.widget<BottomNavigationBar>(
        find.byType(BottomNavigationBar),
      );
      expect(bottomNav.currentIndex, 0);
    });
  });

  group('Dashboard Icons', () {
    testWidgets('Icons should change when tab is selected', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: DashboardScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Sur l'onglet Carte, l'icône devrait être remplie (Icons.map)
      expect(find.byIcon(Icons.map), findsOneWidget);
      expect(find.byIcon(Icons.map_outlined), findsNothing);
      
      // Les autres icônes devraient être outlined
      expect(find.byIcon(Icons.list_alt_outlined), findsOneWidget);
      expect(find.byIcon(Icons.emoji_events_outlined), findsOneWidget);
      expect(find.byIcon(Icons.account_balance_wallet_outlined), findsOneWidget);
      expect(find.byIcon(Icons.person_outline), findsOneWidget);
    });

    testWidgets('Active icon should change when navigating', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: DashboardScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Naviguer vers Livraisons
      await tester.tap(find.text('Livraisons'));
      await tester.pumpAndSettle();

      // L'icône Livraisons devrait être remplie
      expect(find.byIcon(Icons.list_alt), findsOneWidget);
      // Et l'icône Carte devrait être outlined maintenant
      expect(find.byIcon(Icons.map_outlined), findsOneWidget);
    });
  });

  group('Dashboard Responsiveness', () {
    testWidgets('Dashboard should handle screen rotation', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: DashboardScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Simuler une rotation d'écran
      await tester.binding.setSurfaceSize(const Size(800, 600));
      await tester.pumpAndSettle();

      // Le dashboard devrait toujours fonctionner
      expect(find.byType(BottomNavigationBar), findsOneWidget);
      
      // Retour à la taille normale
      await tester.binding.setSurfaceSize(const Size(400, 800));
      await tester.pumpAndSettle();
    });
  });
}
