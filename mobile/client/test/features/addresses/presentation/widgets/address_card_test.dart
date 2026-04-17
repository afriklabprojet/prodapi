import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drpharma_client/features/addresses/domain/entities/address_entity.dart';
import 'package:drpharma_client/features/addresses/presentation/widgets/address_card.dart';

void main() {
  group('AddressCard Widget Tests', () {
    late AddressEntity testAddress;
    late AddressEntity defaultAddress;

    setUp(() {
      testAddress = AddressEntity(
        id: 1,
        label: 'Maison',
        address: '123 Rue de la Paix',
        city: 'Paris',
        district: '8ème arrondissement',
        phone: '+33612345678',
        instructions: 'Sonnez à l\'interphone',
        latitude: 48.8566,
        longitude: 2.3522,
        isDefault: false,
        fullAddress: '123 Rue de la Paix, 8ème arrondissement, Paris',
        hasCoordinates: true,
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 1),
      );

      defaultAddress = testAddress.copyWith(
        id: 2,
        label: 'Bureau',
        isDefault: true,
      );
    });

    testWidgets('should render address card with all details', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AddressCard(address: testAddress, onTap: () {}),
          ),
        ),
      );

      // Vérifier que tous les éléments sont affichés
      expect(find.text('Maison'), findsOneWidget);
      expect(find.text('123 Rue de la Paix'), findsOneWidget);
      expect(find.text('8ème arrondissement, Paris'), findsOneWidget);
      expect(find.text('+33612345678'), findsOneWidget);
      expect(find.text('Sonnez à l\'interphone'), findsOneWidget);
      expect(find.text('Position GPS enregistrée'), findsOneWidget);
    });

    testWidgets('should show default badge for default address', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AddressCard(address: defaultAddress, onTap: () {}),
          ),
        ),
      );

      expect(find.text('Par défaut'), findsOneWidget);
      expect(find.byIcon(Icons.location_on), findsOneWidget);
    });

    testWidgets('should not show default badge for non-default address', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AddressCard(address: testAddress, onTap: () {}),
          ),
        ),
      );

      expect(find.text('Par défaut'), findsNothing);
      expect(find.byIcon(Icons.location_on_outlined), findsOneWidget);
    });

    testWidgets('should call onTap when card is tapped', (tester) async {
      var tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AddressCard(address: testAddress, onTap: () => tapped = true),
          ),
        ),
      );

      // Tap sur la carte (premier InkWell, pas le menu d'actions)
      await tester.tap(find.byType(InkWell).first);
      await tester.pumpAndSettle();

      expect(tapped, isTrue);
    });

    testWidgets('should show popup menu with actions', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AddressCard(
              address: testAddress,
              onTap: () {},
              onDefault: () {},
              onDelete: () {},
            ),
          ),
        ),
      );

      // Ouvrir le menu popup
      await tester.tap(find.byType(PopupMenuButton<String>));
      await tester.pumpAndSettle();

      expect(find.text('Définir par défaut'), findsOneWidget);
      expect(find.text('Supprimer'), findsOneWidget);
    });

    testWidgets('should not show "Définir par défaut" for default address', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AddressCard(
              address: defaultAddress,
              onTap: () {},
              onDefault: () {},
              onDelete: () {},
            ),
          ),
        ),
      );

      await tester.tap(find.byType(PopupMenuButton<String>));
      await tester.pumpAndSettle();

      expect(find.text('Définir par défaut'), findsNothing);
      expect(find.text('Supprimer'), findsOneWidget);
    });

    testWidgets('should show confirmation dialog when dismissed', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AddressCard(
              address: testAddress,
              onTap: () {},
              onDelete: () {},
            ),
          ),
        ),
      );

      // Effectuer un swipe pour supprimer
      await tester.drag(find.byType(Dismissible), const Offset(-500, 0));
      await tester.pumpAndSettle();

      // Vérifier que le dialogue de confirmation s'affiche
      expect(find.text('Supprimer l\'adresse'), findsOneWidget);
      expect(
        find.text('Êtes-vous sûr de vouloir supprimer "Maison" ?'),
        findsOneWidget,
      );
      expect(find.text('Annuler'), findsOneWidget);
      expect(find.text('Supprimer'), findsWidgets);
    });

    testWidgets('should hide actions in selection mode', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AddressCard(
              address: testAddress,
              onTap: () {},
              showActions: false,
            ),
          ),
        ),
      );

      expect(find.byType(PopupMenuButton<String>), findsNothing);
    });

    testWidgets('should handle address without optional details', (
      tester,
    ) async {
      final minimalAddress = AddressEntity(
        id: 3,
        label: 'Test',
        address: 'Test Address',
        city: null,
        district: null,
        phone: null,
        instructions: null,
        latitude: null,
        longitude: null,
        isDefault: false,
        fullAddress: 'Test Address',
        hasCoordinates: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AddressCard(address: minimalAddress, onTap: () {}),
          ),
        ),
      );

      expect(find.text('Test'), findsOneWidget);
      expect(find.text('Test Address'), findsOneWidget);
      expect(find.text('Position GPS enregistrée'), findsNothing);
      expect(find.byIcon(Icons.phone_outlined), findsNothing);
      expect(find.byIcon(Icons.info_outline), findsNothing);
    });
  });
}
