import 'package:flutter/foundation.dart';
import '../../domain/entities/chat_message.dart';

@immutable
class ChatState {
  final List<ChatMessage> messages;
  final bool isLoadingInitial;
  final bool isLoadingMore;
  final bool isSending;
  final bool isRemoteTyping;
  final bool isConnected;
  final bool hasMore;
  final bool canSend;
  final int? oldestServerId;
  final String? error;
  final Map<int, DateTime> readReceipts;

  const ChatState({
    required this.messages,
    required this.isLoadingInitial,
    required this.isLoadingMore,
    required this.isSending,
    required this.isRemoteTyping,
    required this.isConnected,
    required this.hasMore,
    this.canSend = true,
    this.oldestServerId,
    this.error,
    this.readReceipts = const {},
  });

  static const initial = ChatState(
    messages: [],
    isLoadingInitial: true,
    isLoadingMore: false,
    isSending: false,
    isRemoteTyping: false,
    isConnected: false,
    hasMore: false,
    readReceipts: {},
  );

  MessageStatus effectiveStatus(ChatMessage msg) {
    if (!msg.isMine) return msg.status;
    if (msg.status == MessageStatus.failed || msg.status == MessageStatus.sending) {
      return msg.status;
    }
    final sid = msg.serverId;
    if (sid != null && readReceipts.isNotEmpty) {
      for (final cursor in readReceipts.keys) {
        if (cursor >= sid) return MessageStatus.read;
      }
    }
    return msg.status;
  }

  ChatState copyWith({
    List<ChatMessage>? messages,
    bool? isLoadingInitial,
    bool? isLoadingMore,
    bool? isSending,
    bool? isRemoteTyping,
    bool? isConnected,
    bool? hasMore,
    bool? canSend,
    int? oldestServerId,
    Object? error = _kSentinel,
    Map<int, DateTime>? readReceipts,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      isLoadingInitial: isLoadingInitial ?? this.isLoadingInitial,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      isSending: isSending ?? this.isSending,
      isRemoteTyping: isRemoteTyping ?? this.isRemoteTyping,
      isConnected: isConnected ?? this.isConnected,
      hasMore: hasMore ?? this.hasMore,
      canSend: canSend ?? this.canSend,
      oldestServerId: oldestServerId ?? this.oldestServerId,
      error: identical(error, _kSentinel) ? this.error : error as String?,
      readReceipts: readReceipts ?? this.readReceipts,
    );
  }
}

const _kSentinel = Object();
