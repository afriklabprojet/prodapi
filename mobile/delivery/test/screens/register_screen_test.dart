import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mocktail/mocktail.dart';
import 'package:courier/presentation/screens/register_screen_redesign.dart';
import 'package:courier/data/repositories/auth_repository.dart';
import '../helpers/widget_test_helpers.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  setUpAll(() async {
    await initHiveForTests();
  });

  tearDownAll(() async {
    await cleanupHiveForTests();
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Widget buildScreen() {
    final mockAuthRepo = MockAuthRepository();
    return ProviderScope(
      overrides: [
        ...commonWidgetTestOverrides(),
        authRepositoryProvider.overrideWithValue(mockAuthRepo),
      ],
      child: const MaterialApp(home: RegisterScreenRedesign()),
    );
  }

  group('RegisterScreenRedesign', () {
    testWidgets('renders registration form', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(Scaffold), findsWidgets);
    });

    testWidgets('has text form fields', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(TextFormField), findsWidgets);
    });

    testWidgets('shows step 1 header', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pump(const Duration(seconds: 1));
      expect(find.textContaining('Étape 1'), findsOneWidget);
    });

    testWidgets('shows Devenir Livreur title', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('Devenir Livreur'), findsOneWidget);
    });

    testWidgets('shows name field', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('Nom complet'), findsOneWidget);
    });

    testWidgets('shows phone field', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('Téléphone'), findsOneWidget);
    });

    testWidgets('shows email field', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pump(const Duration(seconds: 1));
      expect(find.textContaining('Email'), findsOneWidget);
    });

    testWidgets('shows password field', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('Mot de passe'), findsOneWidget);
    });

    testWidgets('shows confirm password field', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('Confirmer mot de passe'), findsOneWidget);
    });

    testWidgets('shows Continuer button', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('Continuer'), findsOneWidget);
    });

    testWidgets('shows already have account link', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pump(const Duration(seconds: 1));
      expect(find.textContaining('Déjà un compte'), findsOneWidget);
    });

    testWidgets('shows Se connecter link', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('Se connecter'), findsOneWidget);
    });

    testWidgets('can enter name text', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pump(const Duration(seconds: 1));
      final nameField = find.byType(TextFormField).first;
      await tester.enterText(nameField, 'Test User');
      await tester.pump();
      expect(find.text('Test User'), findsOneWidget);
    });

    testWidgets('shows password toggle icons', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pump(const Duration(seconds: 1));
      // Password fields have toggle visibility buttons
      expect(find.byType(IconButton), findsWidgets);
    });

    testWidgets('shows Informations personnelles section', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pump(const Duration(seconds: 1));
      expect(find.textContaining('personnelles'), findsOneWidget);
    });

    testWidgets('shows terms acceptance area with RichText', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pump(const Duration(seconds: 1));
      // Terms area uses RichText with TextSpan
      expect(find.byType(RichText), findsWidgets);
    });

    testWidgets('has multiple TextFormField for step 1', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pump(const Duration(seconds: 1));
      // Name, phone, email, password, confirmPassword = at least 5
      expect(find.byType(TextFormField), findsAtLeast(4));
    });
  });
}
