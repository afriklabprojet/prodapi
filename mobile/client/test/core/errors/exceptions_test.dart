import 'package:flutter_test/flutter_test.dart';
import 'package:drpharma_client/core/errors/exceptions.dart';

void main() {
  // ---------------------------------------------------------------------------
  // ServerException
  // ---------------------------------------------------------------------------
  group('ServerException', () {
    test('stores message and statusCode', () {
      final e = ServerException(message: 'Not found', statusCode: 404);
      expect(e.message, 'Not found');
      expect(e.statusCode, 404);
      expect(e.responseData, isNull);
    });

    test('stores responseData', () {
      final e = ServerException(
        message: 'Payment in progress',
        statusCode: 409,
        responseData: {'redirect_url': 'https://pay.example.com'},
      );
      expect(e.responseData!['redirect_url'], 'https://pay.example.com');
    });

    test('allows null statusCode', () {
      final e = ServerException(message: 'error');
      expect(e.statusCode, isNull);
    });

    test('toString contains class name and message', () {
      final e = ServerException(message: 'Erreur', statusCode: 500);
      expect(e.toString(), contains('ServerException'));
      expect(e.toString(), contains('Erreur'));
      expect(e.toString(), contains('500'));
    });
  });

  // ---------------------------------------------------------------------------
  // NetworkException
  // ---------------------------------------------------------------------------
  group('NetworkException', () {
    test('uses default message', () {
      final e = NetworkException();
      expect(e.message, 'Erreur de connexion réseau');
    });

    test('accepts custom message', () {
      final e = NetworkException(message: 'Wi-Fi désactivé');
      expect(e.message, 'Wi-Fi désactivé');
    });

    test('toString contains NetworkException', () {
      expect(NetworkException().toString(), contains('NetworkException'));
    });
  });

  // ---------------------------------------------------------------------------
  // UnauthorizedException
  // ---------------------------------------------------------------------------
  group('UnauthorizedException', () {
    test('uses default message', () {
      final e = UnauthorizedException();
      expect(e.message, 'Session expirée');
    });

    test('accepts custom message', () {
      final e = UnauthorizedException(message: 'Token invalide');
      expect(e.message, 'Token invalide');
    });

    test('toString contains UnauthorizedException', () {
      expect(
        UnauthorizedException().toString(),
        contains('UnauthorizedException'),
      );
    });
  });

  // ---------------------------------------------------------------------------
  // ValidationException
  // ---------------------------------------------------------------------------
  group('ValidationException', () {
    test('stores errors map', () {
      final e = ValidationException(
        errors: {
          'email': ['Format invalide'],
          'password': ['Trop court'],
        },
      );
      expect(e.errors['email'], ['Format invalide']);
      expect(e.errors['password'], ['Trop court']);
    });

    test('firstError returns first error of first key', () {
      final e = ValidationException(
        errors: {
          'name': ['Requis', 'Trop court'],
          'email': ['Invalide'],
        },
      );
      expect(e.firstError, 'Requis');
    });

    test('firstError returns fallback when errors map is empty', () {
      final e = ValidationException(errors: {});
      expect(e.firstError, 'Erreur de validation');
    });

    test('firstError throws when first key has empty list', () {
      final e = ValidationException(errors: {'field': []});
      // errors['field']?.first throws StateError for empty list
      expect(() => e.firstError, throwsStateError);
    });

    test('toString contains ValidationException', () {
      final e = ValidationException(errors: {});
      expect(e.toString(), contains('ValidationException'));
    });
  });

  // ---------------------------------------------------------------------------
  // CacheException
  // ---------------------------------------------------------------------------
  group('CacheException', () {
    test('uses default message', () {
      final e = CacheException();
      expect(e.message, 'Erreur de cache');
    });

    test('accepts custom message', () {
      final e = CacheException(message: 'Cache expiré');
      expect(e.message, 'Cache expiré');
    });

    test('toString contains CacheException', () {
      expect(CacheException().toString(), contains('CacheException'));
    });
  });
}
