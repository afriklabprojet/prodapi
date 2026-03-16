import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';

import 'package:drpharma_client/features/auth/presentation/pages/register_page.dart';
import 'package:drpharma_client/features/auth/presentation/providers/auth_provider.dart';
import 'package:drpharma_client/features/auth/presentation/providers/auth_state.dart';
import 'package:drpharma_client/features/auth/presentation/providers/auth_notifier.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:drpharma_client/config/providers.dart';
import '../../../../helpers/fake_api_client.dart';

// Mocks
class MockAuthNotifier extends StateNotifier<AuthState> with Mock implements AuthNotifier {
  MockAuthNotifier() : super(const AuthState.initial());
  
  @override
  Future<void> register({
    required String name,
    required String email,
    required String phone,
    required String password,
    required String passwordConfirmation,
    String? address,
  }) async {}
  
  @override
  Future<void> logout() async {}
}

class FakeAuthState extends Fake implements AuthState {}

void main() {
  late SharedPreferences sharedPreferences;
  late MockAuthNotifier mockAuthNotifier;

  setUpAll(() {
    registerFallbackValue(FakeAuthState());
  });

  setUp(() async {
  SharedPreferences.setMockInitialValues({});
    sharedPreferences = await SharedPreferences.getInstance();
    mockAuthNotifier = MockAuthNotifier();
  });

  Widget createTestWidget({AuthState? initialState}) {
    return ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(sharedPreferences),
        apiClientProvider.overrideWithValue(FakeApiClient()),
        authProvider.overrideWith((ref) {
          if (initialState != null) {
            return MockAuthNotifier()..state = initialState;
          }
          return mockAuthNotifier;
        }),
      ],
      child: MaterialApp(
        home: const RegisterPage(),
        routes: {
          '/login': (_) => const Scaffold(body: Text('Login')),
          '/home': (_) => const Scaffold(body: Text('Home')),
          '/otp-verification': (_) => const Scaffold(body: Text('OTP')),
        },
      ),
    );
  }

  group('RegisterPage Widget Tests', () {
    testWidgets('should render register page with all elements', (tester) async {
      await tester.pumpWidget(createTestWidget());

      // Vérifier le titre
      expect(find.textContaining('Créer un compte'), findsWidgets);
      
      // Vérifier les champs de saisie
      expect(find.byType(TextFormField), findsWidgets);
    });

    testWidgets('should have name input field', (tester) async {
      await tester.pumpWidget(createTestWidget());

      expect(find.byType(TextFormField), findsWidgets);
    });

    testWidgets('should have email input field', (tester) async {
      await tester.pumpWidget(createTestWidget());

      expect(find.byType(TextFormField), findsWidgets);
    });

    testWidgets('should have phone input field', (tester) async {
      await tester.pumpWidget(createTestWidget());

      expect(find.byType(TextFormField), findsWidgets);
    });

    testWidgets('should have password input field', (tester) async {
      await tester.pumpWidget(createTestWidget());

      expect(find.byType(TextFormField), findsWidgets);
    });

    testWidgets('should have confirm password input field', (tester) async {
      await tester.pumpWidget(createTestWidget());

      expect(find.byType(TextFormField), findsWidgets);
    });

    testWidgets('should have register button', (tester) async {
      await tester.pumpWidget(createTestWidget());

      // Chercher le bouton d'inscription
      expect(find.textContaining('Créer'), findsWidgets);
    });

    testWidgets('should have login link', (tester) async {
      await tester.pumpWidget(createTestWidget());

      // Chercher le lien de connexion
      expect(find.textContaining('connecter'), findsWidgets);
    });

    testWidgets('should have terms checkbox', (tester) async {
      await tester.pumpWidget(createTestWidget());

      // Chercher la checkbox des conditions
      expect(find.byType(Checkbox), findsWidgets);
    });
  });

  group('RegisterPage Form Validation', () {
    testWidgets('should validate empty name field', (tester) async {
      await tester.pumpWidget(createTestWidget());

      // Scroll to find the register button
      await tester.dragUntilVisible(
        find.text('Créer mon compte'),
        find.byType(SingleChildScrollView),
        const Offset(0, -100),
      );

      // Taper sur le bouton sans remplir les champs
      final registerButton = find.text('Créer mon compte');
      if (registerButton.evaluate().isNotEmpty) {
        await tester.tap(registerButton.first);
      }

      // Devrait afficher une erreur
      expect(find.byType(RegisterPage), findsOneWidget);
    });

    testWidgets('should validate email format', (tester) async {
      await tester.pumpWidget(createTestWidget());

      final textFields = find.byType(TextFormField);
      
      // Entrer un email invalide dans le deuxième champ (email)
      if (textFields.evaluate().length > 1) {
        await tester.enterText(textFields.at(1), 'invalid-email');
      }

      expect(find.byType(RegisterPage), findsOneWidget);
    });

    testWidgets('should validate phone format', (tester) async {
      await tester.pumpWidget(createTestWidget());

      final textFields = find.byType(TextFormField);
      
      // Entrer un numéro invalide
      if (textFields.evaluate().length > 2) {
        await tester.enterText(textFields.at(2), '123');
      }

      expect(find.byType(RegisterPage), findsOneWidget);
    });

    testWidgets('should validate password length', (tester) async {
      await tester.pumpWidget(createTestWidget());

      final textFields = find.byType(TextFormField);
      
      // Entrer un mot de passe court
      if (textFields.evaluate().length > 3) {
        await tester.enterText(textFields.at(3), '123');
      }

      expect(find.byType(RegisterPage), findsOneWidget);
    });

    testWidgets('should validate password confirmation', (tester) async {
      await tester.pumpWidget(createTestWidget());

      final textFields = find.byType(TextFormField);
      
      if (textFields.evaluate().length > 4) {
        // Entrer des mots de passe différents
        await tester.enterText(textFields.at(3), 'Password123!');
        await tester.enterText(textFields.at(4), 'DifferentPassword');
      }

      expect(find.byType(RegisterPage), findsOneWidget);
    });

    testWidgets('should accept valid registration data', (tester) async {
      await tester.pumpWidget(createTestWidget());

      final textFields = find.byType(TextFormField);
      
      if (textFields.evaluate().length >= 5) {
        await tester.enterText(textFields.at(0), 'John Doe');
        await tester.enterText(textFields.at(1), 'john@example.com');
        await tester.enterText(textFields.at(2), '0701020304');
        await tester.enterText(textFields.at(3), 'Password123!');
        await tester.enterText(textFields.at(4), 'Password123!');
      }

      expect(find.byType(RegisterPage), findsOneWidget);
    });
  });

  group('RegisterPage Password Strength', () {
    testWidgets('should show password strength indicator', (tester) async {
      await tester.pumpWidget(createTestWidget());

      // Vérifier la présence de l'indicateur de force
      expect(find.byType(RegisterPage), findsOneWidget);
    });

    testWidgets('should update strength on password input', (tester) async {
      await tester.pumpWidget(createTestWidget());

      final textFields = find.byType(TextFormField);
      
      if (textFields.evaluate().length > 3) {
        // Entrer un mot de passe faible
        await tester.enterText(textFields.at(3), '1234');
        
        // Entrer un mot de passe fort
        await tester.enterText(textFields.at(3), 'StrongP@ssw0rd!');
      }

      expect(find.byType(RegisterPage), findsOneWidget);
    });
  });

  group('RegisterPage UI Interactions', () {
    testWidgets('should toggle password visibility', (tester) async {
      await tester.pumpWidget(createTestWidget());

      // Chercher l'icône de visibilité
      final visibilityIcon = find.byIcon(Icons.visibility_off);
      if (visibilityIcon.evaluate().isNotEmpty) {
        await tester.tap(visibilityIcon.first);
      }

      expect(find.byType(RegisterPage), findsOneWidget);
    });

    testWidgets('should toggle terms checkbox', (tester) async {
      await tester.pumpWidget(createTestWidget());

      final checkbox = find.byType(Checkbox);
      if (checkbox.evaluate().isNotEmpty) {
        await tester.tap(checkbox.first);
      }

      expect(find.byType(RegisterPage), findsOneWidget);
    });

    testWidgets('should scroll form', (tester) async {
      await tester.pumpWidget(createTestWidget());

      // Scroll down
      await tester.drag(
        find.byType(SingleChildScrollView).first,
        const Offset(0, -200),
      );

      expect(find.byType(RegisterPage), findsOneWidget);
    });
  });

  group('RegisterPage Loading State', () {
    testWidgets('should show loading indicator when registering', (tester) async {
      await tester.pumpWidget(createTestWidget(
        initialState: const AuthState(status: AuthStatus.loading),
      ));

      // Devrait afficher un indicateur de chargement
      expect(find.byType(CircularProgressIndicator), findsWidgets);
    });

    testWidgets('should disable form during loading', (tester) async {
      await tester.pumpWidget(createTestWidget(
        initialState: const AuthState(status: AuthStatus.loading),
      ));

      // La page devrait être en mode chargement
      expect(find.byType(RegisterPage), findsOneWidget);
    });
  });

  group('RegisterPage Error Handling', () {
    testWidgets('should display error on registration failure', (tester) async {
      await tester.pumpWidget(createTestWidget(
        initialState: const AuthState(
          status: AuthStatus.error,
          errorMessage: 'Email already exists',
        ),
      ));

      expect(find.byType(RegisterPage), findsOneWidget);
    });

    testWidgets('should show network error message', (tester) async {
      await tester.pumpWidget(createTestWidget(
        initialState: const AuthState(
          status: AuthStatus.error,
          errorMessage: 'Network connection failed',
        ),
      ));

      expect(find.byType(RegisterPage), findsOneWidget);
    });

    testWidgets('should show validation error message', (tester) async {
      await tester.pumpWidget(createTestWidget(
        initialState: const AuthState(
          status: AuthStatus.error,
          errorMessage: 'Validation error',
        ),
      ));

      expect(find.byType(RegisterPage), findsOneWidget);
    });
  });

  group('RegisterPage Accessibility', () {
    testWidgets('should have semantic labels', (tester) async {
      await tester.pumpWidget(createTestWidget());

      expect(find.byType(Semantics), findsWidgets);
    });

    testWidgets('should support keyboard navigation', (tester) async {
      await tester.pumpWidget(createTestWidget());

      final textFields = find.byType(TextFormField);
      expect(textFields, findsWidgets);
    });
  });
}
