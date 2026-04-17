import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:courier/data/models/user.dart';
import 'package:courier/data/repositories/auth_repository.dart';
import 'package:courier/presentation/widgets/profile/personnel_card.dart';
import '../helpers/widget_test_helpers.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  setUpAll(() => initHiveForTests());
  tearDownAll(() => cleanupHiveForTests());

  late MockAuthRepository mockAuthRepo;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    mockAuthRepo = MockAuthRepository();
  });

  Widget buildWidget(User user) {
    return ProviderScope(
      overrides: [
        ...commonWidgetTestOverrides(),
        authRepositoryProvider.overrideWithValue(mockAuthRepo),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: PersonnelCard(user: user),
          ),
        ),
      ),
    );
  }

  group('PersonnelCard', () {
    testWidgets('renders user email', (tester) async {
      await tester.pumpWidget(buildWidget(
        const User(id: 1, name: 'Jean Dupont', email: 'jean@test.com'),
      ));
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('Email'), findsOneWidget);
      expect(find.text('jean@test.com'), findsOneWidget);
    });

    testWidgets('renders header text', (tester) async {

      await tester.pumpWidget(buildWidget(
        const User(id: 1, name: 'Jean', email: 'j@t.com'),
      ));
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('Informations personnelles'), findsOneWidget);
    });

    testWidgets('renders phone when provided', (tester) async {

      await tester.pumpWidget(buildWidget(
        const User(id: 1, name: 'Jean', email: 'j@t.com', phone: '+225 07 12 34 56'),
      ));
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('Téléphone'), findsOneWidget);
      expect(find.text('+225 07 12 34 56'), findsOneWidget);
    });

    testWidgets('shows "Non renseigné" when phone is null', (tester) async {

      await tester.pumpWidget(buildWidget(
        const User(id: 1, name: 'Jean', email: 'j@t.com'),
      ));
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('Non renseigné'), findsOneWidget);
    });

    testWidgets('renders vehicleType motorcycle as Moto', (tester) async {

      await tester.pumpWidget(buildWidget(
        const User(
          id: 1,
          name: 'Jean',
          email: 'j@t.com',
          courier: CourierInfo(id: 10, status: 'active', vehicleType: 'motorcycle'),
        ),
      ));
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('Véhicule'), findsOneWidget);
      expect(find.text('Moto'), findsOneWidget);
    });

    testWidgets('renders vehicleType car as Voiture', (tester) async {

      await tester.pumpWidget(buildWidget(
        const User(
          id: 1,
          name: 'Jean',
          email: 'j@t.com',
          courier: CourierInfo(id: 10, status: 'active', vehicleType: 'car'),
        ),
      ));
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('Voiture'), findsOneWidget);
    });

    testWidgets('renders vehicleType bicycle as Vélo', (tester) async {

      await tester.pumpWidget(buildWidget(
        const User(
          id: 1,
          name: 'Jean',
          email: 'j@t.com',
          courier: CourierInfo(id: 10, status: 'active', vehicleType: 'bicycle'),
        ),
      ));
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('Vélo'), findsOneWidget);
    });

    testWidgets('renders vehicleType scooter as Scooter', (tester) async {

      await tester.pumpWidget(buildWidget(
        const User(
          id: 1,
          name: 'Jean',
          email: 'j@t.com',
          courier: CourierInfo(id: 10, status: 'active', vehicleType: 'scooter'),
        ),
      ));
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('Scooter'), findsOneWidget);
    });

    testWidgets('renders unknown vehicleType verbatim', (tester) async {

      await tester.pumpWidget(buildWidget(
        const User(
          id: 1,
          name: 'Jean',
          email: 'j@t.com',
          courier: CourierInfo(id: 10, status: 'active', vehicleType: 'tricycle'),
        ),
      ));
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('tricycle'), findsOneWidget);
    });

    testWidgets('shows "Non configuré" when no courier', (tester) async {

      await tester.pumpWidget(buildWidget(
        const User(id: 1, name: 'Jean', email: 'j@t.com'),
      ));
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('Non configuré'), findsOneWidget);
    });

    testWidgets('renders vehicle plate number when provided', (tester) async {

      await tester.pumpWidget(buildWidget(
        const User(
          id: 1,
          name: 'Jean',
          email: 'j@t.com',
          courier: CourierInfo(
            id: 10,
            status: 'active',
            vehicleType: 'car',
            vehicleNumber: 'AB-1234-CI',
          ),
        ),
      ));
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('Plaque'), findsOneWidget);
      expect(find.text('AB-1234-CI'), findsOneWidget);
    });

    testWidgets('hides plate when vehicleNumber is null', (tester) async {

      await tester.pumpWidget(buildWidget(
        const User(
          id: 1,
          name: 'Jean',
          email: 'j@t.com',
          courier: CourierInfo(id: 10, status: 'active', vehicleType: 'motorcycle'),
        ),
      ));
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('Plaque'), findsNothing);
    });

    testWidgets('phone edit button opens dialog', (tester) async {

      await tester.pumpWidget(buildWidget(
        const User(id: 1, name: 'Jean', email: 'j@t.com', phone: '+225 00'),
      ));
      await tester.pump(const Duration(seconds: 1));

      // Find the edit button near phone (blue edit icon)
      final editButtons = find.byIcon(Icons.edit_rounded);
      expect(editButtons, findsWidgets);

      // Tap the second edit button (first is the profile edit in header)
      await tester.tap(editButtons.last);
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('Modifier le téléphone'), findsOneWidget);
      expect(find.text('Annuler'), findsOneWidget);
      expect(find.text('Enregistrer'), findsOneWidget);
    });

    testWidgets('phone dialog validates empty phone', (tester) async {

      await tester.pumpWidget(buildWidget(
        const User(id: 1, name: 'Jean', email: 'j@t.com'),
      ));
      await tester.pump(const Duration(seconds: 1));

      final editButtons = find.byIcon(Icons.edit_rounded);
      await tester.tap(editButtons.last);
      await tester.pump(const Duration(seconds: 1));

      // Clear the field and try to save
      await tester.enterText(find.byType(TextFormField), '');
      await tester.tap(find.text('Enregistrer'));
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('Veuillez entrer un numéro'), findsOneWidget);
    });

    testWidgets('phone dialog validates too short phone', (tester) async {

      await tester.pumpWidget(buildWidget(
        const User(id: 1, name: 'Jean', email: 'j@t.com'),
      ));
      await tester.pump(const Duration(seconds: 1));

      final editButtons = find.byIcon(Icons.edit_rounded);
      await tester.tap(editButtons.last);
      await tester.pump(const Duration(seconds: 1));

      await tester.enterText(find.byType(TextFormField), '1234');
      await tester.tap(find.text('Enregistrer'));
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('Numéro trop court'), findsOneWidget);
    });

    testWidgets('phone dialog cancel button closes dialog', (tester) async {

      await tester.pumpWidget(buildWidget(
        const User(id: 1, name: 'Jean', email: 'j@t.com'),
      ));
      await tester.pump(const Duration(seconds: 1));

      final editButtons = find.byIcon(Icons.edit_rounded);
      await tester.tap(editButtons.last);
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('Modifier le téléphone'), findsOneWidget);

      await tester.tap(find.text('Annuler'));
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('Modifier le téléphone'), findsNothing);
    });
  });
}
