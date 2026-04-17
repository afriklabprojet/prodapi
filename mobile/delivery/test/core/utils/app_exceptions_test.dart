import 'package:flutter_test/flutter_test.dart';
import 'package:courier/core/utils/app_exceptions.dart';

void main() {
  group('AppException hierarchy', () {
    test('NetworkException has correct defaults', () {
      const e = NetworkException();
      expect(e.message, 'Network error');
      expect(e.userMessage, contains('connexion internet'));
      expect(e.toString(), e.userMessage);
    });

    test('NetworkException with custom message', () {
      const e = NetworkException(
        message: 'Timeout',
        userMessage: 'La connexion a pris trop de temps.',
      );
      expect(e.message, 'Timeout');
      expect(e.userMessage, 'La connexion a pris trop de temps.');
    });

    test('SessionExpiredException has correct defaults', () {
      const e = SessionExpiredException();
      expect(e.userMessage, contains('reconnecter'));
      expect(e.code, 'SESSION_EXPIRED');
    });

    test('ForbiddenException has correct defaults', () {
      const e = ForbiddenException();
      expect(e.userMessage, 'Accès refusé.');
    });

    test('NotFoundException has correct defaults', () {
      const e = NotFoundException();
      expect(e.userMessage, contains('introuvable'));
    });

    test('ValidationException with field errors', () {
      const e = ValidationException(
        fieldErrors: {
          'email': ['L\'email est requis', 'Format invalide'],
          'phone': ['Le numéro est invalide'],
        },
      );
      expect(e.fieldErrors, hasLength(2));
      expect(e.fieldErrors['email'], hasLength(2));
      expect(e.firstFieldError, 'L\'email est requis');
    });

    test('ValidationException with empty field errors returns userMessage', () {
      const e = ValidationException();
      expect(e.fieldErrors, isEmpty);
      expect(e.firstFieldError, e.userMessage);
    });

    test('ServerException has correct defaults', () {
      const e = ServerException();
      expect(e.userMessage, contains('serveur'));
    });

    test('CacheException has correct defaults', () {
      const e = CacheException();
      expect(e.userMessage, contains('locales'));
    });

    test('ConflictException has correct defaults', () {
      const e = ConflictException();
      expect(e.userMessage, contains('actuellement'));
    });

    test('RateLimitException has correct defaults', () {
      const e = RateLimitException();
      expect(e.userMessage, contains('patienter'));
    });

    test('ApiException with statusCode', () {
      const e = ApiException(
        statusCode: 500,
        message: 'Internal Server Error',
        userMessage: 'Erreur serveur',
      );
      expect(e.statusCode, 500);
      expect(e.message, 'Internal Server Error');
      expect(e.userMessage, 'Erreur serveur');
    });

    test('All exceptions are AppException', () {
      const exceptions = <AppException>[
        NetworkException(),
        ApiException(message: 'test', userMessage: 'test'),
        SessionExpiredException(),
        ForbiddenException(),
        NotFoundException(),
        ValidationException(),
        ServerException(),
        CacheException(),
        ConflictException(),
        RateLimitException(),
      ];

      for (final e in exceptions) {
        expect(e, isA<AppException>());
        expect(e.message, isNotEmpty);
        expect(e.userMessage, isNotEmpty);
      }
    });

    test('sealed class exhaustive pattern matching works', () {
      const AppException e = SessionExpiredException();

      final result = switch (e) {
        NetworkException() => 'network',
        SessionExpiredException() => 'session',
        ForbiddenException() => 'forbidden',
        NotFoundException() => 'not_found',
        ValidationException() => 'validation',
        ServerException() => 'server',
        CacheException() => 'cache',
        ConflictException() => 'conflict',
        RateLimitException() => 'rate_limit',
        ApiException() => 'api',
        PendingApprovalException() => 'pending_approval',
        IncompleteKycException() => 'incomplete_kyc',
      };

      expect(result, 'session');
    });

    test('PendingApprovalException has correct defaults', () {
      const e = PendingApprovalException();
      expect(e.userMessage, contains('approbation'));
      expect(e.code, 'PENDING_APPROVAL');
      expect(e.status, 'pending_approval');
    });

    test('PendingApprovalException with custom status', () {
      const e = PendingApprovalException(status: 'suspended');
      expect(e.status, 'suspended');
    });

    test('IncompleteKycException has correct defaults', () {
      const e = IncompleteKycException();
      expect(e.userMessage, contains('vérification'));
      expect(e.code, 'INCOMPLETE_KYC');
      expect(e.rejectionReason, isNull);
    });

    test('IncompleteKycException with rejection reason', () {
      const e = IncompleteKycException(rejectionReason: 'Document unclear');
      expect(e.rejectionReason, 'Document unclear');
    });

    test('ApiException errors field', () {
      const e = ApiException(
        statusCode: 422,
        message: 'Validation',
        userMessage: 'Invalid',
        errors: {'email': 'required'},
      );
      expect(e.errors, isNotNull);
      expect(e.errors!['email'], 'required');
    });

    test('ApiException errors default null', () {
      const e = ApiException(message: 'x', userMessage: 'x');
      expect(e.errors, isNull);
    });
  });
}
