import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// ══════════════════════════════════════════════════════════════════════════════
// MODÈLES DE CHAT ENRICHIS
// ══════════════════════════════════════════════════════════════════════════════

/// Types de messages supportés
enum MessageType {
  text,
  image,
  voice,
  location,
  quickReply,
  system,
}

extension MessageTypeExtension on MessageType {
  String get value {
    switch (this) {
      case MessageType.text:
        return 'text';
      case MessageType.image:
        return 'image';
      case MessageType.voice:
        return 'voice';
      case MessageType.location:
        return 'location';
      case MessageType.quickReply:
        return 'quick_reply';
      case MessageType.system:
        return 'system';
    }
  }

  static MessageType fromString(String value) {
    switch (value) {
      case 'image':
        return MessageType.image;
      case 'voice':
        return MessageType.voice;
      case 'location':
        return MessageType.location;
      case 'quick_reply':
        return MessageType.quickReply;
      case 'system':
        return MessageType.system;
      default:
        return MessageType.text;
    }
  }
}

/// Statut de lecture du message
enum MessageStatus {
  sending,
  sent,
  delivered,
  read,
  failed,
}

extension MessageStatusExtension on MessageStatus {
  String get value {
    switch (this) {
      case MessageStatus.sending:
        return 'sending';
      case MessageStatus.sent:
        return 'sent';
      case MessageStatus.delivered:
        return 'delivered';
      case MessageStatus.read:
        return 'read';
      case MessageStatus.failed:
        return 'failed';
    }
  }

  static MessageStatus fromString(String value) {
    switch (value) {
      case 'sent':
        return MessageStatus.sent;
      case 'delivered':
        return MessageStatus.delivered;
      case 'read':
        return MessageStatus.read;
      case 'failed':
        return MessageStatus.failed;
      default:
        return MessageStatus.sending;
    }
  }

  IconData get icon {
    switch (this) {
      case MessageStatus.sending:
        return Icons.schedule;
      case MessageStatus.sent:
        return Icons.check;
      case MessageStatus.delivered:
        return Icons.done_all;
      case MessageStatus.read:
        return Icons.done_all;
      case MessageStatus.failed:
        return Icons.error_outline;
    }
  }

  Color get color {
    switch (this) {
      case MessageStatus.sending:
        return Colors.grey;
      case MessageStatus.sent:
        return Colors.grey;
      case MessageStatus.delivered:
        return Colors.grey;
      case MessageStatus.read:
        return Colors.blue;
      case MessageStatus.failed:
        return Colors.red;
    }
  }
}

/// Rôle de l'expéditeur
enum SenderRole {
  courier,
  customer,
  pharmacy,
  system,
}

extension SenderRoleExtension on SenderRole {
  String get value {
    switch (this) {
      case SenderRole.courier:
        return 'courier';
      case SenderRole.customer:
        return 'customer';
      case SenderRole.pharmacy:
        return 'pharmacy';
      case SenderRole.system:
        return 'system';
    }
  }

  static SenderRole fromString(String value) {
    switch (value) {
      case 'customer':
        return SenderRole.customer;
      case 'pharmacy':
        return SenderRole.pharmacy;
      case 'system':
        return SenderRole.system;
      default:
        return SenderRole.courier;
    }
  }

  String get label {
    switch (this) {
      case SenderRole.courier:
        return 'Livreur';
      case SenderRole.customer:
        return 'Client';
      case SenderRole.pharmacy:
        return 'Pharmacie';
      case SenderRole.system:
        return 'Système';
    }
  }

  Color get color {
    switch (this) {
      case SenderRole.courier:
        return Colors.blue;
      case SenderRole.customer:
        return Colors.green;
      case SenderRole.pharmacy:
        return Colors.orange;
      case SenderRole.system:
        return Colors.grey;
    }
  }

  IconData get icon {
    switch (this) {
      case SenderRole.courier:
        return Icons.delivery_dining;
      case SenderRole.customer:
        return Icons.person;
      case SenderRole.pharmacy:
        return Icons.local_pharmacy;
      case SenderRole.system:
        return Icons.info;
    }
  }
}

/// Message de chat enrichi
class EnhancedChatMessage {
  final String id;
  final String content;
  final MessageType type;
  final SenderRole senderRole;
  final int senderId;
  final String senderName;
  final String? senderAvatar;
  final String target;
  final MessageStatus status;
  final DateTime createdAt;
  final DateTime? readAt;
  final Map<String, dynamic>? metadata;
  
  // Pour les messages vocaux
  final String? audioUrl;
  final Duration? audioDuration;
  
  // Pour les images
  final String? imageUrl;
  final String? thumbnailUrl;
  
  // Pour la localisation
  final double? latitude;
  final double? longitude;
  final String? locationAddress;
  
  // Pour les réponses rapides
  final String? replyToId;
  final String? replyToContent;

  const EnhancedChatMessage({
    required this.id,
    required this.content,
    required this.type,
    required this.senderRole,
    required this.senderId,
    required this.senderName,
    this.senderAvatar,
    required this.target,
    required this.status,
    required this.createdAt,
    this.readAt,
    this.metadata,
    this.audioUrl,
    this.audioDuration,
    this.imageUrl,
    this.thumbnailUrl,
    this.latitude,
    this.longitude,
    this.locationAddress,
    this.replyToId,
    this.replyToContent,
  });

  /// Vérifier si ce message est envoyé par le livreur actuel
  bool isFromCourier(int courierId) => senderRole == SenderRole.courier && senderId == courierId;

  /// Copier avec modifications
  EnhancedChatMessage copyWith({
    String? id,
    String? content,
    MessageType? type,
    SenderRole? senderRole,
    int? senderId,
    String? senderName,
    String? senderAvatar,
    String? target,
    MessageStatus? status,
    DateTime? createdAt,
    DateTime? readAt,
    Map<String, dynamic>? metadata,
    String? audioUrl,
    Duration? audioDuration,
    String? imageUrl,
    String? thumbnailUrl,
    double? latitude,
    double? longitude,
    String? locationAddress,
    String? replyToId,
    String? replyToContent,
  }) {
    return EnhancedChatMessage(
      id: id ?? this.id,
      content: content ?? this.content,
      type: type ?? this.type,
      senderRole: senderRole ?? this.senderRole,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      senderAvatar: senderAvatar ?? this.senderAvatar,
      target: target ?? this.target,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      readAt: readAt ?? this.readAt,
      metadata: metadata ?? this.metadata,
      audioUrl: audioUrl ?? this.audioUrl,
      audioDuration: audioDuration ?? this.audioDuration,
      imageUrl: imageUrl ?? this.imageUrl,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      locationAddress: locationAddress ?? this.locationAddress,
      replyToId: replyToId ?? this.replyToId,
      replyToContent: replyToContent ?? this.replyToContent,
    );
  }

  /// De JSON/Firestore
  factory EnhancedChatMessage.fromJson(Map<String, dynamic> json, String docId) {
    return EnhancedChatMessage(
      id: docId,
      content: json['content'] ?? '',
      type: MessageTypeExtension.fromString(json['type'] ?? 'text'),
      senderRole: SenderRoleExtension.fromString(json['sender_type'] ?? 'courier'),
      senderId: json['sender_id'] ?? 0,
      senderName: json['sender_name'] ?? 'Inconnu',
      senderAvatar: json['sender_avatar'],
      target: json['target'] ?? 'customer',
      status: MessageStatusExtension.fromString(json['status'] ?? 'sent'),
      createdAt: json['created_at'] is Timestamp
          ? (json['created_at'] as Timestamp).toDate()
          : DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.now(),
      readAt: json['read_at'] is Timestamp
          ? (json['read_at'] as Timestamp).toDate()
          : null,
      metadata: json['metadata'] as Map<String, dynamic>?,
      audioUrl: json['audio_url'],
      audioDuration: json['audio_duration'] != null
          ? Duration(milliseconds: json['audio_duration'])
          : null,
      imageUrl: json['image_url'],
      thumbnailUrl: json['thumbnail_url'],
      latitude: json['latitude']?.toDouble(),
      longitude: json['longitude']?.toDouble(),
      locationAddress: json['location_address'],
      replyToId: json['reply_to_id'],
      replyToContent: json['reply_to_content'],
    );
  }

  /// Vers JSON/Firestore
  Map<String, dynamic> toJson() {
    return {
      'content': content,
      'type': type.value,
      'sender_type': senderRole.value,
      'sender_id': senderId,
      'sender_name': senderName,
      if (senderAvatar != null) 'sender_avatar': senderAvatar,
      'target': target,
      'status': status.value,
      'created_at': FieldValue.serverTimestamp(),
      if (readAt != null) 'read_at': Timestamp.fromDate(readAt!),
      if (metadata != null) 'metadata': metadata,
      if (audioUrl != null) 'audio_url': audioUrl,
      if (audioDuration != null) 'audio_duration': audioDuration!.inMilliseconds,
      if (imageUrl != null) 'image_url': imageUrl,
      if (thumbnailUrl != null) 'thumbnail_url': thumbnailUrl,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (locationAddress != null) 'location_address': locationAddress,
      if (replyToId != null) 'reply_to_id': replyToId,
      if (replyToContent != null) 'reply_to_content': replyToContent,
    };
  }
}

/// Conversation/Discussion
class ChatConversation {
  final int orderId;
  final String target;
  final String targetName;
  final String? targetAvatar;
  final EnhancedChatMessage? lastMessage;
  final int unreadCount;
  final DateTime updatedAt;
  final bool isTyping;

  const ChatConversation({
    required this.orderId,
    required this.target,
    required this.targetName,
    this.targetAvatar,
    this.lastMessage,
    required this.unreadCount,
    required this.updatedAt,
    this.isTyping = false,
  });

  ChatConversation copyWith({
    int? orderId,
    String? target,
    String? targetName,
    String? targetAvatar,
    EnhancedChatMessage? lastMessage,
    int? unreadCount,
    DateTime? updatedAt,
    bool? isTyping,
  }) {
    return ChatConversation(
      orderId: orderId ?? this.orderId,
      target: target ?? this.target,
      targetName: targetName ?? this.targetName,
      targetAvatar: targetAvatar ?? this.targetAvatar,
      lastMessage: lastMessage ?? this.lastMessage,
      unreadCount: unreadCount ?? this.unreadCount,
      updatedAt: updatedAt ?? this.updatedAt,
      isTyping: isTyping ?? this.isTyping,
    );
  }
}

/// Réponses rapides prédéfinies
class QuickReply {
  final String id;
  final String text;
  final IconData? icon;
  final String? category;

  const QuickReply({
    required this.id,
    required this.text,
    this.icon,
    this.category,
  });

  /// Liste des réponses rapides par défaut
  static List<QuickReply> get defaults => [
    const QuickReply(
      id: 'arriving',
      text: 'Je suis en route !',
      icon: Icons.directions_bike,
      category: 'status',
    ),
    const QuickReply(
      id: 'arrived',
      text: 'Je suis arrivé',
      icon: Icons.location_on,
      category: 'status',
    ),
    const QuickReply(
      id: 'waiting',
      text: 'Je vous attends à l\'entrée',
      icon: Icons.hourglass_empty,
      category: 'status',
    ),
    const QuickReply(
      id: 'traffic',
      text: 'Il y a du trafic, j\'arrive bientôt',
      icon: Icons.traffic,
      category: 'delay',
    ),
    const QuickReply(
      id: 'calling',
      text: 'Je vous appelle',
      icon: Icons.phone,
      category: 'contact',
    ),
    const QuickReply(
      id: 'address',
      text: 'Pouvez-vous confirmer l\'adresse ?',
      icon: Icons.map,
      category: 'question',
    ),
    const QuickReply(
      id: 'thanks',
      text: 'Merci et bonne journée !',
      icon: Icons.thumb_up,
      category: 'closing',
    ),
    const QuickReply(
      id: 'cant_find',
      text: 'Je ne trouve pas l\'adresse',
      icon: Icons.help_outline,
      category: 'problem',
    ),
  ];

  /// Grouper par catégorie
  static Map<String, List<QuickReply>> get byCategory {
    final map = <String, List<QuickReply>>{};
    for (final reply in defaults) {
      final category = reply.category ?? 'other';
      map.putIfAbsent(category, () => []).add(reply);
    }
    return map;
  }
}

/// État de saisie (typing indicator)
class TypingStatus {
  final int orderId;
  final String target;
  final SenderRole senderRole;
  final int senderId;
  final String senderName;
  final DateTime startedAt;

  const TypingStatus({
    required this.orderId,
    required this.target,
    required this.senderRole,
    required this.senderId,
    required this.senderName,
    required this.startedAt,
  });

  bool get isExpired {
    // Typing indicator expire après 5 secondes
    return DateTime.now().difference(startedAt).inSeconds > 5;
  }

  factory TypingStatus.fromJson(Map<String, dynamic> json, String docId) {
    return TypingStatus(
      orderId: json['order_id'] ?? 0,
      target: json['target'] ?? '',
      senderRole: SenderRoleExtension.fromString(json['sender_type'] ?? ''),
      senderId: json['sender_id'] ?? 0,
      senderName: json['sender_name'] ?? '',
      startedAt: json['started_at'] is Timestamp
          ? (json['started_at'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'order_id': orderId,
      'target': target,
      'sender_type': senderRole.value,
      'sender_id': senderId,
      'sender_name': senderName,
      'started_at': FieldValue.serverTimestamp(),
    };
  }
}
