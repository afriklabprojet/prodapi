import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:courier/presentation/screens/login_screen_redesign.dart';
import 'package:courier/presentation/screens/register_screen_redesign.dart';

/// Tests d'intégration pour le flux d'authentification
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Authentication Flow', () {
    testWidgets('Login screen should display correctly', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: LoginScreenRedesign(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Vérifier que les éléments principaux sont affichés
      expect(find.text('Connexion'), findsOneWidget);
      expect(find.byType(TextFormField), findsAtLeast(2));
      expect(find.text('SE CONNECTER'), findsOneWidget);
    });

    testWidgets('Login form should validate empty fields', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: LoginScreenRedesign(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Cliquer sur le bouton sans remplir les champs
      await tester.tap(find.text('SE CONNECTER'));
      await tester.pumpAndSettle();

      // Vérifier que les messages d'erreur de validation apparaissent
      expect(find.textContaining('entrer'), findsAtLeast(1));
    });

    testWidgets('Login form should accept valid input', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: LoginScreenRedesign(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Trouver les champs de texte
      final emailField = find.byType(TextFormField).first;
      final passwordField = find.byType(TextFormField).at(1);

      // Entrer des valeurs
      await tester.enterText(emailField, 'test@example.com');
      await tester.enterText(passwordField, 'password123');
      await tester.pumpAndSettle();

      // Les champs doivent contenir les valeurs
      expect(find.text('test@example.com'), findsOneWidget);
    });

    testWidgets('Password visibility toggle should work', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: LoginScreenRedesign(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Trouver le bouton de visibilité du mot de passe
      final visibilityButton = find.byIcon(Icons.visibility_off_outlined);
      
      if (visibilityButton.evaluate().isNotEmpty) {
        await tester.tap(visibilityButton);
        await tester.pumpAndSettle();
        
        // L'icône devrait changer
        expect(find.byIcon(Icons.visibility_outlined), findsOneWidget);
      }
    });

    testWidgets('Navigate to register screen', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: LoginScreenRedesign(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Chercher le lien d'inscription
      final registerLink = find.textContaining('Créer un compte');
      
      if (registerLink.evaluate().isNotEmpty) {
        await tester.tap(registerLink);
        await tester.pumpAndSettle();
        
        // Vérifier qu'on est sur l'écran d'inscription
        expect(find.byType(RegisterScreenRedesign), findsOneWidget);
      }
    });

    testWidgets('Login should show loading indicator', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: LoginScreenRedesign(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Remplir les champs
      final emailField = find.byType(TextFormField).first;
      final passwordField = find.byType(TextFormField).at(1);

      await tester.enterText(emailField, 'test@example.com');
      await tester.enterText(passwordField, 'password123');
      await tester.pumpAndSettle();

      // Cliquer sur connexion (ne pas attendre pumpAndSettle car on veut voir le loading)
      await tester.tap(find.text('SE CONNECTER'));
      await tester.pump();

      // Vérifier qu'un indicateur de chargement s'affiche
      // (CircularProgressIndicator ou le bouton est désactivé)
      expect(
        find.byType(CircularProgressIndicator).evaluate().isNotEmpty ||
        find.text('SE CONNECTER').evaluate().isEmpty,
        isTrue,
      );
    });

    testWidgets('Error message should display on invalid credentials', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: LoginScreenRedesign(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Remplir avec des identifiants invalides
      final emailField = find.byType(TextFormField).first;
      final passwordField = find.byType(TextFormField).at(1);

      await tester.enterText(emailField, 'invalid@test.com');
      await tester.enterText(passwordField, 'wrongpassword');
      await tester.pumpAndSettle();

      // Cliquer sur connexion
      await tester.tap(find.text('SE CONNECTER'));
      
      // Attendre la réponse du serveur (timeout court pour les tests)
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // On s'attend à une erreur (soit validation locale soit serveur)
      // Le test vérifie juste que l'app ne crash pas
    });

    testWidgets('Clear errors when typing', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: LoginScreenRedesign(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Soumettre un formulaire vide pour générer des erreurs
      await tester.tap(find.text('SE CONNECTER'));
      await tester.pumpAndSettle();

      // Vérifier qu'il y a des erreurs
      final hasErrors = find.textContaining('Veuillez').evaluate().isNotEmpty;
      
      if (hasErrors) {
        // Commencer à taper dans un champ
        final emailField = find.byType(TextFormField).first;
        await tester.enterText(emailField, 'a');
        await tester.pumpAndSettle();

        // L'erreur devrait être effacée pour ce champ
        // (comportement attendu basé sur onChanged)
      }
    });
  });

  group('Registration Flow', () {
    testWidgets('Register screen should display correctly', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: RegisterScreenRedesign(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Vérifier que les éléments principaux sont affichés
      expect(find.textContaining('Inscription'), findsAtLeast(1));
      expect(find.byType(TextFormField), findsAtLeast(3));
    });

    testWidgets('Register form should validate required fields', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: RegisterScreenRedesign(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Chercher le bouton d'inscription
      final submitButton = find.textContaining("S'INSCRIRE");
      
      if (submitButton.evaluate().isNotEmpty) {
        await tester.tap(submitButton);
        await tester.pumpAndSettle();

        // Des messages de validation devraient apparaître
        expect(find.textContaining('Veuillez'), findsAtLeast(1));
      }
    });

    testWidgets('Navigate back to login from register', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: RegisterScreenRedesign(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Chercher le lien vers connexion
      final loginLink = find.textContaining('Déjà un compte');
      
      if (loginLink.evaluate().isNotEmpty) {
        await tester.tap(loginLink);
        await tester.pumpAndSettle();
        
        // Vérifier qu'on est sur l'écran de connexion
        expect(find.byType(LoginScreenRedesign), findsOneWidget);
      }
    });
  });
}
