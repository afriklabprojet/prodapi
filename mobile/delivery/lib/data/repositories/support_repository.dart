import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/api_constants.dart';
import '../../core/network/api_client.dart';
import '../../core/utils/safe_json_utils.dart';
import '../models/support_ticket.dart';

final supportRepositoryProvider = Provider<SupportRepository>((ref) {
  return SupportRepository(ref.read(dioProvider));
});

class SupportRepository {
  final Dio _dio;

  SupportRepository(this._dio);

  /// Récupérer la liste des tickets de support
  Future<List<SupportTicket>> getTickets({int page = 1}) async {
    try {
      final response = await _dio.get(
        ApiConstants.supportTickets,
        queryParameters: {'page': page},
      );

      final data = response.data;
      if (data['success'] == true && data['data'] != null) {
        final ticketsData = data['data']['data'] as List? ?? data['data'] as List;
        return ticketsData
            .map((json) => SupportTicket.fromJson(json as Map<String, dynamic>))
            .toList();
      }
      return [];
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Créer un nouveau ticket
  Future<SupportTicket> createTicket({
    required String subject,
    required String description,
    required String category,
    String priority = 'medium',
  }) async {
    try {
      final response = await _dio.post(
        ApiConstants.supportTickets,
        data: {
          'subject': subject,
          'description': description,
          'category': category,
          'priority': priority,
        },
      );

      final data = response.data;
      if (data['success'] == true && data['data'] != null) {
        return SupportTicket.fromJson(data['data'] as Map<String, dynamic>);
      }
      throw Exception('Erreur lors de la création du ticket');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Récupérer les détails d'un ticket avec ses messages
  Future<SupportTicket> getTicketDetails(int ticketId) async {
    try {
      final response = await _dio.get(ApiConstants.supportTicketDetail(ticketId));

      final data = response.data;
      if (data['success'] == true && data['data'] != null) {
        return SupportTicket.fromJson(data['data'] as Map<String, dynamic>);
      }
      throw Exception('Ticket non trouvé');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Envoyer un message dans un ticket
  Future<SupportMessage> sendMessage(int ticketId, String message, {String? attachmentPath}) async {
    try {
      FormData? formData;
      
      if (attachmentPath != null) {
        formData = FormData.fromMap({
          'message': message,
          'attachment': await MultipartFile.fromFile(attachmentPath),
        });
      }

      final response = await _dio.post(
        ApiConstants.supportTicketMessages(ticketId),
        data: formData ?? {'message': message},
      );

      final data = response.data;
      if (data['success'] == true && data['data'] != null) {
        return SupportMessage.fromJson(data['data'] as Map<String, dynamic>);
      }
      throw Exception('Erreur lors de l\'envoi du message');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Marquer un ticket comme résolu
  Future<SupportTicket> resolveTicket(int ticketId) async {
    try {
      final response = await _dio.post(ApiConstants.supportTicketResolve(ticketId));

      final data = response.data;
      if (data['success'] == true && data['data'] != null) {
        return SupportTicket.fromJson(data['data'] as Map<String, dynamic>);
      }
      throw Exception('Erreur lors de la résolution du ticket');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Fermer un ticket
  Future<SupportTicket> closeTicket(int ticketId) async {
    try {
      final response = await _dio.post(ApiConstants.supportTicketClose(ticketId));

      final data = response.data;
      if (data['success'] == true && data['data'] != null) {
        return SupportTicket.fromJson(data['data'] as Map<String, dynamic>);
      }
      throw Exception('Erreur lors de la fermeture du ticket');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Récupérer les statistiques de support
  Future<SupportStats> getStats() async {
    try {
      final response = await _dio.get(ApiConstants.supportTicketsStats);

      final data = response.data;
      if (data['success'] == true && data['data'] != null) {
        return SupportStats.fromJson(data['data'] as Map<String, dynamic>);
      }
      return const SupportStats();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Récupérer les FAQ pour les coursiers
  Future<List<FAQItem>> getFaq() async {
    try {
      final response = await _dio.get(ApiConstants.supportFaqCourier);

      final data = response.data;
      if (data['success'] == true && data['data'] != null) {
        final faqData = data['data'] as List;
        return faqData
            .map((json) => FAQItem.fromJson(json as Map<String, dynamic>))
            .toList();
      }
      return [];
    } on DioException {
      // En cas d'erreur, retourner une liste vide (le fallback sera utilisé)
      return [];
    }
  }

  /// Signaler un incident lié à une livraison (architecture propre : pas de Dio dans l'UI)
  Future<void> reportIncident({
    required int deliveryId,
    required String reason,
  }) async {
    try {
      await _dio.post('/courier/report-problem', data: {
        'category': 'delivery',
        'subject': 'Incident Livraison #$deliveryId',
        'description': 'Motif: $reason',
        'metadata': {'delivery_id': deliveryId, 'reason': reason},
      });
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }



  /// Gestion des erreurs
  Exception _handleError(DioException e) {
    if (e.response?.statusCode == 404) {
      return Exception('Ticket non trouvé');
    }
    if (e.response?.statusCode == 400) {
      final message = SafeJsonUtils.safeData(e.response?.data)['message'] ?? 'Action non autorisée';
      return Exception(message);
    }
    if (e.response?.statusCode == 422) {
      final data = SafeJsonUtils.safeData(e.response?.data);
      if (data.containsKey('message')) {
        return Exception(data['message']);
      }
      return Exception('Données invalides');
    }
    return Exception('Erreur de connexion. Veuillez réessayer.');
  }
}
