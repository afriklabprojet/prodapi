import 'package:flutter_test/flutter_test.dart';
import 'package:drpharma_pharmacy/core/errors/failure.dart';

void main() {
  group('ServerFailure', () {
    test('should create failure with message', () {
      const failure = ServerFailure('Server error occurred');

      expect(failure.message, 'Server error occurred');
    });

    test('should have correct toString representation', () {
      const failure = ServerFailure('Internal server error');

      expect(failure.toString(), 'Internal server error');
    });

    test('should be instance of Failure', () {
      const failure = ServerFailure('Test');

      expect(failure, isA<Failure>());
    });
  });

  group('CacheFailure', () {
    test('should create failure with message', () {
      const failure = CacheFailure('Cache miss');

      expect(failure.message, 'Cache miss');
    });

    test('should have correct toString representation', () {
      const failure = CacheFailure('No cached data found');

      expect(failure.toString(), 'No cached data found');
    });

    test('should be instance of Failure', () {
      const failure = CacheFailure('Test');

      expect(failure, isA<Failure>());
    });
  });

  group('NetworkFailure', () {
    test('should create failure with message', () {
      const failure = NetworkFailure('No internet connection');

      expect(failure.message, 'No internet connection');
    });

    test('should have correct toString representation', () {
      const failure = NetworkFailure('Connection timeout');

      expect(failure.toString(), 'Connection timeout');
    });

    test('should be instance of Failure', () {
      const failure = NetworkFailure('Test');

      expect(failure, isA<Failure>());
    });
  });

  group('UnauthorizedFailure', () {
    test('should create failure with message', () {
      const failure = UnauthorizedFailure('Invalid token');

      expect(failure.message, 'Invalid token');
    });

    test('should have correct toString representation', () {
      const failure = UnauthorizedFailure('Session expired');

      expect(failure.toString(), 'Session expired');
    });

    test('should be instance of Failure', () {
      const failure = UnauthorizedFailure('Test');

      expect(failure, isA<Failure>());
    });
  });

  group('ForbiddenFailure', () {
    test('should create failure with message', () {
      const failure = ForbiddenFailure('Access denied');

      expect(failure.message, 'Access denied');
      expect(failure.errorCode, isNull);
    });

    test('should create failure with message and error code', () {
      const failure = ForbiddenFailure('Account not approved', errorCode: 'ACCOUNT_PENDING');

      expect(failure.message, 'Account not approved');
      expect(failure.errorCode, 'ACCOUNT_PENDING');
    });

    test('should have correct toString representation', () {
      const failure = ForbiddenFailure('Account suspended', errorCode: 'SUSPENDED');

      expect(failure.toString(), 'Account suspended');
    });

    test('should be instance of Failure', () {
      const failure = ForbiddenFailure('Test');

      expect(failure, isA<Failure>());
    });

    test('should support different error codes', () {
      const pendingFailure = ForbiddenFailure('Pending', errorCode: 'ACCOUNT_PENDING');
      const suspendedFailure = ForbiddenFailure('Suspended', errorCode: 'ACCOUNT_SUSPENDED');
      const rejectedFailure = ForbiddenFailure('Rejected', errorCode: 'ACCOUNT_REJECTED');

      expect(pendingFailure.errorCode, 'ACCOUNT_PENDING');
      expect(suspendedFailure.errorCode, 'ACCOUNT_SUSPENDED');
      expect(rejectedFailure.errorCode, 'ACCOUNT_REJECTED');
    });
  });

  group('ValidationFailure', () {
    test('should create failure with single field error', () {
      final failure = ValidationFailure({
        'email': ['Invalid email format'],
      });

      expect(failure.errors['email'], ['Invalid email format']);
    });

    test('should create failure with multiple field errors', () {
      final failure = ValidationFailure({
        'email': ['Invalid email format'],
        'password': ['Password too short', 'Password must contain a number'],
      });

      expect(failure.errors['email'], ['Invalid email format']);
      expect(failure.errors['password'], hasLength(2));
    });

    test('should combine all error messages in message property', () {
      final failure = ValidationFailure({
        'email': ['Invalid email'],
        'password': ['Too short'],
      });

      expect(failure.message, contains('Invalid email'));
      expect(failure.message, contains('Too short'));
    });

    test('should have correct toString representation', () {
      final failure = ValidationFailure({
        'name': ['Name is required'],
      });

      expect(failure.toString(), 'Name is required');
    });

    test('should be instance of Failure', () {
      final failure = ValidationFailure({});

      expect(failure, isA<Failure>());
    });

    test('should handle empty errors map', () {
      final failure = ValidationFailure({});

      expect(failure.errors, isEmpty);
      expect(failure.message, isEmpty);
    });

    test('should handle multiple errors for same field', () {
      final failure = ValidationFailure({
        'password': [
          'Password must be at least 8 characters',
          'Password must contain uppercase letter',
          'Password must contain a number',
        ],
      });

      expect(failure.errors['password'], hasLength(3));
      expect(failure.message, contains('8 characters'));
      expect(failure.message, contains('uppercase'));
      expect(failure.message, contains('number'));
    });
  });

  group('Failure type checking', () {
    test('should correctly identify failure types', () {
      const serverFailure = ServerFailure('');
      const cacheFailure = CacheFailure('');
      const networkFailure = NetworkFailure('');
      const unauthorizedFailure = UnauthorizedFailure('');
      const forbiddenFailure = ForbiddenFailure('');
      final validationFailure = ValidationFailure({});

      expect(serverFailure, isA<ServerFailure>());
      expect(cacheFailure, isA<CacheFailure>());
      expect(networkFailure, isA<NetworkFailure>());
      expect(unauthorizedFailure, isA<UnauthorizedFailure>());
      expect(forbiddenFailure, isA<ForbiddenFailure>());
      expect(validationFailure, isA<ValidationFailure>());

      // All are also Failure
      expect(serverFailure, isA<Failure>());
      expect(cacheFailure, isA<Failure>());
      expect(networkFailure, isA<Failure>());
      expect(unauthorizedFailure, isA<Failure>());
      expect(forbiddenFailure, isA<Failure>());
      expect(validationFailure, isA<Failure>());
    });
  });
}
