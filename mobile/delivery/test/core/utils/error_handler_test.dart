import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:courier/core/utils/error_handler.dart';
import 'package:courier/core/utils/app_exceptions.dart';

void main() {
  group('ErrorHandler.cleanMessage', () {
    test('returns userMessage for AppException', () {
      const e = NetworkException();
      expect(ErrorHandler.cleanMessage(e), e.userMessage);
    });

    test('strips Exception: prefix', () {
      final msg = ErrorHandler.cleanMessage(Exception('Erreur réseau'));
      expect(msg, isNot(startsWith('Exception:')));
      expect(msg, contains('Erreur réseau'));
    });

    test('strips repeated Exception: prefixes', () {
      final msg = ErrorHandler.cleanMessage('Exception: Exception: Oops');
      expect(msg, 'Oops');
    });

    test('returns fallback for empty message', () {
      final msg = ErrorHandler.cleanMessage('Exception: ');
      expect(msg, contains('réessayer'));
    });
  });

  group('ErrorHandler.toAppException', () {
    test('returns same AppException if already typed', () {
      const original = NetworkException();
      final result = ErrorHandler.toAppException(original);
      expect(identical(result, original), isTrue);
    });

    test('detects SocketException as NetworkException', () {
      final result = ErrorHandler.toAppException(
        Exception('SocketException: Connection refused'),
      );
      expect(result, isA<NetworkException>());
    });

    test('detects timeout string as NetworkException', () {
      final result = ErrorHandler.toAppException(
        Exception('Connection timeout occurred'),
      );
      expect(result, isA<NetworkException>());
    });

    test('unknown error becomes ApiException', () {
      final result = ErrorHandler.toAppException(Exception('Something weird'));
      expect(result, isA<ApiException>());
    });

    test('uses fallbackMessage for unknown error', () {
      final result = ErrorHandler.toAppException(
        Exception('x'),
        fallbackMessage: 'Erreur personnalisée',
      );
      expect(result.userMessage, 'Erreur personnalisée');
    });
  });

  group('ErrorHandler.toAppException with DioException', () {
    test('connectionTimeout → NetworkException', () {
      final dio = DioException(
        type: DioExceptionType.connectionTimeout,
        requestOptions: RequestOptions(path: '/test'),
      );
      final result = ErrorHandler.toAppException(dio);
      expect(result, isA<NetworkException>());
    });

    test('sendTimeout → NetworkException', () {
      final dio = DioException(
        type: DioExceptionType.sendTimeout,
        requestOptions: RequestOptions(path: '/test'),
      );
      final result = ErrorHandler.toAppException(dio);
      expect(result, isA<NetworkException>());
    });

    test('connectionError → NetworkException', () {
      final dio = DioException(
        type: DioExceptionType.connectionError,
        requestOptions: RequestOptions(path: '/test'),
      );
      final result = ErrorHandler.toAppException(dio);
      expect(result, isA<NetworkException>());
    });

    test('cancel → ApiException', () {
      final dio = DioException(
        type: DioExceptionType.cancel,
        requestOptions: RequestOptions(path: '/test'),
      );
      final result = ErrorHandler.toAppException(dio);
      expect(result, isA<ApiException>());
      expect(result.userMessage, contains('annulée'));
    });

    test('401 → SessionExpiredException', () {
      final dio = DioException(
        type: DioExceptionType.badResponse,
        response: Response(
          statusCode: 401,
          requestOptions: RequestOptions(path: '/test'),
        ),
        requestOptions: RequestOptions(path: '/test'),
      );
      final result = ErrorHandler.toAppException(dio);
      expect(result, isA<SessionExpiredException>());
    });

    test('403 → ForbiddenException', () {
      final dio = DioException(
        type: DioExceptionType.badResponse,
        response: Response(
          statusCode: 403,
          data: {'message': 'Profil coursier non trouvé'},
          requestOptions: RequestOptions(path: '/test'),
        ),
        requestOptions: RequestOptions(path: '/test'),
      );
      final result = ErrorHandler.toAppException(dio);
      expect(result, isA<ForbiddenException>());
      expect(result.userMessage, 'Profil coursier non trouvé');
    });

    test('404 → NotFoundException', () {
      final dio = DioException(
        type: DioExceptionType.badResponse,
        response: Response(
          statusCode: 404,
          requestOptions: RequestOptions(path: '/test'),
        ),
        requestOptions: RequestOptions(path: '/test'),
      );
      final result = ErrorHandler.toAppException(dio);
      expect(result, isA<NotFoundException>());
    });

    test('422 → ValidationException with field errors', () {
      final dio = DioException(
        type: DioExceptionType.badResponse,
        response: Response(
          statusCode: 422,
          data: {
            'message': 'Données invalides',
            'errors': {
              'email': ['Email requis', 'Format invalide'],
              'phone': ['Numéro invalide'],
            },
          },
          requestOptions: RequestOptions(path: '/test'),
        ),
        requestOptions: RequestOptions(path: '/test'),
      );
      final result = ErrorHandler.toAppException(dio);
      expect(result, isA<ValidationException>());
      final ve = result as ValidationException;
      expect(ve.fieldErrors['email'], hasLength(2));
      expect(ve.fieldErrors['phone'], hasLength(1));
    });

    test('429 → RateLimitException', () {
      final dio = DioException(
        type: DioExceptionType.badResponse,
        response: Response(
          statusCode: 429,
          requestOptions: RequestOptions(path: '/test'),
        ),
        requestOptions: RequestOptions(path: '/test'),
      );
      final result = ErrorHandler.toAppException(dio);
      expect(result, isA<RateLimitException>());
    });

    test('500 → ServerException', () {
      final dio = DioException(
        type: DioExceptionType.badResponse,
        response: Response(
          statusCode: 500,
          requestOptions: RequestOptions(path: '/test'),
        ),
        requestOptions: RequestOptions(path: '/test'),
      );
      final result = ErrorHandler.toAppException(dio);
      expect(result, isA<ServerException>());
    });

    test('409 → ConflictException', () {
      final dio = DioException(
        type: DioExceptionType.badResponse,
        response: Response(
          statusCode: 409,
          data: {'message': 'Livraison déjà prise'},
          requestOptions: RequestOptions(path: '/test'),
        ),
        requestOptions: RequestOptions(path: '/test'),
      );
      final result = ErrorHandler.toAppException(dio);
      expect(result, isA<ConflictException>());
      expect(result.userMessage, 'Livraison déjà prise');
    });

    test('unknown DioException with SocketException → NetworkException', () {
      final dio = DioException(
        type: DioExceptionType.unknown,
        error: 'SocketException: Connection refused',
        requestOptions: RequestOptions(path: '/test'),
      );
      final result = ErrorHandler.toAppException(dio);
      expect(result, isA<NetworkException>());
    });
  });

  group('ErrorHandler domain-specific messages', () {
    test('getDeliveryErrorMessage for 404', () {
      final dio = DioException(
        type: DioExceptionType.badResponse,
        response: Response(
          statusCode: 404,
          requestOptions: RequestOptions(path: '/test'),
        ),
        requestOptions: RequestOptions(path: '/test'),
      );
      final msg = ErrorHandler.getDeliveryErrorMessage(dio);
      expect(msg, contains('introuvable'));
    });

    test('getDeliveryErrorMessage for 409', () {
      final dio = DioException(
        type: DioExceptionType.badResponse,
        response: Response(
          statusCode: 409,
          data: {'message': 'Livraison prise'},
          requestOptions: RequestOptions(path: '/test'),
        ),
        requestOptions: RequestOptions(path: '/test'),
      );
      final msg = ErrorHandler.getDeliveryErrorMessage(dio);
      expect(msg, 'Livraison prise');
    });

    test('getProfileErrorMessage for 403 COURIER_PROFILE_NOT_FOUND', () {
      final dio = DioException(
        type: DioExceptionType.badResponse,
        response: Response(
          statusCode: 403,
          data: {
            'message': 'Non trouvé',
            'error_code': 'COURIER_PROFILE_NOT_FOUND',
          },
          requestOptions: RequestOptions(path: '/test'),
        ),
        requestOptions: RequestOptions(path: '/test'),
      );
      final msg = ErrorHandler.getProfileErrorMessage(dio);
      expect(msg, contains('coursier non trouvé'));
    });

    test('getProfileErrorMessage for 401', () {
      final dio = DioException(
        type: DioExceptionType.badResponse,
        response: Response(
          statusCode: 401,
          requestOptions: RequestOptions(path: '/test'),
        ),
        requestOptions: RequestOptions(path: '/test'),
      );
      final msg = ErrorHandler.getProfileErrorMessage(dio);
      expect(msg, contains('reconnecter'));
    });

    test('getChatErrorMessage for random error', () {
      final msg = ErrorHandler.getChatErrorMessage(Exception('Erreur'));
      expect(msg, isNotEmpty);
    });
  });
}
