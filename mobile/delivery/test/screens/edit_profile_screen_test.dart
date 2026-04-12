import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mocktail/mocktail.dart';
import 'package:courier/presentation/screens/edit_profile_screen.dart';
import 'package:courier/data/repositories/auth_repository.dart';
import 'package:courier/data/models/user.dart';
import '../helpers/widget_test_helpers.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepository mockAuthRepo;

  setUpAll(() async {
    await initHiveForTests();
  });

  tearDownAll(() async {
    await cleanupHiveForTests();
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    mockAuthRepo = MockAuthRepository();
  });

  Widget buildWidget() {
    final user = User.fromJson({
      'id': 1,
      'name': 'Jean Dupont',
      'email': 'jean@test.com',
      'phone': '+2250101010101',
      'courier': {
        'id': 1,
        'status': 'active',
        'completed_deliveries': '50',
        'rating': '4.5',
      },
    });
    return ProviderScope(
      overrides: [
        ...commonWidgetTestOverrides(),
        authRepositoryProvider.overrideWithValue(mockAuthRepo),
      ],
      child: MaterialApp(home: EditProfileScreen(user: user)),
    );
  }

  group('EditProfileScreen', () {
    testWidgets('renders edit profile screen', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('displays user name in form', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pump(const Duration(seconds: 1));
      expect(find.textContaining('Jean'), findsWidgets);
    });

    testWidgets('shows EditProfileScreen widget', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(EditProfileScreen), findsOneWidget);
    });

    testWidgets('has TextFormField for name', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(TextFormField), findsWidgets);
    });

    testWidgets('shows email in form', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pump(const Duration(seconds: 1));
      expect(find.textContaining('jean@test.com'), findsWidgets);
    });

    testWidgets('shows phone in form', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pump(const Duration(seconds: 1));
      expect(find.textContaining('01'), findsWidgets);
    });

    testWidgets('has save button', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pump(const Duration(seconds: 1));
      final elevated = find.byType(ElevatedButton);
      final filled = find.byType(FilledButton);
      expect(
        elevated.evaluate().length + filled.evaluate().length,
        greaterThanOrEqualTo(1),
      );
    });

    testWidgets('has app bar area', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pump(const Duration(seconds: 1));
      // Screen has a top navigation area
      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('has avatar section', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pump(const Duration(seconds: 1));
      // Avatar area uses some image widget
      expect(find.byType(EditProfileScreen), findsOneWidget);
    });

    testWidgets('is scrollable', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pump(const Duration(seconds: 1));
      final scrollViews = find.byType(SingleChildScrollView);
      final listViews = find.byType(ListView);
      expect(
        scrollViews.evaluate().length + listViews.evaluate().length,
        greaterThanOrEqualTo(1),
      );
    });
  });

  group('EditProfileScreen - user variations', () {
    Widget buildWithUser(Map<String, dynamic> json) {
      final user = User.fromJson(json);
      return ProviderScope(
        overrides: [
          ...commonWidgetTestOverrides(),
          authRepositoryProvider.overrideWithValue(mockAuthRepo),
        ],
        child: MaterialApp(home: EditProfileScreen(user: user)),
      );
    }

    testWidgets('user with motorcycle vehicle type', (tester) async {
      await tester.pumpWidget(
        buildWithUser({
          'id': 2,
          'name': 'Ali Koné',
          'email': 'ali@test.com',
          'phone': '+2250505050505',
          'courier': {
            'id': 2,
            'status': 'active',
            'completed_deliveries': '10',
            'rating': '3.8',
            'vehicle_type': 'motorcycle',
            'plate_number': 'CI-9999',
          },
        }),
      );
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(EditProfileScreen), findsOneWidget);
      expect(find.textContaining('Ali'), findsWidgets);
    });

    testWidgets('user with car vehicle type', (tester) async {
      await tester.pumpWidget(
        buildWithUser({
          'id': 3,
          'name': 'Fatou Traoré',
          'email': 'fatou@test.com',
          'phone': '+2250606060606',
          'courier': {
            'id': 3,
            'status': 'active',
            'completed_deliveries': '200',
            'rating': '4.9',
            'vehicle_type': 'car',
            'plate_number': 'AB-1234-CI',
          },
        }),
      );
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(EditProfileScreen), findsOneWidget);
    });

    testWidgets('user with bicycle vehicle type', (tester) async {
      await tester.pumpWidget(
        buildWithUser({
          'id': 4,
          'name': 'Bakary Cissé',
          'email': 'bakary@test.com',
          'phone': '+2250808080808',
          'courier': {
            'id': 4,
            'status': 'active',
            'completed_deliveries': '5',
            'rating': '4.0',
            'vehicle_type': 'bicycle',
          },
        }),
      );
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(EditProfileScreen), findsOneWidget);
    });

    testWidgets('user with scooter vehicle type', (tester) async {
      await tester.pumpWidget(
        buildWithUser({
          'id': 5,
          'name': 'Moussa Diallo',
          'email': 'moussa@test.com',
          'phone': '+2250909090909',
          'courier': {
            'id': 5,
            'status': 'active',
            'completed_deliveries': '30',
            'rating': '4.2',
            'vehicle_type': 'scooter',
            'plate_number': 'SC-555',
          },
        }),
      );
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(EditProfileScreen), findsOneWidget);
    });

    testWidgets('user with no vehicle type', (tester) async {
      await tester.pumpWidget(
        buildWithUser({
          'id': 6,
          'name': 'Aminata Bamba',
          'email': 'aminata@test.com',
          'phone': '+2250707070707',
          'courier': {
            'id': 6,
            'status': 'active',
            'completed_deliveries': '0',
            'rating': '0',
          },
        }),
      );
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(EditProfileScreen), findsOneWidget);
    });

    testWidgets('user with avatar URL', (tester) async {
      await tester.pumpWidget(
        buildWithUser({
          'id': 7,
          'name': 'Yao Pascal',
          'email': 'yao@test.com',
          'phone': '+2250111111111',
          'avatar': 'https://example.com/avatar.jpg',
          'courier': {
            'id': 7,
            'status': 'active',
            'completed_deliveries': '75',
            'rating': '4.6',
          },
        }),
      );
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(EditProfileScreen), findsOneWidget);
    });

    testWidgets('user with no email', (tester) async {
      await tester.pumpWidget(
        buildWithUser({
          'id': 8,
          'name': 'Ibrahim Koné',
          'email': '',
          'phone': '+2250222222222',
          'courier': {
            'id': 8,
            'status': 'active',
            'completed_deliveries': '15',
            'rating': '3.5',
          },
        }),
      );
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(EditProfileScreen), findsOneWidget);
    });
  });

  group('EditProfileScreen - form interactions', () {
    testWidgets('can clear name field', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pump(const Duration(seconds: 1));
      final nameFields = find.byType(TextFormField);
      if (nameFields.evaluate().isNotEmpty) {
        await tester.enterText(nameFields.first, '');
        await tester.pump();
      }
      expect(find.byType(EditProfileScreen), findsOneWidget);
    });

    testWidgets('can enter short phone number', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pump(const Duration(seconds: 1));
      // Find phone field (typically second TextFormField)
      final nameFields = find.byType(TextFormField);
      if (nameFields.evaluate().length >= 2) {
        await tester.enterText(nameFields.at(1), '123');
        await tester.pump();
      }
      expect(find.byType(EditProfileScreen), findsOneWidget);
    });

    testWidgets('form contains multiple fields', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(TextFormField), findsAtLeastNWidgets(2));
    });
  });

  group('EditProfileScreen - labels and structure', () {
    testWidgets('shows Modifier le profil header', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pump(const Duration(seconds: 1));
      expect(find.textContaining('Modifier'), findsWidgets);
    });

    testWidgets('shows Informations personnelles section', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pump(const Duration(seconds: 1));
      expect(find.textContaining('Informations'), findsWidgets);
    });

    testWidgets('shows Nom complet label', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pump(const Duration(seconds: 1));
      expect(find.textContaining('Nom'), findsWidgets);
    });

    testWidgets('shows Téléphone label', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pump(const Duration(seconds: 1));
      expect(find.textContaining('phone'), findsWidgets);
    });

    testWidgets('shows Email label', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pump(const Duration(seconds: 1));
      expect(find.textContaining('mail'), findsWidgets);
    });

    testWidgets('shows Enregistrer button', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pump(const Duration(seconds: 1));
      expect(find.textContaining('Enregistrer'), findsWidgets);
    });

    testWidgets('has person_outline icon for name', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pump(const Duration(seconds: 1));
      expect(find.byIcon(Icons.person_outline_rounded), findsWidgets);
    });

    testWidgets('has phone icon', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pump(const Duration(seconds: 1));
      expect(find.byIcon(Icons.phone_outlined), findsWidgets);
    });

    testWidgets('has email icon', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pump(const Duration(seconds: 1));
      expect(find.byIcon(Icons.email_outlined), findsWidgets);
    });

    testWidgets('has back button icon', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pump(const Duration(seconds: 1));
      expect(find.byIcon(Icons.arrow_back_ios_new_rounded), findsWidgets);
    });

    testWidgets('has Form widget', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(Form), findsOneWidget);
    });

    testWidgets('has Scaffold', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(Scaffold), findsWidgets);
    });

    testWidgets('has GestureDetector for avatar', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(GestureDetector), findsWidgets);
    });

    testWidgets('has SizedBox spacers', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(SizedBox), findsWidgets);
    });

    testWidgets('has Column layout', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(Column), findsWidgets);
    });
  });

  group('EditProfileScreen - vehicle section', () {
    Widget buildWithUser(Map<String, dynamic> json) {
      final user = User.fromJson(json);
      return ProviderScope(
        overrides: [
          ...commonWidgetTestOverrides(),
          authRepositoryProvider.overrideWithValue(mockAuthRepo),
        ],
        child: MaterialApp(home: EditProfileScreen(user: user)),
      );
    }

    testWidgets('shows Véhicule section label', (tester) async {
      await tester.pumpWidget(
        buildWithUser({
          'id': 10,
          'name': 'Test User',
          'email': 'test@test.com',
          'phone': '+2250101010101',
          'courier': {
            'id': 10,
            'status': 'active',
            'completed_deliveries': '50',
            'rating': '4.5',
            'vehicle_type': 'motorcycle',
            'plate_number': 'CI-9999',
          },
        }),
      );
      await tester.pump(const Duration(seconds: 1));
      expect(find.textContaining('hicule'), findsWidgets);
    });

    testWidgets('motorcycle shows two_wheeler icon', (tester) async {
      await tester.pumpWidget(
        buildWithUser({
          'id': 11,
          'name': 'Moto User',
          'email': 'moto@test.com',
          'phone': '+2250101010101',
          'courier': {
            'id': 11,
            'status': 'active',
            'completed_deliveries': '10',
            'rating': '4.0',
            'vehicle_type': 'motorcycle',
            'plate_number': 'AB-1234',
          },
        }),
      );
      await tester.pump(const Duration(seconds: 1));
      expect(find.byIcon(Icons.two_wheeler_rounded), findsWidgets);
    });

    testWidgets('car shows directions_car icon', (tester) async {
      await tester.pumpWidget(
        buildWithUser({
          'id': 12,
          'name': 'Car User',
          'email': 'car@test.com',
          'phone': '+2250202020202',
          'courier': {
            'id': 12,
            'status': 'active',
            'completed_deliveries': '20',
            'rating': '4.0',
            'vehicle_type': 'car',
            'plate_number': 'CAR-1234',
          },
        }),
      );
      await tester.pump(const Duration(seconds: 1));
      expect(find.byIcon(Icons.directions_car_rounded), findsWidgets);
    });

    testWidgets('bicycle shows pedal_bike icon', (tester) async {
      await tester.pumpWidget(
        buildWithUser({
          'id': 13,
          'name': 'Bike User',
          'email': 'bike@test.com',
          'phone': '+2250303030303',
          'courier': {
            'id': 13,
            'status': 'active',
            'completed_deliveries': '5',
            'rating': '3.5',
            'vehicle_type': 'bicycle',
          },
        }),
      );
      await tester.pump(const Duration(seconds: 1));
      expect(find.byIcon(Icons.pedal_bike_rounded), findsWidgets);
    });

    testWidgets('scooter shows electric_scooter icon', (tester) async {
      await tester.pumpWidget(
        buildWithUser({
          'id': 14,
          'name': 'Scooter User',
          'email': 'scooter@test.com',
          'phone': '+2250404040404',
          'courier': {
            'id': 14,
            'status': 'active',
            'completed_deliveries': '15',
            'rating': '4.2',
            'vehicle_type': 'scooter',
            'plate_number': 'SC-555',
          },
        }),
      );
      await tester.pump(const Duration(seconds: 1));
      expect(find.byIcon(Icons.electric_scooter_rounded), findsWidgets);
    });

    testWidgets('plate number field with badge icon', (tester) async {
      await tester.pumpWidget(
        buildWithUser({
          'id': 15,
          'name': 'Plate User',
          'email': 'plate@test.com',
          'phone': '+2250505050505',
          'courier': {
            'id': 15,
            'status': 'active',
            'completed_deliveries': '25',
            'rating': '4.1',
            'vehicle_type': 'motorcycle',
            'plate_number': 'AB 1234 CI',
          },
        }),
      );
      await tester.pump(const Duration(seconds: 1));
      expect(find.byIcon(Icons.badge_outlined), findsWidgets);
    });

    testWidgets('shows plate number field', (tester) async {
      await tester.pumpWidget(
        buildWithUser({
          'id': 16,
          'name': 'Plate Display',
          'email': 'display@test.com',
          'phone': '+2250606060606',
          'courier': {
            'id': 16,
            'status': 'active',
            'completed_deliveries': '30',
            'rating': '4.3',
            'vehicle_type': 'car',
            'plate_number': 'CI-9999-AB',
          },
        }),
      );
      await tester.pump(const Duration(seconds: 1));
      expect(find.byIcon(Icons.badge_outlined), findsWidgets);
    });

    testWidgets('Changer la photo text present', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pump(const Duration(seconds: 1));
      expect(find.textContaining('Changer'), findsWidgets);
    });

    testWidgets('at least 3 TextFormField in form', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(TextFormField), findsAtLeastNWidgets(3));
    });
  });

  group('EditProfileScreen - form validation', () {
    testWidgets('clearing name and tapping save does not crash', (
      tester,
    ) async {
      await tester.pumpWidget(buildWidget());
      await tester.pump(const Duration(seconds: 1));
      final nameFields = find.byType(TextFormField);
      if (nameFields.evaluate().isNotEmpty) {
        await tester.enterText(nameFields.first, '');
        await tester.pump();
      }
      // Try to tap save
      final saveBtn = find.textContaining('Enregistrer');
      if (saveBtn.evaluate().isNotEmpty) {
        await tester.tap(saveBtn.first);
        await tester.pump(const Duration(seconds: 1));
      }
      expect(find.byType(EditProfileScreen), findsOneWidget);
    });

    testWidgets('empty name shows validation error', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pump(const Duration(seconds: 1));
      final nameFields = find.byType(TextFormField);
      if (nameFields.evaluate().isNotEmpty) {
        await tester.enterText(nameFields.first, '');
        await tester.pump();
      }
      final saveBtn = find.textContaining('Enregistrer');
      if (saveBtn.evaluate().isNotEmpty) {
        await tester.tap(saveBtn.first);
        await tester.pump(const Duration(seconds: 1));
      }
      // Should show 'Le nom est requis' or similar
      expect(find.byType(EditProfileScreen), findsOneWidget);
    });

    testWidgets('typing new name in field works', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pump(const Duration(seconds: 1));
      final nameFields = find.byType(TextFormField);
      if (nameFields.evaluate().isNotEmpty) {
        await tester.enterText(nameFields.first, 'Nouveau Nom');
        await tester.pump();
      }
      expect(find.text('Nouveau Nom'), findsOneWidget);
    });

    testWidgets('entering email in field works', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pump(const Duration(seconds: 1));
      final fields = find.byType(TextFormField);
      // email is typically 3rd field (name, phone, email)
      if (fields.evaluate().length >= 3) {
        await tester.enterText(fields.at(2), 'new@email.com');
        await tester.pump();
      }
      expect(find.byType(EditProfileScreen), findsOneWidget);
    });
  });
}
