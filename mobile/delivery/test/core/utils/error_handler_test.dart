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

    test('getDeliveryErrorMessage for 403 with COURIER_PROFILE_NOT_FOUND', () {
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
      final msg = ErrorHandler.getDeliveryErrorMessage(dio);
      expect(msg, contains('profil coursier'));
    });

    test('getDeliveryErrorMessage for 403 without special code', () {
      final dio = DioException(
        type: DioExceptionType.badResponse,
        response: Response(
          statusCode: 403,
          data: {'message': 'Custom forbidden'},
          requestOptions: RequestOptions(path: '/test'),
        ),
        requestOptions: RequestOptions(path: '/test'),
      );
      final msg = ErrorHandler.getDeliveryErrorMessage(dio);
      expect(msg, 'Custom forbidden');
    });

    test('getDeliveryErrorMessage for non-DioException', () {
      final msg = ErrorHandler.getDeliveryErrorMessage(Exception('random'));
      expect(msg, isNotEmpty);
    });

    test('getChatErrorMessage returns fallback', () {
      final msg = ErrorHandler.getChatErrorMessage(Exception('chat error'));
      expect(msg, isNotEmpty);
    });

    test('getProfileErrorMessage for generic error', () {
      final msg = ErrorHandler.getProfileErrorMessage(Exception('generic'));
      expect(msg, contains('profil'));
    });

    test('getDeliveryErrorMessage for 409 without server message', () {
      final dio = DioException(
        type: DioExceptionType.badResponse,
        response: Response(
          statusCode: 409,
          requestOptions: RequestOptions(path: '/test'),
        ),
        requestOptions: RequestOptions(path: '/test'),
      );
      final msg = ErrorHandler.getDeliveryErrorMessage(dio);
      expect(msg, contains('disponible'));
    });
  });

  group('ErrorHandler additional DioException types', () {
    test('receiveTimeout → NetworkException', () {
      final dio = DioException(
        type: DioExceptionType.receiveTimeout,
        requestOptions: RequestOptions(path: '/test'),
      );
      final result = ErrorHandler.toAppException(dio);
      expect(result, isA<NetworkException>());
    });

    test('badCertificate → ApiException about security', () {
      final dio = DioException(
        type: DioExceptionType.badCertificate,
        requestOptions: RequestOptions(path: '/test'),
      );
      final result = ErrorHandler.toAppException(dio);
      expect(result, isA<ApiException>());
      expect(result.userMessage, contains('sécurité'));
    });

    test('unknown DioException with XMLHttpRequest → NetworkException', () {
      final dio = DioException(
        type: DioExceptionType.unknown,
        error: 'XMLHttpRequest error',
        requestOptions: RequestOptions(path: '/test'),
      );
      final result = ErrorHandler.toAppException(dio);
      expect(result, isA<NetworkException>());
    });

    test('unknown DioException generic → ApiException', () {
      final dio = DioException(
        type: DioExceptionType.unknown,
        error: 'Some random error',
        requestOptions: RequestOptions(path: '/test'),
      );
      final result = ErrorHandler.toAppException(dio);
      expect(result, isA<ApiException>());
    });

    test('502 → ServerException', () {
      final dio = DioException(
        type: DioExceptionType.badResponse,
        response: Response(
          statusCode: 502,
          requestOptions: RequestOptions(path: '/test'),
        ),
        requestOptions: RequestOptions(path: '/test'),
      );
      final result = ErrorHandler.toAppException(dio);
      expect(result, isA<ServerException>());
    });

    test('503 → ServerException', () {
      final dio = DioException(
        type: DioExceptionType.badResponse,
        response: Response(
          statusCode: 503,
          requestOptions: RequestOptions(path: '/test'),
        ),
        requestOptions: RequestOptions(path: '/test'),
      );
      final result = ErrorHandler.toAppException(dio);
      expect(result, isA<ServerException>());
    });

    test('unknown status code → ApiException', () {
      final dio = DioException(
        type: DioExceptionType.badResponse,
        response: Response(
          statusCode: 418,
          requestOptions: RequestOptions(path: '/test'),
        ),
        requestOptions: RequestOptions(path: '/test'),
      );
      final result = ErrorHandler.toAppException(dio);
      expect(result, isA<ApiException>());
    });

    test('unknown status code with fallback message', () {
      final dio = DioException(
        type: DioExceptionType.badResponse,
        response: Response(
          statusCode: 418,
          requestOptions: RequestOptions(path: '/test'),
        ),
        requestOptions: RequestOptions(path: '/test'),
      );
      final result = ErrorHandler.toAppException(
        dio,
        fallbackMessage: 'Custom',
      );
      expect(result.userMessage, 'Custom');
    });

    test('unknown DioException with fallback', () {
      final dio = DioException(
        type: DioExceptionType.unknown,
        error: 'Random',
        requestOptions: RequestOptions(path: '/test'),
      );
      final result = ErrorHandler.toAppException(
        dio,
        fallbackMessage: 'Fallback',
      );
      expect(result.userMessage, 'Fallback');
    });
  });

  group('ErrorHandler edge cases', () {
    test('cleanMessage with plain number', () {
      final msg = ErrorHandler.cleanMessage(42);
      expect(msg, '42');
    });

    test('cleanMessage with empty string after prefix stripping', () {
      final msg = ErrorHandler.cleanMessage('Exception: Exception: ');
      expect(msg, contains('réessayer'));
    });

    test('toAppException detects "connection refused"', () {
      final result = ErrorHandler.toAppException(
        Exception('connection refused by server'),
      );
      expect(result, isA<NetworkException>());
    });

    test('toAppException detects "network is unreachable"', () {
      final result = ErrorHandler.toAppException(
        Exception('network is unreachable'),
      );
      expect(result, isA<NetworkException>());
    });

    test('toAppException detects "xmlhttprequest"', () {
      final result = ErrorHandler.toAppException(
        Exception('XMLHttpRequest failed'),
      );
      expect(result, isA<NetworkException>());
    });

    test('422 without field errors returns empty fieldErrors', () {
      final dio = DioException(
        type: DioExceptionType.badResponse,
        response: Response(
          statusCode: 422,
          data: {'message': 'Invalid'},
          requestOptions: RequestOptions(path: '/test'),
        ),
        requestOptions: RequestOptions(path: '/test'),
      );
      final result = ErrorHandler.toAppException(dio);
      expect(result, isA<ValidationException>());
      expect((result as ValidationException).fieldErrors, isEmpty);
    });

    test('422 with non-list field error values', () {
      final dio = DioException(
        type: DioExceptionType.badResponse,
        response: Response(
          statusCode: 422,
          data: {
            'message': 'Invalid',
            'errors': {'email': 'single error string'},
          },
          requestOptions: RequestOptions(path: '/test'),
        ),
        requestOptions: RequestOptions(path: '/test'),
      );
      final result = ErrorHandler.toAppException(dio);
      expect(result, isA<ValidationException>());
      final ve = result as ValidationException;
      expect(ve.fieldErrors['email'], ['single error string']);
    });

    test('403 extracts error_code', () {
      final dio = DioException(
        type: DioExceptionType.badResponse,
        response: Response(
          statusCode: 403,
          data: {'message': 'Forbidden', 'error_code': 'CUSTOM_CODE'},
          requestOptions: RequestOptions(path: '/test'),
        ),
        requestOptions: RequestOptions(path: '/test'),
      );
      final result = ErrorHandler.toAppException(dio);
      expect(result, isA<ForbiddenException>());
      expect((result as ForbiddenException).code, 'CUSTOM_CODE');
    });

    test('404 with server message', () {
      final dio = DioException(
        type: DioExceptionType.badResponse,
        response: Response(
          statusCode: 404,
          data: {'message': 'Order not found'},
          requestOptions: RequestOptions(path: '/test'),
        ),
        requestOptions: RequestOptions(path: '/test'),
      );
      final result = ErrorHandler.toAppException(dio);
      expect(result, isA<NotFoundException>());
      expect(result.userMessage, 'Order not found');
    });

    test('getReadableMessage returns userMessage', () {
      final msg = ErrorHandler.getReadableMessage(const NetworkException());
      expect(msg, isNotEmpty);
    });

    test('getReadableMessage with defaultMessage', () {
      final msg = ErrorHandler.getReadableMessage(
        Exception('x'),
        defaultMessage: 'Custom default',
      );
      expect(msg, 'Custom default');
    });
  });
}
