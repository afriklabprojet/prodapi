import 'package:flutter/foundation.dart';

enum MessageStatus { sending, sent, delivered, read, failed }

@immutable
class ChatMessage {
  final String localId;
  final int? serverId;
  final String message;
  final String senderType;
  final int senderId;
  final String? senderName;
  final bool isMine;
  final DateTime? readAt;
  final DateTime createdAt;
  final MessageStatus status;
  final int? sessionId;

  const ChatMessage({
    required this.localId,
    this.serverId,
    required this.message,
    required this.senderType,
    required this.senderId,
    this.senderName,
    required this.isMine,
    this.readAt,
    required this.createdAt,
    this.status = MessageStatus.sent,
    this.sessionId,
  });

  ChatMessage copyWith({
    String? localId,
    int? serverId,
    String? message,
    String? senderType,
    int? senderId,
    String? senderName,
    bool? isMine,
    DateTime? readAt,
    DateTime? createdAt,
    MessageStatus? status,
    int? sessionId,
  }) {
    return ChatMessage(
      localId: localId ?? this.localId,
      serverId: serverId ?? this.serverId,
      message: message ?? this.message,
      senderType: senderType ?? this.senderType,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      isMine: isMine ?? this.isMine,
      readAt: readAt ?? this.readAt,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
      sessionId: sessionId ?? this.sessionId,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChatMessage &&
          runtimeType == other.runtimeType &&
          localId == other.localId;

  @override
  int get hashCode => localId.hashCode;
}
