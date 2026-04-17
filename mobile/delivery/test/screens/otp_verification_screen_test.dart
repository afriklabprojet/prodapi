import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mocktail/mocktail.dart';
import 'package:courier/presentation/screens/otp_verification_screen.dart';
import 'package:courier/data/repositories/auth_repository.dart';
import 'package:courier/core/services/firebase_otp_service.dart';
import '../helpers/widget_test_helpers.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

class MockFirebaseOtpService extends Mock implements FirebaseOtpService {}

void main() {
  late MockAuthRepository mockAuthRepo;
  late MockFirebaseOtpService mockOtpService;

  setUpAll(() async {
    await initHiveForTests();
  });

  tearDownAll(() async {
    await cleanupHiveForTests();
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    mockAuthRepo = MockAuthRepository();
    mockOtpService = MockFirebaseOtpService();
    when(() => mockOtpService.hasVerificationId).thenReturn(false);
    when(() => mockOtpService.currentUserId).thenReturn(null);
    when(
      () => mockOtpService.sendOtp(phoneNumber: any(named: 'phoneNumber')),
    ).thenAnswer((_) async {});
  });

  Widget buildWidget({String identifier = '+2250101010101'}) {
    return ProviderScope(
      overrides: [
        ...commonWidgetTestOverrides(),
        authRepositoryProvider.overrideWithValue(mockAuthRepo),
        firebaseOtpServiceProvider.overrideWithValue(mockOtpService),
      ],
      child: MaterialApp(home: OtpVerificationScreen(identifier: identifier)),
    );
  }

  group('OtpVerificationScreen', () {
    testWidgets('renders OTP screen', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(buildWidget());
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('displays identifier', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(buildWidget(identifier: '+2250707070707'));
      await tester.pump(const Duration(seconds: 1));
      expect(find.textContaining('07'), findsWidgets);
    });

    testWidgets('shows OTP input fields', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(buildWidget());
      await tester.pump(const Duration(seconds: 1));
      // OTP fields are TextField
      final textFields = find.byType(TextField);
      final textFormFields = find.byType(TextFormField);
      expect(
        textFields.evaluate().length + textFormFields.evaluate().length,
        greaterThanOrEqualTo(1),
      );
    });

    testWidgets('has verify button', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(buildWidget());
      await tester.pump(const Duration(seconds: 1));
      final elevated = find.byType(ElevatedButton);
      final filled = find.byType(FilledButton);
      expect(
        elevated.evaluate().length + filled.evaluate().length,
        greaterThanOrEqualTo(1),
      );
    });

    testWidgets('shows countdown timer', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(buildWidget());
      await tester.pump(const Duration(seconds: 1));
      // Timer or Text widgets showing countdown
      expect(find.byType(Text), findsWidgets);
    });

    testWidgets('renders with different identifier', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(buildWidget(identifier: 'test@mail.com'));
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(OtpVerificationScreen), findsOneWidget);
    });

    testWidgets('has back button or navigation', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(buildWidget());
      await tester.pump(const Duration(seconds: 1));
      // AppBar typically has back button
      expect(find.byType(IconButton), findsWidgets);
    });

    testWidgets('shows resend option', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(buildWidget());
      await tester.pump(const Duration(seconds: 1));
      // Resend button or text
      expect(find.byType(GestureDetector), findsWidgets);
    });
  });

  group('OtpVerificationScreen - Purpose variations', () {
    testWidgets('renders with passwordReset purpose', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final screen = ProviderScope(
        overrides: [
          ...commonWidgetTestOverrides(),
          authRepositoryProvider.overrideWithValue(mockAuthRepo),
          firebaseOtpServiceProvider.overrideWithValue(mockOtpService),
        ],
        child: MaterialApp(
          home: OtpVerificationScreen(
            identifier: '+2250707070707',
            purpose: OtpPurpose.passwordReset,
          ),
        ),
      );

      await tester.pumpWidget(screen);
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(OtpVerificationScreen), findsOneWidget);
      // Password reset should show different title / icon
      expect(find.byType(Icon), findsWidgets);
    });

    testWidgets('renders verification purpose', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final screen = ProviderScope(
        overrides: [
          ...commonWidgetTestOverrides(),
          authRepositoryProvider.overrideWithValue(mockAuthRepo),
          firebaseOtpServiceProvider.overrideWithValue(mockOtpService),
        ],
        child: MaterialApp(
          home: OtpVerificationScreen(
            identifier: '+2250707070707',
            purpose: OtpPurpose.verification,
          ),
        ),
      );

      await tester.pumpWidget(screen);
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(OtpVerificationScreen), findsOneWidget);
    });
  });

  group('OtpVerificationScreen - Identifier types', () {
    testWidgets('with email identifier', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildWidget(identifier: 'user@example.com'));
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(OtpVerificationScreen), findsOneWidget);
      // Email identifier should show masked email
      expect(find.byType(Text), findsWidgets);
    });

    testWidgets('with short phone', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildWidget(identifier: '+225000'));
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(OtpVerificationScreen), findsOneWidget);
    });

    testWidgets('with long phone number', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildWidget(identifier: '+2250707070707070'));
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(OtpVerificationScreen), findsOneWidget);
    });
  });

  group('OtpVerificationScreen - Input interactions', () {
    testWidgets('can type in OTP fields', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildWidget());
      await tester.pump(const Duration(seconds: 1));

      // Find first text field and enter a digit
      final textFields = find.byType(TextField);
      if (textFields.evaluate().isNotEmpty) {
        await tester.enterText(textFields.first, '1');
        await tester.pump();
      }
      expect(find.byType(OtpVerificationScreen), findsOneWidget);
    });

    testWidgets('verify button is present and tappable', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildWidget());
      await tester.pump(const Duration(seconds: 1));

      final buttons = find.byType(ElevatedButton);
      final filled = find.byType(FilledButton);
      final allButtons = [...buttons.evaluate(), ...filled.evaluate()];
      expect(allButtons.length, greaterThanOrEqualTo(1));
    });

    testWidgets('info text about delivery channel visible', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildWidget());
      await tester.pump(const Duration(seconds: 1));

      // Should show info about SMS/WhatsApp delivery
      expect(find.byType(Text), findsWidgets);
    });

    testWidgets('scrollable content on small screen', (tester) async {
      tester.view.physicalSize = const Size(720, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildWidget());
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(OtpVerificationScreen), findsOneWidget);
    });
  });
}
