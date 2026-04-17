import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/orders/data/models/chat_message.dart';
import '../network/api_client.dart';
import '../../config/providers.dart';

/// Service de chat utilisant l'API HTTP (polling) au lieu de Firestore
/// Avantages: Pas de dépendance Firebase, fonctionne offline, plus simple
class ApiChatService {
  final ApiClient _apiClient;
  Timer? _pollingTimer;
  final _messagesController = StreamController<List<ChatMessage>>.broadcast();
  
  int? _currentDeliveryId;
  List<ChatMessage> _cachedMessages = [];
  DateTime? _lastFetchTime;

  ApiChatService(this._apiClient);

  /// Stream de messages (remplace Firestore snapshots)
  Stream<List<ChatMessage>> get messagesStream => _messagesController.stream;

  /// Démarre le polling pour une livraison
  void startPolling(int deliveryId, {Duration interval = const Duration(seconds: 3)}) {
    stopPolling();
    _currentDeliveryId = deliveryId;
    _cachedMessages = [];
    _lastFetchTime = null;
    
    // Fetch initial
    _fetchMessages();
    
    // Polling toutes les X secondes
    _pollingTimer = Timer.periodic(interval, (_) => _fetchMessages());
    debugPrint('🔄 [ApiChat] Started polling for delivery $deliveryId every ${interval.inSeconds}s');
  }

  /// Arrête le polling
  void stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
    _currentDeliveryId = null;
    debugPrint('🔄 [ApiChat] Stopped polling');
  }

  /// Récupère les messages depuis l'API
  Future<void> _fetchMessages() async {
    if (_currentDeliveryId == null) return;

    try {
      final response = await _apiClient.get(
        '/customer/deliveries/$_currentDeliveryId/chat',
        queryParameters: {
          if (_lastFetchTime != null) 'since': _lastFetchTime!.toIso8601String(),
        },
      );

      if (response.data['success'] == true) {
        final List<dynamic> data = response.data['data'] ?? [];
        final messages = data.map((json) => ChatMessage.fromJson(json)).toList();
        
        // Merge avec cache (nouveaux messages uniquement)
        if (_lastFetchTime != null) {
          // Ajouter les nouveaux messages
          for (final msg in messages) {
            if (!_cachedMessages.any((m) => m.id == msg.id)) {
              _cachedMessages.add(msg);
            }
          }
        } else {
          _cachedMessages = messages;
        }
        
        // Trier par date
        _cachedMessages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
        
        _lastFetchTime = DateTime.now();
        _messagesController.add(_cachedMessages);
        
        debugPrint('🔄 [ApiChat] Fetched ${messages.length} messages (total: ${_cachedMessages.length})');
      }
    } catch (e) {
      debugPrint('❌ [ApiChat] Error fetching messages: $e');
    }
  }

  /// Envoie un message
  Future<bool> sendMessage({
    required int deliveryId,
    required String content,
    required String target, // 'courier', 'pharmacy', 'all'
  }) async {
    try {
      final response = await _apiClient.post(
        '/customer/deliveries/$deliveryId/chat',
        data: {
          'message': content,
          'target': target,
        },
      );

      if (response.data['success'] == true) {
        debugPrint('✅ [ApiChat] Message sent successfully');
        // Force refresh immédiat
        await _fetchMessages();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('❌ [ApiChat] Error sending message: $e');
      return false;
    }
  }

  /// Marque tous les messages comme lus
  Future<void> markAllAsRead(int deliveryId) async {
    try {
      await _apiClient.post('/customer/deliveries/$deliveryId/chat/read');
      debugPrint('✅ [ApiChat] Messages marked as read');
    } catch (e) {
      debugPrint('❌ [ApiChat] Error marking as read: $e');
    }
  }

  /// Nombre de messages non lus
  Future<int> getUnreadCount(int deliveryId) async {
    try {
      final response = await _apiClient.get('/customer/deliveries/$deliveryId/chat/unread');
      return response.data['data']?['count'] ?? 0;
    } catch (e) {
      return 0;
    }
  }

  void dispose() {
    stopPolling();
    _messagesController.close();
  }
}

/// Provider pour le service de chat API
final apiChatServiceProvider = Provider<ApiChatService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return ApiChatService(apiClient);
});

/// Provider pour les messages d'un delivery spécifique
final apiChatMessagesProvider = StreamProvider.family<List<ChatMessage>, int>((ref, deliveryId) {
  final chatService = ref.watch(apiChatServiceProvider);
  chatService.startPolling(deliveryId);
  
  ref.onDispose(() {
    chatService.stopPolling();
  });
  
  return chatService.messagesStream;
});
