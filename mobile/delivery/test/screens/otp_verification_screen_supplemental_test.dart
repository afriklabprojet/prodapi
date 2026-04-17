import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:courier/presentation/screens/otp_verification_screen.dart';
import 'package:courier/data/repositories/auth_repository.dart';
import 'package:courier/data/models/user.dart';
import 'package:courier/core/services/firebase_otp_service.dart';
import '../helpers/widget_test_helpers.dart';

class _MockAuthRepo extends Mock implements AuthRepository {}

class _MockOtpService extends Mock implements FirebaseOtpService {}

void main() {
  late _MockAuthRepo mockAuthRepo;
  late _MockOtpService mockOtpService;

  setUpAll(() async {
    await initHiveForTests();
    registerFallbackValue(OtpPurpose.verification);
  });

  tearDownAll(() async {
    await cleanupHiveForTests();
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    mockAuthRepo = _MockAuthRepo();
    mockOtpService = _MockOtpService();
    // Stub Firebase OTP service basics (only used for phone identifiers)
    when(() => mockOtpService.hasVerificationId).thenReturn(false);
    when(() => mockOtpService.currentUserId).thenReturn(null);
    when(
      () => mockOtpService.sendOtp(phoneNumber: any(named: 'phoneNumber')),
    ).thenAnswer((_) async {});
  });

  /// Build OTP widget with GoRouter so context.go() and context.pushReplacement()
  /// don't throw in tests. Uses an email identifier by default to skip Firebase.
  Widget buildWidget({
    String identifier = 'user@example.com',
    OtpPurpose purpose = OtpPurpose.verification,
  }) {
    return ProviderScope(
      overrides: [
        ...commonWidgetTestOverrides(),
        authRepositoryProvider.overrideWithValue(mockAuthRepo),
        firebaseOtpServiceProvider.overrideWithValue(mockOtpService),
      ],
      child: MaterialApp.router(
        routerConfig: GoRouter(
          initialLocation: '/',
          routes: [
            GoRoute(
              path: '/',
              builder: (_, _) => OtpVerificationScreen(
                identifier: identifier,
                purpose: purpose,
              ),
            ),
            GoRoute(
              path: '/dashboard',
              builder: (_, _) => const Scaffold(body: Text('Dashboard Page')),
            ),
            GoRoute(
              path: '/settings/change-password',
              builder: (_, _) =>
                  const Scaffold(body: Text('Change Password Page')),
              redirect: (context, state) => null,
            ),
          ],
        ),
      ),
    );
  }

  group('OtpVerificationScreen - supplemental coverage', () {
    testWidgets('shows error when OTP has less than 4 digits', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      // Type only 2 digits in first 2 OTP fields
      final textFields = find.byType(TextField);
      await tester.enterText(textFields.at(0), '1');
      await tester.pump();
      await tester.enterText(textFields.at(1), '2');
      await tester.pump();

      // Tap the verify button (ElevatedButton with "Confirmer")
      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();

      expect(find.text('Veuillez saisir le code complet.'), findsOneWidget);
    });

    testWidgets('enters 6 digits → verifyOtp succeeds → navigates to dashboard', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      const fakeUser = User(
        id: 1,
        name: 'Test User',
        email: 'user@example.com',
      );
      when(
        () => mockAuthRepo.verifyOtp(
          any(),
          any(),
          firebaseUid: any(named: 'firebaseUid'),
        ),
      ).thenAnswer((_) async => fakeUser);

      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      // Type one digit per field — entering digit in last field triggers auto-submit
      final textFields = find.byType(TextField);
      for (int i = 0; i < 6; i++) {
        await tester.enterText(textFields.at(i), '${i + 1}');
        await tester.pump();
      }

      await tester.pumpAndSettle();

      // After navigation, Dashboard page should be visible
      expect(find.text('Dashboard Page'), findsOneWidget);
    });

    testWidgets('enters 6 digits → verifyOtp throws → shows error message', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      when(
        () => mockAuthRepo.verifyOtp(
          any(),
          any(),
          firebaseUid: any(named: 'firebaseUid'),
        ),
      ).thenThrow(Exception('Code invalide'));

      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      final textFields = find.byType(TextField);
      for (int i = 0; i < 6; i++) {
        await tester.enterText(textFields.at(i), '9');
        await tester.pump();
      }

      await tester.pumpAndSettle();

      expect(find.text('Code invalide'), findsOneWidget);
    });

    testWidgets(
      'passwordReset purpose: 6 digits → verifyResetOtp → navigates to change-password',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        when(
          () => mockAuthRepo.verifyResetOtp(any(), any()),
        ).thenAnswer((_) async => 'reset_token_abc');

        await tester.pumpWidget(buildWidget(purpose: OtpPurpose.passwordReset));
        await tester.pumpAndSettle();

        // Verify the reset UI shows correct icon/title cue
        expect(find.byIcon(Icons.lock_reset), findsOneWidget);

        final textFields = find.byType(TextField);
        for (int i = 0; i < 6; i++) {
          await tester.enterText(textFields.at(i), '5');
          await tester.pump();
        }

        await tester.pumpAndSettle();

        expect(find.text('Change Password Page'), findsOneWidget);
      },
    );

    testWidgets('resend OTP after cooldown expires', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      when(
        () => mockAuthRepo.sendOtp(any(), purpose: any(named: 'purpose')),
      ).thenAnswer((_) async => <String, dynamic>{});

      await tester.pumpWidget(buildWidget());
      await tester.pump(); // initial frame

      // Advance timer tick by tick to expire the 60-second cooldown
      for (int i = 0; i < 62; i++) {
        await tester.pump(const Duration(seconds: 1));
      }

      // 'Renvoyer le code' GestureDetector should now be visible
      expect(find.text('Renvoyer le code'), findsOneWidget);

      await tester.tap(find.text('Renvoyer le code'));
      await tester.pumpAndSettle();

      expect(find.text('Code renvoyé avec succès.'), findsOneWidget);
    });

    testWidgets('renders passwordReset purpose with correct title', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildWidget(purpose: OtpPurpose.passwordReset));
      await tester.pumpAndSettle();

      expect(find.text('Réinitialisation'), findsOneWidget);
      expect(find.text('Vérifier'), findsOneWidget);
    });

    testWidgets('verify button says Confirmer for verification purpose', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      expect(find.text('Vérification'), findsOneWidget);
      expect(find.text('Confirmer'), findsOneWidget);
    });
  });
}
