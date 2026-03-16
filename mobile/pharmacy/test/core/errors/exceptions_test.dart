import 'package:flutter_test/flutter_test.dart';
import 'package:drpharma_pharmacy/core/errors/exceptions.dart';

void main() {
  group('ServerException', () {
    test('should create ServerException with message and statusCode', () {
      final exception = ServerException(
        message: 'Internal server error',
        statusCode: 500,
      );

      expect(exception.message, 'Internal server error');
      expect(exception.statusCode, 500);
    });

    test('should have correct toString representation', () {
      final exception = ServerException(
        message: 'Not found',
        statusCode: 404,
      );

      expect(
        exception.toString(),
        'ServerException: Not found (Status: 404)',
      );
    });

    test('should handle null statusCode', () {
      final exception = ServerException(message: 'Unknown error');

      expect(exception.message, 'Unknown error');
      expect(exception.statusCode, isNull);
    });
  });

  group('NetworkException', () {
    test('should create NetworkException with message', () {
      final exception = NetworkException(
        message: 'No internet connection',
      );

      expect(exception.message, 'No internet connection');
    });

    test('should have correct toString representation', () {
      final exception = NetworkException(
        message: 'Connection timeout',
      );

      expect(
        exception.toString(),
        'NetworkException: Connection timeout',
      );
    });
  });

  group('UnauthorizedException', () {
    test('should create UnauthorizedException with default message', () {
      final exception = UnauthorizedException();

      expect(exception.message, 'Unauthorized access');
    });

    test('should create UnauthorizedException with custom message', () {
      final exception = UnauthorizedException(
        message: 'Session expired',
      );

      expect(exception.message, 'Session expired');
    });

    test('should have correct toString representation', () {
      final exception = UnauthorizedException(
        message: 'Invalid token',
      );

      expect(
        exception.toString(),
        'UnauthorizedException: Invalid token',
      );
    });
  });

  group('ForbiddenException', () {
    test('should create ForbiddenException with message', () {
      final exception = ForbiddenException(
        message: 'Account not approved',
      );

      expect(exception.message, 'Account not approved');
      expect(exception.errorCode, isNull);
    });

    test('should create ForbiddenException with errorCode', () {
      final exception = ForbiddenException(
        message: 'Account suspended',
        errorCode: 'ACCOUNT_SUSPENDED',
      );

      expect(exception.message, 'Account suspended');
      expect(exception.errorCode, 'ACCOUNT_SUSPENDED');
    });

    test('should have correct toString representation', () {
      final exception = ForbiddenException(
        message: 'Pharmacy not active',
        errorCode: 'PHARMACY_INACTIVE',
      );

      expect(
        exception.toString(),
        'ForbiddenException: Pharmacy not active (code: PHARMACY_INACTIVE)',
      );
    });
  });

  group('CacheException', () {
    test('should create CacheException with message', () {
      final exception = CacheException(
        message: 'Cache read error',
      );

      expect(exception.message, 'Cache read error');
    });

    test('should have correct toString representation', () {
      final exception = CacheException(
        message: 'Failed to save data',
      );

      expect(
        exception.toString(),
        'CacheException: Failed to save data',
      );
    });
  });

  group('Exception Types', () {
    test('all exceptions should implement Exception', () {
      expect(ServerException(message: 'test'), isA<Exception>());
      expect(NetworkException(message: 'test'), isA<Exception>());
      expect(UnauthorizedException(), isA<Exception>());
      expect(ForbiddenException(message: 'test'), isA<Exception>());
      expect(CacheException(message: 'test'), isA<Exception>());
    });
  });

  group('Common Error Scenarios', () {
    test('should handle 401 unauthorized scenario', () {
      final exception = UnauthorizedException(
        message: 'Identifiants invalides',
      );

      expect(exception.message.contains('Identifiants'), true);
    });

    test('should handle 403 pending pharmacy scenario', () {
      final exception = ForbiddenException(
        message: 'Votre pharmacie est en attente d\'approbation',
        errorCode: 'PHARMACY_PENDING',
      );

      expect(exception.errorCode, 'PHARMACY_PENDING');
      expect(exception.message.contains('attente'), true);
    });

    test('should handle network timeout scenario', () {
      final exception = NetworkException(
        message: 'Délai de connexion dépassé',
      );

      expect(exception.message.contains('Délai'), true);
    });

    test('should handle server error scenario', () {
      final exception = ServerException(
        message: 'Erreur interne du serveur',
        statusCode: 500,
      );

      expect(exception.statusCode, 500);
      expect(exception.message.contains('Erreur'), true);
    });
  });
}
