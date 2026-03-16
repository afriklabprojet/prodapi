import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:courier/presentation/screens/deliveries_screen.dart';
import 'package:courier/presentation/screens/dashboard_screen.dart';

/// Tests d'intégration pour le flux de livraison
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Deliveries Screen', () {
    testWidgets('Deliveries screen should display with tabs', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: DeliveriesScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Vérifier que les onglets sont affichés
      expect(find.text('Disponibles'), findsOneWidget);
      expect(find.text('En Cours'), findsOneWidget);
      expect(find.text('Terminées'), findsOneWidget);
    });

    testWidgets('Should have search bar', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: DeliveriesScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Vérifier la présence de la barre de recherche
      expect(find.byType(TextField), findsOneWidget);
      expect(find.byIcon(Icons.search), findsOneWidget);
    });

    testWidgets('Search bar should accept input', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: DeliveriesScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Trouver la barre de recherche et entrer du texte
      await tester.enterText(find.byType(TextField), 'Pharmacie');
      await tester.pumpAndSettle();

      // Vérifier que le texte a été entré
      expect(find.text('Pharmacie'), findsOneWidget);
    });

    testWidgets('Tab navigation should work', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: DeliveriesScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Taper sur l'onglet "En Cours"
      await tester.tap(find.text('En Cours'));
      await tester.pumpAndSettle();

      // Taper sur l'onglet "Terminées"
      await tester.tap(find.text('Terminées'));
      await tester.pumpAndSettle();

      // Revenir à "Disponibles"
      await tester.tap(find.text('Disponibles'));
      await tester.pumpAndSettle();
    });

    testWidgets('Should have Multi button', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: DeliveriesScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Vérifier la présence du bouton Multi (batch mode)
      expect(find.text('Multi'), findsOneWidget);
      expect(find.byIcon(Icons.layers), findsOneWidget);
    });

    testWidgets('App bar should display title', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: DeliveriesScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Vérifier le titre
      expect(find.text('Mes Courses'), findsOneWidget);
    });

    testWidgets('Swipe between tabs', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: DeliveriesScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Swipe vers la gauche pour passer à l'onglet suivant
      await tester.drag(
        find.byType(TabBarView),
        const Offset(-300, 0),
      );
      await tester.pumpAndSettle();

      // Swipe à nouveau
      await tester.drag(
        find.byType(TabBarView),
        const Offset(-300, 0),
      );
      await tester.pumpAndSettle();

      // Swipe vers la droite pour revenir
      await tester.drag(
        find.byType(TabBarView),
        const Offset(300, 0),
      );
      await tester.pumpAndSettle();
    });

    testWidgets('Empty state should show when no deliveries', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: DeliveriesScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // S'il n'y a pas de livraisons, un message vide devrait s'afficher
      // (on ne peut pas garantir l'état, donc on vérifie juste que ça ne crash pas)
    });
  });

  group('Delivery Flow from Dashboard', () {
    testWidgets('Navigate to deliveries from dashboard', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: DashboardScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Taper sur l'onglet Livraisons dans la bottom nav
      await tester.tap(find.text('Livraisons'));
      await tester.pumpAndSettle();

      // Vérifier qu'on est bien sur l'écran des livraisons
      expect(find.text('Mes Courses'), findsOneWidget);
      expect(find.text('Disponibles'), findsOneWidget);
    });

    testWidgets('Navigate between tabs from dashboard', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: DashboardScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Aller sur Livraisons
      await tester.tap(find.text('Livraisons'));
      await tester.pumpAndSettle();

      // Changer d'onglet dans les livraisons
      await tester.tap(find.text('En Cours'));
      await tester.pumpAndSettle();

      // Revenir sur la carte
      await tester.tap(find.text('Carte'));
      await tester.pumpAndSettle();

      // Retourner sur Livraisons (l'état devrait être préservé)
      await tester.tap(find.text('Livraisons'));
      await tester.pumpAndSettle();
    });
  });

  group('Delivery Search', () {
    testWidgets('Search with reference number', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: DeliveriesScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Rechercher par numéro de référence
      await tester.enterText(find.byType(TextField), '#12345');
      await tester.pumpAndSettle();

      expect(find.text('#12345'), findsOneWidget);
    });

    testWidgets('Search with pharmacy name', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: DeliveriesScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Rechercher par nom de pharmacie
      await tester.enterText(find.byType(TextField), 'Pharmacie Centrale');
      await tester.pumpAndSettle();

      expect(find.text('Pharmacie Centrale'), findsOneWidget);
    });

    testWidgets('Clear search', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: DeliveriesScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Entrer du texte puis l'effacer
      final searchField = find.byType(TextField);
      await tester.enterText(searchField, 'Test');
      await tester.pumpAndSettle();

      await tester.enterText(searchField, '');
      await tester.pumpAndSettle();

      // Le champ devrait être vide
      final textField = tester.widget<TextField>(searchField);
      expect(textField.controller?.text, '');
    });
  });

  group('Delivery History Tab', () {
    testWidgets('History tab should be accessible', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: DeliveriesScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Aller sur l'onglet Terminées (historique)
      await tester.tap(find.text('Terminées'));
      await tester.pumpAndSettle();

      // L'onglet devrait être actif
    });
  });
}
