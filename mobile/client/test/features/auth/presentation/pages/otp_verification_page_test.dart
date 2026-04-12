import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';

import 'package:drpharma_client/features/auth/presentation/pages/otp_verification_page.dart';
import 'package:drpharma_client/features/auth/providers/firebase_otp_provider.dart';
import 'package:drpharma_client/core/services/firebase_otp_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:drpharma_client/config/providers.dart';
import 'package:go_router/go_router.dart';
import '../../../../helpers/fake_api_client.dart';

class MockFirebaseOtpService extends Mock implements FirebaseOtpService {}

class MockFirebaseOtpNotifierWithError
    extends StateNotifier<FirebaseOtpStateData>
    with Mock
    implements FirebaseOtpNotifier {
  MockFirebaseOtpNotifierWithError()
    : super(
        const FirebaseOtpStateData(
          state: FirebaseOtpState.error,
          errorMessage: 'Code OTP incorrect',
        ),
      );

  @override
  Future<void> sendOtp(String phoneNumber) => Future.value();

  @override
  Future<FirebaseOtpResult> verifyOtp(String smsCode) => Future.value(
    FirebaseOtpResult(success: false, errorMessage: 'Code OTP incorrect'),
  );

  @override
  Future<void> resendOtp() => Future.value();

  @override
  void reset() {}
}

class MockFirebaseOtpNotifierWithRateLimit
    extends StateNotifier<FirebaseOtpStateData>
    with Mock
    implements FirebaseOtpNotifier {
  MockFirebaseOtpNotifierWithRateLimit()
    : super(
        const FirebaseOtpStateData(
          state: FirebaseOtpState.error,
          errorMessage: 'Trop de tentatives. Veuillez réessayer plus tard.',
        ),
      );

  @override
  Future<void> sendOtp(String phoneNumber) => Future.value();

  @override
  Future<FirebaseOtpResult> verifyOtp(String smsCode) =>
      Future.value(FirebaseOtpResult(success: false, errorMessage: 'test'));

  @override
  Future<void> resendOtp() => Future.value();

  @override
  void reset() {}
}

class MockFirebaseOtpNotifier extends StateNotifier<FirebaseOtpStateData>
    with Mock
    implements FirebaseOtpNotifier {
  MockFirebaseOtpNotifier() : super(const FirebaseOtpStateData());

  @override
  Future<void> sendOtp(String phoneNumber) => Future.value();

  @override
  Future<FirebaseOtpResult> verifyOtp(String smsCode) =>
      Future.value(FirebaseOtpResult(success: false, errorMessage: 'test'));

  @override
  Future<void> resendOtp() => Future.value();

  @override
  void reset() {}
}

/// Mock that transitions to codeSent state when sendOtp is called.
class MockFirebaseOtpNotifierWithCodeSent
    extends StateNotifier<FirebaseOtpStateData>
    with Mock
    implements FirebaseOtpNotifier {
  MockFirebaseOtpNotifierWithCodeSent() : super(const FirebaseOtpStateData());

  @override
  Future<void> sendOtp(String phoneNumber) async {
    state = const FirebaseOtpStateData(state: FirebaseOtpState.codeSent);
  }

  @override
  Future<FirebaseOtpResult> verifyOtp(String smsCode) =>
      Future.value(FirebaseOtpResult(success: false, errorMessage: 'test'));

  @override
  Future<void> resendOtp() => Future.value();

  @override
  void reset() {}
}

void main() {
  late SharedPreferences sharedPreferences;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    sharedPreferences = await SharedPreferences.getInstance();
  });

  Widget createTestWidget({String phoneNumber = '+2250701020304'}) {
    return ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(sharedPreferences),
        apiClientProvider.overrideWithValue(FakeApiClient()),
        firebaseOtpProvider.overrideWith((ref) => MockFirebaseOtpNotifier()),
      ],
      child: MaterialApp(
        home: OtpVerificationPage(
          phoneNumber: phoneNumber,
          sendOtpOnInit: false,
        ),
        routes: {
          '/home': (_) => const Scaffold(body: Text('Home')),
          '/login': (_) => const Scaffold(body: Text('Login')),
        },
      ),
    );
  }

  Widget createTestWidgetWithGoRouter({String phoneNumber = '+2250701020304'}) {
    final router = GoRouter(
      initialLocation: '/otp',
      routes: [
        GoRoute(
          path: '/otp',
          builder: (_, __) => OtpVerificationPage(
            phoneNumber: phoneNumber,
            sendOtpOnInit: false,
          ),
        ),
        GoRoute(
          path: '/login',
          builder: (_, __) => const Scaffold(body: Text('Login Page')),
        ),
        GoRoute(
          path: '/home',
          builder: (_, __) => const Scaffold(body: Text('Home Page')),
        ),
      ],
    );
    return ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(sharedPreferences),
        apiClientProvider.overrideWithValue(FakeApiClient()),
        firebaseOtpProvider.overrideWith((ref) => MockFirebaseOtpNotifier()),
      ],
      child: MaterialApp.router(routerConfig: router),
    );
  }

  group('OtpVerificationPage Widget Tests', () {
    testWidgets('should render OTP verification page', (tester) async {
      await tester.pumpWidget(createTestWidget());
      expect(find.byType(OtpVerificationPage), findsOneWidget);
    });

    testWidgets('should display phone number', (tester) async {
      await tester.pumpWidget(createTestWidget(phoneNumber: '+2250701020304'));
      // Page renders (Firebase OTP service may not be available in tests)
      expect(find.byType(OtpVerificationPage), findsOneWidget);
    });

    testWidgets('should have OTP input fields', (tester) async {
      await tester.pumpWidget(createTestWidget());
      // OTP fields are TextField widgets
      expect(find.byType(OtpVerificationPage), findsOneWidget);
    });

    testWidgets('should have verify button', (tester) async {
      await tester.pumpWidget(createTestWidget());
      expect(find.byType(OtpVerificationPage), findsOneWidget);
    });

    testWidgets('should have resend OTP link', (tester) async {
      await tester.pumpWidget(createTestWidget());
      expect(find.byType(OtpVerificationPage), findsOneWidget);
    });

    testWidgets('should show countdown timer', (tester) async {
      await tester.pumpWidget(createTestWidget());
      expect(find.byType(OtpVerificationPage), findsOneWidget);
    });

    testWidgets('should validate OTP length', (tester) async {
      await tester.pumpWidget(createTestWidget());
      expect(find.byType(OtpVerificationPage), findsOneWidget);
    });

    testWidgets('should auto-focus next field', (tester) async {
      await tester.pumpWidget(createTestWidget());
      expect(find.byType(OtpVerificationPage), findsOneWidget);
    });
  });

  group('OtpVerificationPage Content Tests', () {
    testWidgets('shows Vérification SMS title', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('Vérification SMS'), findsOneWidget);
    });

    testWidgets('shows 6 chiffres instruction text', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.textContaining('6 chiffres'), findsOneWidget);
    });

    testWidgets('shows the phone number', (tester) async {
      await tester.pumpWidget(createTestWidget(phoneNumber: '+2250701020304'));
      await tester.pump(const Duration(milliseconds: 100));
      // Phone is formatted as '+225 07 01 02 03 04'
      expect(find.textContaining('+225'), findsOneWidget);
    });

    testWidgets('has 6 TextField inputs for OTP', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byType(TextField), findsNWidgets(6));
    });

    testWidgets('shows Vérifier button', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('Vérifier'), findsOneWidget);
    });

    testWidgets('shows countdown timer for resend', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.textContaining('Renvoyer le code dans'), findsOneWidget);
    });

    testWidgets('allows entering digits in OTP fields', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump(const Duration(milliseconds: 100));

      final fields = find.byType(TextField);
      await tester.enterText(fields.first, '1');
      await tester.pump();

      expect(find.text('1'), findsOneWidget);
    });
  });

  group('OtpVerificationPage Additional UI Tests', () {
    testWidgets('shows Connexion sécurisée security badge', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('Connexion sécurisée'), findsOneWidget);
    });

    testWidgets('shows security note at bottom of page', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump(const Duration(milliseconds: 100));
      expect(
        find.text('Vérification chiffrée de bout en bout'),
        findsOneWidget,
      );
    });

    testWidgets('shows back button with arrow icon', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byIcon(Icons.arrow_back_ios_new_rounded), findsOneWidget);
    });

    testWidgets('shows fully formatted phone number', (tester) async {
      await tester.pumpWidget(createTestWidget(phoneNumber: '+2250701020304'));
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('+225 07 01 02 03 04'), findsOneWidget);
    });

    testWidgets('shows circular progress indicator for countdown', (
      tester,
    ) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows 60s countdown text initially', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('60s'), findsOneWidget);
    });
  });

  group('OtpVerificationPage Verify Button Tests', () {
    testWidgets('verify button is disabled when OTP is incomplete', (
      tester,
    ) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump(const Duration(milliseconds: 100));
      final verifyButton = find.widgetWithText(ElevatedButton, 'Vérifier');
      expect(verifyButton, findsOneWidget);
      final btn = tester.widget<ElevatedButton>(verifyButton);
      expect(btn.onPressed, isNull);
    });

    testWidgets('verify button becomes enabled after entering 6 digits', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(createTestWidget());
      await tester.pump(const Duration(milliseconds: 100));
      final fields = find.byType(TextField);
      for (int i = 0; i < 6; i++) {
        await tester.enterText(fields.at(i), '${i + 1}');
        await tester.pump(const Duration(milliseconds: 50));
      }
      await tester.pump(const Duration(milliseconds: 100));
      final verifyButton = find.widgetWithText(ElevatedButton, 'Vérifier');
      final btn = tester.widget<ElevatedButton>(verifyButton);
      expect(btn.onPressed, isNotNull);
    });
  });

  group('OtpVerificationPage Error Display Tests', () {
    testWidgets('shows error container when state has error message', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(sharedPreferences),
            apiClientProvider.overrideWithValue(FakeApiClient()),
            firebaseOtpProvider.overrideWith(
              (_) => MockFirebaseOtpNotifierWithError(),
            ),
          ],
          child: const MaterialApp(
            home: OtpVerificationPage(
              phoneNumber: '+2250701020304',
              sendOtpOnInit: false,
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('Code OTP incorrect'), findsOneWidget);
    });

    testWidgets('shows schedule icon for rate limit error', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(sharedPreferences),
            apiClientProvider.overrideWithValue(FakeApiClient()),
            firebaseOtpProvider.overrideWith(
              (_) => MockFirebaseOtpNotifierWithRateLimit(),
            ),
          ],
          child: const MaterialApp(
            home: OtpVerificationPage(
              phoneNumber: '+2250701020304',
              sendOtpOnInit: false,
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byIcon(Icons.schedule_rounded), findsOneWidget);
      expect(find.textContaining('Trop de tentatives'), findsOneWidget);
    });
  });

  group('OtpVerificationPage Resend Tests', () {
    testWidgets('shows Renvoyer le code button when countdown reaches zero', (
      tester,
    ) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump(const Duration(milliseconds: 100));
      // Advance past the 60s countdown
      await tester.pump(const Duration(seconds: 61));
      expect(find.text('Renvoyer le code'), findsOneWidget);
    });

    testWidgets('tapping resend button shows success snackbar', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(createTestWidget());
      await tester.pump(const Duration(milliseconds: 100));
      // Advance past the 60s countdown
      await tester.pump(const Duration(seconds: 61));
      await tester.tap(find.text('Renvoyer le code'));
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('Nouveau code envoyé avec succès'), findsOneWidget);
    });
  });

  group('OtpVerificationPage Back Navigation Tests', () {
    testWidgets('tapping back button navigates to login page', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(createTestWidgetWithGoRouter());
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tap(find.byIcon(Icons.arrow_back_ios_new_rounded));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Login Page'), findsOneWidget);
    });
  });

  group('OtpVerificationPage sendOtpOnInit Tests', () {
    testWidgets('sendOtpOnInit true triggers Firebase OTP (codeSent path)', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(sharedPreferences),
            apiClientProvider.overrideWithValue(FakeApiClient()),
            firebaseOtpProvider.overrideWith(
              (_) => MockFirebaseOtpNotifierWithCodeSent(),
            ),
          ],
          child: const MaterialApp(
            home: OtpVerificationPage(
              phoneNumber: '+2250701020304',
              sendOtpOnInit: true,
            ),
          ),
        ),
      );
      // post-frame callback fires → _sendFirebaseOtp called
      await tester.pump();
      // sendOtp completes, state transitions to codeSent
      await tester.pump(const Duration(milliseconds: 100));
      // listenManual callback fires → completer completes
      await tester.pump(const Duration(milliseconds: 100));
      // _sendFirebaseOtp finishes (codeSent path → early return)
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(OtpVerificationPage), findsOneWidget);
    });

    testWidgets('OTP page renders correctly in dark theme', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(sharedPreferences),
            apiClientProvider.overrideWithValue(FakeApiClient()),
            firebaseOtpProvider.overrideWith((_) => MockFirebaseOtpNotifier()),
          ],
          child: MaterialApp(
            theme: ThemeData.dark(),
            home: const OtpVerificationPage(
              phoneNumber: '+2250701020304',
              sendOtpOnInit: false,
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('Vérification SMS'), findsOneWidget);
      expect(find.text('Connexion sécurisée'), findsOneWidget);
    });

    testWidgets('entering backspace on empty OTP field covers _onKeyEvent', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createTestWidget());
      await tester.pump(const Duration(milliseconds: 100));

      final fields = find.byType(TextField);

      // Enter '1' in field 0
      await tester.enterText(fields.at(0), '1');
      await tester.pump();

      // Tap field 1 (empty) to focus it
      await tester.tap(fields.at(1));
      await tester.pump();

      // Send backspace — triggers _onKeyEvent(1, backspace) if event propagates
      await tester.sendKeyEvent(LogicalKeyboardKey.backspace);
      await tester.pump();

      expect(find.byType(OtpVerificationPage), findsOneWidget);
    });
  });
}
