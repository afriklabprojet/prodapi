import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:courier/presentation/widgets/profile/personnel_card.dart';
import 'package:courier/data/models/user.dart';
import '../../helpers/widget_test_helpers.dart';

void main() {
  Widget buildWidget({Map<String, dynamic>? courierData, String? phone}) {
    final json = {
      'id': 1,
      'name': 'Marie Konan',
      'email': 'marie@test.com',
      'phone': phone ?? '+2250707070707',
    };
    if (courierData != null) {
      json['courier'] = courierData;
    }
    final user = User.fromJson(json);
    return ProviderScope(
      overrides: commonWidgetTestOverrides(),
      child: MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(child: PersonnelCard(user: user)),
        ),
      ),
    );
  }

  group('PersonnelCard', () {
    testWidgets('renders with user info', (tester) async {
      await tester.pumpWidget(
        buildWidget(
          courierData: {
            'id': 1,
            'status': 'active',
            'completed_deliveries': '80',
            'rating': '4.9',
          },
        ),
      );
      expect(find.byType(PersonnelCard), findsOneWidget);
    });

    testWidgets('displays user email', (tester) async {
      await tester.pumpWidget(
        buildWidget(
          courierData: {
            'id': 1,
            'status': 'active',
            'completed_deliveries': '80',
            'rating': '4.9',
          },
        ),
      );
      expect(find.text('marie@test.com'), findsOneWidget);
    });

    testWidgets('displays phone number', (tester) async {
      await tester.pumpWidget(
        buildWidget(
          courierData: {
            'id': 1,
            'status': 'active',
            'completed_deliveries': '80',
            'rating': '4.9',
          },
        ),
      );
      expect(find.textContaining('+225'), findsWidgets);
    });

    testWidgets('contains Text widgets', (tester) async {
      await tester.pumpWidget(
        buildWidget(
          courierData: {
            'id': 1,
            'status': 'active',
            'completed_deliveries': '80',
            'rating': '4.9',
          },
        ),
      );
      expect(find.byType(Text), findsWidgets);
    });

    testWidgets('contains Icon widgets', (tester) async {
      await tester.pumpWidget(
        buildWidget(
          courierData: {
            'id': 1,
            'status': 'active',
            'completed_deliveries': '80',
            'rating': '4.9',
          },
        ),
      );
      expect(find.byType(Icon), findsWidgets);
    });

    testWidgets('contains Container widgets', (tester) async {
      await tester.pumpWidget(
        buildWidget(
          courierData: {
            'id': 1,
            'status': 'active',
            'completed_deliveries': '80',
            'rating': '4.9',
          },
        ),
      );
      expect(find.byType(Container), findsWidgets);
    });

    testWidgets('contains Column widgets', (tester) async {
      await tester.pumpWidget(
        buildWidget(
          courierData: {
            'id': 1,
            'status': 'active',
            'completed_deliveries': '80',
            'rating': '4.9',
          },
        ),
      );
      expect(find.byType(Column), findsWidgets);
    });

    testWidgets('contains Row widgets', (tester) async {
      await tester.pumpWidget(
        buildWidget(
          courierData: {
            'id': 1,
            'status': 'active',
            'completed_deliveries': '80',
            'rating': '4.9',
          },
        ),
      );
      expect(find.byType(Row), findsWidgets);
    });

    // ── Section labels ──

    testWidgets('shows "Informations personnelles" title', (tester) async {
      await tester.pumpWidget(
        buildWidget(
          courierData: {
            'id': 1,
            'status': 'active',
            'completed_deliveries': '80',
            'rating': '4.9',
          },
        ),
      );
      expect(find.text('Informations personnelles'), findsOneWidget);
    });

    testWidgets('shows Email label', (tester) async {
      await tester.pumpWidget(
        buildWidget(courierData: {'id': 1, 'status': 'active'}),
      );
      expect(find.text('Email'), findsOneWidget);
    });

    testWidgets('shows Téléphone label', (tester) async {
      await tester.pumpWidget(
        buildWidget(courierData: {'id': 1, 'status': 'active'}),
      );
      expect(find.text('Téléphone'), findsOneWidget);
    });

    testWidgets('shows Véhicule label', (tester) async {
      await tester.pumpWidget(
        buildWidget(courierData: {'id': 1, 'status': 'active'}),
      );
      expect(find.text('Véhicule'), findsOneWidget);
    });

    // ── Vehicle label tests ──

    testWidgets('motorcycle shows "Moto"', (tester) async {
      await tester.pumpWidget(
        buildWidget(
          courierData: {
            'id': 1,
            'status': 'active',
            'vehicle_type': 'motorcycle',
          },
        ),
      );
      expect(find.text('Moto'), findsOneWidget);
    });

    testWidgets('car shows "Voiture"', (tester) async {
      await tester.pumpWidget(
        buildWidget(
          courierData: {'id': 1, 'status': 'active', 'vehicle_type': 'car'},
        ),
      );
      expect(find.text('Voiture'), findsOneWidget);
    });

    testWidgets('bicycle shows "Vélo"', (tester) async {
      await tester.pumpWidget(
        buildWidget(
          courierData: {'id': 1, 'status': 'active', 'vehicle_type': 'bicycle'},
        ),
      );
      expect(find.text('Vélo'), findsOneWidget);
    });

    testWidgets('scooter shows "Scooter"', (tester) async {
      await tester.pumpWidget(
        buildWidget(
          courierData: {'id': 1, 'status': 'active', 'vehicle_type': 'scooter'},
        ),
      );
      expect(find.text('Scooter'), findsOneWidget);
    });

    testWidgets('unknown vehicle type shows raw value', (tester) async {
      await tester.pumpWidget(
        buildWidget(
          courierData: {'id': 1, 'status': 'active', 'vehicle_type': 'truck'},
        ),
      );
      expect(find.text('truck'), findsOneWidget);
    });

    testWidgets('null vehicle type shows "Non défini"', (tester) async {
      await tester.pumpWidget(
        buildWidget(
          courierData: {'id': 1, 'status': 'active', 'vehicle_type': null},
        ),
      );
      expect(find.text('Non défini'), findsOneWidget);
    });

    // ── Courier null ──

    testWidgets('no courier shows "Non configuré"', (tester) async {
      await tester.pumpWidget(buildWidget(courierData: null));
      expect(find.text('Non configuré'), findsOneWidget);
    });

    // ── Vehicle number ──

    testWidgets('shows plate section when vehicleNumber present', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildWidget(
          courierData: {
            'id': 1,
            'status': 'active',
            'vehicle_type': 'motorcycle',
            'vehicle_number': 'AB-1234-CI',
          },
        ),
      );
      expect(find.text('Plaque'), findsOneWidget);
      expect(find.text('AB-1234-CI'), findsOneWidget);
    });

    testWidgets('hides plate section when vehicleNumber null', (tester) async {
      await tester.pumpWidget(
        buildWidget(
          courierData: {
            'id': 1,
            'status': 'active',
            'vehicle_type': 'motorcycle',
          },
        ),
      );
      expect(find.text('Plaque'), findsNothing);
    });

    // ── Icons ──

    testWidgets('shows edit icon for profile', (tester) async {
      await tester.pumpWidget(
        buildWidget(courierData: {'id': 1, 'status': 'active'}),
      );
      expect(find.byIcon(Icons.edit_rounded), findsWidgets);
    });

    testWidgets('shows person icon in header', (tester) async {
      await tester.pumpWidget(
        buildWidget(courierData: {'id': 1, 'status': 'active'}),
      );
      expect(find.byIcon(Icons.person_outline_rounded), findsOneWidget);
    });

    testWidgets('shows email icon', (tester) async {
      await tester.pumpWidget(
        buildWidget(courierData: {'id': 1, 'status': 'active'}),
      );
      expect(find.byIcon(Icons.email_outlined), findsOneWidget);
    });

    testWidgets('shows phone icon', (tester) async {
      await tester.pumpWidget(
        buildWidget(courierData: {'id': 1, 'status': 'active'}),
      );
      expect(find.byIcon(Icons.phone_android_rounded), findsOneWidget);
    });

    testWidgets('shows vehicle icon', (tester) async {
      await tester.pumpWidget(
        buildWidget(courierData: {'id': 1, 'status': 'active'}),
      );
      expect(find.byIcon(Icons.two_wheeler_rounded), findsOneWidget);
    });
  });
}
