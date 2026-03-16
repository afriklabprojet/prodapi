import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/chat_message.dart';

/// Provider pour le service de chat temps réel
final realtimeChatServiceProvider = Provider<RealtimeChatService>((ref) {
  return RealtimeChatService();
});

/// Provider pour écouter les messages en temps réel d'une commande
final realtimeMessagesProvider = StreamProvider.family<List<ChatMessage>, ({int orderId, String target})>((ref, args) {
  final service = ref.watch(realtimeChatServiceProvider);
  return service.watchMessages(args.orderId, args.target);
});

/// Provider pour le compteur de messages non lus
final unreadMessagesCountProvider = StreamProvider.family<int, int>((ref, orderId) {
  final service = ref.watch(realtimeChatServiceProvider);
  return service.watchUnreadCount(orderId);
});

/// Service de chat en temps réel utilisant Firestore
///
/// Structure Firestore :
/// ```
/// orders/{orderId}/messages/{messageId}
///   ├── content: String
///   ├── sender_type: String ('courier', 'customer', 'pharmacy')
///   ├── sender_id: int
///   ├── sender_name: String
///   ├── target: String ('customer', 'pharmacy')
///   ├── is_read: bool
///   ├── created_at: Timestamp
///   └── metadata: Map?
/// ```
class RealtimeChatService {
  final FirebaseFirestore _firestore;
  
  /// ID du livreur connecté
  int? _courierId;
  String? _courierName;

  RealtimeChatService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Initialiser le service avec les infos du livreur
  void initialize({required int courierId, required String courierName}) {
    _courierId = courierId;
    _courierName = courierName;
    if (kDebugMode) debugPrint('💬 [RealtimeChat] Initialisé pour livreur #$courierId');
  }

  /// Référence à la collection des messages d'une commande
  CollectionReference _messagesRef(int orderId) {
    return _firestore.collection('orders').doc(orderId.toString()).collection('messages');
  }

  /// Écouter les messages en temps réel
  Stream<List<ChatMessage>> watchMessages(int orderId, String target) {
    return _messagesRef(orderId)
        .where('target', whereIn: [target, 'all'])
        .orderBy('created_at', descending: true)
        .limit(100)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return ChatMessage(
              id: int.tryParse(doc.id) ?? doc.id.hashCode,
              content: data['content'] ?? '',
              senderName: data['sender_name'] ?? '',
              isMe: data['sender_type'] == 'courier' && data['sender_id'] == _courierId,
              createdAt: (data['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
            );
          }).toList();
        });
  }

  /// Écouter le nombre de messages non lus
  Stream<int> watchUnreadCount(int orderId) {
    return _messagesRef(orderId)
        .where('sender_type', isNotEqualTo: 'courier')
        .where('is_read', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  /// Envoyer un message via Firestore (pour mise à jour temps réel)
  Future<void> sendMessageToFirestore({
    required int orderId,
    required String content,
    required String target,
  }) async {
    if (_courierId == null) {
      throw Exception('Service non initialisé. Appelez initialize() d\'abord.');
    }

    try {
      await _messagesRef(orderId).add({
        'content': content,
        'sender_type': 'courier',
        'sender_id': _courierId,
        'sender_name': _courierName ?? 'Livreur',
        'target': target,
        'is_read': false,
        'created_at': FieldValue.serverTimestamp(),
      });
      
      if (kDebugMode) debugPrint('📤 [RealtimeChat] Message envoyé pour commande #$orderId');
    } catch (e) {
      if (kDebugMode) debugPrint('❌ [RealtimeChat] Erreur envoi message: $e');
      rethrow;
    }
  }

  /// Marquer les messages comme lus
  Future<void> markMessagesAsRead(int orderId, String target) async {
    try {
      final batch = _firestore.batch();
      final unreadMessages = await _messagesRef(orderId)
          .where('target', isEqualTo: target)
          .where('sender_type', isNotEqualTo: 'courier')
          .where('is_read', isEqualTo: false)
          .get();

      for (final doc in unreadMessages.docs) {
        batch.update(doc.reference, {'is_read': true});
      }

      await batch.commit();
      if (kDebugMode) debugPrint('✅ [RealtimeChat] ${unreadMessages.docs.length} messages marqués comme lus');
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ [RealtimeChat] Erreur marquage messages: $e');
    }
  }

  /// Écouter les notifications de nouveaux messages (toutes commandes)
  Stream<QuerySnapshot> watchAllNewMessages() {
    if (_courierId == null) return const Stream.empty();
    
    return _firestore
        .collectionGroup('messages')
        .where('sender_type', isNotEqualTo: 'courier')
        .where('is_read', isEqualTo: false)
        .orderBy('sender_type')
        .orderBy('created_at', descending: true)
        .limit(50)
        .snapshots();
  }
}
