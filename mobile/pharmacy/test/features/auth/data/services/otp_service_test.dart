import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:drpharma_pharmacy/core/errors/failure.dart';
import 'package:drpharma_pharmacy/core/network/api_client.dart';
import 'package:drpharma_pharmacy/features/auth/data/services/otp_service.dart';

class MockApiClient extends Mock implements ApiClient {}

class MockDio extends Mock implements Dio {}

void main() {
  late OtpService service;
  late MockApiClient mockApiClient;
  late MockDio mockDio;

  setUp(() {
    mockApiClient = MockApiClient();
    mockDio = MockDio();
    when(() => mockApiClient.dio).thenReturn(mockDio);
    service = OtpService(mockApiClient);
  });

  group('requestOtp', () {
    test('returns channel on success', () async {
      when(
        () =>
            mockDio.post('/auth/resend', data: {'identifier': '+22507070707'}),
      ).thenAnswer(
        (_) async => Response(
          data: {'channel': 'whatsapp'},
          statusCode: 200,
          requestOptions: RequestOptions(path: '/auth/resend'),
        ),
      );

      final result = await service.requestOtp('+22507070707');

      expect(result, const Right('whatsapp'));
    });

    test('defaults to sms when no channel in response', () async {
      when(
        () =>
            mockDio.post('/auth/resend', data: {'identifier': '+22507070707'}),
      ).thenAnswer(
        (_) async => Response(
          data: <String, dynamic>{},
          statusCode: 200,
          requestOptions: RequestOptions(path: '/auth/resend'),
        ),
      );

      final result = await service.requestOtp('+22507070707');

      expect(result, const Right('sms'));
    });

    test('returns ServerFailure on error', () async {
      when(
        () =>
            mockDio.post('/auth/resend', data: {'identifier': '+22507070707'}),
      ).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/auth/resend'),
          type: DioExceptionType.badResponse,
        ),
      );

      final result = await service.requestOtp('+22507070707');

      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) => expect(failure, isA<ServerFailure>()),
        (_) => fail('Expected Left'),
      );
    });
  });

  group('verifyOtp', () {
    test('returns true on success', () async {
      when(
        () => mockDio.post(
          '/auth/verify',
          data: {'identifier': '+22507070707', 'otp': '123456'},
        ),
      ).thenAnswer(
        (_) async => Response(
          data: {'verified': true},
          statusCode: 200,
          requestOptions: RequestOptions(path: '/auth/verify'),
        ),
      );

      final result = await service.verifyOtp(
        identifier: '+22507070707',
        otp: '123456',
      );

      expect(result, const Right(true));
    });

    test('returns ServerFailure on invalid OTP', () async {
      when(
        () => mockDio.post(
          '/auth/verify',
          data: {'identifier': '+22507070707', 'otp': '000000'},
        ),
      ).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/auth/verify'),
          type: DioExceptionType.badResponse,
          response: Response(
            statusCode: 422,
            data: {'message': 'OTP invalid'},
            requestOptions: RequestOptions(path: '/auth/verify'),
          ),
        ),
      );

      final result = await service.verifyOtp(
        identifier: '+22507070707',
        otp: '000000',
      );

      expect(result.isLeft(), isTrue);
      result.fold((failure) {
        expect(failure, isA<ServerFailure>());
        expect(failure.message, 'Code invalide ou expiré');
      }, (_) => fail('Expected Left'));
    });
  });
}
