import '../../domain/entities/chat_message.dart';

class ChatMessageModel {
  final int id;
  final String message;
  final String senderType;
  final int senderId;
  final String? senderName;
  final bool isMine;
  final DateTime? readAt;
  final DateTime createdAt;

  const ChatMessageModel({
    required this.id,
    required this.message,
    required this.senderType,
    required this.senderId,
    this.senderName,
    required this.isMine,
    this.readAt,
    required this.createdAt,
  });

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) {
    return ChatMessageModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      message: json['message']?.toString() ?? '',
      senderType: json['sender_type']?.toString() ?? 'unknown',
      senderId: json['sender_id'] is int
          ? json['sender_id']
          : int.tryParse(json['sender_id'].toString()) ?? 0,
      senderName: json['sender_name']?.toString(),
      isMine: json['is_mine'] == true || json['is_mine'] == 1,
      readAt: json['read_at'] != null
          ? DateTime.tryParse(json['read_at'].toString())
          : null,
      createdAt:
          DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  ChatMessage toEntity() {
    return ChatMessage(
      localId: id.toString(),
      serverId: id,
      message: message,
      senderType: senderType,
      senderId: senderId,
      senderName: senderName,
      isMine: isMine,
      readAt: readAt,
      createdAt: createdAt,
      status: MessageStatus.sent,
    );
  }

  /// Normalises nested `{sender: {type, id, name}}` into flat fields.
  static Map<String, dynamic> flattenSender(Map<String, dynamic> map) {
    final sender = map['sender'];
    if (sender is Map && !map.containsKey('sender_type')) {
      return {
        ...map,
        'sender_type': sender['type']?.toString() ?? 'unknown',
        'sender_id': sender['id'] ?? 0,
        'sender_name': sender['name']?.toString(),
      };
    }
    return map;
  }
}
