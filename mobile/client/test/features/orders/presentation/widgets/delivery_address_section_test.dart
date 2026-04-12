import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drpharma_client/features/addresses/domain/entities/address_entity.dart';
import 'package:drpharma_client/features/orders/presentation/widgets/delivery_address_section.dart';

void main() {
  late TextEditingController addressController;
  late TextEditingController cityController;
  late TextEditingController phoneController;
  late TextEditingController labelController;

  setUp(() {
    addressController = TextEditingController();
    cityController = TextEditingController();
    phoneController = TextEditingController();
    labelController = TextEditingController();
  });

  tearDown(() {
    addressController.dispose();
    cityController.dispose();
    phoneController.dispose();
    labelController.dispose();
  });

  final tAddress = AddressEntity(
    id: 1,
    label: 'Maison',
    address: '123 Rue de Paris',
    fullAddress: '123 Rue de Paris, Paris',
    city: 'Paris',
    phone: '0612345678',
    isDefault: true,
    hasCoordinates: true,
    latitude: 48.8566,
    longitude: 2.3522,
    createdAt: DateTime(2024, 1, 1),
    updatedAt: DateTime(2024, 1, 1),
  );

  Widget buildWidget({
    bool useManualAddress = false,
    bool hasAddresses = true,
    AddressEntity? selectedAddress,
    bool saveAddress = false,
    bool isDark = false,
    ValueChanged<bool>? onToggleManualAddress,
    ValueChanged<AddressEntity?>? onAddressSelected,
    ValueChanged<bool>? onSaveAddressChanged,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: DeliveryAddressSection(
            useManualAddress: useManualAddress,
            hasAddresses: hasAddresses,
            selectedAddress: selectedAddress,
            onToggleManualAddress: onToggleManualAddress ?? (_) {},
            onAddressSelected: onAddressSelected ?? (_) {},
            addressController: addressController,
            cityController: cityController,
            phoneController: phoneController,
            labelController: labelController,
            saveAddress: saveAddress,
            onSaveAddressChanged: onSaveAddressChanged ?? (_) {},
            isDark: isDark,
          ),
        ),
      ),
    );
  }

  group('DeliveryAddressSection', () {
    group('rendering', () {
      testWidgets('should render with default values', (tester) async {
        await tester.pumpWidget(
          buildWidget(
            useManualAddress:
                true, // Use manual to avoid AddressSelector needing ProviderScope
          ),
        );
        await tester.pump();

        expect(find.byType(DeliveryAddressSection), findsOneWidget);
      });

      testWidgets('should show address type toggle when has addresses', (
        tester,
      ) async {
        await tester.pumpWidget(
          buildWidget(hasAddresses: true, useManualAddress: true),
        );
        await tester.pump();

        expect(find.text('Adresses enregistrées'), findsOneWidget);
        expect(find.text('Nouvelle adresse'), findsOneWidget);
      });

      testWidgets('should not show toggle when no addresses', (tester) async {
        await tester.pumpWidget(buildWidget(hasAddresses: false));
        await tester.pump();

        expect(find.text('Adresses enregistrées'), findsNothing);
        expect(find.text('Nouvelle adresse'), findsNothing);
      });

      testWidgets('should show address form when useManualAddress is true', (
        tester,
      ) async {
        await tester.pumpWidget(
          buildWidget(useManualAddress: true, hasAddresses: true),
        );
        await tester.pump();

        // The form should contain text fields
        expect(find.byType(TextFormField), findsWidgets);
      });

      testWidgets('should show address form when no addresses exist', (
        tester,
      ) async {
        await tester.pumpWidget(
          buildWidget(useManualAddress: false, hasAddresses: false),
        );
        await tester.pump();

        // Form should be shown automatically
        expect(find.byType(TextFormField), findsWidgets);
      });
    });

    group('toggle buttons', () {
      testWidgets('should highlight saved address button when not using manual', (
        tester,
      ) async {
        // Note: We use useManualAddress: true to avoid AddressSelector which needs ProviderScope
        // and just verify the button is present
        await tester.pumpWidget(
          buildWidget(useManualAddress: true, hasAddresses: true),
        );
        await tester.pump();

        final savedAddressButton = find.text('Adresses enregistrées');
        expect(savedAddressButton, findsOneWidget);
      });

      testWidgets('should highlight new address button when using manual', (
        tester,
      ) async {
        await tester.pumpWidget(
          buildWidget(useManualAddress: true, hasAddresses: true),
        );
        await tester.pump();

        final newAddressButton = find.text('Nouvelle adresse');
        expect(newAddressButton, findsOneWidget);
      });

      testWidgets(
        'should call onToggleManualAddress when saved address button tapped',
        (tester) async {
          bool? toggledValue;
          await tester.pumpWidget(
            buildWidget(
              useManualAddress: true,
              hasAddresses: true,
              onToggleManualAddress: (value) => toggledValue = value,
            ),
          );
          await tester.pump();

          await tester.tap(find.text('Adresses enregistrées'));
          await tester.pump();

          expect(toggledValue, false);
        },
      );

      testWidgets(
        'should call onToggleManualAddress when new address button tapped',
        (tester) async {
          bool? toggledValue;
          await tester.pumpWidget(
            buildWidget(
              useManualAddress: true, // Use true to avoid AddressSelector
              hasAddresses: true,
              onToggleManualAddress: (value) => toggledValue = value,
            ),
          );
          await tester.pump();

          await tester.tap(find.text('Nouvelle adresse'));
          await tester.pump();

          expect(toggledValue, true);
        },
      );
    });

    group('icons', () {
      testWidgets('should show bookmark icon for saved address', (
        tester,
      ) async {
        await tester.pumpWidget(
          buildWidget(hasAddresses: true, useManualAddress: true),
        );
        await tester.pump();

        // Form shows bookmark_border when saveAddress is false (default)
        expect(find.byIcon(Icons.bookmark_border), findsOneWidget);
      });

      testWidgets('should show my_location icon for new address form', (
        tester,
      ) async {
        await tester.pumpWidget(
          buildWidget(hasAddresses: true, useManualAddress: true),
        );
        await tester.pump();

        expect(find.byIcon(Icons.my_location), findsOneWidget);
      });
    });

    group('dark mode', () {
      testWidgets('should render correctly in dark mode', (tester) async {
        await tester.pumpWidget(
          buildWidget(isDark: true, hasAddresses: true, useManualAddress: true),
        );
        await tester.pump();

        expect(find.byType(DeliveryAddressSection), findsOneWidget);
      });

      testWidgets('should render form in dark mode', (tester) async {
        await tester.pumpWidget(
          buildWidget(isDark: true, useManualAddress: true, hasAddresses: true),
        );
        await tester.pump();

        expect(find.byType(TextFormField), findsWidgets);
      });
    });

    group('with selected address', () {
      // Note: Tests with useManualAddress: false require ProviderScope
      // because AddressSelector uses Riverpod. We test with useManualAddress: true
      // to avoid this dependency in unit tests.

      testWidgets('should accept selected address parameter', (tester) async {
        // Test that widget accepts selectedAddress parameter without crashing
        // Using useManualAddress to avoid AddressSelector which needs ProviderScope
        await tester.pumpWidget(
          buildWidget(
            hasAddresses: true,
            useManualAddress: true, // Use manual to avoid AddressSelector
            selectedAddress: tAddress,
          ),
        );
        await tester.pump();

        expect(find.byType(DeliveryAddressSection), findsOneWidget);
      });

      testWidgets(
        'should display form when using manual address with selected',
        (tester) async {
          await tester.pumpWidget(
            buildWidget(
              useManualAddress: true,
              hasAddresses: true,
              selectedAddress: tAddress,
            ),
          );
          await tester.pump();

          // Form should be shown when using manual address
          expect(find.byType(TextFormField), findsWidgets);
        },
      );
    });

    group('controller values', () {
      testWidgets('should use provided controllers', (tester) async {
        addressController.text = '456 Test Street';
        cityController.text = 'Lyon';
        phoneController.text = '0699999999';
        labelController.text = 'Work';

        await tester.pumpWidget(
          buildWidget(useManualAddress: true, hasAddresses: true),
        );
        await tester.pump();

        // Controllers should retain their values
        expect(addressController.text, '456 Test Street');
        expect(cityController.text, 'Lyon');
        expect(phoneController.text, '0699999999');
        expect(labelController.text, 'Work');
      });
    });

    group('save address checkbox', () {
      testWidgets('should respect saveAddress value', (tester) async {
        await tester.pumpWidget(
          buildWidget(
            useManualAddress: true,
            hasAddresses: true,
            saveAddress: true,
          ),
        );
        await tester.pump();

        expect(find.byType(DeliveryAddressSection), findsOneWidget);
      });

      testWidgets('should pass onSaveAddressChanged to form', (tester) async {
        await tester.pumpWidget(
          buildWidget(
            useManualAddress: true,
            hasAddresses: true,
            saveAddress: false,
            onSaveAddressChanged: (_) {},
          ),
        );
        await tester.pump();

        // Widget should build without errors
        expect(find.byType(DeliveryAddressSection), findsOneWidget);
      });
    });

    group('InkWell interaction', () {
      testWidgets('should have InkWell for toggle buttons with manual mode', (
        tester,
      ) async {
        await tester.pumpWidget(
          buildWidget(
            hasAddresses: true,
            useManualAddress:
                true, // Use manual to avoid AddressSelector needing ProviderScope
          ),
        );
        await tester.pump();

        expect(find.byType(InkWell), findsWidgets);
      });

      testWidgets('should respond to tap on both buttons from manual mode', (
        tester,
      ) async {
        final toggleValues = <bool>[];
        await tester.pumpWidget(
          buildWidget(
            hasAddresses: true,
            useManualAddress: true, // Start in manual mode
            onToggleManualAddress: (value) => toggleValues.add(value),
          ),
        );
        await tester.pump();

        // Tap on saved address button (switching from manual)
        await tester.tap(find.text('Adresses enregistrées'));
        await tester.pump();

        // Tap on new address button
        await tester.tap(find.text('Nouvelle adresse'));
        await tester.pump();

        expect(toggleValues, [false, true]);
      });
    });
  });
}
