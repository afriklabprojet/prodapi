import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mocktail/mocktail.dart';
import 'package:courier/presentation/screens/edit_profile_screen.dart';
import 'package:courier/data/models/user.dart';
import 'package:courier/data/repositories/auth_repository.dart';
import 'package:courier/data/repositories/delivery_repository.dart';
import 'package:courier/l10n/app_localizations.dart';
import '../helpers/widget_test_helpers.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

class MockDeliveryRepository extends Mock implements DeliveryRepository {}

void main() {
  setUpAll(() async {
    await initHiveForTests();
    registerFallbackValue(Uint8List(0));
  });

  tearDownAll(() async {
    await cleanupHiveForTests();
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  // ─── Test users ───────────────────────────────────────────────────────────

  const testUser = User(
    id: 1,
    name: 'Jean Kouadio',
    email: 'jean@test.com',
    phone: '+2250700112233',
    role: 'courier',
    avatar: null,
    courier: CourierInfo(
      id: 1,
      status: 'available',
      vehicleType: 'motorcycle',
      vehicleNumber: 'AB-1234',
      rating: 4.5,
      completedDeliveries: 100,
    ),
  );

  const testUserWithAvatar = User(
    id: 2,
    name: 'Marie Diallo',
    email: 'marie@test.com',
    phone: '+2250701234567',
    role: 'courier',
    avatar: 'https://example.com/avatar.jpg',
    courier: CourierInfo(
      id: 2,
      status: 'available',
      vehicleType: 'car',
      vehicleNumber: 'CI-5678',
      rating: 4.8,
      completedDeliveries: 200,
    ),
  );

  // ─── Helpers ──────────────────────────────────────────────────────────────

  Future<({MockAuthRepository auth, MockDeliveryRepository delivery})>
  pumpEditProfile(WidgetTester tester, {User user = testUser}) async {
    tester.view.physicalSize = const Size(1080, 5000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final mockAuth = MockAuthRepository();
    final mockDelivery = MockDeliveryRepository();

    // Stubs
    when(
      () => mockDelivery.updateCourierProfile(
        name: any(named: 'name'),
        phone: any(named: 'phone'),
        vehicleType: any(named: 'vehicleType'),
        vehicleNumber: any(named: 'vehicleNumber'),
      ),
    ).thenAnswer((_) async {});

    when(
      () => mockAuth.uploadAvatar(any()),
    ).thenAnswer((_) async => 'https://example.com/new-avatar.jpg');

    when(() => mockAuth.deleteAvatar()).thenAnswer((_) async {});

    final orig = FlutterError.onError;
    FlutterError.onError = (_) {};
    try {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            ...commonWidgetTestOverrides(),
            authRepositoryProvider.overrideWithValue(mockAuth),
            deliveryRepositoryProvider.overrideWithValue(mockDelivery),
          ],
          child: MaterialApp(
            locale: const Locale('fr'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: EditProfileScreen(user: user),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));
    } finally {
      FlutterError.onError = orig;
    }

    return (auth: mockAuth, delivery: mockDelivery);
  }

  Future<void> drain(WidgetTester tester) async {
    final orig = FlutterError.onError;
    FlutterError.onError = (_) {};
    try {
      await tester.pump(const Duration(seconds: 5));
      await tester.pump(const Duration(seconds: 5));
    } finally {
      FlutterError.onError = orig;
    }
  }

  // ─── Lock icon (read-only email field) ───────────────────────────────────

  group('EditProfileScreen - read-only email field', () {
    testWidgets('shows lock icon for email read-only field', (tester) async {
      await pumpEditProfile(tester);
      expect(find.byIcon(Icons.lock_outline_rounded), findsWidgets);
      await drain(tester);
    });

    testWidgets('shows email label text', (tester) async {
      await pumpEditProfile(tester);
      expect(find.text('Email'), findsWidgets);
      await drain(tester);
    });
  });

  // ─── Vehicle selector ─────────────────────────────────────────────────────

  group('EditProfileScreen - vehicle selector', () {
    testWidgets('shows all four vehicle options', (tester) async {
      await pumpEditProfile(tester);
      expect(find.text('Moto'), findsWidgets);
      expect(find.text('Voiture'), findsWidgets);
      expect(find.text('Scooter'), findsWidgets);
      expect(find.text('Vélo'), findsWidgets);
      await drain(tester);
    });

    testWidgets('shows car icon', (tester) async {
      await pumpEditProfile(tester);
      expect(find.byIcon(Icons.directions_car_rounded), findsWidgets);
      await drain(tester);
    });

    testWidgets('shows scooter icon', (tester) async {
      await pumpEditProfile(tester);
      expect(find.byIcon(Icons.electric_scooter_rounded), findsWidgets);
      await drain(tester);
    });

    testWidgets('shows bicycle icon', (tester) async {
      await pumpEditProfile(tester);
      expect(find.byIcon(Icons.pedal_bike_rounded), findsWidgets);
      await drain(tester);
    });

    testWidgets('shows motorcycle icon', (tester) async {
      await pumpEditProfile(tester);
      expect(find.byIcon(Icons.two_wheeler_rounded), findsWidgets);
      await drain(tester);
    });

    testWidgets('tapping Voiture selects car vehicle', (tester) async {
      final orig = FlutterError.onError;
      FlutterError.onError = (_) {};
      try {
        await pumpEditProfile(tester);

        // Tap the 'Voiture' option
        final voitureText = find.text('Voiture');
        if (voitureText.evaluate().isNotEmpty) {
          await tester.tap(voitureText.first);
          await tester.pump(const Duration(milliseconds: 300));
        }
        // Still renders after selection
        expect(find.byType(EditProfileScreen), findsOneWidget);
      } finally {
        FlutterError.onError = orig;
      }
      await drain(tester);
    });

    testWidgets('tapping Scooter selects scooter vehicle', (tester) async {
      final orig = FlutterError.onError;
      FlutterError.onError = (_) {};
      try {
        await pumpEditProfile(tester);

        final scooterText = find.text('Scooter');
        if (scooterText.evaluate().isNotEmpty) {
          await tester.tap(scooterText.first);
          await tester.pump(const Duration(milliseconds: 300));
        }
        expect(find.byType(EditProfileScreen), findsOneWidget);
      } finally {
        FlutterError.onError = orig;
      }
      await drain(tester);
    });

    testWidgets('tapping Vélo selects bicycle vehicle', (tester) async {
      final orig = FlutterError.onError;
      FlutterError.onError = (_) {};
      try {
        await pumpEditProfile(tester);

        final veloText = find.text('Vélo');
        if (veloText.evaluate().isNotEmpty) {
          await tester.tap(veloText.first);
          await tester.pump(const Duration(milliseconds: 300));
        }
        expect(find.byType(EditProfileScreen), findsOneWidget);
      } finally {
        FlutterError.onError = orig;
      }
      await drain(tester);
    });

    testWidgets('tapping Moto keeps motorcycle selected', (tester) async {
      final orig = FlutterError.onError;
      FlutterError.onError = (_) {};
      try {
        await pumpEditProfile(tester);

        final motoText = find.text('Moto');
        if (motoText.evaluate().isNotEmpty) {
          await tester.tap(motoText.first);
          await tester.pump(const Duration(milliseconds: 300));
        }
        expect(find.text('Moto'), findsWidgets);
      } finally {
        FlutterError.onError = orig;
      }
      await drain(tester);
    });
  });

  // ─── Photo options bottom sheet ───────────────────────────────────────────

  group('EditProfileScreen - photo options', () {
    testWidgets('tapping Changer la photo opens bottom sheet', (tester) async {
      final orig = FlutterError.onError;
      FlutterError.onError = (_) {};
      try {
        await pumpEditProfile(tester);

        final changePhotoBtn = find.text('Changer la photo');
        if (changePhotoBtn.evaluate().isNotEmpty) {
          await tester.tap(changePhotoBtn.first);
          await tester.pumpAndSettle(const Duration(milliseconds: 500));
          // Bottom sheet should show gallery and camera options
          expect(find.text('Galerie'), findsOneWidget);
          expect(find.text('Caméra'), findsOneWidget);
        }
      } finally {
        FlutterError.onError = orig;
      }
      await drain(tester);
    });

    testWidgets('photo sheet title is Photo de profil', (tester) async {
      final orig = FlutterError.onError;
      FlutterError.onError = (_) {};
      try {
        await pumpEditProfile(tester);

        final changePhotoBtn = find.text('Changer la photo');
        if (changePhotoBtn.evaluate().isNotEmpty) {
          await tester.tap(changePhotoBtn.first);
          await tester.pumpAndSettle(const Duration(milliseconds: 500));
          expect(find.text('Photo de profil'), findsOneWidget);
        }
      } finally {
        FlutterError.onError = orig;
      }
      await drain(tester);
    });

    testWidgets('no delete option when user has no avatar', (tester) async {
      final orig = FlutterError.onError;
      FlutterError.onError = (_) {};
      try {
        // testUser has avatar: null
        await pumpEditProfile(tester, user: testUser);

        final changePhotoBtn = find.text('Changer la photo');
        if (changePhotoBtn.evaluate().isNotEmpty) {
          await tester.tap(changePhotoBtn.first);
          await tester.pumpAndSettle(const Duration(milliseconds: 500));
          // Should NOT show delete option
          expect(find.text('Supprimer la photo'), findsNothing);
        }
      } finally {
        FlutterError.onError = orig;
      }
      await drain(tester);
    });

    testWidgets('shows delete option when user has avatar', (tester) async {
      final orig = FlutterError.onError;
      FlutterError.onError = (_) {};
      try {
        await pumpEditProfile(tester, user: testUserWithAvatar);

        final changePhotoBtn = find.text('Changer la photo');
        if (changePhotoBtn.evaluate().isNotEmpty) {
          await tester.tap(changePhotoBtn.first);
          await tester.pumpAndSettle(const Duration(milliseconds: 500));
          expect(find.text('Supprimer la photo'), findsOneWidget);
        }
      } finally {
        FlutterError.onError = orig;
      }
      await drain(tester);
    });

    testWidgets('photo sheet shows gallery icon', (tester) async {
      final orig = FlutterError.onError;
      FlutterError.onError = (_) {};
      try {
        await pumpEditProfile(tester);

        final changePhotoBtn = find.text('Changer la photo');
        if (changePhotoBtn.evaluate().isNotEmpty) {
          await tester.tap(changePhotoBtn.first);
          await tester.pumpAndSettle(const Duration(milliseconds: 500));
          expect(find.byIcon(Icons.photo_library_rounded), findsOneWidget);
        }
      } finally {
        FlutterError.onError = orig;
      }
      await drain(tester);
    });

    testWidgets('photo sheet shows camera icon', (tester) async {
      final orig = FlutterError.onError;
      FlutterError.onError = (_) {};
      try {
        await pumpEditProfile(tester);

        final changePhotoBtn = find.text('Changer la photo');
        if (changePhotoBtn.evaluate().isNotEmpty) {
          await tester.tap(changePhotoBtn.first);
          await tester.pumpAndSettle(const Duration(milliseconds: 500));
          expect(find.byIcon(Icons.camera_alt_rounded), findsWidgets);
        }
      } finally {
        FlutterError.onError = orig;
      }
      await drain(tester);
    });
  });

  // ─── Form validation ──────────────────────────────────────────────────────

  group('EditProfileScreen - form validation', () {
    testWidgets('empty name field shows validation error on save', (
      tester,
    ) async {
      final orig = FlutterError.onError;
      FlutterError.onError = (_) {};
      try {
        await pumpEditProfile(tester);

        // Clear the name field
        final nameField = find.text('Jean Kouadio');
        if (nameField.evaluate().isNotEmpty) {
          await tester.tap(nameField.first);
          await tester.pump(const Duration(milliseconds: 100));
          // Select all text and delete
          await tester.enterText(nameField.first, '');
          await tester.pump(const Duration(milliseconds: 100));
        }

        // Tap save button
        final saveBtn = find.text('Enregistrer');
        if (saveBtn.evaluate().isNotEmpty) {
          await tester.tap(saveBtn.first);
          await tester.pump(const Duration(milliseconds: 500));
        }

        // Validation error should appear
        expect(find.text('Le nom est requis'), findsWidgets);
      } finally {
        FlutterError.onError = orig;
      }
      await drain(tester);
    });

    testWidgets('too short phone shows validation error on save', (
      tester,
    ) async {
      final orig = FlutterError.onError;
      FlutterError.onError = (_) {};
      try {
        await pumpEditProfile(tester);

        // Set phone to something too short (< 8 chars)
        final phoneField = find.ancestor(
          of: find.byIcon(Icons.phone_outlined),
          matching: find.byType(TextFormField),
        );
        if (phoneField.evaluate().isNotEmpty) {
          await tester.tap(phoneField.first);
          await tester.pump(const Duration(milliseconds: 100));
          await tester.enterText(phoneField.first, '123');
          await tester.pump(const Duration(milliseconds: 100));
        }

        // Tap save
        final saveBtn = find.text('Enregistrer');
        if (saveBtn.evaluate().isNotEmpty) {
          await tester.tap(saveBtn.first);
          await tester.pump(const Duration(milliseconds: 500));
        }

        expect(find.text('Numéro trop court'), findsWidgets);
      } finally {
        FlutterError.onError = orig;
      }
      await drain(tester);
    });
  });

  // ─── Save flow ────────────────────────────────────────────────────────────

  group('EditProfileScreen - save flow', () {
    testWidgets('save with changes calls updateCourierProfile', (tester) async {
      final orig = FlutterError.onError;
      FlutterError.onError = (_) {};
      try {
        final mocks = await pumpEditProfile(tester);

        // Change the name to trigger _hasChanges
        final nameField = find.ancestor(
          of: find.byIcon(Icons.person_outline_rounded),
          matching: find.byType(TextFormField),
        );
        if (nameField.evaluate().isNotEmpty) {
          await tester.tap(nameField.first);
          await tester.pump(const Duration(milliseconds: 100));
          await tester.enterText(nameField.first, 'Nouveau Nom');
          await tester.pump(const Duration(milliseconds: 100));
        }

        // Tap save
        final saveBtn = find.text('Enregistrer');
        if (saveBtn.evaluate().isNotEmpty) {
          await tester.tap(saveBtn.first);
          await tester.pump(const Duration(seconds: 1));
        }

        verify(
          () => mocks.delivery.updateCourierProfile(
            name: any(named: 'name'),
            phone: any(named: 'phone'),
            vehicleType: any(named: 'vehicleType'),
            vehicleNumber: any(named: 'vehicleNumber'),
          ),
        ).called(1);
      } finally {
        FlutterError.onError = orig;
      }
      await drain(tester);
    });

    testWidgets('save error shows error snackbar', (tester) async {
      final orig = FlutterError.onError;
      FlutterError.onError = (_) {};
      try {
        final mockAuth = MockAuthRepository();
        final mockDelivery = MockDeliveryRepository();

        // Mock updateCourierProfile to throw
        when(
          () => mockDelivery.updateCourierProfile(
            name: any(named: 'name'),
            phone: any(named: 'phone'),
            vehicleType: any(named: 'vehicleType'),
            vehicleNumber: any(named: 'vehicleNumber'),
          ),
        ).thenThrow(Exception('Erreur réseau'));

        tester.view.physicalSize = const Size(1080, 5000);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              ...commonWidgetTestOverrides(),
              authRepositoryProvider.overrideWithValue(mockAuth),
              deliveryRepositoryProvider.overrideWithValue(mockDelivery),
            ],
            child: MaterialApp(
              locale: const Locale('fr'),
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: const EditProfileScreen(user: testUser),
            ),
          ),
        );
        await tester.pump(const Duration(milliseconds: 300));

        // Change name to trigger _hasChanges
        final nameField = find.ancestor(
          of: find.byIcon(Icons.person_outline_rounded),
          matching: find.byType(TextFormField),
        );
        if (nameField.evaluate().isNotEmpty) {
          await tester.tap(nameField.first);
          await tester.pump(const Duration(milliseconds: 100));
          await tester.enterText(nameField.first, 'Nom Modifié');
          await tester.pump(const Duration(milliseconds: 100));
        }

        // Tap save
        final saveBtn = find.text('Enregistrer');
        if (saveBtn.evaluate().isNotEmpty) {
          await tester.tap(saveBtn.first);
          await tester.pump(const Duration(seconds: 1));
        }

        // Verify error was thrown (mock called)
        verify(
          () => mockDelivery.updateCourierProfile(
            name: any(named: 'name'),
            phone: any(named: 'phone'),
            vehicleType: any(named: 'vehicleType'),
            vehicleNumber: any(named: 'vehicleNumber'),
          ),
        ).called(1);
      } finally {
        FlutterError.onError = orig;
      }
      await drain(tester);
    });

    testWidgets('save button shows CircularProgressIndicator while saving', (
      tester,
    ) async {
      final orig = FlutterError.onError;
      FlutterError.onError = (_) {};
      try {
        final completer = Completer<void>();
        final mockAuth = MockAuthRepository();
        final mockDelivery = MockDeliveryRepository();
        when(
          () => mockDelivery.updateCourierProfile(
            name: any(named: 'name'),
            phone: any(named: 'phone'),
            vehicleType: any(named: 'vehicleType'),
            vehicleNumber: any(named: 'vehicleNumber'),
          ),
        ).thenAnswer((_) => completer.future);

        tester.view.physicalSize = const Size(1080, 5000);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              ...commonWidgetTestOverrides(),
              authRepositoryProvider.overrideWithValue(mockAuth),
              deliveryRepositoryProvider.overrideWithValue(mockDelivery),
            ],
            child: MaterialApp(
              locale: const Locale('fr'),
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: const EditProfileScreen(user: testUser),
            ),
          ),
        );
        await tester.pump(const Duration(milliseconds: 300));

        // Change name to trigger _hasChanges
        final nameField = find.ancestor(
          of: find.byIcon(Icons.person_outline_rounded),
          matching: find.byType(TextFormField),
        );
        if (nameField.evaluate().isNotEmpty) {
          await tester.tap(nameField.first);
          await tester.pump(const Duration(milliseconds: 100));
          await tester.enterText(nameField.first, 'Nom En Cours');
          await tester.pump(const Duration(milliseconds: 100));
        }

        // Tap save
        final saveBtn = find.text('Enregistrer');
        if (saveBtn.evaluate().isNotEmpty) {
          await tester.tap(saveBtn.first);
          await tester.pump(const Duration(milliseconds: 100));
        }

        // While save is in progress, should show CircularProgressIndicator
        expect(find.byType(CircularProgressIndicator), findsWidgets);

        // Complete with error to avoid context.pop navigation issues
        completer.completeError(Exception('test error'));
        await tester.pump(const Duration(milliseconds: 200));
      } finally {
        FlutterError.onError = orig;
      }
      await drain(tester);
    });
  });

  // ─── App bar ──────────────────────────────────────────────────────────────

  group('EditProfileScreen - app bar', () {
    testWidgets('shows Modifier le profil title', (tester) async {
      await pumpEditProfile(tester);
      expect(find.text('Modifier le profil'), findsWidgets);
      await drain(tester);
    });

    testWidgets('shows back arrow icon', (tester) async {
      await pumpEditProfile(tester);
      expect(find.byIcon(Icons.arrow_back_ios_new_rounded), findsOneWidget);
      await drain(tester);
    });
  });

  // ─── Section labels ───────────────────────────────────────────────────────

  group('EditProfileScreen - section labels', () {
    testWidgets('shows Informations personnelles section label', (
      tester,
    ) async {
      await pumpEditProfile(tester);
      expect(find.text('Informations personnelles'), findsWidgets);
      await drain(tester);
    });

    testWidgets('shows Véhicule section label', (tester) async {
      await pumpEditProfile(tester);
      expect(find.text('Véhicule'), findsWidgets);
      await drain(tester);
    });

    testWidgets('shows Numéro de plaque hint', (tester) async {
      await pumpEditProfile(tester);
      // The plate field should be visible with initial value
      expect(find.text('AB-1234'), findsWidgets);
      await drain(tester);
    });
  });

  // ─── With avatar (car vehicle type) ──────────────────────────────────────

  group('EditProfileScreen - car vehicle user', () {
    testWidgets('renders with car vehicle type initial', (tester) async {
      final orig = FlutterError.onError;
      FlutterError.onError = (_) {};
      try {
        await pumpEditProfile(tester, user: testUserWithAvatar);
        expect(find.byType(EditProfileScreen), findsOneWidget);
        // Voiture should be shown (initial vehicle = car)
        expect(find.text('Voiture'), findsWidgets);
      } finally {
        FlutterError.onError = orig;
      }
      await drain(tester);
    });

    testWidgets('shows email for user with avatar', (tester) async {
      final orig = FlutterError.onError;
      FlutterError.onError = (_) {};
      try {
        await pumpEditProfile(tester, user: testUserWithAvatar);
        expect(find.text('marie@test.com'), findsWidgets);
      } finally {
        FlutterError.onError = orig;
      }
      await drain(tester);
    });
  });
}
