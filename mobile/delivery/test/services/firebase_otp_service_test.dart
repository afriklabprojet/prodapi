import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:courier/core/services/firebase_otp_service.dart';

class _MockFirebaseAuth extends Mock implements FirebaseAuth {}

class _MockUserCredential extends Mock implements UserCredential {}

class _MockUser extends Mock implements User {}

class _FakePhoneAuthCredential extends Fake implements PhoneAuthCredential {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    registerFallbackValue(_FakePhoneAuthCredential());
    registerFallbackValue(const Duration(seconds: 30));
  });

  group('FirebaseOtpState', () {
    test('has all expected values', () {
      expect(FirebaseOtpState.values.length, 6);
      expect(FirebaseOtpState.values, contains(FirebaseOtpState.initial));
      expect(FirebaseOtpState.values, contains(FirebaseOtpState.codeSent));
      expect(FirebaseOtpState.values, contains(FirebaseOtpState.verifying));
      expect(FirebaseOtpState.values, contains(FirebaseOtpState.verified));
      expect(FirebaseOtpState.values, contains(FirebaseOtpState.error));
      expect(FirebaseOtpState.values, contains(FirebaseOtpState.timeout));
    });
  });

  group('FirebaseOtpResult', () {
    test('success factory creates successful result', () {
      final result = FirebaseOtpResult.success(
        firebaseUid: 'uid123',
        phoneNumber: '+22507123456',
      );
      expect(result.success, true);
      expect(result.firebaseUid, 'uid123');
      expect(result.phoneNumber, '+22507123456');
      expect(result.errorMessage, isNull);
    });

    test('success factory with no params', () {
      final result = FirebaseOtpResult.success();
      expect(result.success, true);
      expect(result.firebaseUid, isNull);
      expect(result.phoneNumber, isNull);
    });

    test('error factory creates error result', () {
      final result = FirebaseOtpResult.error('Code invalide');
      expect(result.success, false);
      expect(result.errorMessage, 'Code invalide');
      expect(result.firebaseUid, isNull);
      expect(result.phoneNumber, isNull);
    });

    test('constructor with all fields', () {
      final result = FirebaseOtpResult(
        success: true,
        firebaseUid: 'uid',
        phoneNumber: '+225',
        errorMessage: null,
      );
      expect(result.success, true);
      expect(result.firebaseUid, 'uid');
    });
  });

  group('FirebaseOtpService - additional', () {
    test('FirebaseOtpResult error with empty message', () {
      final result = FirebaseOtpResult.error('');
      expect(result.success, isFalse);
      expect(result.errorMessage, '');
    });

    test('FirebaseOtpResult success with firebaseUid only', () {
      final result = FirebaseOtpResult.success(firebaseUid: 'abc');
      expect(result.success, isTrue);
      expect(result.firebaseUid, 'abc');
      expect(result.phoneNumber, isNull);
    });

    test('FirebaseOtpState indices', () {
      expect(FirebaseOtpState.initial.index, 0);
      expect(FirebaseOtpState.codeSent.index, 1);
      expect(FirebaseOtpState.verifying.index, 2);
      expect(FirebaseOtpState.verified.index, 3);
      expect(FirebaseOtpState.error.index, 4);
      expect(FirebaseOtpState.timeout.index, 5);
    });
  });

  group('FirebaseOtpService', () {
    test('starts with no verification id and reads current user id', () {
      final auth = _MockFirebaseAuth();
      final user = _MockUser();
      when(() => auth.currentUser).thenReturn(user);
      when(() => user.uid).thenReturn('uid-current');

      final service = FirebaseOtpService(auth: auth);

      expect(service.hasVerificationId, isFalse);
      expect(service.currentUserId, 'uid-current');
    });

    test('sendOtp normalizes the phone number and emits codeSent', () async {
      final auth = _MockFirebaseAuth();
      final states = <FirebaseOtpState>[];
      String? sentPhone;

      when(
        () => auth.verifyPhoneNumber(
          phoneNumber: any(named: 'phoneNumber'),
          timeout: any(named: 'timeout'),
          codeSent: any(named: 'codeSent'),
          verificationCompleted: any(named: 'verificationCompleted'),
          verificationFailed: any(named: 'verificationFailed'),
          codeAutoRetrievalTimeout: any(named: 'codeAutoRetrievalTimeout'),
          forceResendingToken: any(named: 'forceResendingToken'),
        ),
      ).thenAnswer((invocation) async {
        sentPhone = invocation.namedArguments[#phoneNumber] as String;
        final codeSent = invocation.namedArguments[#codeSent]
            as void Function(String, int?);
        codeSent('verification-123', 42);
      });

      final service = FirebaseOtpService(auth: auth)
        ..onStateChanged = (state, {error}) => states.add(state);

      await service.sendOtp(phoneNumber: '07 12 34 56 78');

      expect(sentPhone, '+2250712345678');
      expect(states, [FirebaseOtpState.initial, FirebaseOtpState.codeSent]);
      expect(service.hasVerificationId, isTrue);
    });

    test('sendOtp handles verificationCompleted and auto-retrieved code', () async {
      final auth = _MockFirebaseAuth();
      final user = _MockUser();
      final credentialResult = _MockUserCredential();
      final states = <FirebaseOtpState>[];
      String? autoCode;

      when(() => auth.signInWithCredential(any())).thenAnswer((_) async => credentialResult);
      when(() => credentialResult.user).thenReturn(user);
      when(() => user.uid).thenReturn('uid-auto');
      when(() => user.phoneNumber).thenReturn('+2250712345678');
      when(
        () => auth.verifyPhoneNumber(
          phoneNumber: any(named: 'phoneNumber'),
          timeout: any(named: 'timeout'),
          codeSent: any(named: 'codeSent'),
          verificationCompleted: any(named: 'verificationCompleted'),
          verificationFailed: any(named: 'verificationFailed'),
          codeAutoRetrievalTimeout: any(named: 'codeAutoRetrievalTimeout'),
          forceResendingToken: any(named: 'forceResendingToken'),
        ),
      ).thenAnswer((invocation) async {
        final verificationCompleted = invocation.namedArguments[#verificationCompleted] as dynamic;
        final credential = PhoneAuthProvider.credential(
          verificationId: 'auto-verification',
          smsCode: '123456',
        );
        await verificationCompleted(credential);
      });

      final service = FirebaseOtpService(auth: auth)
        ..onStateChanged = (state, {error}) {
          states.add(state);
        }
        ..onSmsCodeAutoRetrieved = (code) {
          autoCode = code;
        };

      await service.sendOtp(phoneNumber: '0712345678');

      expect(autoCode, '123456');
      expect(states, [FirebaseOtpState.initial, FirebaseOtpState.verified]);
    });

    test('sendOtp maps Firebase failures to a friendly error message', () async {
      final auth = _MockFirebaseAuth();
      final states = <FirebaseOtpState>[];
      String? lastError;

      when(
        () => auth.verifyPhoneNumber(
          phoneNumber: any(named: 'phoneNumber'),
          timeout: any(named: 'timeout'),
          codeSent: any(named: 'codeSent'),
          verificationCompleted: any(named: 'verificationCompleted'),
          verificationFailed: any(named: 'verificationFailed'),
          codeAutoRetrievalTimeout: any(named: 'codeAutoRetrievalTimeout'),
          forceResendingToken: any(named: 'forceResendingToken'),
        ),
      ).thenAnswer((invocation) async {
        final verificationFailed = invocation.namedArguments[#verificationFailed]
            as void Function(FirebaseAuthException);
        verificationFailed(
          FirebaseAuthException(
            code: 'invalid-phone-number',
            message: 'bad phone',
          ),
        );
      });

      final service = FirebaseOtpService(auth: auth)
        ..onStateChanged = (state, {error}) {
          states.add(state);
          lastError = error;
        };

      await service.sendOtp(phoneNumber: '123');

      expect(states.last, FirebaseOtpState.error);
      expect(
        lastError,
        'Numéro de téléphone invalide. Vérifiez le format.',
      );
    });

    test('sendOtp stores verification id on timeout', () async {
      final auth = _MockFirebaseAuth();
      final states = <FirebaseOtpState>[];

      when(
        () => auth.verifyPhoneNumber(
          phoneNumber: any(named: 'phoneNumber'),
          timeout: any(named: 'timeout'),
          codeSent: any(named: 'codeSent'),
          verificationCompleted: any(named: 'verificationCompleted'),
          verificationFailed: any(named: 'verificationFailed'),
          codeAutoRetrievalTimeout: any(named: 'codeAutoRetrievalTimeout'),
          forceResendingToken: any(named: 'forceResendingToken'),
        ),
      ).thenAnswer((invocation) async {
        final timeoutCallback = invocation.namedArguments[#codeAutoRetrievalTimeout]
            as void Function(String);
        timeoutCallback('timeout-id');
      });

      final service = FirebaseOtpService(auth: auth)
        ..onStateChanged = (state, {error}) => states.add(state);

      await service.sendOtp(phoneNumber: '0712345678');

      expect(states.last, FirebaseOtpState.timeout);
      expect(service.hasVerificationId, isTrue);
    });

    test('verifyOtp returns error when no code was sent', () async {
      final service = FirebaseOtpService(auth: _MockFirebaseAuth());

      final result = await service.verifyOtp('123456');

      expect(result.success, isFalse);
      expect(result.errorMessage, contains('Aucun code'));
    });

    test('verifyOtp signs in and returns a success result', () async {
      final auth = _MockFirebaseAuth();
      final user = _MockUser();
      final credentialResult = _MockUserCredential();
      final states = <FirebaseOtpState>[];

      when(() => auth.signInWithCredential(any())).thenAnswer((_) async => credentialResult);
      when(() => credentialResult.user).thenReturn(user);
      when(() => user.uid).thenReturn('uid-verified');
      when(() => user.phoneNumber).thenReturn('+2250712345678');
      when(
        () => auth.verifyPhoneNumber(
          phoneNumber: any(named: 'phoneNumber'),
          timeout: any(named: 'timeout'),
          codeSent: any(named: 'codeSent'),
          verificationCompleted: any(named: 'verificationCompleted'),
          verificationFailed: any(named: 'verificationFailed'),
          codeAutoRetrievalTimeout: any(named: 'codeAutoRetrievalTimeout'),
          forceResendingToken: any(named: 'forceResendingToken'),
        ),
      ).thenAnswer((invocation) async {
        final codeSent = invocation.namedArguments[#codeSent]
            as void Function(String, int?);
        codeSent('manual-verification-id', 7);
      });

      final service = FirebaseOtpService(auth: auth)
        ..onStateChanged = (state, {error}) => states.add(state);

      await service.sendOtp(phoneNumber: '0712345678');
      final result = await service.verifyOtp('654321');

      expect(result.success, isTrue);
      expect(result.firebaseUid, 'uid-verified');
      expect(result.phoneNumber, '+2250712345678');
      expect(
        states,
        containsAllInOrder([
          FirebaseOtpState.initial,
          FirebaseOtpState.codeSent,
          FirebaseOtpState.verifying,
          FirebaseOtpState.verified,
        ]),
      );
    });

    test('verifyOtp maps invalid verification code to friendly message', () async {
      final auth = _MockFirebaseAuth();
      String? lastError;

      when(
        () => auth.verifyPhoneNumber(
          phoneNumber: any(named: 'phoneNumber'),
          timeout: any(named: 'timeout'),
          codeSent: any(named: 'codeSent'),
          verificationCompleted: any(named: 'verificationCompleted'),
          verificationFailed: any(named: 'verificationFailed'),
          codeAutoRetrievalTimeout: any(named: 'codeAutoRetrievalTimeout'),
          forceResendingToken: any(named: 'forceResendingToken'),
        ),
      ).thenAnswer((invocation) async {
        final codeSent = invocation.namedArguments[#codeSent]
            as void Function(String, int?);
        codeSent('bad-code-id', null);
      });
      when(() => auth.signInWithCredential(any())).thenThrow(
        FirebaseAuthException(
          code: 'invalid-verification-code',
          message: 'wrong code',
        ),
      );

      final service = FirebaseOtpService(auth: auth)
        ..onStateChanged = (state, {error}) => lastError = error;

      await service.sendOtp(phoneNumber: '0712345678');
      final result = await service.verifyOtp('000000');

      expect(result.success, isFalse);
      expect(result.errorMessage, 'Code invalide. Vérifiez et réessayez.');
      expect(lastError, 'Code invalide. Vérifiez et réessayez.');
    });

    test('resendOtp reuses sendOtp flow and reset clears internal state', () async {
      final auth = _MockFirebaseAuth();
      final states = <FirebaseOtpState>[];

      when(
        () => auth.verifyPhoneNumber(
          phoneNumber: any(named: 'phoneNumber'),
          timeout: any(named: 'timeout'),
          codeSent: any(named: 'codeSent'),
          verificationCompleted: any(named: 'verificationCompleted'),
          verificationFailed: any(named: 'verificationFailed'),
          codeAutoRetrievalTimeout: any(named: 'codeAutoRetrievalTimeout'),
          forceResendingToken: any(named: 'forceResendingToken'),
        ),
      ).thenAnswer((invocation) async {
        final codeSent = invocation.namedArguments[#codeSent]
            as void Function(String, int?);
        codeSent('resend-id', 11);
      });

      final service = FirebaseOtpService(auth: auth)
        ..onStateChanged = (state, {error}) {
          states.add(state);
        }
        ..onSmsCodeAutoRetrieved = (_) {
          // no-op for reset coverage
        };

      await service.resendOtp(
        phoneNumber: '07 12 34 56 78',
        timeout: const Duration(seconds: 30),
      );

      expect(states, [FirebaseOtpState.initial, FirebaseOtpState.codeSent]);
      expect(service.hasVerificationId, isTrue);

      service.reset();

      expect(service.hasVerificationId, isFalse);
      expect(service.onStateChanged, isNull);
      expect(service.onSmsCodeAutoRetrieved, isNull);
    });

    test('provider can be overridden with a FirebaseOtpService instance', () {
      final mockedService = FirebaseOtpService(auth: _MockFirebaseAuth());
      final container = ProviderContainer(
        overrides: [
          firebaseOtpServiceProvider.overrideWithValue(mockedService),
        ],
      );
      addTearDown(container.dispose);

      expect(container.read(firebaseOtpServiceProvider), same(mockedService));
    });
  });
}
