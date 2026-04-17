import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:courier/presentation/providers/delivery_providers.dart';
import 'package:courier/presentation/providers/profile_provider.dart';
import 'package:courier/presentation/widgets/common/kyc_banner.dart';
import 'package:courier/data/models/courier_profile.dart';
import 'package:courier/data/models/user.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  CourierProfile makeProfile({String kycStatus = 'verified'}) {
    return CourierProfile(
      id: 1,
      name: 'Test Courier',
      email: 'test@courier.com',
      status: 'available',
      vehicleType: 'moto',
      plateNumber: 'AB-123',
      rating: 4.5,
      completedDeliveries: 10,
      earnings: 50000,
      kycStatus: kycStatus,
    );
  }

  User makeUser({String kycStatus = 'verified'}) {
    return User(
      id: 1,
      name: 'Test Courier',
      email: 'test@courier.com',
      courier: CourierInfo(id: 1, status: 'available', kycStatus: kycStatus),
    );
  }

  Widget buildBanner({required String kycStatus}) {
    return ProviderScope(
      overrides: [
        courierProfileProvider.overrideWith(
          (ref) => Future.value(makeProfile(kycStatus: kycStatus)),
        ),
        profileProvider.overrideWith(
          (ref) => Future.value(makeUser(kycStatus: kycStatus)),
        ),
      ],
      child: const MaterialApp(home: Scaffold(body: KycBanner())),
    );
  }

  group('KycBanner', () {
    testWidgets('hidden when KYC is verified', (tester) async {
      await tester.pumpWidget(buildBanner(kycStatus: 'verified'));
      await tester.pump(const Duration(milliseconds: 100));

      // SizedBox.shrink
      expect(find.byType(Container), findsNothing);
      expect(find.text('Vérifier'), findsNothing);
    });

    testWidgets('shows message when KYC is incomplete', (tester) async {
      await tester.pumpWidget(buildBanner(kycStatus: 'incomplete'));
      await tester.pump(const Duration(milliseconds: 100));

      expect(
        find.text('Complétez votre vérification pour recevoir des commandes'),
        findsOneWidget,
      );
      expect(find.text('Vérifier'), findsOneWidget);
    });

    testWidgets('shows pending message for pending_review', (tester) async {
      await tester.pumpWidget(buildBanner(kycStatus: 'pending_review'));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Documents en cours de vérification'), findsOneWidget);
      // No "Vérifier" button when pending
      expect(find.text('Vérifier'), findsNothing);
    });

    testWidgets('shows rejected message', (tester) async {
      await tester.pumpWidget(buildBanner(kycStatus: 'rejected'));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.textContaining('refusés'), findsOneWidget);
      expect(find.text('Corriger'), findsOneWidget);
    });
  });
}
