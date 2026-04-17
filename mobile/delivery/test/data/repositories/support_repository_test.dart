import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:courier/data/repositories/support_repository.dart';
import 'package:courier/core/constants/api_constants.dart';

class MockDio extends Mock implements Dio {}

void main() {
  late MockDio mockDio;
  late SupportRepository repo;

  setUp(() {
    mockDio = MockDio();
    repo = SupportRepository(mockDio);
  });

  group('getTickets', () {
    test('returns list of tickets on success', () async {
      when(() => mockDio.get(
            ApiConstants.supportTickets,
            queryParameters: any(named: 'queryParameters'),
          )).thenAnswer((_) async => Response(
            data: {
              'success': true,
              'data': {
                'data': [
                  {
                    'id': 1,
                    'user_id': 10,
                    'subject': 'Test Ticket',
                    'description': 'Desc',
                    'status': 'open',
                    'category': 'general',
                    'priority': 'medium',
                    'created_at': '2024-01-15T10:00:00.000Z',
                  },
                ],
              },
            },
            statusCode: 200,
            requestOptions: RequestOptions(path: ''),
          ));

      final result = await repo.getTickets();
      expect(result.length, 1);
      expect(result.first.subject, 'Test Ticket');
    });

    test('returns empty list when success is false', () async {
      when(() => mockDio.get(
            ApiConstants.supportTickets,
            queryParameters: any(named: 'queryParameters'),
          )).thenAnswer((_) async => Response(
            data: {'success': false},
            statusCode: 200,
            requestOptions: RequestOptions(path: ''),
          ));

      final result = await repo.getTickets();
      expect(result, isEmpty);
    });

    test('throws on DioException', () async {
      when(() => mockDio.get(
            ApiConstants.supportTickets,
            queryParameters: any(named: 'queryParameters'),
          )).thenThrow(DioException(
        requestOptions: RequestOptions(path: ''),
        type: DioExceptionType.badResponse,
        response: Response(
          statusCode: 500,
          requestOptions: RequestOptions(path: ''),
        ),
      ));

      expect(() => repo.getTickets(), throwsA(isA<Exception>()));
    });
  });

  group('createTicket', () {
    test('creates ticket successfully', () async {
      when(() => mockDio.post(
            ApiConstants.supportTickets,
            data: any(named: 'data'),
          )).thenAnswer((_) async => Response(
            data: {
              'success': true,
              'data': {
                'id': 2,
                'user_id': 10,
                'subject': 'New Ticket',
                'description': 'New Desc',
                'status': 'open',
                'category': 'bug',
                'priority': 'high',
                'created_at': '2024-01-15T10:00:00.000Z',
              },
            },
            statusCode: 201,
            requestOptions: RequestOptions(path: ''),
          ));

      final result = await repo.createTicket(
        subject: 'New Ticket',
        description: 'New Desc',
        category: 'bug',
        priority: 'high',
      );
      expect(result.subject, 'New Ticket');
    });

    test('throws when success is false', () async {
      when(() => mockDio.post(
            ApiConstants.supportTickets,
            data: any(named: 'data'),
          )).thenAnswer((_) async => Response(
            data: {'success': false},
            statusCode: 200,
            requestOptions: RequestOptions(path: ''),
          ));

      expect(
        () => repo.createTicket(
          subject: 'X',
          description: 'Y',
          category: 'Z',
        ),
        throwsA(isA<Exception>()),
      );
    });
  });
}
