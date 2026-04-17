import 'dart:async';

import '../../domain/entities/chat_message.dart';
import '../../domain/repositories/i_chat_repository.dart';
import '../datasources/chat_api_datasource.dart';
import '../datasources/chat_realtime_datasource.dart';

/// Combines [ChatApiDatasource] (HTTP) with an optional [ChatRealtimeDatasource]
/// (Pusher WebSocket). Falls back to delta-polling when WebSocket is unavailable.
class ChatRepositoryImpl implements IChatRepository {
  final ChatApiDatasource _api;
  final ChatRealtimeDatasource? _realtime;

  final _msgCtrl = StreamController<ChatMessage>.broadcast();
  final _typingCtrl = StreamController<bool>.broadcast();
  final _connCtrl = StreamController<bool>.broadcast();
  final _readCtrl = StreamController<int>.broadcast();

  @override
  Stream<ChatMessage> get messageStream => _msgCtrl.stream;
  @override
  Stream<bool> get typingStream => _typingCtrl.stream;
  @override
  Stream<bool> get connectionStream => _connCtrl.stream;
  @override
  Stream<int> get readReceiptStream => _readCtrl.stream;

  StreamSubscription<ChatMessage>? _realtimeMsgSub;
  StreamSubscription<bool>? _realtimeTypingSub;
  StreamSubscription<bool>? _realtimeConnSub;
  StreamSubscription<int>? _realtimeReadSub;

  Timer? _pollTimer;
  int _lastServerId = 0;
  bool _disposed = false;

  final _offlineQueue = <_QueuedMessage>[];

  static const _pollInterval = Duration(seconds: 5);

  ChatRepositoryImpl({
    required ChatApiDatasource api,
    ChatRealtimeDatasource? realtime,
  })  : _api = api,
        _realtime = realtime;

  // ── IChatRepository ────────────────────────────────────────────────────────

  @override
  Future<void> connectRealtime() async {
    if (_realtime == null) {
      _emitConn(false);
      _startPolling();
      return;
    }

    try {
      await _realtime.connect();

      _realtimeMsgSub = _realtime.messageStream.listen((msg) {
        if (!_msgCtrl.isClosed) _msgCtrl.add(msg);
      });
      _realtimeTypingSub = _realtime.typingStream.listen((t) {
        if (!_typingCtrl.isClosed) _typingCtrl.add(t);
      });
      _realtimeConnSub = _realtime.connectionStream.listen((connected) {
        _emitConn(connected);
        if (!connected) {
          _startPolling();
        } else {
          _stopPolling();
          _flushOfflineQueue();
        }
      });
      _realtimeReadSub = _realtime.readReceiptStream.listen((cursor) {
        if (!_readCtrl.isClosed) _readCtrl.add(cursor);
      });
    } catch (_) {
      _emitConn(false);
      _startPolling();
    }
  }

  @override
  Future<List<ChatMessage>> fetchMessages({int? before, int limit = 30}) =>
      _api.fetchMessages(before: before, limit: limit);

  @override
  Future<ChatMessage> sendMessage({
    required String localId,
    required String message,
    String? target,
  }) async {
    try {
      final result = await _api.sendMessage(
        localId: localId,
        message: message,
        target: target,
      );
      _flushOfflineQueue();
      return result;
    } catch (e) {
      if (_pollTimer != null) {
        _offlineQueue.add(_QueuedMessage(localId: localId, message: message, target: target));
        rethrow;
      }
      rethrow;
    }
  }

  @override
  Future<void> markAsRead({required int messageId}) =>
      _api.markAsRead(messageId: messageId);

  @override
  void sendTyping() => _realtime?.sendTyping();

  @override
  Future<void> dispose() async {
    _disposed = true;
    _stopPolling();
    _realtimeMsgSub?.cancel();
    _realtimeTypingSub?.cancel();
    _realtimeConnSub?.cancel();
    _realtimeReadSub?.cancel();
    await _realtime?.dispose();
    _msgCtrl.close();
    _typingCtrl.close();
    _connCtrl.close();
    _readCtrl.close();
  }

  // ── Polling ────────────────────────────────────────────────────────────────

  void _startPolling() {
    if (_pollTimer != null || _disposed) return;
    _pollTimer = Timer.periodic(_pollInterval, (_) => _poll());
  }

  void _stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  Future<void> _poll() async {
    if (_disposed) return;
    try {
      final messages = await _api.fetchMessages(before: null, limit: 20);
      for (final msg in messages) {
        final id = msg.serverId;
        if (id != null && id > _lastServerId) {
          _lastServerId = id;
          if (!_msgCtrl.isClosed) _msgCtrl.add(msg);
        }
      }
    } catch (_) {}
  }

  Future<void> _flushOfflineQueue() async {
    while (_offlineQueue.isNotEmpty) {
      final queued = _offlineQueue.removeAt(0);
      try {
        await _api.sendMessage(
          localId: queued.localId,
          message: queued.message,
          target: queued.target,
        );
      } catch (_) {
        _offlineQueue.insert(0, queued);
        break;
      }
    }
  }

  void _emitConn(bool connected) {
    if (!_connCtrl.isClosed) _connCtrl.add(connected);
  }
}

class _QueuedMessage {
  final String localId;
  final String message;
  final String? target;
  _QueuedMessage({required this.localId, required this.message, this.target});
}
