import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:courier/data/repositories/wallet_repository.dart';
import 'package:courier/core/constants/api_constants.dart';
import '../../helpers/test_helpers.dart';

class MockDio extends Mock implements Dio {}

void main() {
  late MockDio mockDio;
  late WalletRepository repo;

  setUpAll(() async {
    await setupTestDependencies();
  });

  setUp(() {
    mockDio = MockDio();
    repo = WalletRepository(mockDio);
  });

  group('getWalletData', () {
    test('throws on 404', () async {
      when(() => mockDio.get(ApiConstants.wallet)).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: ''),
          type: DioExceptionType.badResponse,
          response: Response(
            statusCode: 404,
            requestOptions: RequestOptions(path: ''),
          ),
        ),
      );

      expect(
        () => repo.getWalletData(),
        throwsA(
          predicate<Exception>((e) => e.toString().contains('non trouvé')),
        ),
      );
    });

    test('throws on 401', () async {
      when(() => mockDio.get(ApiConstants.wallet)).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: ''),
          type: DioExceptionType.badResponse,
          response: Response(
            statusCode: 401,
            requestOptions: RequestOptions(path: ''),
          ),
        ),
      );

      expect(
        () => repo.getWalletData(),
        throwsA(
          predicate<Exception>((e) => e.toString().contains('Session expirée')),
        ),
      );
    });

    test('throws on 403 with message', () async {
      when(() => mockDio.get(ApiConstants.wallet)).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: ''),
          type: DioExceptionType.badResponse,
          response: Response(
            statusCode: 403,
            data: {'message': 'Profil coursier non trouvé'},
            requestOptions: RequestOptions(path: ''),
          ),
        ),
      );

      expect(
        () => repo.getWalletData(),
        throwsA(
          predicate<Exception>((e) => e.toString().contains('Profil coursier')),
        ),
      );
    });
  });

  group('canDeliver', () {
    test('returns map on success', () async {
      when(() => mockDio.get(ApiConstants.walletCanDeliver)).thenAnswer(
        (_) async => Response(
          data: {
            'data': {'can_deliver': true, 'balance': 5000},
          },
          statusCode: 200,
          requestOptions: RequestOptions(path: ''),
        ),
      );

      final result = await repo.canDeliver();
      expect(result['can_deliver'], isTrue);
    });

    test('throws on 403', () async {
      when(() => mockDio.get(ApiConstants.walletCanDeliver)).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: ''),
          type: DioExceptionType.badResponse,
          response: Response(
            statusCode: 403,
            data: {'message': 'Profil coursier non trouvé.'},
            requestOptions: RequestOptions(path: ''),
          ),
        ),
      );

      expect(() => repo.canDeliver(), throwsA(isA<Exception>()));
    });
  });
}
