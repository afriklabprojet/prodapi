import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:drpharma_client/core/errors/error_handler.dart';
import 'package:drpharma_client/core/errors/exceptions.dart' as exc;

void main() {
  // ---------------------------------------------------------------------------
  // ErrorHandler.getErrorMessage
  // ---------------------------------------------------------------------------

  group('ErrorHandler.getErrorMessage — AppException', () {
    test('returns userMessage from AppException', () {
      const e = AppException(userMessage: 'Erreur métier');
      expect(ErrorHandler.getErrorMessage(e), 'Erreur métier');
    });

    test('returns userMessage from NetworkException (subclass)', () {
      const e = NetworkException(userMessage: 'Pas de réseau');
      expect(ErrorHandler.getErrorMessage(e), 'Pas de réseau');
    });

    test('returns default userMessage from NetworkException', () {
      const e = NetworkException();
      expect(ErrorHandler.getErrorMessage(e), 'Erreur de connexion');
    });
  });

  group('ErrorHandler.getErrorMessage — data exceptions', () {
    test('returns message from exc.ServerException', () {
      final e = exc.ServerException(message: 'Erreur 500', statusCode: 500);
      expect(ErrorHandler.getErrorMessage(e), 'Erreur 500');
    });

    test('returns message from exc.NetworkException', () {
      final e = exc.NetworkException(message: 'Réseau indisponible');
      expect(ErrorHandler.getErrorMessage(e), 'Réseau indisponible');
    });

    test('returns message from exc.CacheException', () {
      final e = exc.CacheException(message: 'Cache corrompu');
      expect(ErrorHandler.getErrorMessage(e), 'Cache corrompu');
    });

    test('returns session expired for exc.UnauthorizedException', () {
      final e = exc.UnauthorizedException();
      expect(ErrorHandler.getErrorMessage(e), contains('Session expirée'));
    });

    test('returns first validation error from exc.ValidationException', () {
      final e = exc.ValidationException(
        errors: {
          'email': ['Email invalide'],
          'password': ['Trop court'],
        },
      );
      expect(ErrorHandler.getErrorMessage(e), 'Email invalide');
    });

    test('returns fallback for empty ValidationException', () {
      final e = exc.ValidationException(errors: {});
      expect(ErrorHandler.getErrorMessage(e), 'Données invalides');
    });
  });

  group('ErrorHandler.getErrorMessage — DioException', () {
    DioException makeDio(
      DioExceptionType type, {
      int? statusCode,
      dynamic data,
    }) {
      return DioException(
        type: type,
        requestOptions: RequestOptions(path: '/test'),
        response: (statusCode != null)
            ? Response(
                requestOptions: RequestOptions(path: '/test'),
                statusCode: statusCode,
                data: data,
              )
            : null,
      );
    }

    test('connectionTimeout → délai de connexion', () {
      final e = makeDio(DioExceptionType.connectionTimeout);
      expect(ErrorHandler.getErrorMessage(e), contains('Délai'));
    });

    test('sendTimeout → délai de connexion', () {
      final e = makeDio(DioExceptionType.sendTimeout);
      expect(ErrorHandler.getErrorMessage(e), contains('Délai'));
    });

    test('receiveTimeout → délai de connexion', () {
      final e = makeDio(DioExceptionType.receiveTimeout);
      expect(ErrorHandler.getErrorMessage(e), contains('Délai'));
    });

    test('cancel → requête annulée', () {
      final e = makeDio(DioExceptionType.cancel);
      expect(ErrorHandler.getErrorMessage(e), 'Requête annulée');
    });

    test('badCertificate → certificat invalide', () {
      final e = makeDio(DioExceptionType.badCertificate);
      expect(ErrorHandler.getErrorMessage(e), contains('Certificat'));
    });

    test('unknown → erreur connexion', () {
      final e = makeDio(DioExceptionType.unknown);
      expect(ErrorHandler.getErrorMessage(e), 'Erreur de connexion');
    });

    test('connectionError → impossible se connecter', () {
      final e = makeDio(DioExceptionType.connectionError);
      expect(ErrorHandler.getErrorMessage(e), contains('connecter'));
    });

    test('badResponse 400 → requête invalide', () {
      final e = makeDio(DioExceptionType.badResponse, statusCode: 400);
      expect(ErrorHandler.getErrorMessage(e), 'Requête invalide');
    });

    test('badResponse 400 with message → uses server message', () {
      final e = makeDio(
        DioExceptionType.badResponse,
        statusCode: 400,
        data: {'message': 'Champ manquant'},
      );
      expect(ErrorHandler.getErrorMessage(e), 'Champ manquant');
    });

    test('badResponse 401 → session expirée', () {
      final e = makeDio(DioExceptionType.badResponse, statusCode: 401);
      expect(ErrorHandler.getErrorMessage(e), contains('Session expirée'));
    });

    test('badResponse 403 → accès non autorisé', () {
      final e = makeDio(DioExceptionType.badResponse, statusCode: 403);
      expect(ErrorHandler.getErrorMessage(e), contains('Accès non autorisé'));
    });

    test('badResponse 404 → ressource non trouvée', () {
      final e = makeDio(DioExceptionType.badResponse, statusCode: 404);
      expect(ErrorHandler.getErrorMessage(e), contains('non trouvée'));
    });

    test('badResponse 409 → conflit de données', () {
      final e = makeDio(DioExceptionType.badResponse, statusCode: 409);
      expect(ErrorHandler.getErrorMessage(e), contains('Conflit'));
    });

    test('badResponse 422 → données invalides', () {
      final e = makeDio(DioExceptionType.badResponse, statusCode: 422);
      expect(ErrorHandler.getErrorMessage(e), contains('invalides'));
    });

    test('badResponse 429 → trop de requêtes', () {
      final e = makeDio(DioExceptionType.badResponse, statusCode: 429);
      expect(ErrorHandler.getErrorMessage(e), contains('Trop de requêtes'));
    });

    test('badResponse 500 → erreur serveur', () {
      final e = makeDio(DioExceptionType.badResponse, statusCode: 500);
      expect(ErrorHandler.getErrorMessage(e), contains('serveur'));
    });

    test('badResponse 502 → service indisponible', () {
      final e = makeDio(DioExceptionType.badResponse, statusCode: 502);
      expect(ErrorHandler.getErrorMessage(e), contains('indisponible'));
    });

    test('badResponse 503 → service indisponible', () {
      final e = makeDio(DioExceptionType.badResponse, statusCode: 503);
      expect(ErrorHandler.getErrorMessage(e), contains('indisponible'));
    });

    test('badResponse unknown code → uses error field', () {
      final e = makeDio(
        DioExceptionType.badResponse,
        statusCode: 418,
        data: {'error': 'Je suis une théière'},
      );
      expect(ErrorHandler.getErrorMessage(e), 'Je suis une théière');
    });

    test('badResponse unknown code without message → Erreur XXX', () {
      final e = makeDio(DioExceptionType.badResponse, statusCode: 418);
      expect(ErrorHandler.getErrorMessage(e), contains('418'));
    });

    test('badResponse with errors map → first error value', () {
      final e = makeDio(
        DioExceptionType.badResponse,
        statusCode: 422,
        data: {
          'errors': {'name': 'Nom requis'},
        },
      );
      expect(ErrorHandler.getErrorMessage(e), 'Nom requis');
    });
  });

  group('ErrorHandler.getErrorMessage — dart exceptions', () {
    test('TimeoutException → délai trop long', () {
      final e = TimeoutException('timed out');
      expect(ErrorHandler.getErrorMessage(e), contains('trop de temps'));
    });

    test('FormatException → données invalides reçues', () {
      final e = FormatException('bad format');
      expect(ErrorHandler.getErrorMessage(e), contains('invalides reçues'));
    });

    test('unknown error → erreur inattendue', () {
      expect(
        ErrorHandler.getErrorMessage('some random string'),
        contains('inattendue'),
      );
    });
  });

  // ---------------------------------------------------------------------------
  // ErrorHandler.runSafe
  // ---------------------------------------------------------------------------

  group('ErrorHandler.runSafe', () {
    test('returns result when operation succeeds', () async {
      final result = await ErrorHandler.runSafe<String>(
        () async => 'success',
        onError: (msg) => fail('Should not call onError'),
      );
      expect(result, 'success');
    });

    test('calls onError and returns null when operation throws', () async {
      String? capturedMessage;
      final result = await ErrorHandler.runSafe<String>(
        () async => throw exc.ServerException(message: 'Oops', statusCode: 500),
        onError: (msg) => capturedMessage = msg,
      );
      expect(result, isNull);
      expect(capturedMessage, 'Oops');
    });

    test('returns fallbackValue when operation throws', () async {
      final result = await ErrorHandler.runSafe<String>(
        () async => throw exc.NetworkException(),
        onError: (_) {},
        fallbackValue: 'default',
      );
      expect(result, 'default');
    });

    test('passes operationName without crashing', () async {
      String? captured;
      await ErrorHandler.runSafe<void>(
        () async => throw Exception('boom'),
        onError: (msg) => captured = msg,
        operationName: 'testOp',
      );
      expect(captured, isNotNull);
    });
  });

  // ---------------------------------------------------------------------------
  // AppException class
  // ---------------------------------------------------------------------------

  group('AppException', () {
    test('toString includes code and userMessage', () {
      const e = AppException(userMessage: 'Msg', code: 'ERR_001');
      expect(e.toString(), contains('ERR_001'));
      expect(e.toString(), contains('Msg'));
    });

    test('toString with null code', () {
      const e = AppException(userMessage: 'Msg');
      expect(e.toString(), contains('AppException'));
    });

    test('stores all fields', () {
      const e = AppException(
        userMessage: 'User msg',
        technicalMessage: 'Tech msg',
        code: 'CODE',
        originalError: 'original',
      );
      expect(e.userMessage, 'User msg');
      expect(e.technicalMessage, 'Tech msg');
      expect(e.code, 'CODE');
      expect(e.originalError, 'original');
    });
  });
}
