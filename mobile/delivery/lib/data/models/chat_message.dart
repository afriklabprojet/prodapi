import 'package:freezed_annotation/freezed_annotation.dart';

part 'chat_message.freezed.dart';

@freezed
abstract class ChatMessage with _$ChatMessage {
  const ChatMessage._();

  const factory ChatMessage({
    required int id,
    required String content,
    required bool isMe,
    required String senderName,
    required DateTime createdAt,
  }) = _ChatMessage;

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] is int
          ? json['id']
          : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      content: (json['content'] ?? json['message'] ?? '').toString(),
      isMe: (json['is_me'] ?? json['is_mine']) == true,
      senderName: json['sender_name']?.toString() ?? 'Inconnu',
      createdAt: DateTime.tryParse(
              (json['created_at'] ?? '').toString()) ??
          DateTime.now(),
    );
  }
}

