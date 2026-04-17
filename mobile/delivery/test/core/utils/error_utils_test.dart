import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:courier/core/utils/error_utils.dart';

void main() {
  group('userFriendlyError', () {
    // ── DioException ──────────────────────────────────

    test('connectionTimeout → message lent', () {
      final e = DioException(
        requestOptions: RequestOptions(path: ''),
        type: DioExceptionType.connectionTimeout,
      );
      expect(userFriendlyError(e), 'Connexion lente, veuillez réessayer');
    });

    test('sendTimeout → message lent', () {
      final e = DioException(
        requestOptions: RequestOptions(path: ''),
        type: DioExceptionType.sendTimeout,
      );
      expect(userFriendlyError(e), 'Connexion lente, veuillez réessayer');
    });

    test('receiveTimeout → message lent', () {
      final e = DioException(
        requestOptions: RequestOptions(path: ''),
        type: DioExceptionType.receiveTimeout,
      );
      expect(userFriendlyError(e), 'Connexion lente, veuillez réessayer');
    });

    test('connectionError → pas de connexion', () {
      final e = DioException(
        requestOptions: RequestOptions(path: ''),
        type: DioExceptionType.connectionError,
      );
      expect(userFriendlyError(e), 'Pas de connexion internet');
    });

    test('cancel → requête annulée', () {
      final e = DioException(
        requestOptions: RequestOptions(path: ''),
        type: DioExceptionType.cancel,
      );
      expect(userFriendlyError(e), 'Requête annulée');
    });

    test('badResponse 401 → session expirée', () {
      final e = DioException(
        requestOptions: RequestOptions(path: ''),
        type: DioExceptionType.badResponse,
        response: Response(
          statusCode: 401,
          requestOptions: RequestOptions(path: ''),
        ),
      );
      expect(
        userFriendlyError(e),
        'Session expirée, veuillez vous reconnecter',
      );
    });

    test('badResponse 403 → session expirée', () {
      final e = DioException(
        requestOptions: RequestOptions(path: ''),
        type: DioExceptionType.badResponse,
        response: Response(
          statusCode: 403,
          requestOptions: RequestOptions(path: ''),
        ),
      );
      expect(
        userFriendlyError(e),
        'Session expirée, veuillez vous reconnecter',
      );
    });

    test('badResponse 404 → introuvable', () {
      final e = DioException(
        requestOptions: RequestOptions(path: ''),
        type: DioExceptionType.badResponse,
        response: Response(
          statusCode: 404,
          requestOptions: RequestOptions(path: ''),
        ),
      );
      expect(userFriendlyError(e), 'Ressource introuvable');
    });

    test('badResponse 422 with message → returns server message', () {
      final e = DioException(
        requestOptions: RequestOptions(path: ''),
        type: DioExceptionType.badResponse,
        response: Response(
          statusCode: 422,
          data: {'message': 'Le champ email est requis'},
          requestOptions: RequestOptions(path: ''),
        ),
      );
      expect(userFriendlyError(e), 'Le champ email est requis');
    });

    test('badResponse 422 without message → données invalides', () {
      final e = DioException(
        requestOptions: RequestOptions(path: ''),
        type: DioExceptionType.badResponse,
        response: Response(
          statusCode: 422,
          data: {'errors': {}},
          requestOptions: RequestOptions(path: ''),
        ),
      );
      expect(userFriendlyError(e), 'Données invalides');
    });

    test('badResponse 500 → erreur serveur', () {
      final e = DioException(
        requestOptions: RequestOptions(path: ''),
        type: DioExceptionType.badResponse,
        response: Response(
          statusCode: 500,
          requestOptions: RequestOptions(path: ''),
        ),
      );
      expect(
        userFriendlyError(e),
        'Erreur serveur, veuillez réessayer plus tard',
      );
    });

    test('badResponse unknown status → une erreur', () {
      final e = DioException(
        requestOptions: RequestOptions(path: ''),
        type: DioExceptionType.badResponse,
        response: Response(
          statusCode: 418,
          requestOptions: RequestOptions(path: ''),
        ),
      );
      expect(userFriendlyError(e), 'Une erreur est survenue');
    });

    test('unknown DioExceptionType → erreur réseau', () {
      final e = DioException(
        requestOptions: RequestOptions(path: ''),
        type: DioExceptionType.unknown,
      );
      expect(userFriendlyError(e), 'Une erreur réseau est survenue');
    });

    // ── Non-Dio exceptions ────────────────────────────

    test('SocketException → pas de connexion', () {
      final e = const SocketException('Connection refused');
      expect(userFriendlyError(e), 'Pas de connexion internet');
    });

    test('FormatException → erreur de format', () {
      final e = const FormatException('bad format');
      expect(userFriendlyError(e), 'Erreur de format de données');
    });

    test('string containing SocketException → pas de connexion', () {
      expect(
        userFriendlyError(Exception('SocketException: Connection refused')),
        'Pas de connexion internet',
      );
    });

    test('string containing timeout → connexion lente', () {
      expect(
        userFriendlyError(Exception('Connection timeout')),
        'Connexion lente, veuillez réessayer',
      );
    });

    test('string containing firebase → erreur de service', () {
      expect(
        userFriendlyError(Exception('Firebase error xyz')),
        'Erreur de service, veuillez réessayer',
      );
    });

    test('unknown error → message générique', () {
      expect(
        userFriendlyError(Exception('something weird')),
        'Une erreur est survenue, veuillez réessayer',
      );
    });
  });
}
