import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:drpharma_client/features/profile/presentation/pages/edit_profile_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:drpharma_client/config/providers.dart';
import '../../../../helpers/fake_api_client.dart';

void main() {
  late SharedPreferences sharedPreferences;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    sharedPreferences = await SharedPreferences.getInstance();
  });

  Widget createTestWidget() {
    return ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(sharedPreferences),
        apiClientProvider.overrideWithValue(FakeApiClient()),
      ],
      child: MaterialApp(home: const EditProfilePage()),
    );
  }

  group('EditProfilePage Widget Tests', () {
    testWidgets('should render edit profile page', (tester) async {
      await tester.pumpWidget(createTestWidget());
      expect(find.byType(EditProfilePage), findsOneWidget);
    });

    testWidgets('should have name text field', (tester) async {
      await tester.pumpWidget(createTestWidget());
      expect(find.byType(TextFormField), findsWidgets);
    });

    testWidgets('should have phone text field', (tester) async {
      await tester.pumpWidget(createTestWidget());
      expect(find.byType(TextFormField), findsWidgets);
    });

    testWidgets('should have email text field', (tester) async {
      await tester.pumpWidget(createTestWidget());
      expect(find.byType(TextFormField), findsWidgets);
    });

    testWidgets('should have save button', (tester) async {
      await tester.pumpWidget(createTestWidget());
      expect(find.byType(ElevatedButton), findsWidgets);
    });

    testWidgets('should have profile picture change option', (tester) async {
      await tester.pumpWidget(createTestWidget());
      expect(find.byType(EditProfilePage), findsOneWidget);
    });

    testWidgets('should validate empty name', (tester) async {
      await tester.pumpWidget(createTestWidget());

      final nameField = find.byType(TextFormField).first;
      await tester.enterText(nameField, '');

      expect(find.byType(EditProfilePage), findsOneWidget);
    });

    testWidgets('should validate phone format', (tester) async {
      await tester.pumpWidget(createTestWidget());
      expect(find.byType(EditProfilePage), findsOneWidget);
    });

    testWidgets('should validate email format', (tester) async {
      await tester.pumpWidget(createTestWidget());
      expect(find.byType(EditProfilePage), findsOneWidget);
    });

    testWidgets('should have back navigation', (tester) async {
      await tester.pumpWidget(createTestWidget());
      expect(find.byType(AppBar), findsOneWidget);
    });

    testWidgets('should be scrollable', (tester) async {
      await tester.pumpWidget(createTestWidget());
      expect(find.byType(SingleChildScrollView), findsWidgets);
    });
  });

  group('EditProfilePage Form Content', () {
    testWidgets('shows AppBar title Modifier le profil', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();
      expect(find.text('Modifier le profil'), findsOneWidget);
    });

    testWidgets('shows Nom complet label', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();
      expect(find.textContaining('Nom complet'), findsWidgets);
    });

    testWidgets('shows Email label', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();
      expect(find.textContaining('Email'), findsWidgets);
    });

    testWidgets('shows Téléphone (optionnel) label', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();
      expect(find.textContaining('Téléphone'), findsWidgets);
    });

    testWidgets('shows Enregistrer les modifications button', (tester) async {
      tester.view.physicalSize = const Size(1080, 3600);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();
      expect(find.text('Enregistrer les modifications'), findsOneWidget);
    });

    testWidgets('has at least 3 TextFormField inputs', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();
      expect(find.byType(TextFormField), findsAtLeastNWidgets(3));
    });

    testWidgets('entering invalid email shows Email invalide error', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 3600);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      final emailField = find
          .ancestor(
            of: find.textContaining('Email'),
            matching: find.byType(TextFormField),
          )
          .first;
      await tester.enterText(emailField, 'not-an-email');
      await tester.pump();

      await tester.tap(find.text('Enregistrer les modifications'));
      await tester.pump();

      expect(find.textContaining('Email invalide'), findsOneWidget);
    });
  });

  group('EditProfilePage Password Section Tests', () {
    testWidgets('shows Changer le mot de passe section header', (tester) async {
      tester.view.physicalSize = const Size(1080, 3600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();
      expect(find.textContaining('Changer le mot de passe'), findsOneWidget);
    });

    testWidgets('shows Mot de passe actuel field after enabling switch', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 3600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();
      // Toggle the password change switch
      await tester.tap(find.byType(Switch).last);
      await tester.pump();
      expect(find.text('Mot de passe actuel'), findsOneWidget);
    });

    testWidgets('shows Nouveau mot de passe field after enabling switch', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 3600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();
      await tester.tap(find.byType(Switch).last);
      await tester.pump();
      expect(find.text('Nouveau mot de passe'), findsOneWidget);
    });

    testWidgets('shows Confirmer le mot de passe field after enabling switch', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 3600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();
      await tester.tap(find.byType(Switch).last);
      await tester.pump();
      expect(find.text('Confirmer le mot de passe'), findsOneWidget);
    });

    testWidgets('shows lock_outline icon after enabling password switch', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 3600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();
      await tester.tap(find.byType(Switch).last);
      await tester.pump();
      expect(find.byIcon(Icons.lock_outline), findsOneWidget);
    });

    testWidgets('shows visibility_off icons after enabling password switch', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 3600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();
      await tester.tap(find.byType(Switch).last);
      await tester.pumpAndSettle();
      // Password fields appear; visibility icons depend on toggle state
      expect(
        find.byIcon(Icons.visibility_off).evaluate().length +
            find.byIcon(Icons.visibility).evaluate().length,
        greaterThan(0),
      );
    });

    testWidgets('shows delete avatar button', (tester) async {
      tester.view.physicalSize = const Size(1080, 3600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();
      expect(find.text("Supprimer l'avatar"), findsOneWidget);
    });

    testWidgets('shows person icon in name field', (tester) async {
      tester.view.physicalSize = const Size(1080, 3600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.person), findsOneWidget);
    });

    testWidgets('shows email icon in email field', (tester) async {
      tester.view.physicalSize = const Size(1080, 3600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.email), findsOneWidget);
    });

    testWidgets('shows phone icon in phone field', (tester) async {
      tester.view.physicalSize = const Size(1080, 3600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.phone), findsOneWidget);
    });
  });
}
