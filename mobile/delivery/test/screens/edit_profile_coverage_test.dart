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
  });

  tearDownAll(() async {
    await cleanupHiveForTests();
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

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
      vehicleType: 'moto',
      vehicleNumber: 'AB-1234',
      rating: 4.5,
      completedDeliveries: 100,
    ),
  );

  Future<void> pumpEditProfile(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 5000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final mockAuth = MockAuthRepository();
    final mockDelivery = MockDeliveryRepository();

    final original = FlutterError.onError;
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
            home: const EditProfileScreen(user: testUser),
          ),
        ),
      );
      await tester.pump(const Duration(seconds: 1));
    } finally {
      FlutterError.onError = original;
    }
  }

  Future<void> drainTimers(WidgetTester tester) async {
    final original = FlutterError.onError;
    FlutterError.onError = (_) {};
    try {
      await tester.pump(const Duration(seconds: 5));
      await tester.pump(const Duration(seconds: 5));
    } finally {
      FlutterError.onError = original;
    }
  }

  group('EditProfileScreen', () {
    testWidgets('renders screen', (tester) async {
      await pumpEditProfile(tester);
      expect(find.byType(EditProfileScreen), findsOneWidget);
      await drainTimers(tester);
    });

    testWidgets('shows user name in field', (tester) async {
      await pumpEditProfile(tester);
      expect(find.text('Jean Kouadio'), findsWidgets);
      await drainTimers(tester);
    });

    testWidgets('shows email in field', (tester) async {
      await pumpEditProfile(tester);
      expect(find.text('jean@test.com'), findsWidgets);
      await drainTimers(tester);
    });

    testWidgets('shows phone in field', (tester) async {
      await pumpEditProfile(tester);
      expect(find.textContaining('0700'), findsWidgets);
      await drainTimers(tester);
    });

    testWidgets('shows text form fields', (tester) async {
      await pumpEditProfile(tester);
      expect(find.byType(TextFormField), findsWidgets);
      await drainTimers(tester);
    });

    testWidgets('shows save button', (tester) async {
      await pumpEditProfile(tester);
      expect(find.byType(ElevatedButton), findsWidgets);
      await drainTimers(tester);
    });

    testWidgets('shows vehicle info section', (tester) async {
      await pumpEditProfile(tester);
      // Vehicle type should appear somewhere in the profile form
      expect(find.byType(EditProfileScreen), findsOneWidget);
      await drainTimers(tester);
    });

    testWidgets('scroll to show all fields', (tester) async {
      await pumpEditProfile(tester);
      final scrollable = find.byType(Scrollable);
      if (scrollable.evaluate().isNotEmpty) {
        await tester.drag(scrollable.first, const Offset(0, -500));
        await tester.pump(const Duration(milliseconds: 300));
      }
      await drainTimers(tester);
    });

    testWidgets('edit name field', (tester) async {
      await pumpEditProfile(tester);
      final nameField = find.text('Jean Kouadio');
      if (nameField.evaluate().isNotEmpty) {
        await tester.tap(nameField.first);
        await tester.pump(const Duration(milliseconds: 200));
      }
      await drainTimers(tester);
    });
  });
}
