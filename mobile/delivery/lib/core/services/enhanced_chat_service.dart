import 'dart:async';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as path;
import '../../data/models/enhanced_chat_message.dart';
import '../../presentation/providers/delivery_providers.dart';

// ══════════════════════════════════════════════════════════════════════════════
// PROVIDERS
// ══════════════════════════════════════════════════════════════════════════════

/// Provider pour le service de chat enrichi
/// Auto-initialisé avec le profil du livreur
final enhancedChatServiceProvider = Provider<EnhancedChatService>((ref) {
  final service = EnhancedChatService();
  
  // Auto-initialiser dès que le profil est disponible
  final profileAsync = ref.watch(courierProfileProvider);
  profileAsync.whenData((profile) {
    service.initialize(
      courierId: profile.id,
      courierName: profile.name,
      courierAvatar: profile.avatar,
    );
  });
  
  return service;
});

/// Provider pour écouter les messages enrichis en temps réel
final enhancedMessagesProvider = StreamProvider.family<List<EnhancedChatMessage>, ({int orderId, String target})>((ref, args) {
  final service = ref.watch(enhancedChatServiceProvider);
  return service.watchMessages(args.orderId, args.target);
});

/// Provider pour les conversations actives
final activeConversationsProvider = StreamProvider<List<ChatConversation>>((ref) {
  final service = ref.watch(enhancedChatServiceProvider);
  return service.watchActiveConversations();
});

/// Provider pour l'indicateur de saisie
final typingStatusProvider = StreamProvider.family<TypingStatus?, ({int orderId, String target})>((ref, args) {
  final service = ref.watch(enhancedChatServiceProvider);
  return service.watchTypingStatus(args.orderId, args.target);
});

/// Provider pour le nombre total de messages non lus
final totalUnreadCountProvider = StreamProvider<int>((ref) {
  final service = ref.watch(enhancedChatServiceProvider);
  return service.watchTotalUnreadCount();
});

// ══════════════════════════════════════════════════════════════════════════════
// SERVICE DE CHAT ENRICHI
// ══════════════════════════════════════════════════════════════════════════════

/// Service de chat enrichi avec support pour :
/// - Messages texte, images, vocaux, localisation
/// - Indicateurs de saisie (typing)
/// - Accusés de lecture
/// - Réponses rapides
/// - Upload de médias
class EnhancedChatService {
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;
  
  int? _courierId;
  String? _courierName;
  String? _courierAvatar;
  
  Timer? _typingTimer;
  bool _isCurrentlyTyping = false;

  EnhancedChatService({
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _storage = storage ?? FirebaseStorage.instance;

  /// Initialiser le service avec les infos du livreur
  void initialize({
    required int courierId,
    required String courierName,
    String? courierAvatar,
  }) {
    _courierId = courierId;
    _courierName = courierName;
    _courierAvatar = courierAvatar;
    if (kDebugMode) debugPrint('💬 [EnhancedChat] Initialisé pour $courierName (#$courierId)');
  }

  /// Vérifier que le service est initialisé
  void _ensureInitialized() {
    if (_courierId == null) {
      throw Exception('EnhancedChatService non initialisé. Appelez initialize() d\'abord.');
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // RÉFÉRENCES FIRESTORE
  // ═══════════════════════════════════════════════════════════════════════════

  CollectionReference _messagesRef(int orderId) {
    return _firestore.collection('orders').doc(orderId.toString()).collection('messages');
  }

  CollectionReference get _typingRef {
    return _firestore.collection('typing_status');
  }

  DocumentReference _conversationRef(int orderId, String target) {
    return _firestore
        .collection('courier_conversations')
        .doc('$_courierId')
        .collection('conversations')
        .doc('${orderId}_$target');
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // MESSAGES
  // ═══════════════════════════════════════════════════════════════════════════

  /// Écouter les messages en temps réel
  Stream<List<EnhancedChatMessage>> watchMessages(int orderId, String target) {
    return _messagesRef(orderId)
        .where('target', whereIn: [target, 'all', 'courier'])
        .orderBy('created_at', descending: true)
        .limit(100)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return EnhancedChatMessage.fromJson(
              doc.data() as Map<String, dynamic>,
              doc.id,
            );
          }).toList();
        });
  }

  /// Envoyer un message texte
  Future<EnhancedChatMessage> sendTextMessage({
    required int orderId,
    required String content,
    required String target,
    String? replyToId,
    String? replyToContent,
  }) async {
    _ensureInitialized();

    final message = EnhancedChatMessage(
      id: '',
      content: content,
      type: MessageType.text,
      senderRole: SenderRole.courier,
      senderId: _courierId!,
      senderName: _courierName ?? 'Livreur',
      senderAvatar: _courierAvatar,
      target: target,
      status: MessageStatus.sending,
      createdAt: DateTime.now(),
      replyToId: replyToId,
      replyToContent: replyToContent,
    );

    try {
      final docRef = await _messagesRef(orderId).add(message.toJson());
      
      // Mettre à jour le statut à 'sent'
      await docRef.update({'status': MessageStatus.sent.value});
      
      // Mettre à jour la conversation
      await _updateConversation(orderId, target, message);
      
      // Arrêter l'indicateur de saisie
      await stopTyping(orderId, target);
      
      if (kDebugMode) debugPrint('📤 [EnhancedChat] Message texte envoyé');
      
      return message.copyWith(id: docRef.id, status: MessageStatus.sent);
    } catch (e) {
      if (kDebugMode) debugPrint('❌ [EnhancedChat] Erreur envoi message: $e');
      rethrow;
    }
  }

  /// Envoyer une image
  Future<EnhancedChatMessage> sendImageMessage({
    required int orderId,
    required File imageFile,
    required String target,
    String? caption,
  }) async {
    _ensureInitialized();

    try {
      // Upload de l'image
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${path.basename(imageFile.path)}';
      final ref = _storage.ref().child('chat_images/$orderId/$fileName');
      
      final uploadTask = await ref.putFile(imageFile);
      final imageUrl = await uploadTask.ref.getDownloadURL();
      
      // Générer une miniature (optionnel, pourrait être fait côté serveur)
      final thumbnailUrl = imageUrl; // Pour simplifier
      
      final message = EnhancedChatMessage(
        id: '',
        content: caption ?? '',
        type: MessageType.image,
        senderRole: SenderRole.courier,
        senderId: _courierId!,
        senderName: _courierName ?? 'Livreur',
        senderAvatar: _courierAvatar,
        target: target,
        status: MessageStatus.sending,
        createdAt: DateTime.now(),
        imageUrl: imageUrl,
        thumbnailUrl: thumbnailUrl,
      );

      final docRef = await _messagesRef(orderId).add(message.toJson());
      await docRef.update({'status': MessageStatus.sent.value});
      await _updateConversation(orderId, target, message);
      
      if (kDebugMode) debugPrint('📸 [EnhancedChat] Image envoyée');
      
      return message.copyWith(id: docRef.id, status: MessageStatus.sent);
    } catch (e) {
      if (kDebugMode) debugPrint('❌ [EnhancedChat] Erreur envoi image: $e');
      rethrow;
    }
  }

  /// Envoyer un message vocal
  Future<EnhancedChatMessage> sendVoiceMessage({
    required int orderId,
    required File audioFile,
    required Duration duration,
    required String target,
  }) async {
    _ensureInitialized();

    try {
      // Upload de l'audio
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_voice.m4a';
      final ref = _storage.ref().child('chat_voice/$orderId/$fileName');
      
      final uploadTask = await ref.putFile(audioFile);
      final audioUrl = await uploadTask.ref.getDownloadURL();
      
      final message = EnhancedChatMessage(
        id: '',
        content: 'Message vocal',
        type: MessageType.voice,
        senderRole: SenderRole.courier,
        senderId: _courierId!,
        senderName: _courierName ?? 'Livreur',
        senderAvatar: _courierAvatar,
        target: target,
        status: MessageStatus.sending,
        createdAt: DateTime.now(),
        audioUrl: audioUrl,
        audioDuration: duration,
      );

      final docRef = await _messagesRef(orderId).add(message.toJson());
      await docRef.update({'status': MessageStatus. sent.value});
      await _updateConversation(orderId, target, message);
      
      if (kDebugMode) debugPrint('🎤 [EnhancedChat] Message vocal envoyé');
      
      return message.copyWith(id: docRef.id, status: MessageStatus.sent);
    } catch (e) {
      if (kDebugMode) debugPrint('❌ [EnhancedChat] Erreur envoi vocal: $e');
      rethrow;
    }
  }

  /// Envoyer la localisation actuelle
  Future<EnhancedChatMessage> sendLocationMessage({
    required int orderId,
    required double latitude,
    required double longitude,
    required String target,
    String? address,
  }) async {
    _ensureInitialized();

    final message = EnhancedChatMessage(
      id: '',
      content: address ?? 'Ma position actuelle',
      type: MessageType.location,
      senderRole: SenderRole.courier,
      senderId: _courierId!,
      senderName: _courierName ?? 'Livreur',
      senderAvatar: _courierAvatar,
      target: target,
      status: MessageStatus.sending,
      createdAt: DateTime.now(),
      latitude: latitude,
      longitude: longitude,
      locationAddress: address,
    );

    try {
      final docRef = await _messagesRef(orderId).add(message.toJson());
      await docRef.update({'status': MessageStatus.sent.value});
      await _updateConversation(orderId, target, message);
      
      if (kDebugMode) debugPrint('📍 [EnhancedChat] Localisation envoyée');
      
      return message.copyWith(id: docRef.id, status: MessageStatus.sent);
    } catch (e) {
      if (kDebugMode) debugPrint('❌ [EnhancedChat] Erreur envoi localisation: $e');
      rethrow;
    }
  }

  /// Envoyer une réponse rapide
  Future<EnhancedChatMessage> sendQuickReply({
    required int orderId,
    required QuickReply quickReply,
    required String target,
  }) async {
    return sendTextMessage(
      orderId: orderId,
      content: quickReply.text,
      target: target,
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // INDICATEUR DE SAISIE
  // ═══════════════════════════════════════════════════════════════════════════

  /// Signaler que l'utilisateur est en train de taper
  Future<void> startTyping(int orderId, String target) async {
    _ensureInitialized();
    
    if (_isCurrentlyTyping) return;
    _isCurrentlyTyping = true;

    try {
      final docId = '${orderId}_${target}_$_courierId';
      await _typingRef.doc(docId).set({
        'order_id': orderId,
        'target': target,
        'sender_type': SenderRole.courier.value,
        'sender_id': _courierId,
        'sender_name': _courierName,
        'started_at': FieldValue.serverTimestamp(),
      });

      // Auto-stop après 5 secondes
      _typingTimer?.cancel();
      _typingTimer = Timer(const Duration(seconds: 5), () {
        stopTyping(orderId, target);
      });
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ [EnhancedChat] Erreur typing indicator: $e');
    }
  }

  /// Arrêter l'indicateur de saisie
  Future<void> stopTyping(int orderId, String target) async {
    if (!_isCurrentlyTyping) return;
    _isCurrentlyTyping = false;
    _typingTimer?.cancel();

    try {
      final docId = '${orderId}_${target}_$_courierId';
      await _typingRef.doc(docId).delete();
    } catch (e) {
      // Ignorer les erreurs de suppression
    }
  }

  /// Écouter l'indicateur de saisie de l'autre partie
  Stream<TypingStatus?> watchTypingStatus(int orderId, String target) {
    // On cherche si customer ou pharmacy tape
    final otherType = target == 'customer' ? 'customer' : 'pharmacy';
    
    return _typingRef
        .where('order_id', isEqualTo: orderId)
        .where('sender_type', isEqualTo: otherType)
        .snapshots()
        .map((snapshot) {
          if (snapshot.docs.isEmpty) return null;
          
          final doc = snapshot.docs.first;
          final status = TypingStatus.fromJson(
            doc.data() as Map<String, dynamic>,
            doc.id,
          );
          
          // Vérifier si expiré
          if (status.isExpired) return null;
          return status;
        });
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ACCUSÉS DE LECTURE
  // ═══════════════════════════════════════════════════════════════════════════

  /// Marquer les messages comme lus
  Future<void> markMessagesAsRead(int orderId, String target) async {
    try {
      final batch = _firestore.batch();
      
      // Trouver les messages non lus du client/pharmacie
      final unreadMessages = await _messagesRef(orderId)
          .where('sender_type', isNotEqualTo: 'courier')
          .where('status', whereIn: ['sent', 'delivered'])
          .get();

      for (final doc in unreadMessages.docs) {
        batch.update(doc.reference, {
          'status': MessageStatus.read.value,
          'read_at': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();
      
      // Mettre à jour le compteur de non lus de la conversation
      await _conversationRef(orderId, target).update({
        'unread_count': 0,
      });
      
      if (kDebugMode) debugPrint('✅ [EnhancedChat] ${unreadMessages.docs.length} messages marqués comme lus');
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ [EnhancedChat] Erreur marquage messages: $e');
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // CONVERSATIONS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Mettre à jour la conversation après envoi d'un message
  Future<void> _updateConversation(
    int orderId,
    String target,
    EnhancedChatMessage message,
  ) async {
    try {
      await _conversationRef(orderId, target).set({
        'order_id': orderId,
        'target': target,
        'last_message_content': message.content,
        'last_message_type': message.type.value,
        'last_message_time': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ [EnhancedChat] Erreur mise à jour conversation: $e');
    }
  }

  /// Écouter les conversations actives
  Stream<List<ChatConversation>> watchActiveConversations() {
    if (_courierId == null) return Stream.value([]);

    return _firestore
        .collection('courier_conversations')
        .doc('$_courierId')
        .collection('conversations')
        .orderBy('updated_at', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data();
            return ChatConversation(
              orderId: data['order_id'] ?? 0,
              target: data['target'] ?? '',
              targetName: data['target_name'] ?? (data['target'] == 'customer' ? 'Client' : 'Pharmacie'),
              targetAvatar: data['target_avatar'],
              unreadCount: data['unread_count'] ?? 0,
              updatedAt: data['updated_at'] is Timestamp
                  ? (data['updated_at'] as Timestamp).toDate()
                  : DateTime.now(),
            );
          }).toList();
        });
  }

  /// Écouter le nombre total de messages non lus
  Stream<int> watchTotalUnreadCount() {
    if (_courierId == null) return Stream.value(0);

    return _firestore
        .collection('courier_conversations')
        .doc('$_courierId')
        .collection('conversations')
        .snapshots()
        .map((snapshot) {
          int total = 0;
          for (final doc in snapshot.docs) {
            total += (doc.data()['unread_count'] ?? 0) as int;
          }
          return total;
        });
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // GESTION DES MESSAGES
  // ═══════════════════════════════════════════════════════════════════════════

  /// Supprimer un message
  Future<void> deleteMessage(int orderId, String target, String messageId) async {
    if (messageId.isEmpty) return;
    
    try {
      await _messagesRef(orderId).doc(messageId).delete();
      if (kDebugMode) debugPrint('🗑️ [EnhancedChat] Message supprimé: $messageId');
    } catch (e) {
      if (kDebugMode) debugPrint('❌ [EnhancedChat] Erreur suppression message: $e');
      rethrow;
    }
  }

  /// Effacer toute la conversation
  Future<void> clearConversation(int orderId, String target) async {
    try {
      final snapshot = await _messagesRef(orderId)
          .where('target', isEqualTo: target)
          .get();
      
      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
      
      // Mettre à jour le compteur de la conversation
      if (_courierId != null) {
        final convRef = _firestore
            .collection('courier_conversations')
            .doc('$_courierId')
            .collection('conversations')
            .doc('${orderId}_$target');
        await convRef.update({
          'unread_count': 0,
          'updated_at': FieldValue.serverTimestamp(),
        });
      }
      
      if (kDebugMode) debugPrint('🗑️ [EnhancedChat] Conversation effacée: $orderId - $target');
    } catch (e) {
      if (kDebugMode) debugPrint('❌ [EnhancedChat] Erreur effacement conversation: $e');
      rethrow;
    }
  }

  /// Signaler une conversation
  Future<void> reportConversation(int orderId, String target, String targetName) async {
    try {
      await _firestore.collection('reports').add({
        'type': 'chat_conversation',
        'order_id': orderId,
        'target': target,
        'target_name': targetName,
        'reporter_id': _courierId,
        'reporter_name': _courierName,
        'reporter_role': 'courier',
        'status': 'pending',
        'created_at': FieldValue.serverTimestamp(),
      });
      
      if (kDebugMode) debugPrint('🚨 [EnhancedChat] Conversation signalée: $orderId - $target');
    } catch (e) {
      if (kDebugMode) debugPrint('❌ [EnhancedChat] Erreur signalement: $e');
      // Ne pas relancer l'erreur pour le signalement - afficher un message de succès quand même
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // NETTOYAGE
  // ═══════════════════════════════════════════════════════════════════════════

  /// Nettoyer les ressources
  void dispose() {
    _typingTimer?.cancel();
  }
}
