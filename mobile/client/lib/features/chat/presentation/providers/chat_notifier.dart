import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/error_handler.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/repositories/i_chat_repository.dart';
import 'chat_state.dart';

class ChatNotifier extends StateNotifier<ChatState> {
  final IChatRepository _repository;
  final bool _canSend;
  final String? _participantType;

  StreamSubscription<ChatMessage>? _msgSub;
  StreamSubscription<bool>? _typingSub;
  StreamSubscription<bool>? _connSub;
  StreamSubscription<int>? _readSub;

  static const _pageSize = 30;

  ChatNotifier(IChatRepository repository, {bool canSend = true, String? participantType})
      : _repository = repository,
        _canSend = canSend,
        _participantType = participantType,
        super(ChatState.initial.copyWith(canSend: canSend)) {
    _init();
  }

  Future<void> _init() async {
    _msgSub = _repository.messageStream.listen(_onIncoming);
    _typingSub = _repository.typingStream.listen(_onTyping);
    _connSub = _repository.connectionStream.listen(_onConnection);
    _readSub = _repository.readReceiptStream.listen(_onReadReceipt);

    await _repository.connectRealtime();
    await loadMessages();
  }

  void _onIncoming(ChatMessage incoming) {
    if (!mounted) return;
    final list = List<ChatMessage>.from(state.messages);

    final idx = list.indexWhere((m) => m.localId == incoming.localId);
    if (idx >= 0) {
      list[idx] = incoming;
    } else {
      if (incoming.serverId != null &&
          list.any((m) => m.serverId == incoming.serverId)) {
        return;
      }
      list.add(incoming);
    }

    list.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    state = state.copyWith(messages: List.unmodifiable(list));
  }

  void _onTyping(bool typing) {
    if (mounted) state = state.copyWith(isRemoteTyping: typing);
  }

  void _onConnection(bool connected) {
    if (mounted) state = state.copyWith(isConnected: connected);
  }

  void _onReadReceipt(int cursor) {
    if (!mounted || cursor <= 0) return;
    final updated = Map<int, DateTime>.from(state.readReceipts);
    updated[cursor] = DateTime.now();
    state = state.copyWith(readReceipts: Map.unmodifiable(updated));
  }

  Future<void> loadMessages() async {
    if (!mounted) return;
    state = state.copyWith(isLoadingInitial: true, error: null);
    try {
      final msgs = await _repository.fetchMessages(limit: _pageSize);
      final oldest = msgs.isNotEmpty ? msgs.first.serverId : null;
      state = state.copyWith(
        messages: List.unmodifiable(msgs),
        isLoadingInitial: false,
        hasMore: msgs.length >= _pageSize,
        oldestServerId: oldest,
      );
    } catch (e) {
      if (mounted) {
        state = state.copyWith(
          isLoadingInitial: false,
          error: ErrorHandler.getErrorMessage(e),
        );
      }
    }
  }

  Future<void> loadMore() async {
    if (!mounted) return;
    if (state.isLoadingMore || !state.hasMore || state.oldestServerId == null) return;

    state = state.copyWith(isLoadingMore: true);
    try {
      final older = await _repository.fetchMessages(
        before: state.oldestServerId,
        limit: _pageSize,
      );
      final merged = [...older, ...state.messages];
      state = state.copyWith(
        messages: List.unmodifiable(merged),
        isLoadingMore: false,
        hasMore: older.length >= _pageSize,
        oldestServerId: older.isNotEmpty ? older.first.serverId : state.oldestServerId,
      );
    } catch (_) {
      if (mounted) state = state.copyWith(isLoadingMore: false);
    }
  }

  Future<bool> sendMessage(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || !mounted) return false;

    if (!_canSend) {
      state = state.copyWith(error: 'Cette conversation est terminée.');
      return false;
    }

    final localId = '${DateTime.now().microsecondsSinceEpoch}';
    final optimistic = ChatMessage(
      localId: localId,
      message: trimmed,
      senderType: 'customer',
      senderId: 0,
      isMine: true,
      createdAt: DateTime.now(),
      status: MessageStatus.sending,
    );

    _onIncoming(optimistic);
    state = state.copyWith(isSending: true);

    try {
      final confirmed = await _repository.sendMessage(
        localId: localId,
        message: trimmed,
        target: _resolveTarget(_participantType),
      );
      _onIncoming(confirmed);
      return true;
    } catch (e) {
      _onIncoming(optimistic.copyWith(status: MessageStatus.failed));
      rethrow;
    } finally {
      if (mounted) state = state.copyWith(isSending: false);
    }
  }

  Future<void> retryFailed(ChatMessage failed) async {
    if (!mounted) return;
    final list = state.messages.where((m) => m.localId != failed.localId).toList();
    state = state.copyWith(messages: List.unmodifiable(list));
    try {
      await sendMessage(failed.message);
    } catch (_) {}
  }

  Future<void> markAsRead() async {
    try {
      final lastMsg = state.messages.lastWhere(
        (m) => m.serverId != null && !m.isMine,
        orElse: () => state.messages.last,
      );
      if (lastMsg.serverId != null) {
        await _repository.markAsRead(messageId: lastMsg.serverId!);
      }
    } catch (_) {}
  }

  void onTypingInput() => _repository.sendTyping();

  void clearError() {
    if (mounted) state = state.copyWith(error: null);
  }

  static String? _resolveTarget(String? participantType) {
    switch (participantType) {
      case 'courier':
        return 'courier';
      case 'pharmacy':
        return 'pharmacy';
      case null:
        return null;
      default:
        return 'all';
    }
  }

  @override
  void dispose() {
    _msgSub?.cancel();
    _typingSub?.cancel();
    _connSub?.cancel();
    _readSub?.cancel();
    _repository.dispose();
    super.dispose();
  }
}
