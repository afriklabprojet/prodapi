import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../config/providers.dart';
import '../../../../core/config/pusher_config.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/services/secure_storage_service.dart';
import '../../data/datasources/chat_api_datasource.dart';
import '../../data/datasources/chat_realtime_datasource.dart';
import '../../data/repositories/chat_repository_impl.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/repositories/i_chat_repository.dart';
import 'chat_notifier.dart';
import 'chat_state.dart';

// ── ChatParams ─────────────────────────────────────────────────────────────

@immutable
class ChatParams {
  final int? deliveryId;
  final int orderId;
  final bool canSend;
  final String participantType;
  final int participantId;
  final String participantName;
  final String? participantPhone;

  const ChatParams({
    this.deliveryId,
    required this.orderId,
    this.canSend = true,
    required this.participantType,
    required this.participantId,
    required this.participantName,
    this.participantPhone,
  });

  /// Clé unique pour le provider family.
  /// Format: 'delivery-{id}' si deliveryId existe, sinon 'order-{id}'
  String get familyKey => deliveryId != null 
      ? 'delivery-$deliveryId' 
      : 'order-$orderId';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChatParams &&
          runtimeType == other.runtimeType &&
          deliveryId == other.deliveryId &&
          orderId == other.orderId &&
          participantType == other.participantType &&
          participantId == other.participantId;

  @override
  int get hashCode => Object.hash(deliveryId, orderId, participantType, participantId);
}

// ── Per-chat Repository Provider ───────────────────────────────────────────

final _chatRepoProvider =
    Provider.family<IChatRepository, String>((ref, familyKey) {
  final apiClient = ref.watch(apiClientProvider);

  int? deliveryId;
  int? orderId;
  
  // Parse la clé pour déterminer si c'est une livraison ou une commande
  if (familyKey.startsWith('delivery-')) {
    deliveryId = int.tryParse(familyKey.replaceFirst('delivery-', ''));
  } else if (familyKey.startsWith('order-')) {
    orderId = int.tryParse(familyKey.replaceFirst('order-', ''));
  }

  final api = ChatApiDatasource(
    apiClient: apiClient,
    deliveryId: deliveryId,
    orderId: orderId,
  );

  late final IChatRepository repo;

  if (PusherConfig.pusherEnabled && deliveryId != null) {
    final currentUserId = ref.read(currentUserProvider)?.id;
    repo = _LazyRealtimeRepository(
      api: api,
      deliveryId: deliveryId,
      tokenFuture: SecureStorageService.getToken(),
      currentUserId: currentUserId,
    );
  } else {
    repo = ChatRepositoryImpl(api: api);
  }

  ref.onDispose(() => repo.dispose());
  return repo;
});

// ── ChatNotifier Provider ──────────────────────────────────────────────────

final chatNotifierProvider =
    StateNotifierProvider.family<ChatNotifier, ChatState, ChatParams>(
  (ref, params) {
    final repo = ref.watch(_chatRepoProvider(params.familyKey));
    return ChatNotifier(repo, canSend: params.canSend, participantType: params.participantType);
  },
);

// ── LazyRealtimeRepository ─────────────────────────────────────────────────

class _LazyRealtimeRepository implements IChatRepository {
  final ChatApiDatasource _api;
  final int _deliveryId;
  final Future<String?> _tokenFuture;
  final int? _currentUserId;

  final _msgRelay = StreamController<ChatMessage>.broadcast();
  final _typingRelay = StreamController<bool>.broadcast();
  final _connRelay = StreamController<bool>.broadcast();
  final _readRelay = StreamController<int>.broadcast();

  ChatRepositoryImpl? _inner;
  StreamSubscription<ChatMessage>? _msgSub;
  StreamSubscription<bool>? _typingSub;
  StreamSubscription<bool>? _connSub;
  StreamSubscription<int>? _readSub;

  _LazyRealtimeRepository({
    required ChatApiDatasource api,
    required int deliveryId,
    required Future<String?> tokenFuture,
    int? currentUserId,
  })  : _api = api,
        _deliveryId = deliveryId,
        _tokenFuture = tokenFuture,
        _currentUserId = currentUserId;

  @override
  Stream<ChatMessage> get messageStream => _msgRelay.stream;
  @override
  Stream<bool> get typingStream => _typingRelay.stream;
  @override
  Stream<bool> get connectionStream => _connRelay.stream;
  @override
  Stream<int> get readReceiptStream => _readRelay.stream;

  @override
  Future<void> connectRealtime() async {
    final token = await _tokenFuture;

    ChatRealtimeDatasource? realtime;
    if (token != null && token.isNotEmpty) {
      realtime = ChatRealtimeDatasource(
        deliveryId: _deliveryId,
        authToken: token,
        currentUserId: _currentUserId,
      );
    }

    _inner = ChatRepositoryImpl(api: _api, realtime: realtime);

    _msgSub = _inner!.messageStream.listen((m) {
      if (!_msgRelay.isClosed) _msgRelay.add(m);
    });
    _typingSub = _inner!.typingStream.listen((t) {
      if (!_typingRelay.isClosed) _typingRelay.add(t);
    });
    _connSub = _inner!.connectionStream.listen((c) {
      if (!_connRelay.isClosed) _connRelay.add(c);
    });
    _readSub = _inner!.readReceiptStream.listen((r) {
      if (!_readRelay.isClosed) _readRelay.add(r);
    });

    await _inner!.connectRealtime();
  }

  @override
  Future<List<ChatMessage>> fetchMessages({int? before, int limit = 30}) {
    if (_inner != null) return _inner!.fetchMessages(before: before, limit: limit);
    return _api.fetchMessages(before: before, limit: limit);
  }

  @override
  Future<ChatMessage> sendMessage({required String localId, required String message, String? target}) {
    if (_inner == null) throw StateError('connectRealtime() not called yet');
    return _inner!.sendMessage(localId: localId, message: message, target: target);
  }

  @override
  Future<void> markAsRead({required int messageId}) {
    if (_inner == null) throw StateError('connectRealtime() not called yet');
    return _inner!.markAsRead(messageId: messageId);
  }

  @override
  void sendTyping() => _inner?.sendTyping();

  @override
  Future<void> dispose() async {
    _msgSub?.cancel();
    _typingSub?.cancel();
    _connSub?.cancel();
    _readSub?.cancel();
    await _inner?.dispose();
    _msgRelay.close();
    _typingRelay.close();
    _connRelay.close();
    _readRelay.close();
  }
}
