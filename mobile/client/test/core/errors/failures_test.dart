import 'package:flutter_test/flutter_test.dart';
import 'package:drpharma_client/core/errors/failures.dart';
import 'package:drpharma_client/core/errors/auth_failures.dart';
import 'package:drpharma_client/core/errors/cart_failures.dart';

void main() {
  // ────────────────────────────────────────────────────────────────────────────
  // failures.dart
  // ────────────────────────────────────────────────────────────────────────────
  group('ServerFailure', () {
    test('creates with message and optional statusCode/responseData', () {
      const f = ServerFailure(message: 'Server error', statusCode: 500);
      expect(f.message, 'Server error');
      expect(f.statusCode, 500);
      expect(f.responseData, isNull);
    });

    test('props includes message and statusCode', () {
      const f = ServerFailure(message: 'err', statusCode: 404);
      expect(f.props, ['err', 404]);
    });

    test('two instances with same data are equal', () {
      const a = ServerFailure(message: 'err', statusCode: 500);
      const b = ServerFailure(message: 'err', statusCode: 500);
      expect(a, b);
    });

    test('supports responseData', () {
      const f = ServerFailure(
        message: 'Payment in progress',
        statusCode: 409,
        responseData: {'redirect_url': 'https://pay.example.com'},
      );
      expect(f.responseData!['redirect_url'], 'https://pay.example.com');
    });
  });

  group('NetworkFailure', () {
    test('has default message', () {
      const f = NetworkFailure();
      expect(f.message, 'Erreur de connexion réseau');
    });

    test('accepts custom message', () {
      const f = NetworkFailure(message: 'No internet');
      expect(f.message, 'No internet');
    });

    test('two identical instances are equal', () {
      const a = NetworkFailure();
      const b = NetworkFailure();
      expect(a, b);
    });
  });

  group('CacheFailure', () {
    test('has default message', () {
      const f = CacheFailure();
      expect(f.message, 'Erreur de cache');
    });
  });

  group('ValidationFailure', () {
    test('creates with message and errors map', () {
      const f = ValidationFailure(
        message: 'Validation failed',
        errors: {
          'email': ['Email invalide'],
        },
      );
      expect(f.message, 'Validation failed');
      expect(f.errors['email'], ['Email invalide']);
    });

    test('props includes message and errors', () {
      const f = ValidationFailure(
        message: 'err',
        errors: {
          'field': ['required'],
        },
      );
      expect(f.props, contains('err'));
    });

    test('defaults to empty errors map', () {
      const f = ValidationFailure(message: 'err');
      expect(f.errors, isEmpty);
    });
  });

  group('UnauthorizedFailure', () {
    test('has default message', () {
      const f = UnauthorizedFailure();
      expect(f.message, contains('reconnecter'));
    });
  });

  group('UnknownFailure', () {
    test('has default message', () {
      const f = UnknownFailure();
      expect(f.message, 'Erreur inattendue');
    });
  });

  // ────────────────────────────────────────────────────────────────────────────
  // auth_failures.dart
  // ────────────────────────────────────────────────────────────────────────────
  group('InvalidCredentialsFailure', () {
    test('has default message', () {
      const f = InvalidCredentialsFailure();
      expect(f.message, contains('Identifiants'));
    });
  });

  group('AccountNotFoundFailure', () {
    test('has default message', () {
      const f = AccountNotFoundFailure();
      expect(f.message, contains('compte'));
    });
  });

  group('AccountLockedFailure', () {
    test('has default message and optional lockDuration', () {
      const f = AccountLockedFailure(lockDuration: Duration(minutes: 15));
      expect(f.message, contains('bloqué'));
      expect(f.lockDuration, const Duration(minutes: 15));
    });

    test('props includes lockDuration', () {
      const f = AccountLockedFailure(lockDuration: Duration(minutes: 5));
      expect(f.props, contains(const Duration(minutes: 5)));
    });
  });

  group('InvalidOtpFailure', () {
    test('has default message and optional attemptsRemaining', () {
      const f = InvalidOtpFailure(attemptsRemaining: 2);
      expect(f.message, contains('Code'));
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
      expect(f.message, contains('demandes'));
    });

    test('accepts retryAfter', () {
      const f = TooManyOtpAttemptsFailure(retryAfter: Duration(minutes: 10));
      expect(f.retryAfter, const Duration(minutes: 10));
    });
  });

  group('OtpSendFailure', () {
    test('has default message and reason', () {
      const f = OtpSendFailure();
      expect(f.message, contains('envoyer'));
      expect(f.reason, OtpSendError.unknown);
    });

    test('has all OtpSendError values', () {
      expect(OtpSendError.values.length, 4);
      expect(OtpSendError.values, contains(OtpSendError.invalidPhoneNumber));
      expect(OtpSendError.values, contains(OtpSendError.quotaExceeded));
      expect(OtpSendError.values, contains(OtpSendError.serviceUnavailable));
    });

    test('props includes reason', () {
      const f = OtpSendFailure(reason: OtpSendError.quotaExceeded);
      expect(f.props, contains(OtpSendError.quotaExceeded));
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
      expect(f.message, contains('invalide'));
    });
  });

  group('RefreshTokenExpiredFailure', () {
    test('has default message', () {
      const f = RefreshTokenExpiredFailure();
      expect(f.message, contains('reconnect'));
    });
  });

  group('PhoneNotVerifiedFailure', () {
    test('holds phone number', () {
      const f = PhoneNotVerifiedFailure(phone: '+2250700000001');
      expect(f.phone, '+2250700000001');
      expect(f.props, contains('+2250700000001'));
    });
  });

  group('EmailAlreadyExistsFailure', () {
    test('has default message', () {
      const f = EmailAlreadyExistsFailure();
      expect(f.message, contains('email'));
    });
  });

  group('PhoneAlreadyExistsFailure', () {
    test('has default message', () {
      const f = PhoneAlreadyExistsFailure();
      expect(f.message, contains('téléphone'));
    });
  });

  // ────────────────────────────────────────────────────────────────────────────
  // cart_failures.dart
  // ────────────────────────────────────────────────────────────────────────────
  group('ProductUnavailableFailure', () {
    test('message includes product name', () {
      const f = ProductUnavailableFailure(
        productId: 1,
        productName: 'Doliprane',
      );
      expect(f.message, contains('Doliprane'));
      expect(f.productId, 1);
    });

    test('props includes productId and productName', () {
      const f = ProductUnavailableFailure(productId: 1, productName: 'X');
      expect(f.props, contains(1));
      expect(f.props, contains('X'));
    });
  });

  group('InsufficientStockFailure', () {
    test('message includes quantities', () {
      const f = InsufficientStockFailure(
        productId: 1,
        requestedQuantity: 5,
        availableStock: 2,
      );
      expect(f.message, contains('5'));
      expect(f.message, contains('2'));
    });
  });

  group('DifferentPharmacyFailure', () {
    test('message includes pharmacy names', () {
      const f = DifferentPharmacyFailure(
        currentPharmacyId: 1,
        currentPharmacyName: 'Pharmacie A',
        newPharmacyId: 2,
        newPharmacyName: 'Pharmacie B',
      );
      expect(f.message, contains('Pharmacie A'));
    });
  });

  group('ItemNotFoundFailure', () {
    test('holds productId', () {
      const f = ItemNotFoundFailure(productId: 42);
      expect(f.productId, 42);
    });
  });

  group('InvalidQuantityFailure', () {
    test('message includes quantity', () {
      const f = InvalidQuantityFailure(quantity: -1);
      expect(f.message, contains('-1'));
    });
  });

  group('CartPersistenceFailure', () {
    test('message includes operation', () {
      const f = CartPersistenceFailure(operation: 'save');
      expect(f.message, contains('save'));
    });
  });

  group('CartRestoreFailure', () {
    test('has default message', () {
      const f = CartRestoreFailure();
      expect(f.message, contains('restaurer'));
    });
  });

  group('CartSyncFailure', () {
    test('uses reason in message when provided', () {
      const f = CartSyncFailure(reason: 'Network error');
      expect(f.message, contains('Network error'));
    });

    test('uses default message when no reason', () {
      const f = CartSyncFailure();
      expect(f.message, contains('synchronisation'));
    });
  });

  group('CartConflictFailure', () {
    test('message includes item counts', () {
      const f = CartConflictFailure(localItemCount: 3, serverItemCount: 5);
      expect(f.message, contains('3'));
      expect(f.message, contains('5'));
    });
  });

  group('CartLimitReachedFailure', () {
    test('message includes max items', () {
      const f = CartLimitReachedFailure(maxItems: 50, currentItems: 50);
      expect(f.message, contains('50'));
    });
  });

  group('CartExpiredFailure', () {
    test('message mentions expiry', () {
      const f = CartExpiredFailure(age: Duration(hours: 48));
      expect(f.message, contains('expiré'));
    });
  });

  group('ProductDiscontinuedFailure', () {
    test('message includes product name', () {
      const f = ProductDiscontinuedFailure(
        productId: 1,
        productName: 'Aspirine',
      );
      expect(f.message, contains('Aspirine'));
    });
  });

  group('PriceChangedFailure', () {
    test('message includes old and new prices', () {
      final f = PriceChangedFailure(
        productId: 1,
        oldPrice: 1000,
        newPrice: 1200,
      );
      expect(f.message, contains('1000'));
      expect(f.message, contains('1200'));
    });
  });
}
