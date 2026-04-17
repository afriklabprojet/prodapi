import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:courier/presentation/screens/pending_approval_screen.dart';
import 'package:courier/presentation/providers/delivery_providers.dart';
import 'package:courier/data/models/courier_profile.dart';
import '../helpers/widget_test_helpers.dart';

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

  final testProfile = const CourierProfile(
    id: 1,
    name: 'Test Courier',
    email: 'test@example.com',
    status: 'pending_approval',
    vehicleType: 'motorcycle',
    plateNumber: 'AB-123',
    rating: 4.5,
    completedDeliveries: 10,
    earnings: 50000.0,
    kycStatus: 'approved',
  );

  Widget buildScreen({
    String status = 'pending_approval',
    String message = 'Votre compte est en cours de validation.',
  }) {
    return ProviderScope(
      overrides: [
        ...commonWidgetTestOverrides(),
        courierProfileProvider.overrideWith((_) async => testProfile),
      ],
      child: MaterialApp(
        home: PendingApprovalScreen(status: status, message: message),
      ),
    );
  }

  group('PendingApprovalScreen - pending_approval status', () {
    testWidgets('shows En Attente title for pending', (tester) async {
      tester.view.physicalSize = const Size(1080, 5000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildScreen(status: 'pending_approval'));
      await tester.pump(const Duration(seconds: 1));

      expect(find.textContaining('Approbation'), findsWidgets);
    });

    testWidgets('shows progress stepper for pending', (tester) async {
      tester.view.physicalSize = const Size(1080, 5000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildScreen(status: 'pending_approval'));
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('Progression de votre inscription'), findsOneWidget);
      expect(find.text('Documents reçus'), findsOneWidget);
      expect(find.text('Vérification en cours'), findsOneWidget);
      expect(find.text('Compte activé'), findsOneWidget);
    });

    testWidgets('shows 24-48h delay badge', (tester) async {
      tester.view.physicalSize = const Size(1080, 5000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildScreen(status: 'pending_approval'));
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('Validation sous 24-48h ouvrées'), findsOneWidget);
    });

    testWidgets('shows verify status button', (tester) async {
      tester.view.physicalSize = const Size(1080, 5000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildScreen(status: 'pending_approval'));
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('Vérifier mon statut'), findsOneWidget);
    });

    testWidgets('shows notification info container', (tester) async {
      tester.view.physicalSize = const Size(1080, 5000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildScreen(status: 'pending_approval'));
      await tester.pump(const Duration(seconds: 1));

      expect(
        find.textContaining('notification dès que votre compte sera validé'),
        findsOneWidget,
      );
    });

    testWidgets('shows Une question button for pending', (tester) async {
      tester.view.physicalSize = const Size(1080, 5000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildScreen(status: 'pending_approval'));
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('Une question ?'), findsOneWidget);
    });

    testWidgets('shows Retour à la connexion button', (tester) async {
      tester.view.physicalSize = const Size(1080, 5000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildScreen(status: 'pending_approval'));
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('Retour à la connexion'), findsOneWidget);
    });

    testWidgets('tap verify status calls courierProfileProvider', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 5000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildScreen(status: 'pending_approval'));
      await tester.pump(const Duration(seconds: 1));

      await tester.tap(find.text('Vérifier mon statut'));
      await tester.pump(const Duration(seconds: 2));

      // After successful check, should show snackbar
      expect(find.textContaining('Statut vérifié'), findsOneWidget);
    });
  });

  group('PendingApprovalScreen - suspended status', () {
    testWidgets('shows Compte Suspendu title', (tester) async {
      tester.view.physicalSize = const Size(1080, 5000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        buildScreen(
          status: 'suspended',
          message: 'Votre compte a été suspendu.',
        ),
      );
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('Compte Suspendu'), findsOneWidget);
      expect(find.text('Votre compte a été suspendu.'), findsOneWidget);
    });

    testWidgets('shows Contacter le support for suspended', (tester) async {
      tester.view.physicalSize = const Size(1080, 5000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        buildScreen(status: 'suspended', message: 'Compte suspendu.'),
      );
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('Contacter le support'), findsOneWidget);
    });
  });

  group('PendingApprovalScreen - rejected status', () {
    testWidgets('shows Inscription Refusée title', (tester) async {
      tester.view.physicalSize = const Size(1080, 5000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        buildScreen(status: 'rejected', message: 'Votre dossier a été refusé.'),
      );
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('Inscription Refusée'), findsOneWidget);
    });

    testWidgets('shows Contacter le support for rejected', (tester) async {
      tester.view.physicalSize = const Size(1080, 5000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        buildScreen(status: 'rejected', message: 'Dossier refusé.'),
      );
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('Contacter le support'), findsOneWidget);
    });
  });
}
