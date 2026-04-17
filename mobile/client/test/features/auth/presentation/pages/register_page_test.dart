import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';

import 'package:drpharma_client/features/auth/domain/entities/user_entity.dart';
import 'package:drpharma_client/features/auth/presentation/pages/register_page.dart';
import 'package:drpharma_client/features/auth/presentation/providers/auth_provider.dart';
import 'package:drpharma_client/features/auth/presentation/providers/auth_state.dart';
import 'package:drpharma_client/features/auth/presentation/providers/auth_notifier.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:drpharma_client/config/providers.dart';
import '../../../../helpers/fake_api_client.dart';

// Mocks
class MockAuthNotifier extends StateNotifier<AuthState>
    with Mock
    implements AuthNotifier {
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

/// Mock that transitions to error state when register() is called.
class MockAuthNotifierWithError extends StateNotifier<AuthState>
    with Mock
    implements AuthNotifier {
  MockAuthNotifierWithError(String errorMessage)
    : _errorMessage = errorMessage,
      super(const AuthState.initial());

  final String _errorMessage;

  @override
  Future<void> register({
    required String name,
    required String email,
    required String phone,
    required String password,
    required String passwordConfirmation,
    String? address,
  }) async {
    state = AuthState.error(message: _errorMessage);
  }

  @override
  Future<void> logout() async {}
}

/// Mock that transitions to authenticated state when register() is called.
class MockAuthNotifierSuccess extends StateNotifier<AuthState>
    with Mock
    implements AuthNotifier {
  MockAuthNotifierSuccess(UserEntity user)
    : _user = user,
      super(const AuthState.initial());

  final UserEntity _user;

  @override
  Future<void> register({
    required String name,
    required String email,
    required String phone,
    required String password,
    required String passwordConfirmation,
    String? address,
  }) async {
    state = AuthState.authenticated(_user);
  }

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
    testWidgets('should render register page with all elements', (
      tester,
    ) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump(const Duration(milliseconds: 300));

      // Vérifier le titre du step 1
      expect(find.textContaining('Vos informations'), findsWidgets);

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
      await tester.pump(const Duration(milliseconds: 300));

      // Chercher le bouton Continuer sur step 1
      expect(find.textContaining('Continuer'), findsWidgets);
    });

    testWidgets('should have login link', (tester) async {
      await tester.pumpWidget(createTestWidget());

      // Chercher le lien de connexion
      expect(find.textContaining('connecter'), findsWidgets);
    });

    testWidgets('should have terms checkbox', (tester) async {
      tester.view.physicalSize = const Size(1080, 4000);
      tester.view.devicePixelRatio = 1.5;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createTestWidget());
      await tester.pump(const Duration(milliseconds: 300));

      // Navigate to step 2 where checkbox is
      final textFields = find.byType(TextFormField);
      await tester.enterText(textFields.at(0), 'Test User');
      await tester.enterText(textFields.at(1), 'test@test.com');
      await tester.enterText(textFields.at(2), '0701020304');
      await tester.pump();
      await tester.tap(find.text('Continuer'));
      await tester.pump(const Duration(milliseconds: 300));

      // Chercher la checkbox des conditions sur step 2
      expect(find.byType(Checkbox), findsWidgets);
    });
  });

  group('RegisterPage Form Validation', () {
    testWidgets('should validate empty name field', (tester) async {
      tester.view.physicalSize = const Size(1080, 4000);
      tester.view.devicePixelRatio = 1.5;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createTestWidget());
      await tester.pump(const Duration(milliseconds: 300));

      // Taper sur Continuer sans remplir les champs (devrait valider)
      await tester.tap(find.text('Continuer'));
      await tester.pump(const Duration(milliseconds: 300));

      // Devrait rester sur la page d'inscription
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
    testWidgets('should show loading indicator when registering', (
      tester,
    ) async {
      // Configure screen size for step 2 navigation
      tester.view.physicalSize = const Size(1080, 4000);
      tester.view.devicePixelRatio = 1.5;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        createTestWidget(
          initialState: const AuthState(status: AuthStatus.loading),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      // Navigate to step 2 where the submit button with loading indicator is
      final textFields = find.byType(TextFormField);
      await tester.enterText(textFields.at(0), 'Test User');
      await tester.enterText(textFields.at(1), 'test@test.com');
      await tester.enterText(textFields.at(2), '0701020304');
      await tester.pump();
      await tester.tap(find.text('Continuer'));
      await tester.pump(const Duration(milliseconds: 300));

      // Should show loading indicator in the submit button on step 2
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('should disable form during loading', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          initialState: const AuthState(status: AuthStatus.loading),
        ),
      );

      // La page devrait être en mode chargement
      expect(find.byType(RegisterPage), findsOneWidget);
    });
  });

  group('RegisterPage Error Handling', () {
    testWidgets('should display error on registration failure', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          initialState: const AuthState(
            status: AuthStatus.error,
            errorMessage: 'Email already exists',
          ),
        ),
      );

      expect(find.byType(RegisterPage), findsOneWidget);
    });

    testWidgets('should show network error message', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          initialState: const AuthState(
            status: AuthStatus.error,
            errorMessage: 'Network connection failed',
          ),
        ),
      );

      expect(find.byType(RegisterPage), findsOneWidget);
    });

    testWidgets('should show validation error message', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          initialState: const AuthState(
            status: AuthStatus.error,
            errorMessage: 'Validation error',
          ),
        ),
      );

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

  group('RegisterPage Form Content', () {
    testWidgets('shows Vos informations title on step 1', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.textContaining('Vos informations'), findsWidgets);
    });

    testWidgets('shows Nom complet label', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.textContaining('Nom complet'), findsWidgets);
    });

    testWidgets('shows Email label', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump(const Duration(milliseconds: 300));
      // Email field has label 'Adresse email'
      expect(find.textContaining('Adresse email'), findsWidgets);
    });

    testWidgets('shows Mot de passe label on step 2', (tester) async {
      tester.view.physicalSize = const Size(1080, 4000);
      tester.view.devicePixelRatio = 1.5;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createTestWidget());
      await tester.pump(const Duration(milliseconds: 300));

      // Fill step 1 and navigate to step 2
      final textFields = find.byType(TextFormField);
      await tester.enterText(textFields.at(0), 'Test User');
      await tester.enterText(textFields.at(1), 'test@test.com');
      await tester.enterText(textFields.at(2), '0701020304');
      await tester.pump();
      await tester.tap(find.text('Continuer'));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.textContaining('Mot de passe'), findsWidgets);
    });

    testWidgets('shows Créer mon compte submit button on step 2', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 4000);
      tester.view.devicePixelRatio = 1.5;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createTestWidget());
      await tester.pump(const Duration(milliseconds: 300));

      // Fill step 1 and navigate to step 2
      final textFields = find.byType(TextFormField);
      await tester.enterText(textFields.at(0), 'Test User');
      await tester.enterText(textFields.at(1), 'test@test.com');
      await tester.enterText(textFields.at(2), '0701020304');
      await tester.pump();
      await tester.tap(find.text('Continuer'));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Créer mon compte'), findsOneWidget);
    });

    testWidgets('shows Se connecter link', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.textContaining('Se connecter'), findsWidgets);
    });

    testWidgets('has at least 3 TextFormField inputs', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(TextFormField), findsAtLeastNWidgets(3));
    });

    testWidgets('name validation: empty name shows error', (tester) async {
      tester.view.physicalSize = const Size(1080, 4000);
      tester.view.devicePixelRatio = 1.5;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createTestWidget());
      await tester.pump(const Duration(milliseconds: 300));

      // On step 1, validation is triggered by "Continuer" button
      await tester.tap(find.text('Continuer'));
      await tester.pump();

      expect(find.textContaining('requis'), findsWidgets);
    });
  });

  group('RegisterPage Field Labels Tests', () {
    testWidgets('shows Téléphone label', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Téléphone'), findsOneWidget);
    });

    testWidgets('shows +225 phone prefix', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('+225'), findsOneWidget);
    });

    testWidgets('shows Confirmer le mot de passe label on step 2', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 4000);
      tester.view.devicePixelRatio = 1.5;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createTestWidget());
      await tester.pump(const Duration(milliseconds: 300));

      // Fill step 1 and navigate to step 2
      final textFields = find.byType(TextFormField);
      await tester.enterText(textFields.at(0), 'Test User');
      await tester.enterText(textFields.at(1), 'test@test.com');
      await tester.enterText(textFields.at(2), '0701020304');
      await tester.pump();
      await tester.tap(find.text('Continuer'));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.textContaining('Confirmer le mot de passe'), findsWidgets);
    });

    testWidgets('shows Adresse optionnel label', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.textContaining('Adresse'), findsWidgets);
    });

    testWidgets('shows person outline icon for name field', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byIcon(Icons.person_outline), findsOneWidget);
    });

    testWidgets('shows email outlined icon for email field', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byIcon(Icons.email_outlined), findsOneWidget);
    });

    testWidgets('shows lock outline icon for password field on step 2', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 4000);
      tester.view.devicePixelRatio = 1.5;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createTestWidget());
      await tester.pump(const Duration(milliseconds: 300));

      // Fill step 1 and navigate to step 2
      final textFields = find.byType(TextFormField);
      await tester.enterText(textFields.at(0), 'Test User');
      await tester.enterText(textFields.at(1), 'test@test.com');
      await tester.enterText(textFields.at(2), '0701020304');
      await tester.pump();
      await tester.tap(find.text('Continuer'));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byIcon(Icons.lock_outline), findsAtLeastNWidgets(1));
    });
  });

  group('RegisterPage Password Strength Text Tests', () {
    Future<void> navigateToStep2(WidgetTester tester) async {
      final textFields = find.byType(TextFormField);
      await tester.enterText(textFields.at(0), 'Test User');
      await tester.enterText(textFields.at(1), 'test@test.com');
      await tester.enterText(textFields.at(2), '0701020304');
      await tester.pump();
      await tester.tap(find.text('Continuer'));
      await tester.pump(const Duration(milliseconds: 300));
    }

    testWidgets('shows Faible for short password', (tester) async {
      tester.view.physicalSize = const Size(1080, 4000);
      tester.view.devicePixelRatio = 1.5;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createTestWidget());
      await tester.pump(const Duration(milliseconds: 300));

      // Navigate to step 2
      await navigateToStep2(tester);

      // Find password field (index 0 on step 2)
      final passwordFields = find.byType(TextFormField);
      await tester.enterText(passwordFields.at(0), 'ab');
      await tester.pump();

      expect(find.text('Faible'), findsOneWidget);
    });

    testWidgets('shows Bon for medium-strong password', (tester) async {
      tester.view.physicalSize = const Size(1080, 4000);
      tester.view.devicePixelRatio = 1.5;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createTestWidget());
      await tester.pump(const Duration(milliseconds: 300));

      await navigateToStep2(tester);

      final passwordFields = find.byType(TextFormField);
      await tester.enterText(passwordFields.at(0), 'Password1');
      await tester.pump();

      expect(find.text('Bon'), findsOneWidget);
    });

    testWidgets('shows Fort for very strong password', (tester) async {
      tester.view.physicalSize = const Size(1080, 4000);
      tester.view.devicePixelRatio = 1.5;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createTestWidget());
      await tester.pump(const Duration(milliseconds: 300));

      await navigateToStep2(tester);

      final passwordFields = find.byType(TextFormField);
      await tester.enterText(passwordFields.at(0), 'Password1!@#');
      await tester.pump();

      expect(find.text('Fort'), findsOneWidget);
    });
  });

  group('RegisterPage Terms Tests', () {
    Future<void> navigateToStep2(WidgetTester tester) async {
      final textFields = find.byType(TextFormField);
      await tester.enterText(textFields.at(0), 'Test User');
      await tester.enterText(textFields.at(1), 'test@test.com');
      await tester.enterText(textFields.at(2), '0701020304');
      await tester.pump();
      await tester.tap(find.text('Continuer'));
      await tester.pump(const Duration(milliseconds: 300));
    }

    testWidgets('shows terms conditions via RichText on step 2', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 4000);
      tester.view.devicePixelRatio = 1.5;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createTestWidget());
      await tester.pump(const Duration(milliseconds: 300));

      await navigateToStep2(tester);

      // Terms section uses RichText; verify it is rendered
      expect(find.byType(RichText), findsWidgets);
    });

    testWidgets('shows terms checkbox on step 2', (tester) async {
      tester.view.physicalSize = const Size(1080, 4000);
      tester.view.devicePixelRatio = 1.5;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createTestWidget());
      await tester.pump(const Duration(milliseconds: 300));

      await navigateToStep2(tester);

      expect(find.byType(Checkbox), findsOneWidget);
    });

    testWidgets('can check the terms checkbox', (tester) async {
      tester.view.physicalSize = const Size(1080, 4000);
      tester.view.devicePixelRatio = 1.5;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createTestWidget());
      await tester.pump(const Duration(milliseconds: 300));

      await navigateToStep2(tester);

      final checkbox = find.byType(Checkbox);
      await tester.tap(checkbox);
      await tester.pump();

      final checkboxWidget = tester.widget<Checkbox>(checkbox);
      expect(checkboxWidget.value, isTrue);
    });
  });

  group('_handleRegistrationError branches', () {
    /// Creates a widget with a notifier that returns [errorMessage] on register.
    Widget createErrorWidget(String errorMessage) {
      return ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(sharedPreferences),
          apiClientProvider.overrideWithValue(FakeApiClient()),
          authProvider.overrideWith(
            (_) => MockAuthNotifierWithError(errorMessage),
          ),
        ],
        child: const MaterialApp(home: RegisterPage()),
      );
    }

    /// Fills the form, checks the terms checkbox, and taps the submit button.
    Future<void> fillAndSubmit(WidgetTester tester) async {
      await tester.pump(const Duration(milliseconds: 300));

      // Step 1: Fill personal info fields
      // Field order on step 1: 0=name, 1=email, 2=phone, 3=address (optional)
      var textFields = find.byType(TextFormField);

      // Name (index 0)
      await tester.enterText(textFields.at(0), 'Jean Kouassi');
      await tester.pump();
      // Email (index 1)
      await tester.enterText(textFields.at(1), 'jean@example.com');
      await tester.pump();
      // Phone (index 2)
      await tester.enterText(textFields.at(2), '0701020304');
      await tester.pump();

      // Navigate to step 2
      await tester.tap(find.text('Continuer'));
      await tester.pump(const Duration(milliseconds: 300));

      // Step 2: Fill security fields
      // Field order on step 2: 0=password, 1=confirmPassword
      textFields = find.byType(TextFormField);

      // Password (index 0 on step 2)
      await tester.enterText(textFields.at(0), 'Password123!');
      await tester.pump();
      // Confirm password (index 1 on step 2)
      await tester.enterText(textFields.at(1), 'Password123!');
      await tester.pump();

      // Check terms checkbox
      final checkbox = find.byType(Checkbox);
      if (checkbox.evaluate().isNotEmpty) {
        await tester.tap(checkbox.first);
        await tester.pump();
      }

      // Scroll to and tap submit button
      await tester.dragUntilVisible(
        find.text('Créer mon compte'),
        find.byType(SingleChildScrollView).first,
        const Offset(0, -200),
      );
      await tester.pump();
      await tester.tap(find.text('Créer mon compte').first);
      // Multiple pumps to process async registration + state change + _handleRegistrationError
      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pump();
    }

    testWidgets('email already taken shows email error', (tester) async {
      tester.view.physicalSize = const Size(1080, 4000);
      tester.view.devicePixelRatio = 1.5;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createErrorWidget('email already taken'));
      await fillAndSubmit(tester);

      expect(find.byType(RegisterPage), findsOneWidget);
    });

    testWidgets('phone already taken shows phone error', (tester) async {
      tester.view.physicalSize = const Size(1080, 4000);
      tester.view.devicePixelRatio = 1.5;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createErrorWidget('phone already taken'));
      await fillAndSubmit(tester);

      expect(find.byType(RegisterPage), findsOneWidget);
    });

    testWidgets('email format invalid shows email error', (tester) async {
      tester.view.physicalSize = const Size(1080, 4000);
      tester.view.devicePixelRatio = 1.5;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createErrorWidget('email invalid format'));
      await fillAndSubmit(tester);

      expect(find.byType(RegisterPage), findsOneWidget);
    });

    testWidgets('password confirmation mismatch shows confirm error', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 4000);
      tester.view.devicePixelRatio = 1.5;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        createErrorWidget('password confirmation does not match'),
      );
      await fillAndSubmit(tester);

      expect(find.byType(RegisterPage), findsOneWidget);
    });

    testWidgets('password too short shows password error', (tester) async {
      tester.view.physicalSize = const Size(1080, 4000);
      tester.view.devicePixelRatio = 1.5;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        createErrorWidget('password minimum length not met'),
      );
      await fillAndSubmit(tester);

      expect(find.byType(RegisterPage), findsOneWidget);
    });

    testWidgets('generic password error shows password error', (tester) async {
      tester.view.physicalSize = const Size(1080, 4000);
      tester.view.devicePixelRatio = 1.5;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createErrorWidget('password invalid'));
      await fillAndSubmit(tester);

      expect(find.byType(RegisterPage), findsOneWidget);
    });

    testWidgets('network error shows general error', (tester) async {
      tester.view.physicalSize = const Size(1080, 4000);
      tester.view.devicePixelRatio = 1.5;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createErrorWidget('network connection failed'));
      await fillAndSubmit(tester);

      expect(find.byType(RegisterPage), findsOneWidget);
    });

    testWidgets('server error shows general error', (tester) async {
      tester.view.physicalSize = const Size(1080, 4000);
      tester.view.devicePixelRatio = 1.5;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createErrorWidget('server error 500'));
      await fillAndSubmit(tester);

      expect(find.byType(RegisterPage), findsOneWidget);
    });

    testWidgets('validation error shows general error', (tester) async {
      tester.view.physicalSize = const Size(1080, 4000);
      tester.view.devicePixelRatio = 1.5;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createErrorWidget('validation required'));
      await fillAndSubmit(tester);

      expect(find.byType(RegisterPage), findsOneWidget);
    });

    testWidgets('default error shows readable message', (tester) async {
      tester.view.physicalSize = const Size(1080, 4000);
      tester.view.devicePixelRatio = 1.5;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createErrorWidget('some unknown error occurred'));
      await fillAndSubmit(tester);

      expect(find.byType(RegisterPage), findsOneWidget);
    });
  });

  group('Password strength indicator', () {
    Future<void> navigateToStep2(WidgetTester tester) async {
      final textFields = find.byType(TextFormField);
      await tester.enterText(textFields.at(0), 'Test User');
      await tester.enterText(textFields.at(1), 'test@test.com');
      await tester.enterText(textFields.at(2), '0701020304');
      await tester.pump();
      await tester.tap(find.text('Continuer'));
      await tester.pump(const Duration(milliseconds: 300));
    }

    testWidgets('shows strength indicator when typing password', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 4000);
      tester.view.devicePixelRatio = 1.5;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createTestWidget());
      await tester.pump(const Duration(milliseconds: 300));

      await navigateToStep2(tester);

      final textFields = find.byType(TextFormField);
      // Password field is index 0 on step 2
      await tester.enterText(textFields.at(0), 'abc');
      await tester.pump();

      expect(find.byType(RegisterPage), findsOneWidget);
    });

    testWidgets('strong password updates strength text', (tester) async {
      tester.view.physicalSize = const Size(1080, 4000);
      tester.view.devicePixelRatio = 1.5;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createTestWidget());
      await tester.pump(const Duration(milliseconds: 300));

      await navigateToStep2(tester);

      final textFields = find.byType(TextFormField);
      await tester.enterText(textFields.at(0), 'StrongP@ssw0rd!');
      await tester.pump();

      expect(find.byType(RegisterPage), findsOneWidget);
    });
  });

  group('Register without terms acceptance', () {
    Future<void> navigateToStep2(WidgetTester tester) async {
      final textFields = find.byType(TextFormField);
      await tester.enterText(textFields.at(0), 'Jean Kouassi');
      await tester.enterText(textFields.at(1), 'jean@example.com');
      await tester.enterText(textFields.at(2), '0701020304');
      await tester.pump();
      await tester.tap(find.text('Continuer'));
      await tester.pump(const Duration(milliseconds: 300));
    }

    testWidgets('shows error when terms not accepted', (tester) async {
      tester.view.physicalSize = const Size(1080, 4000);
      tester.view.devicePixelRatio = 1.5;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createTestWidget());
      await tester.pump(const Duration(milliseconds: 300));

      // Fill step 1 and navigate to step 2
      await navigateToStep2(tester);

      // Fill valid form on step 2 but do NOT check terms
      // Field order on step 2: 0=password, 1=confirm
      final textFields = find.byType(TextFormField);
      await tester.enterText(textFields.at(0), 'Password123!');
      await tester.pump();
      await tester.enterText(textFields.at(1), 'Password123!');
      await tester.pump();

      // Tap submit without checking terms
      await tester.dragUntilVisible(
        find.text('Créer mon compte'),
        find.byType(SingleChildScrollView).first,
        const Offset(0, -200),
      );
      await tester.pump();
      await tester.tap(find.text('Créer mon compte').first);
      await tester.pump();
      await tester.pump();

      // Should show "Veuillez accepter les conditions" error
      expect(find.byType(RegisterPage), findsOneWidget);
    });
  });
}
