import 'package:flutter_test/flutter_test.dart';
import 'package:drpharma_client/core/errors/auth_failures.dart';
import 'package:drpharma_client/core/errors/failures.dart';

void main() {
  group('InvalidCredentialsFailure', () {
    test('is a Failure', () {
      const f = InvalidCredentialsFailure();
      expect(f, isA<Failure>());
    });

    test('has default message', () {
      const f = InvalidCredentialsFailure();
      expect(f.message, contains('Identifiants incorrects'));
    });

    test('accepts custom message', () {
      const f = InvalidCredentialsFailure(message: 'Mauvais mot de passe');
      expect(f.message, 'Mauvais mot de passe');
    });
  });

  group('AccountNotFoundFailure', () {
    test('has default message', () {
      const f = AccountNotFoundFailure();
      expect(f.message, contains('Aucun compte'));
    });
  });

  group('AccountLockedFailure', () {
    test('has default message', () {
      const f = AccountLockedFailure();
      expect(f.message, contains('bloqué'));
    });

    test('stores lockDuration', () {
      const d = Duration(minutes: 15);
      const f = AccountLockedFailure(lockDuration: d);
      expect(f.lockDuration, d);
    });

    test('props includes lockDuration', () {
      const f = AccountLockedFailure(lockDuration: Duration(minutes: 5));
      expect(f.props, contains(const Duration(minutes: 5)));
    });
  });

  group('InvalidOtpFailure', () {
    test('has default message', () {
      const f = InvalidOtpFailure();
      expect(f.message, contains('Code incorrect'));
    });

    test('stores attemptsRemaining', () {
      const f = InvalidOtpFailure(attemptsRemaining: 2);
      expect(f.attemptsRemaining, 2);
    });

    test('props includes attemptsRemaining', () {
      const f = InvalidOtpFailure(attemptsRemaining: 1);
      expect(f.props, contains(1));
    });
  });

  group('ExpiredOtpFailure', () {
    test('has default message', () {
      const f = ExpiredOtpFailure();
      expect(f.message, contains('expiré'));
    });
  });

  group('TooManyOtpAttemptsFailure', () {
    test('has default message', () {
      const f = TooManyOtpAttemptsFailure();
      expect(f.message, contains('trop de demandes'));
    });

    test('stores retryAfter', () {
      const d = Duration(minutes: 10);
      const f = TooManyOtpAttemptsFailure(retryAfter: d);
      expect(f.retryAfter, d);
    });
  });

  group('OtpSendFailure', () {
    test('has default message and reason', () {
      const f = OtpSendFailure();
      expect(f.message, contains('envoyer'));
      expect(f.reason, OtpSendError.unknown);
    });

    test('stores reason', () {
      const f = OtpSendFailure(reason: OtpSendError.invalidPhoneNumber);
      expect(f.reason, OtpSendError.invalidPhoneNumber);
    });

    test('OtpSendError has all expected values', () {
      expect(OtpSendError.values, contains(OtpSendError.invalidPhoneNumber));
      expect(OtpSendError.values, contains(OtpSendError.quotaExceeded));
      expect(OtpSendError.values, contains(OtpSendError.serviceUnavailable));
      expect(OtpSendError.values, contains(OtpSendError.unknown));
    });
  });

  group('SessionExpiredFailure', () {
    test('has default message', () {
      const f = SessionExpiredFailure();
      expect(f.message, contains('session'));
    });
  });

  group('InvalidTokenFailure', () {
    test('has default message', () {
      const f = InvalidTokenFailure();
      expect(f.message, contains('Session invalide'));
    });
  });

  group('RefreshTokenExpiredFailure', () {
    test('has default message', () {
      const f = RefreshTokenExpiredFailure();
      expect(f.message, contains('Session prolongée expirée'));
    });
  });

  group('PhoneNotVerifiedFailure', () {
    test('stores phone number', () {
      const f = PhoneNotVerifiedFailure(phone: '0700000001');
      expect(f.phone, '0700000001');
    });

    test('props includes phone', () {
      const f = PhoneNotVerifiedFailure(phone: '+22500000000');
      expect(f.props, contains('+22500000000'));
    });
  });

  group('EmailAlreadyExistsFailure', () {
    test('has default message', () {
      const f = EmailAlreadyExistsFailure();
      expect(f.message, contains('déjà utilisée'));
    });
  });

  group('PhoneAlreadyExistsFailure', () {
    test('has default message', () {
      const f = PhoneAlreadyExistsFailure();
      expect(f.message, contains('déjà utilisé'));
    });
  });
}
