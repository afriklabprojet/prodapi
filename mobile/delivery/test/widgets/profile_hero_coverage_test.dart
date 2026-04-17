import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:courier/presentation/widgets/profile/profile_hero.dart';
import 'package:courier/data/models/user.dart';
import 'package:courier/data/repositories/delivery_repository.dart';
import 'package:courier/core/services/location_service.dart';
import '../helpers/widget_test_helpers.dart';

class MockDeliveryRepository extends Mock implements DeliveryRepository {}

class MockLocationService extends Mock implements LocationService {}

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

  final testUser = User(
    id: 1,
    name: 'Jean Kouame',
    email: 'jean@test.com',
    phone: '+225 0700000000',
    avatar: 'https://example.com/avatar.jpg',
    courier: const CourierInfo(
      id: 1,
      status: 'available',
      vehicleType: 'motorcycle',
      vehicleNumber: 'AB-1234-CI',
    ),
  );

  final offlineUser = User(
    id: 2,
    name: 'Marie Diallo',
    email: 'marie@test.com',
    phone: '+225 0700000001',
    courier: const CourierInfo(id: 2, status: 'offline', vehicleType: 'car'),
  );

  final noCourierUser = User(
    id: 3,
    name: 'Pierre Kamagate',
    email: 'pierre@test.com',
    phone: '+225 0700000002',
  );

  Widget buildWidget(
    User user, {
    VoidCallback? onNotificationTap,
    VoidCallback? onSettingsTap,
  }) {
    final mockDeliveryRepo = MockDeliveryRepository();
    final mockLocationService = MockLocationService();

    return ProviderScope(
      overrides: [
        ...commonWidgetTestOverrides(),
        deliveryRepositoryProvider.overrideWithValue(mockDeliveryRepo),
        locationServiceProvider.overrideWithValue(mockLocationService),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: ProfileHero(
              user: user,
              onNotificationTap: onNotificationTap,
              onSettingsTap: onSettingsTap,
            ),
          ),
        ),
      ),
    );
  }

  group('ProfileHero', () {
    testWidgets('renders user name', (tester) async {
      await tester.pumpWidget(buildWidget(testUser));
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('Jean Kouame'), findsOneWidget);
    });

    testWidgets('renders user email', (tester) async {
      await tester.pumpWidget(buildWidget(testUser));
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('jean@test.com'), findsOneWidget);
    });

    testWidgets('shows Profil header', (tester) async {
      await tester.pumpWidget(buildWidget(testUser));
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('Profil'), findsOneWidget);
    });

    testWidgets('shows En ligne status when available', (tester) async {
      await tester.pumpWidget(buildWidget(testUser));
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('En ligne'), findsOneWidget);
    });

    testWidgets('shows Hors ligne status when offline', (tester) async {
      await tester.pumpWidget(buildWidget(offlineUser));
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('Hors ligne'), findsOneWidget);
    });

    testWidgets('shows vehicle type Moto for motorcycle', (tester) async {
      await tester.pumpWidget(buildWidget(testUser));
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('Moto'), findsOneWidget);
    });

    testWidgets('shows vehicle type Voiture for car', (tester) async {
      await tester.pumpWidget(buildWidget(offlineUser));
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('Voiture'), findsOneWidget);
    });

    testWidgets('hides vehicle pill when no courier', (tester) async {
      await tester.pumpWidget(buildWidget(noCourierUser));
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('Moto'), findsNothing);
      expect(find.text('Voiture'), findsNothing);
    });

    testWidgets('shows Disponible text when En ligne', (tester) async {
      await tester.pumpWidget(buildWidget(testUser));
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('Disponible'), findsOneWidget);
      expect(find.text('Vous recevez des commandes'), findsOneWidget);
    });

    testWidgets('shows Indisponible text when offline', (tester) async {
      await tester.pumpWidget(buildWidget(offlineUser));
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('Indisponible'), findsOneWidget);
      expect(find.text('Activez pour recevoir des commandes'), findsOneWidget);
    });

    testWidgets('has notification and settings icons', (tester) async {
      await tester.pumpWidget(buildWidget(testUser));
      await tester.pump(const Duration(seconds: 1));
      expect(find.byIcon(Icons.notifications_none_rounded), findsOneWidget);
      expect(find.byIcon(Icons.settings_outlined), findsOneWidget);
    });

    testWidgets('notification tap callback fires', (tester) async {
      bool tapped = false;
      await tester.pumpWidget(
        buildWidget(testUser, onNotificationTap: () => tapped = true),
      );
      await tester.pump(const Duration(seconds: 1));
      await tester.tap(find.byIcon(Icons.notifications_none_rounded));
      await tester.pump();
      expect(tapped, isTrue);
    });

    testWidgets('settings tap callback fires', (tester) async {
      bool tapped = false;
      await tester.pumpWidget(
        buildWidget(testUser, onSettingsTap: () => tapped = true),
      );
      await tester.pump(const Duration(seconds: 1));
      await tester.tap(find.byIcon(Icons.settings_outlined));
      await tester.pump();
      expect(tapped, isTrue);
    });

    testWidgets('shows switch for availability toggle', (tester) async {
      await tester.pumpWidget(buildWidget(testUser));
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(Switch), findsOneWidget);
    });

    testWidgets('renders no courier user name', (tester) async {
      await tester.pumpWidget(buildWidget(noCourierUser));
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('Pierre Kamagate'), findsOneWidget);
      expect(find.text('pierre@test.com'), findsOneWidget);
    });
  });
}
