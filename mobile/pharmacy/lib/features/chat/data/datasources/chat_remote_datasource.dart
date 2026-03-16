import '../../../../core/network/api_client.dart';
import '../models/chat_message_model.dart';

abstract class ChatRemoteDataSource {
  Future<List<ChatMessageModel>> getMessages(
    int deliveryId,
    String participantType,
    int participantId,
  );
  Future<ChatMessageModel> sendMessage(
    int deliveryId,
    String receiverType,
    int receiverId,
    String message,
  );
  Future<int> getUnreadCount(int deliveryId);
  Future<void> markAsRead(
    int deliveryId,
    String senderType,
    int senderId,
  );
}

class ChatRemoteDataSourceImpl implements ChatRemoteDataSource {
  final ApiClient apiClient;

  ChatRemoteDataSourceImpl({required this.apiClient});

  @override
  Future<List<ChatMessageModel>> getMessages(
    int deliveryId,
    String participantType,
    int participantId,
  ) async {
    final response = await apiClient.get(
      '/pharmacy/deliveries/$deliveryId/chat',
      queryParameters: {
        'participant_type': participantType,
        'participant_id': participantId,
      },
    );
    final data = response.data;
    final list = data is Map && data['data'] != null ? data['data'] as List : data as List;
    return list.map((e) => ChatMessageModel.fromJson(e)).toList();
  }

  @override
  Future<ChatMessageModel> sendMessage(
    int deliveryId,
    String receiverType,
    int receiverId,
    String message,
  ) async {
    final response = await apiClient.post(
      '/pharmacy/deliveries/$deliveryId/chat',
      data: {
        'receiver_type': receiverType,
        'receiver_id': receiverId,
        'message': message,
      },
    );
    final data = response.data;
    final msgData = data is Map && data['data'] != null ? data['data'] : data;
    return ChatMessageModel.fromJson(msgData);
  }

  @override
  Future<int> getUnreadCount(int deliveryId) async {
    final response = await apiClient.get(
      '/pharmacy/deliveries/$deliveryId/chat/unread',
    );
    final data = response.data;
    if (data is Map) {
      return data['count'] ?? data['unread_count'] ?? 0;
    }
    return 0;
  }

  @override
  Future<void> markAsRead(
    int deliveryId,
    String senderType,
    int senderId,
  ) async {
    await apiClient.post(
      '/pharmacy/deliveries/$deliveryId/chat/read',
      data: {
        'sender_type': senderType,
        'sender_id': senderId,
      },
    );
  }
}
