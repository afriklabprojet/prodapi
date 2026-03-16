import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:courier/presentation/screens/profile_screen.dart';
import 'package:courier/presentation/providers/profile_provider.dart';
import 'package:courier/data/models/user.dart';
import 'package:courier/data/models/wallet_data.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  final testUser = User(
    id: 1,
    name: 'Jean Dupont',
    email: 'jean@test.com',
    phone: '+2250700000000',
    role: 'courier',
    courier: CourierInfo(
      id: 10,
      status: 'available',
      vehicleType: 'motorcycle',
      vehicleNumber: 'AB-1234-CI',
      completedDeliveries: 42,
      rating: 4.8,
    ),
  );

  final testWallet = WalletData(
    balance: 15000,
    totalCommissions: 3200,
    deliveriesCount: 42,
  );

  Widget buildScreen({User? user, WalletData? wallet}) {
    return ProviderScope(
      overrides: [
        profileProvider.overrideWith((ref) => Future.value(user ?? testUser)),
        profileWalletProvider.overrideWith((ref) => Future.value(wallet ?? testWallet)),
      ],
      child: const MaterialApp(
        home: ProfileScreen(),
      ),
    );
  }

  group('ProfileScreen', () {
    testWidgets('displays user name', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(find.text('Jean Dupont'), findsOneWidget);
    });

    testWidgets('displays vehicle type', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(find.text('MOTORCYCLE'), findsOneWidget);
    });

    testWidgets('displays user initial in avatar when no image', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(find.text('J'), findsOneWidget); // first letter of Jean
    });

    testWidgets('displays stats grid', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(find.text('Total Livré'), findsOneWidget);
      expect(find.text('Note Moyenne'), findsOneWidget);
      expect(find.text('Solde (FCFA)'), findsOneWidget);
      expect(find.text('Commissions'), findsOneWidget);
    });

    testWidgets('displays delivery count', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(find.text('42'), findsAtLeastNWidgets(1));
    });

    testWidgets('displays rating', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(find.text('4.8'), findsAtLeastNWidgets(1));
    });

    testWidgets('displays section titles', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(find.text('Aperçu'), findsOneWidget);
    });

    testWidgets('displays Personnel & Véhicule section', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      final scrollable = find.byType(Scrollable).first;
      await tester.scrollUntilVisible(find.text('Personnel & Véhicule'), 200, scrollable: scrollable);

      expect(find.text('Personnel & Véhicule'), findsOneWidget);
    });

    testWidgets('displays email info', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      final scrollable = find.byType(Scrollable).first;
      await tester.scrollUntilVisible(find.text('jean@test.com'), 200, scrollable: scrollable);

      expect(find.text('jean@test.com'), findsOneWidget);
    });

    testWidgets('displays phone info', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      final scrollable = find.byType(Scrollable).first;
      await tester.scrollUntilVisible(find.text('+2250700000000'), 200, scrollable: scrollable);

      expect(find.text('+2250700000000'), findsOneWidget);
    });

    testWidgets('displays Préférences section', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      final scrollable = find.byType(Scrollable).first;
      await tester.scrollUntilVisible(find.text('Préférences'), 200, scrollable: scrollable);

      expect(find.text('Préférences'), findsOneWidget);
    });

    testWidgets('displays logout button', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      final scrollable = find.byType(Scrollable).first;
      await tester.scrollUntilVisible(find.text('Se déconnecter de l\'application'), 200, scrollable: scrollable);

      expect(find.text('Se déconnecter de l\'application'), findsOneWidget);
    });

    testWidgets('displays online status indicator', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      // Power toggle should be visible (available status)
      expect(find.byIcon(Icons.power_settings_new), findsOneWidget);
    });

    testWidgets('renders with minimal user data', (tester) async {
      final minimalUser = User(
        id: 2,
        name: 'Test',
        email: 'test@test.com',
      );

      await tester.pumpWidget(buildScreen(user: minimalUser));
      await tester.pumpAndSettle();

      expect(find.text('Test'), findsOneWidget);
      expect(find.text('T'), findsOneWidget); // initial
    });

    testWidgets('displays Hebdomadaire section', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      final scrollable = find.byType(Scrollable).first;
      await tester.scrollUntilVisible(find.text('Hebdomadaire'), 200, scrollable: scrollable);

      expect(find.text('Hebdomadaire'), findsOneWidget);
    });

    // --- Vehicle info section tests ---

    testWidgets('displays vehicle label Moto for motorcycle', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      final scrollable = find.byType(Scrollable).first;
      await tester.scrollUntilVisible(find.textContaining('Moto'), 200, scrollable: scrollable);

      expect(find.textContaining('Moto (AB-1234-CI)'), findsOneWidget);
    });

    testWidgets('displays vehicle label Vélo for bicycle', (tester) async {
      final bicycleUser = User(
        id: 1,
        name: 'Marie',
        email: 'marie@test.com',
        courier: CourierInfo(
          id: 11,
          status: 'available',
          vehicleType: 'bicycle',
          vehicleNumber: 'VL-001',
        ),
      );
      await tester.pumpWidget(buildScreen(user: bicycleUser));
      await tester.pumpAndSettle();

      final scrollable = find.byType(Scrollable).first;
      await tester.scrollUntilVisible(find.textContaining('Vélo'), 200, scrollable: scrollable);

      expect(find.textContaining('Vélo (VL-001)'), findsOneWidget);
    });

    testWidgets('displays vehicle label Voiture for car', (tester) async {
      final carUser = User(
        id: 1,
        name: 'Paul',
        email: 'paul@test.com',
        courier: CourierInfo(
          id: 12,
          status: 'available',
          vehicleType: 'car',
          vehicleNumber: 'AB-5678',
        ),
      );
      await tester.pumpWidget(buildScreen(user: carUser));
      await tester.pumpAndSettle();

      final scrollable = find.byType(Scrollable).first;
      await tester.scrollUntilVisible(find.textContaining('Voiture'), 200, scrollable: scrollable);

      expect(find.textContaining('Voiture (AB-5678)'), findsOneWidget);
    });

    testWidgets('displays vehicle label Scooter for scooter', (tester) async {
      final scooterUser = User(
        id: 1,
        name: 'Koffi',
        email: 'koffi@test.com',
        courier: CourierInfo(
          id: 13,
          status: 'available',
          vehicleType: 'scooter',
          vehicleNumber: 'SC-999',
        ),
      );
      await tester.pumpWidget(buildScreen(user: scooterUser));
      await tester.pumpAndSettle();

      final scrollable = find.byType(Scrollable).first;
      await tester.scrollUntilVisible(find.textContaining('Scooter'), 200, scrollable: scrollable);

      expect(find.textContaining('Scooter (SC-999)'), findsOneWidget);
    });

    testWidgets('displays Profil coursier non configuré when no courier', (tester) async {
      final noCourierUser = User(
        id: 3,
        name: 'Ama',
        email: 'ama@test.com',
      );
      await tester.pumpWidget(buildScreen(user: noCourierUser));
      await tester.pumpAndSettle();

      final scrollable = find.byType(Scrollable).first;
      await tester.scrollUntilVisible(
        find.textContaining('Profil coursier non configuré'),
        200,
        scrollable: scrollable,
      );

      expect(find.textContaining('Profil coursier non configuré'), findsOneWidget);
    });

    testWidgets('displays Non renseigné when no phone', (tester) async {
      final noPhoneUser = User(
        id: 4,
        name: 'Ali',
        email: 'ali@test.com',
        courier: CourierInfo(
          id: 14,
          status: 'available',
          vehicleType: 'motorcycle',
        ),
      );
      await tester.pumpWidget(buildScreen(user: noPhoneUser));
      await tester.pumpAndSettle();

      final scrollable = find.byType(Scrollable).first;
      await tester.scrollUntilVisible(find.text('Non renseigné'), 200, scrollable: scrollable);

      expect(find.text('Non renseigné'), findsOneWidget);
    });

    testWidgets('displays vehicle number --- when null', (tester) async {
      final noPlateUser = User(
        id: 5,
        name: 'Binta',
        email: 'binta@test.com',
        courier: CourierInfo(
          id: 15,
          status: 'available',
          vehicleType: 'motorcycle',
        ),
      );
      await tester.pumpWidget(buildScreen(user: noPlateUser));
      await tester.pumpAndSettle();

      final scrollable = find.byType(Scrollable).first;
      await tester.scrollUntilVisible(find.textContaining('Moto (---)'), 200, scrollable: scrollable);

      expect(find.textContaining('Moto (---)'), findsOneWidget);
    });

    // --- Edit phone dialog test ---

    testWidgets('tapping phone opens edit dialog', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      final scrollable = find.byType(Scrollable).first;
      await tester.scrollUntilVisible(find.text('+2250700000000'), 200, scrollable: scrollable);
      await tester.pumpAndSettle();

      // Tap the phone info tile (it has onTap for edit)
      await tester.tap(find.text('+2250700000000'));
      await tester.pumpAndSettle();

      expect(find.text('Modifier le téléphone'), findsOneWidget);
      expect(find.text('Enregistrer'), findsOneWidget);
      expect(find.text('Annuler'), findsOneWidget);
    });

    testWidgets('edit phone dialog validates empty number', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      final scrollable = find.byType(Scrollable).first;
      await tester.scrollUntilVisible(find.text('+2250700000000'), 200, scrollable: scrollable);
      await tester.pumpAndSettle();

      await tester.tap(find.text('+2250700000000'));
      await tester.pumpAndSettle();

      // Clear the field
      final phoneField = find.byType(TextFormField);
      await tester.enterText(phoneField.last, '');
      await tester.pumpAndSettle();

      await tester.tap(find.text('Enregistrer'));
      await tester.pumpAndSettle();

      expect(find.text('Veuillez entrer un numéro'), findsOneWidget);
    });

    testWidgets('edit phone dialog validates short number', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      final scrollable = find.byType(Scrollable).first;
      await tester.scrollUntilVisible(find.text('+2250700000000'), 200, scrollable: scrollable);
      await tester.pumpAndSettle();

      await tester.tap(find.text('+2250700000000'));
      await tester.pumpAndSettle();

      final phoneField = find.byType(TextFormField);
      await tester.enterText(phoneField.last, '123');
      await tester.pumpAndSettle();

      await tester.tap(find.text('Enregistrer'));
      await tester.pumpAndSettle();

      expect(find.text('Numéro trop court'), findsOneWidget);
    });

    testWidgets('edit phone dialog cancel closes it', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      final scrollable = find.byType(Scrollable).first;
      await tester.scrollUntilVisible(find.text('+2250700000000'), 200, scrollable: scrollable);
      await tester.pumpAndSettle();

      await tester.tap(find.text('+2250700000000'));
      await tester.pumpAndSettle();

      expect(find.text('Modifier le téléphone'), findsOneWidget);

      await tester.tap(find.text('Annuler'));
      await tester.pumpAndSettle();

      expect(find.text('Modifier le téléphone'), findsNothing);
    });

    // --- Preference action buttons ---

    testWidgets('displays action buttons in Préférences', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      final scrollable = find.byType(Scrollable).first;
      await tester.scrollUntilVisible(find.text('Statistiques'), 200, scrollable: scrollable);

      expect(find.text('Statistiques'), findsOneWidget);
      expect(find.text('Historique'), findsOneWidget);
      expect(find.text('Paramètres'), findsOneWidget);
    });

    testWidgets('displays Aide & Support button', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      final scrollable = find.byType(Scrollable).first;
      await tester.scrollUntilVisible(find.text('Aide & Support'), 200, scrollable: scrollable);

      expect(find.text('Aide & Support'), findsOneWidget);
    });

    // --- Logout dialog ---

    testWidgets('logout button shows confirmation dialog', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      final scrollable = find.byType(Scrollable).first;
      await tester.scrollUntilVisible(
        find.text('Se déconnecter de l\'application'),
        200,
        scrollable: scrollable,
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Se déconnecter de l\'application'));
      await tester.pumpAndSettle();

      expect(find.text('Déconnexion'), findsOneWidget);
      expect(find.text('Êtes-vous sûr de vouloir vous déconnecter ?'), findsOneWidget);
      expect(find.text('Déconnecter'), findsOneWidget);
    });

    testWidgets('logout cancel closes dialog', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      final scrollable = find.byType(Scrollable).first;
      await tester.scrollUntilVisible(
        find.text('Se déconnecter de l\'application'),
        200,
        scrollable: scrollable,
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Se déconnecter de l\'application'));
      await tester.pumpAndSettle();

      expect(find.text('Déconnexion'), findsOneWidget);
      await tester.tap(find.text('Annuler'));
      await tester.pumpAndSettle();

      expect(find.text('Déconnexion'), findsNothing);
    });

    // --- Performance card ---

    testWidgets('displays Gains de Livraison in Hebdomadaire', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      final scrollable = find.byType(Scrollable).first;
      await tester.scrollUntilVisible(find.text('Gains de Livraison'), 200, scrollable: scrollable);

      expect(find.text('Gains de Livraison'), findsOneWidget);
    });

    testWidgets('displays performance metrics labels', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      final scrollable = find.byType(Scrollable).first;
      await tester.scrollUntilVisible(find.text('Livraisons'), 200, scrollable: scrollable);

      expect(find.text('Livraisons'), findsOneWidget);
      expect(find.text('Rechargé'), findsOneWidget);
      expect(find.text('Solde'), findsOneWidget);
    });

    // --- Offline status ---

    testWidgets('shows pause icon when offline', (tester) async {
      final offlineUser = User(
        id: 1,
        name: 'Offline Guy',
        email: 'off@test.com',
        courier: CourierInfo(
          id: 20,
          status: 'offline',
          vehicleType: 'motorcycle',
        ),
      );
      await tester.pumpWidget(buildScreen(user: offlineUser));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.pause_circle_outline), findsOneWidget);
    });

    // --- Wallet data display ---

    testWidgets('displays wallet balance in stats grid', (tester) async {
      await tester.pumpWidget(buildScreen(wallet: WalletData(
        balance: 50000,
        totalCommissions: 5000,
        deliveriesCount: 100,
      )));
      await tester.pumpAndSettle();

      // Balance should be formatted: 50 000
      expect(find.textContaining('50'), findsAtLeastNWidgets(1));
    });

    testWidgets('displays edit icon on phone tile', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      final scrollable = find.byType(Scrollable).first;
      await tester.scrollUntilVisible(find.text('+2250700000000'), 200, scrollable: scrollable);

      expect(find.byIcon(Icons.edit), findsOneWidget);
    });

    testWidgets('displays email icon', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      final scrollable = find.byType(Scrollable).first;
      await tester.scrollUntilVisible(find.text('jean@test.com'), 200, scrollable: scrollable);

      expect(find.byIcon(Icons.email_outlined), findsOneWidget);
    });
  });
}
