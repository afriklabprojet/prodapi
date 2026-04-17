import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:courier/data/repositories/support_repository.dart';
import 'package:courier/core/constants/api_constants.dart';
import '../helpers/test_helpers.dart';

void main() {
  late MockDio mockDio;
  late SupportRepository repo;

  setUp(() {
    mockDio = MockDio();
    repo = SupportRepository(mockDio);
  });

  final ticketJson = {
    'id': 1,
    'user_id': 10,
    'subject': 'Problème livraison',
    'description': 'Colis endommagé',
    'category': 'delivery',
    'priority': 'high',
    'status': 'open',
    'reference': 'TK-001',
    'created_at': '2026-02-13T08:00:00Z',
  };

  // ── getTickets ──────────────────────────────────────
  group('getTickets', () {
    test('returns list of SupportTicket on success', () async {
      when(() => mockDio.get(ApiConstants.supportTickets,
              queryParameters: any(named: 'queryParameters')))
          .thenAnswer((_) async => successResponse({
                'success': true,
                'data': {'data': [ticketJson]},
              }));

      final tickets = await repo.getTickets();
      expect(tickets, hasLength(1));
      expect(tickets[0].subject, 'Problème livraison');
      expect(tickets[0].priority, 'high');
    });

    test('returns empty list on empty data', () async {
      when(() => mockDio.get(ApiConstants.supportTickets,
              queryParameters: any(named: 'queryParameters')))
          .thenAnswer((_) async => successResponse({
                'success': true,
                'data': {'data': []},
              }));

      final tickets = await repo.getTickets();
      expect(tickets, isEmpty);
    });

    test('returns empty list when success is false', () async {
      when(() => mockDio.get(ApiConstants.supportTickets,
              queryParameters: any(named: 'queryParameters')))
          .thenAnswer((_) async => successResponse({
                'success': false,
                'data': null,
              }));

      final tickets = await repo.getTickets();
      expect(tickets, isEmpty);
    });

    test('passes page parameter', () async {
      when(() => mockDio.get(ApiConstants.supportTickets,
              queryParameters: any(named: 'queryParameters')))
          .thenAnswer((_) async => successResponse({
                'success': true,
                'data': {'data': []},
              }));

      await repo.getTickets(page: 3);
      verify(() => mockDio.get(ApiConstants.supportTickets,
          queryParameters: {'page': 3})).called(1);
    });

    test('throws on DioException', () async {
      when(() => mockDio.get(ApiConstants.supportTickets,
              queryParameters: any(named: 'queryParameters')))
          .thenThrow(dioError(statusCode: 500));

      expect(() => repo.getTickets(), throwsA(isA<Exception>()));
    });
  });

  // ── createTicket ────────────────────────────────────
  group('createTicket', () {
    test('returns SupportTicket on success', () async {
      when(() => mockDio.post(ApiConstants.supportTickets, data: any(named: 'data')))
          .thenAnswer((_) async => successResponse({
                'success': true,
                'data': ticketJson,
              }));

      final ticket = await repo.createTicket(
        subject: 'Test',
        description: 'Desc',
        category: 'other',
      );
      expect(ticket.id, 1);
    });

    test('throws on failure response', () async {
      when(() => mockDio.post(ApiConstants.supportTickets, data: any(named: 'data')))
          .thenAnswer((_) async => successResponse({
                'success': false,
                'data': null,
              }));

      expect(
        () => repo.createTicket(
          subject: 'Test',
          description: 'Desc',
          category: 'other',
        ),
        throwsA(isA<Exception>()),
      );
    });

    test('throws on DioException', () async {
      when(() => mockDio.post(ApiConstants.supportTickets, data: any(named: 'data')))
          .thenThrow(dioError(statusCode: 422, data: {'message': 'Sujet requis'}));

      expect(
        () => repo.createTicket(
          subject: '',
          description: 'Desc',
          category: 'other',
        ),
        throwsA(isA<Exception>().having(
          (e) => e.toString(), 'msg', contains('Sujet requis'),
        )),
      );
    });
  });

  // ── getTicketDetails ────────────────────────────────
  group('getTicketDetails', () {
    test('returns SupportTicket with messages', () async {
      when(() => mockDio.get(ApiConstants.supportTicketDetail(1)))
          .thenAnswer((_) async => successResponse({
                'success': true,
                'data': {
                  ...ticketJson,
                  'messages': [
                    {
                      'id': 1,
                      'support_ticket_id': 1,
                      'user_id': 10,
                      'message': 'Premier message',
                    }
                  ],
                },
              }));

      final ticket = await repo.getTicketDetails(1);
      expect(ticket.messages, hasLength(1));
      expect(ticket.messages![0].message, 'Premier message');
    });

    test('throws on 404', () async {
      when(() => mockDio.get(ApiConstants.supportTicketDetail(999)))
          .thenThrow(dioError(statusCode: 404));

      expect(
        () => repo.getTicketDetails(999),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'msg',
          contains('non trouvé'),
        )),
      );
    });

    test('throws on failure response', () async {
      when(() => mockDio.get(ApiConstants.supportTicketDetail(1)))
          .thenAnswer((_) async => successResponse({
                'success': false,
                'data': null,
              }));

      expect(
        () => repo.getTicketDetails(1),
        throwsA(isA<Exception>()),
      );
    });
  });

  // ── sendMessage ─────────────────────────────────────
  group('sendMessage', () {
    test('returns SupportMessage on success (text only)', () async {
      when(() => mockDio.post(ApiConstants.supportTicketMessages(1),
              data: any(named: 'data')))
          .thenAnswer((_) async => successResponse({
                'success': true,
                'data': {
                  'id': 5,
                  'support_ticket_id': 1,
                  'user_id': 10,
                  'message': 'Merci',
                },
              }));

      final msg = await repo.sendMessage(1, 'Merci');
      expect(msg.id, 5);
      expect(msg.message, 'Merci');
    });

    test('throws on failure response', () async {
      when(() => mockDio.post(ApiConstants.supportTicketMessages(1),
              data: any(named: 'data')))
          .thenAnswer((_) async => successResponse({
                'success': false,
                'data': null,
              }));

      expect(
        () => repo.sendMessage(1, 'Test'),
        throwsA(isA<Exception>()),
      );
    });

    test('throws on DioException', () async {
      when(() => mockDio.post(ApiConstants.supportTicketMessages(1),
              data: any(named: 'data')))
          .thenThrow(dioError(statusCode: 500));

      expect(
        () => repo.sendMessage(1, 'Test'),
        throwsA(isA<Exception>()),
      );
    });
  });

  // ── resolveTicket / closeTicket ─────────────────────
  group('resolveTicket', () {
    test('returns updated ticket', () async {
      when(() => mockDio.post(ApiConstants.supportTicketResolve(1)))
          .thenAnswer((_) async => successResponse({
                'success': true,
                'data': {...ticketJson, 'status': 'resolved'},
              }));

      final ticket = await repo.resolveTicket(1);
      expect(ticket.status, 'resolved');
    });

    test('throws on failure response', () async {
      when(() => mockDio.post(ApiConstants.supportTicketResolve(1)))
          .thenAnswer((_) async => successResponse({
                'success': false,
                'data': null,
              }));

      expect(
        () => repo.resolveTicket(1),
        throwsA(isA<Exception>()),
      );
    });

    test('throws on DioException', () async {
      when(() => mockDio.post(ApiConstants.supportTicketResolve(1)))
          .thenThrow(dioError(statusCode: 500));

      expect(() => repo.resolveTicket(1), throwsA(isA<Exception>()));
    });
  });

  group('closeTicket', () {
    test('returns closed ticket', () async {
      when(() => mockDio.post(ApiConstants.supportTicketClose(1)))
          .thenAnswer((_) async => successResponse({
                'success': true,
                'data': {...ticketJson, 'status': 'closed'},
              }));

      final ticket = await repo.closeTicket(1);
      expect(ticket.status, 'closed');
    });

    test('throws on failure response', () async {
      when(() => mockDio.post(ApiConstants.supportTicketClose(1)))
          .thenAnswer((_) async => successResponse({
                'success': false,
                'data': null,
              }));

      expect(
        () => repo.closeTicket(1),
        throwsA(isA<Exception>()),
      );
    });

    test('throws on DioException', () async {
      when(() => mockDio.post(ApiConstants.supportTicketClose(1)))
          .thenThrow(dioError(statusCode: 400, data: {'message': 'Déjà fermé'}));

      expect(
        () => repo.closeTicket(1),
        throwsA(isA<Exception>().having(
          (e) => e.toString(), 'msg', contains('Déjà fermé'),
        )),
      );
    });
  });

  // ── getStats ────────────────────────────────────────
  group('getStats', () {
    test('returns SupportStats on success', () async {
      when(() => mockDio.get(ApiConstants.supportTicketsStats))
          .thenAnswer((_) async => successResponse({
                'success': true,
                'data': {
                  'total': 10,
                  'open': 3,
                  'resolved': 5,
                  'closed': 2,
                },
              }));

      final stats = await repo.getStats();
      expect(stats.total, 10);
    });

    test('returns default stats when success is false', () async {
      when(() => mockDio.get(ApiConstants.supportTicketsStats))
          .thenAnswer((_) async => successResponse({
                'success': false,
                'data': null,
              }));

      final stats = await repo.getStats();
      expect(stats.total, 0);
    });

    test('throws on DioException', () async {
      when(() => mockDio.get(ApiConstants.supportTicketsStats))
          .thenThrow(dioError(statusCode: 500));

      expect(() => repo.getStats(), throwsA(isA<Exception>()));
    });
  });

  // ── _handleError ────────────────────────────────────
  group('_handleError (via getTickets)', () {
    test('returns specific message for 400', () async {
      when(() => mockDio.get(ApiConstants.supportTickets,
              queryParameters: any(named: 'queryParameters')))
          .thenThrow(dioError(statusCode: 400, data: {'message': 'Action non autorisée'}));

      expect(
        () => repo.getTickets(),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'msg',
          contains('Action non autorisée'),
        )),
      );
    });

    test('returns specific message for 422', () async {
      when(() => mockDio.get(ApiConstants.supportTickets,
              queryParameters: any(named: 'queryParameters')))
          .thenThrow(dioError(
        statusCode: 422,
        data: {'message': 'Données invalides'},
      ));

      expect(
        () => repo.getTickets(),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'msg',
          contains('Données invalides'),
        )),
      );
    });

    test('returns default message for 422 without message key', () async {
      when(() => mockDio.get(ApiConstants.supportTickets,
              queryParameters: any(named: 'queryParameters')))
          .thenThrow(dioError(statusCode: 422, data: {}));

      expect(
        () => repo.getTickets(),
        throwsA(isA<Exception>().having(
          (e) => e.toString(), 'msg', contains('Données invalides'),
        )),
      );
    });

    test('returns default message for 400 without message key', () async {
      when(() => mockDio.get(ApiConstants.supportTickets,
              queryParameters: any(named: 'queryParameters')))
          .thenThrow(dioError(statusCode: 400, data: {}));

      expect(
        () => repo.getTickets(),
        throwsA(isA<Exception>().having(
          (e) => e.toString(), 'msg', contains('Action non autorisée'),
        )),
      );
    });

    test('returns generic error for other status codes', () async {
      when(() => mockDio.get(ApiConstants.supportTickets,
              queryParameters: any(named: 'queryParameters')))
          .thenThrow(dioError(statusCode: 503));

      expect(
        () => repo.getTickets(),
        throwsA(isA<Exception>().having(
          (e) => e.toString(), 'msg', contains('Erreur de connexion'),
        )),
      );
    });
  });
}
