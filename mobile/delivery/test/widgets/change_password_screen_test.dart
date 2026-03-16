import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:courier/presentation/screens/change_password_screen.dart';
import 'package:courier/data/repositories/auth_repository.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepository mockAuthRepo;

  setUp(() {
    mockAuthRepo = MockAuthRepository();
  });

  Widget buildScreen() {
    return ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(mockAuthRepo),
      ],
      child: const MaterialApp(
        home: ChangePasswordScreen(),
      ),
    );
  }

  group('ChangePasswordScreen', () {
    testWidgets('displays app bar with title', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(find.text('Sécurité'), findsOneWidget);
    });

    testWidgets('displays header card with info', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(find.text('Changer le mot de passe'), findsOneWidget);
      expect(find.text('Créez un mot de passe fort pour protéger votre compte'), findsOneWidget);
      expect(find.byIcon(Icons.shield_outlined), findsOneWidget);
    });

    testWidgets('displays 3 password fields', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(find.text('Mot de passe actuel'), findsOneWidget);
      expect(find.text('Nouveau mot de passe'), findsOneWidget);
      expect(find.text('Confirmer le mot de passe'), findsOneWidget);
      expect(find.byType(TextFormField), findsNWidgets(3));
    });

    testWidgets('displays submit button', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(find.text('Mettre à jour le mot de passe'), findsOneWidget);
      expect(find.byIcon(Icons.security), findsOneWidget);
    });

    testWidgets('validates empty current password', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      // Scroll to make button visible and tap
      await tester.scrollUntilVisible(
        find.text('Mettre à jour le mot de passe'),
        100,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Mettre à jour le mot de passe'));
      await tester.pumpAndSettle();

      expect(find.text('Veuillez entrer votre mot de passe actuel'), findsOneWidget);
    });

    testWidgets('validates empty new password', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      // Enter current password only
      await tester.enterText(find.byType(TextFormField).at(0), 'oldpass123');

      await tester.scrollUntilVisible(
        find.text('Mettre à jour le mot de passe'),
        100,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Mettre à jour le mot de passe'));
      await tester.pumpAndSettle();

      expect(find.text('Veuillez entrer un nouveau mot de passe'), findsOneWidget);
    });

    testWidgets('validates short new password', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField).at(0), 'oldpass123');
      await tester.enterText(find.byType(TextFormField).at(1), 'short');

      await tester.scrollUntilVisible(
        find.text('Mettre à jour le mot de passe'),
        100,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Mettre à jour le mot de passe'));
      await tester.pumpAndSettle();

      expect(find.text('Le mot de passe doit contenir au moins 8 caractères'), findsOneWidget);
    });

    testWidgets('validates password mismatch', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField).at(0), 'oldpass123');
      await tester.enterText(find.byType(TextFormField).at(1), 'NewPass123!');
      await tester.enterText(find.byType(TextFormField).at(2), 'DifferentPass');

      await tester.scrollUntilVisible(
        find.text('Mettre à jour le mot de passe'),
        100,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Mettre à jour le mot de passe'));
      await tester.pumpAndSettle();

      expect(find.text('Les mots de passe ne correspondent pas'), findsOneWidget);
    });

    testWidgets('toggles current password visibility', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      // All fields start obscured, so visibility_outlined icons are present
      final visibilityIcons = find.byIcon(Icons.visibility_outlined);
      expect(visibilityIcons, findsNWidgets(3));

      // Tap first visibility icon
      await tester.tap(visibilityIcons.first);
      await tester.pumpAndSettle();

      // One should change to visibility_off_outlined
      expect(find.byIcon(Icons.visibility_off_outlined), findsOneWidget);
    });

    testWidgets('password strength indicator shows for weak password', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      // Enter a weak password
      await tester.enterText(find.byType(TextFormField).at(1), 'abcdefgh');
      await tester.pumpAndSettle();

      // Should show strength indicator
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      // Should show requirement checks
      expect(find.text('Au moins 8 caractères'), findsOneWidget);
    });

    testWidgets('password strength indicator shows Fort for strong password', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      // Enter a strong password
      await tester.enterText(find.byType(TextFormField).at(1), 'MyStr0ng!Pass');
      await tester.pumpAndSettle();

      expect(find.text('Fort'), findsOneWidget);
    });

    testWidgets('password requirements check marks update', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField).at(1), 'Abc1!');
      await tester.pumpAndSettle();

      // Requirements should be shown
      expect(find.text('Une lettre majuscule'), findsOneWidget);
      expect(find.text('Une lettre minuscule'), findsOneWidget);
      expect(find.text('Un chiffre'), findsOneWidget);
    });

    testWidgets('back button is present', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.arrow_back_ios_new), findsOneWidget);
    });

    testWidgets('successful password change shows success dialog', (tester) async {
      when(() => mockAuthRepo.updatePassword(any(), any()))
          .thenAnswer((_) async {});

      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      // Fill all fields with valid data
      await tester.enterText(find.byType(TextFormField).at(0), 'OldPass123!');
      await tester.enterText(find.byType(TextFormField).at(1), 'NewPass123!');
      await tester.enterText(find.byType(TextFormField).at(2), 'NewPass123!');

      await tester.scrollUntilVisible(
        find.text('Mettre à jour le mot de passe'),
        100,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Mettre à jour le mot de passe'));
      await tester.pumpAndSettle();

      expect(find.text('Mot de passe modifié !'), findsOneWidget);
      expect(find.text('Parfait !'), findsOneWidget);
    });

    testWidgets('failed password change shows error snackbar', (tester) async {
      when(() => mockAuthRepo.updatePassword(any(), any()))
          .thenThrow(Exception('Mot de passe incorrect'));

      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField).at(0), 'WrongPass!');
      await tester.enterText(find.byType(TextFormField).at(1), 'NewPass123!');
      await tester.enterText(find.byType(TextFormField).at(2), 'NewPass123!');

      await tester.scrollUntilVisible(
        find.text('Mettre à jour le mot de passe'),
        100,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Mettre à jour le mot de passe'));
      await tester.pumpAndSettle();

      expect(find.text('Mot de passe incorrect'), findsOneWidget);
    });

    testWidgets('shows loading state during submit', (tester) async {
      final completer = Completer<void>();
      when(() => mockAuthRepo.updatePassword(any(), any()))
          .thenAnswer((_) => completer.future);

      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField).at(0), 'OldPass123!');
      await tester.enterText(find.byType(TextFormField).at(1), 'NewPass123!');
      await tester.enterText(find.byType(TextFormField).at(2), 'NewPass123!');

      await tester.scrollUntilVisible(
        find.text('Mettre à jour le mot de passe'),
        100,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Mettre à jour le mot de passe'));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Complete to avoid timer pending
      completer.complete();
      await tester.pumpAndSettle();
    });

    testWidgets('validates empty confirmation password', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField).at(0), 'OldPass123!');
      await tester.enterText(find.byType(TextFormField).at(1), 'NewPass123!');
      // leave confirmation empty — should show mismatch

      await tester.scrollUntilVisible(
        find.text('Mettre à jour le mot de passe'),
        100,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Mettre à jour le mot de passe'));
      await tester.pumpAndSettle();

      // Empty vs filled = mismatch
      expect(find.text('Les mots de passe ne correspondent pas'), findsAtLeastNWidgets(1));
    });

    testWidgets('password strength shows Moyen for medium password', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField).at(1), 'Abcdefg1');
      await tester.pumpAndSettle();

      expect(find.text('Moyen'), findsOneWidget);
    });
  });
}
