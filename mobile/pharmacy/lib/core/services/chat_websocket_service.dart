import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as ws_status;
import '../config/env_config.dart';
import '../../../features/auth/data/datasources/auth_local_datasource.dart';

// ==================== LOGGING HELPER ====================

void _log(String message, {String emoji = '💬'}) {
  if (kDebugMode) debugPrint('$emoji [ChatWS] $message');
}

void _logError(String message, Object error) {
  if (kDebugMode) debugPrint('❌ [ChatWS] $message: $error');
}

/// États de connexion WebSocket
enum WebSocketState {
  disconnected,
  connecting,
  connected,
  reconnecting,
  error,
}

/// Message WebSocket typé
class ChatWebSocketMessage {
  final String type; // 'message', 'typing', 'read', 'ping', 'pong'
  final int? deliveryId;
  final int? senderId;
  final String? senderType;
  final String? content;
  final DateTime? timestamp;
  final Map<String, dynamic>? data;

  ChatWebSocketMessage({
    required this.type,
    this.deliveryId,
    this.senderId,
    this.senderType,
    this.content,
    this.timestamp,
    this.data,
  });

  factory ChatWebSocketMessage.fromJson(Map<String, dynamic> json) {
    return ChatWebSocketMessage(
      type: json['type'] ?? 'message',
      deliveryId: json['delivery_id'],
      senderId: json['sender_id'],
      senderType: json['sender_type'],
      content: json['content'],
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp'])
          : null,
      data: json['data'],
    );
  }

  Map<String, dynamic> toJson() => {
    'type': type,
    if (deliveryId != null) 'delivery_id': deliveryId,
    if (senderId != null) 'sender_id': senderId,
    if (senderType != null) 'sender_type': senderType,
    if (content != null) 'content': content,
    if (timestamp != null) 'timestamp': timestamp!.toIso8601String(),
    if (data != null) 'data': data,
  };
}

/// Service WebSocket pour le chat temps réel
/// Remplace le polling 15s par une connexion persistante
class ChatWebSocketService {
  static ChatWebSocketService? _instance;
  static ChatWebSocketService get instance => _instance ??= ChatWebSocketService._();

  ChatWebSocketService._();

  WebSocketChannel? _channel;
  StreamSubscription? _subscription;
  Timer? _pingTimer;
  Timer? _reconnectTimer;
  
  WebSocketState _state = WebSocketState.disconnected;
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 5;
  static const Duration _reconnectDelay = Duration(seconds: 3);
  static const Duration _pingInterval = Duration(seconds: 30);
  
  final _stateController = StreamController<WebSocketState>.broadcast();
  final _messageController = StreamController<ChatWebSocketMessage>.broadcast();
  
  /// Stream d'état de connexion
  Stream<WebSocketState> get stateStream => _stateController.stream;
  
  /// Stream de messages entrants
  Stream<ChatWebSocketMessage> get messageStream => _messageController.stream;
  
  /// État actuel
  WebSocketState get state => _state;
  
  /// Vérifie si connecté
  bool get isConnected => _state == WebSocketState.connected;

  /// Connecte au WebSocket
  Future<bool> connect() async {
    if (_state == WebSocketState.connecting || _state == WebSocketState.connected) {
      return _state == WebSocketState.connected;
    }
    
    _setState(WebSocketState.connecting);
    
    try {
      final token = await AuthLocalDataSourceImpl().getToken();
      if (token == null) {
        _log('No auth token', emoji: '❌');
        _setState(WebSocketState.error);
        return false;
      }
      
      // Construire l'URL WebSocket depuis l'API base URL
      final baseUrl = EnvConfig.apiBaseUrl;
      final wsUrl = baseUrl
          .replaceFirst('https://', 'wss://')
          .replaceFirst('http://', 'ws://')
          .replaceFirst('/api', '/ws/chat');
      
      final uri = Uri.parse('$wsUrl?token=$token');
      
      _log('Connecting to $wsUrl', emoji: '🔌');
      
      _channel = WebSocketChannel.connect(uri);
      
      // Attendre la connexion
      await _channel!.ready;
      
      _subscription = _channel!.stream.listen(
        _onMessage,
        onError: _onError,
        onDone: _onDone,
      );
      
      _setState(WebSocketState.connected);
      _reconnectAttempts = 0;
      _startPingTimer();
      
      _log('Connected', emoji: '✅');
      return true;
      
    } catch (e) {
      _logError('Connection failed', e);
      _setState(WebSocketState.error);
      _scheduleReconnect();
      return false;
    }
  }

  /// Déconnecte proprement
  Future<void> disconnect() async {
    _cancelTimers();
    _reconnectAttempts = _maxReconnectAttempts; // Empêcher la reconnexion
    
    await _subscription?.cancel();
    _subscription = null;
    
    await _channel?.sink.close(ws_status.goingAway);
    _channel = null;
    
    _setState(WebSocketState.disconnected);
    _log('Disconnected', emoji: '🔌');
  }

  /// Envoie un message
  void sendMessage({
    required int deliveryId,
    required String receiverType,
    required int receiverId,
    required String message,
  }) {
    if (!isConnected) {
      _log('Not connected, cannot send', emoji: '⚠️');
      return;
    }
    
    final payload = ChatWebSocketMessage(
      type: 'message',
      deliveryId: deliveryId,
      content: message,
      data: {
        'receiver_type': receiverType,
        'receiver_id': receiverId,
      },
    );
    
    _send(payload);
  }

  /// Envoie un indicateur de frappe
  void sendTyping({required int deliveryId}) {
    if (!isConnected) return;
    _send(ChatWebSocketMessage(type: 'typing', deliveryId: deliveryId));
  }

  /// Marque les messages comme lus
  void sendRead({
    required int deliveryId,
    required String participantType,
    required int participantId,
  }) {
    if (!isConnected) return;
    
    _send(ChatWebSocketMessage(
      type: 'read',
      deliveryId: deliveryId,
      data: {
        'participant_type': participantType,
        'participant_id': participantId,
      },
    ));
  }

  /// S'abonne à une conversation spécifique
  void subscribe({required int deliveryId}) {
    if (!isConnected) return;
    _send(ChatWebSocketMessage(type: 'subscribe', deliveryId: deliveryId));
  }

  /// Se désabonne d'une conversation
  void unsubscribe({required int deliveryId}) {
    if (!isConnected) return;
    _send(ChatWebSocketMessage(type: 'unsubscribe', deliveryId: deliveryId));
  }

  void _send(ChatWebSocketMessage message) {
    try {
      _channel?.sink.add(jsonEncode(message.toJson()));
    } catch (e) {
      _logError('Send error', e);
    }
  }

  void _onMessage(dynamic data) {
    try {
      final json = jsonDecode(data as String) as Map<String, dynamic>;
      final message = ChatWebSocketMessage.fromJson(json);
      
      // Gérer le pong silencieusement
      if (message.type == 'pong') return;
      
      _messageController.add(message);
      
      _log('Received: ${message.type}', emoji: '📨');
    } catch (e) {
      _logError('Parse error', e);
    }
  }

  void _onError(dynamic error) {
    _logError('Error', error);
    _setState(WebSocketState.error);
    _scheduleReconnect();
  }

  void _onDone() {
    _log('Connection closed', emoji: '🔌');
    _setState(WebSocketState.disconnected);
    _scheduleReconnect();
  }

  void _setState(WebSocketState state) {
    _state = state;
    _stateController.add(state);
  }

  void _startPingTimer() {
    _pingTimer?.cancel();
    _pingTimer = Timer.periodic(_pingInterval, (_) {
      if (isConnected) {
        _send(ChatWebSocketMessage(type: 'ping'));
      }
    });
  }

  void _scheduleReconnect() {
    if (_reconnectAttempts >= _maxReconnectAttempts) {
      _log('Max reconnect attempts reached', emoji: '❌');
      return;
    }
    
    _cancelTimers();
    _setState(WebSocketState.reconnecting);
    
    final delay = _reconnectDelay * (1 << _reconnectAttempts); // Backoff exponentiel
    _reconnectAttempts++;
    
    _log('Reconnecting in ${delay.inSeconds}s (attempt $_reconnectAttempts)', emoji: '🔄');
    
    _reconnectTimer = Timer(delay, () {
      connect();
    });
  }

  void _cancelTimers() {
    _pingTimer?.cancel();
    _pingTimer = null;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
  }

  /// Libère les ressources
  void dispose() {
    _cancelTimers();
    _subscription?.cancel();
    _channel?.sink.close();
    _stateController.close();
    _messageController.close();
    _instance = null;
  }
}
