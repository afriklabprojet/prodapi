import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:pusher_channels_flutter/pusher_channels_flutter.dart';

import '../../../../core/config/pusher_config.dart';
import '../../../../core/constants/api_constants.dart';
import '../../domain/entities/chat_message.dart';
import '../models/chat_message_model.dart';

class ChatRealtimeDatasource {
  final int deliveryId;
  final String authToken;
  final int? currentUserId;

  PusherChannelsFlutter? _pusher;
  bool _disposed = false;

  final _messageController = StreamController<ChatMessage>.broadcast();
  final _typingController = StreamController<bool>.broadcast();
  final _connectionController = StreamController<bool>.broadcast();
  final _readReceiptController = StreamController<int>.broadcast();

  Timer? _typingResetTimer;

  Stream<ChatMessage> get messageStream => _messageController.stream;
  Stream<bool> get typingStream => _typingController.stream;
  Stream<bool> get connectionStream => _connectionController.stream;
  Stream<int> get readReceiptStream => _readReceiptController.stream;

  ChatRealtimeDatasource({
    required this.deliveryId,
    required this.authToken,
    this.currentUserId,
  });

  String get _channelName => 'private-delivery.$deliveryId.chat';
  String get _authEndpoint => '${ApiConstants.baseUrl}/broadcasting/auth';

  Future<void> connect() async {
    if (_disposed || PusherConfig.pusherKey.isEmpty) return;
    try {
      _pusher = PusherChannelsFlutter.getInstance();
      await _pusher!.init(
        apiKey: PusherConfig.pusherKey,
        cluster: PusherConfig.pusherCluster,
        onConnectionStateChange: _onConnectionStateChange,
        onError: (m, c, e) => debugPrint('⚠️ Pusher error: $m ($c)'),
        onAuthorizer: _authorizeChannel,
      );
      await _pusher!.connect();
      await _pusher!.subscribe(
        channelName: _channelName,
        onEvent: _onEvent,
      );
    } catch (e) {
      debugPrint('❌ [ChatRealtime-Client] connect error: $e');
    }
  }

  Future<Map<String, String>> _authorizeChannel(
      String channelName, String socketId, dynamic options) async {
    try {
      final dio = Dio();
      final resp = await dio.post(
        _authEndpoint,
        data: {'socket_id': socketId, 'channel_name': channelName},
        options: Options(headers: {
          'Authorization': 'Bearer $authToken',
          'Accept': 'application/json',
        }),
      );
      final data = resp.data is String ? jsonDecode(resp.data) : resp.data;
      return {
        'auth': data['auth']?.toString() ?? '',
        'channel_data': data['channel_data']?.toString() ?? '',
      };
    } catch (e) {
      debugPrint('❌ [ChatRealtime-Client] authorizeChannel error: $e');
      return {};
    }
  }

  void _onConnectionStateChange(dynamic current, dynamic previous) {
    final connected = current?.toString() == 'CONNECTED';
    if (!_connectionController.isClosed) _connectionController.add(connected);
  }

  void _onEvent(PusherEvent event) {
    if (_disposed) return;
    final name = event.eventName;
    if (name.contains('MessageSent') || name.contains('message.sent')) {
      _handleMessageEvent(event);
    } else if (name.contains('UserTyping') || name.contains('user.typing')) {
      _handleTypingEvent(event);
    } else if (name.contains('MessageRead') || name.contains('message.read')) {
      _handleReadEvent(event);
    }
  }

  void _handleMessageEvent(PusherEvent event) {
    try {
      final data = jsonDecode(event.data ?? '{}') as Map<String, dynamic>;
      final msgData = data['message'] ?? data;
      final flat = ChatMessageModel.flattenSender(msgData.cast<String, dynamic>());

      final senderType = flat['sender_type']?.toString() ?? '';
      final senderId = flat['sender_id'] is int
          ? flat['sender_id']
          : int.tryParse('${flat['sender_id']}') ?? 0;
      final isMine = senderType == 'customer' || senderId == currentUserId;
      flat['is_mine'] = isMine;

      final model = ChatMessageModel.fromJson(flat);
      if (!_messageController.isClosed) _messageController.add(model.toEntity());
    } catch (e) {
      debugPrint('❌ [ChatRealtime-Client] handleMessageEvent error: $e');
    }
  }

  void _handleTypingEvent(PusherEvent event) {
    try {
      final data = jsonDecode(event.data ?? '{}') as Map<String, dynamic>;
      final typerType = data['sender_type']?.toString() ?? data['user_type']?.toString() ?? '';
      if (typerType == 'customer') return;
      if (!_typingController.isClosed) _typingController.add(true);
      _typingResetTimer?.cancel();
      _typingResetTimer = Timer(const Duration(seconds: 3), () {
        if (!_typingController.isClosed) _typingController.add(false);
      });
    } catch (_) {}
  }

  void _handleReadEvent(PusherEvent event) {
    try {
      final data = jsonDecode(event.data ?? '{}') as Map<String, dynamic>;
      final cursor = data['last_read_id'] ?? data['message_id'];
      if (cursor is int && !_readReceiptController.isClosed) {
        _readReceiptController.add(cursor);
      }
    } catch (_) {}
  }

  void sendTyping() {
    try {
      _pusher?.trigger(PusherEvent(
        channelName: _channelName,
        eventName: 'client-typing',
        data: jsonEncode({'sender_type': 'customer'}),
      ));
    } catch (_) {}
  }

  Future<void> dispose() async {
    _disposed = true;
    _typingResetTimer?.cancel();
    try {
      await _pusher?.unsubscribe(channelName: _channelName);
      await _pusher?.disconnect();
    } catch (_) {}
    _messageController.close();
    _typingController.close();
    _connectionController.close();
    _readReceiptController.close();
  }
}
