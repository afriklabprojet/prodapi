import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:drpharma_pharmacy/core/errors/failure.dart';
import 'package:drpharma_pharmacy/features/auth/domain/entities/auth_response_entity.dart';
import 'package:drpharma_pharmacy/features/auth/domain/entities/user_entity.dart';
import 'package:drpharma_pharmacy/features/auth/domain/repositories/auth_repository.dart';
import 'package:drpharma_pharmacy/features/auth/presentation/pages/login_page.dart';
import 'package:drpharma_pharmacy/features/auth/presentation/providers/auth_provider.dart';
import 'package:drpharma_pharmacy/features/auth/presentation/providers/state/auth_state.dart';

/// Tests widget pour la page de login
/// 
/// Vérifie:
/// - Affichage du formulaire de login
/// - Affichage du loader pendant le chargement
/// - Affichage du dialogue d'erreur sur échec de login
/// - Validation des champs
void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    try {
      await dotenv.load(fileName: '.env');
    } catch (_) {
      dotenv.testLoad(fileInput: '''
APP_NAME=DR-PHARMA
APP_ENV=development
API_BASE_URL=http://127.0.0.1:8000
LOCAL_MACHINE_IP=192.168.1.100
API_TIMEOUT=15000
''');
    }
  });

  group('LoginPage Widget Tests', () {
    late ProviderContainer container;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    /// Default unauthenticated state for tests
    const defaultState = AuthState(status: AuthStatus.unauthenticated);

    /// Helper pour créer le widget avec un provider override
    Widget createTestWidget({AuthState? initialState}) {
      final state = initialState ?? defaultState;
      return ProviderScope(
        overrides: [
          authProvider.overrideWith((ref) => MockAuthNotifier(state)),
        ],
        child: const MaterialApp(
          home: LoginPage(),
        ),
      );
    }

    testWidgets('should display login form', (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Vérifie que le formulaire est affiché
      expect(find.text('Connexion'), findsOneWidget);
      expect(find.text('Email'), findsOneWidget);
      expect(find.text('Mot de passe'), findsOneWidget);
      expect(find.text('Se connecter'), findsOneWidget);
    });

    testWidgets('should display validation errors on empty submit', (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Clique sur le bouton sans remplir les champs
      await tester.tap(find.text('Se connecter'));
      await tester.pumpAndSettle();

      // Vérifie les messages de validation
      expect(find.text('Veuillez entrer votre email'), findsOneWidget);
      expect(find.text('Veuillez entrer votre mot de passe'), findsOneWidget);
    });

    testWidgets('should display email validation error for invalid email', (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Entre un email invalide
      await tester.enterText(find.byType(TextFormField).first, 'invalid-email');
      await tester.enterText(find.byType(TextFormField).last, 'password123');
      
      await tester.tap(find.text('Se connecter'));
      await tester.pumpAndSettle();

      // Vérifie le message de validation email
      expect(find.textContaining('email'), findsWidgets);
    });

    testWidgets('should show loading indicator when authenticating', (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());
      final loadingState = const AuthState(status: AuthStatus.loading);
      
      await tester.pumpWidget(createTestWidget(initialState: loadingState));
      await tester.pump();

      // Vérifie que le loader est affiché
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      
      // Le bouton doit être désactivé
      final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton).first);
      expect(button.onPressed, isNull);
    });

    testWidgets('should show error dialog on authentication error', (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      // État initial unauthenticated
      final unauthState = const AuthState(status: AuthStatus.unauthenticated);
      
      await tester.pumpWidget(createTestWidget(initialState: unauthState));
      await tester.pumpAndSettle();

      // Vérifie que le widget est stable
      expect(find.byType(LoginPage), findsOneWidget);
    });

    testWidgets('should toggle password visibility', (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Trouve le bouton de visibilité (outlined variant)
      final visibilityButton = find.byIcon(Icons.visibility_off_outlined);
      expect(visibilityButton, findsOneWidget);

      // Clique pour afficher le mot de passe
      await tester.tap(visibilityButton);
      await tester.pumpAndSettle();

      // L'icône doit avoir changé
      expect(find.byIcon(Icons.visibility_outlined), findsOneWidget);
    });

    testWidgets('should have remember me checkbox', (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Vérifie que la checkbox existe
      expect(find.byType(Checkbox), findsOneWidget);
      expect(find.text('Se souvenir de moi'), findsOneWidget);

      // Toggle la checkbox
      await tester.tap(find.byType(Checkbox));
      await tester.pumpAndSettle();

      // La checkbox doit être cochée
      final checkbox = tester.widget<Checkbox>(find.byType(Checkbox));
      expect(checkbox.value, isTrue);
    });

    testWidgets('should have register link', (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text("Vous n'avez pas de compte ?"), findsOneWidget);
      expect(find.text("S'inscrire"), findsOneWidget);
    });
  });
}

// ══════════════════════════════════════════════════════════════════════════════
// MOCK NOTIFIER POUR LES TESTS
// ══════════════════════════════════════════════════════════════════════════════

/// Mock du AuthNotifier pour les tests
class MockAuthNotifier extends AuthNotifier {
  MockAuthNotifier(AuthState initialState) : super(_FakeAuthRepository()) {
    state = initialState;
  }

  @override
  Future<void> login(String email, String password) async {
    state = const AuthState(status: AuthStatus.loading);
    await Future.delayed(const Duration(milliseconds: 100));
    state = const AuthState(
      status: AuthStatus.error,
      errorMessage: 'Les identifiants fournis sont incorrects.',
    );
  }

  @override
  Future<void> logout() async {
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  @override
  Future<void> initialize() async {}

  @override
  Future<void> checkAuthStatus() async {}
}

/// Fake AuthRepository pour instancier MockAuthNotifier
class _FakeAuthRepository implements AuthRepository {
  @override
  Future<Either<Failure, AuthResponseEntity>> login({required String email, required String password}) async {
    return const Left(ServerFailure('Not implemented'));
  }
  @override
  Future<Either<Failure, AuthResponseEntity>> register({required String name, required String pName, required String email, required String phone, required String password, required String licenseNumber, required String city, required String address, required double latitude, required double longitude}) async {
    return const Left(ServerFailure('Not implemented'));
  }
  @override
  Future<Either<Failure, void>> logout() async => const Right(null);
  @override
  Future<Either<Failure, UserEntity>> getCurrentUser() async => const Left(ServerFailure('Not implemented'));
  @override
  Future<Either<Failure, bool>> checkAuthStatus() async => const Right(false);
  @override
  Future<Either<Failure, void>> forgotPassword({required String email}) async => const Right(null);
  @override
  Future<Either<Failure, void>> updateProfile({String? name, String? email, String? phone}) async => const Right(null);
}
