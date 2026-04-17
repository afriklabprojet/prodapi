import '../../../../core/network/api_client.dart';
import '../models/chat_message_model.dart';
import '../../domain/entities/chat_message.dart';

/// Handles all HTTP chat operations for the client app.
///
/// Endpoint strategies:
/// - **Delivery-based** (when deliveryId is known): `/customer/deliveries/{id}/chat`
/// - **Order-based** (fallback when only orderId is known): `/customer/orders/{id}/chat`
class ChatApiDatasource {
  final ApiClient _apiClient;
  final int? deliveryId;
  final int? orderId;

  ChatApiDatasource({
    required ApiClient apiClient,
    this.deliveryId,
    this.orderId,
  }) : _apiClient = apiClient;

  String get _messagesPath {
    if (deliveryId != null) return '/customer/deliveries/$deliveryId/chat';
    if (orderId != null) return '/customer/orders/$orderId/chat';
    throw StateError('Neither deliveryId nor orderId provided');
  }

  // ── Messages ───────────────────────────────────────────────────────────────

  Future<List<ChatMessage>> fetchMessages({
    int? before,
    int limit = 30,
  }) async {
    final query = <String, dynamic>{'limit': limit};
    if (before != null) query['before'] = before;

    final response = await _apiClient.get(
      _messagesPath,
      queryParameters: query,
    );

    return _parseList(response.data);
  }

  Future<ChatMessage> sendMessage({
    required String localId,
    required String message,
    String? target,
  }) async {
    final data = <String, dynamic>{'message': message};
    if (target != null) data['target'] = target;

    final response = await _apiClient.post(_messagesPath, data: data);

    final body = response.data;
    if (body is Map && body['success'] == true) {
      final raw = body['message'] ?? body['data'];
      if (raw is Map) {
        return ChatMessageModel.fromJson(
          ChatMessageModel.flattenSender(Map<String, dynamic>.from(raw)),
        ).toEntity().copyWith(localId: localId, status: MessageStatus.sent);
      }
      return ChatMessage(
        localId: localId,
        message: message,
        senderType: 'customer',
        senderId: 0,
        isMine: true,
        createdAt: DateTime.now(),
        status: MessageStatus.sent,
      );
    }

    final reason =
        (body is Map ? body['message']?.toString() : null) ?? 'Send failed';
    throw Exception(reason);
  }

  Future<void> markAsRead({required int messageId}) async {
    await _apiClient.post('$_messagesPath/read', data: {
      'message_id': messageId,
    });
  }

  // ── Parsing ────────────────────────────────────────────────────────────────

  List<ChatMessage> _parseList(dynamic body) {
    if (body == null) return [];
    List<dynamic>? items;

    if (body is List) {
      items = body;
    } else if (body is Map) {
      items = (body['data'] ?? body['messages']) as List<dynamic>?;
    }

    if (items == null) return [];

    return items
        .whereType<Map<String, dynamic>>()
        .map((raw) => ChatMessageModel.fromJson(
              ChatMessageModel.flattenSender(raw),
            ).toEntity())
        .toList();
  }
}
