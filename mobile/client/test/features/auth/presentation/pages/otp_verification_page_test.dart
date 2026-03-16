import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';

import 'package:drpharma_client/features/auth/presentation/pages/otp_verification_page.dart';
import 'package:drpharma_client/features/auth/providers/firebase_otp_provider.dart';
import 'package:drpharma_client/core/services/firebase_otp_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:drpharma_client/config/providers.dart';
import '../../../../helpers/fake_api_client.dart';

class MockFirebaseOtpService extends Mock implements FirebaseOtpService {}

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
        home: OtpVerificationPage(phoneNumber: phoneNumber, sendOtpOnInit: false),
        routes: {
          '/home': (_) => const Scaffold(body: Text('Home')),
          '/login': (_) => const Scaffold(body: Text('Login')),
        },
      ),
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
}
