import 'package:cloud_firestore/cloud_firestore.dart';

/// Modèle de message de chat (courier, pharmacy, customer)
class ChatMessage {
  final String id;
  final String senderId;
  final String senderType; // 'customer', 'courier', or 'pharmacy'
  final String target; // 'customer', 'courier', 'pharmacy', or 'all'
  final String content;
  final DateTime timestamp;
  final bool isRead;

  const ChatMessage({
    required this.id,
    required this.senderId,
    required this.senderType,
    this.target = '',
    required this.content,
    required this.timestamp,
    this.isRead = false,
  });

  bool get isFromCustomer => senderType == 'customer';
  bool get isFromCourier => senderType == 'courier';
  bool get isFromPharmacy => senderType == 'pharmacy';

  /// Aliases for UI compatibility
  bool get isMine => isFromCustomer;
  String get message => content;
  DateTime get createdAt => timestamp;
  DateTime? get readAt => isRead ? timestamp : null;

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    // Supporte le format API V2 avec sender.type/sender.id ou le format plat sender_type/sender_id
    final senderType = json['sender'] is Map
        ? json['sender']['type']?.toString() ?? 'customer'
        : json['sender_type']?.toString() ?? 'customer';
    final senderId = json['sender'] is Map
        ? json['sender']['id']?.toString() ?? ''
        : json['sender_id']?.toString() ?? '';
    // Supporte 'message' (API) ou 'content' (legacy)
    final content = json['message']?.toString() ?? json['content']?.toString() ?? '';
    // target depuis receiver.type ou target direct
    final target = json['receiver'] is Map
        ? json['receiver']['type']?.toString() ?? ''
        : json['target']?.toString() ?? '';

    return ChatMessage(
      id: json['id']?.toString() ?? '',
      senderId: senderId,
      senderType: senderType,
      target: target,
      content: content,
      timestamp: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : json['timestamp'] != null
              ? DateTime.tryParse(json['timestamp'].toString()) ?? DateTime.now()
              : DateTime.now(),
      isRead: json['is_read'] as bool? ?? json['is_mine'] == true || false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sender_id': senderId,
      'sender_type': senderType,
      'content': content,
      'timestamp': timestamp.toIso8601String(),
      'is_read': isRead,
    };
  }

  /// Parse un champ timestamp Firestore (Timestamp, DateTime, ou String)
  static DateTime _parseTimestamp(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString()) ?? DateTime.now();
  }

  factory ChatMessage.fromFirestore(Map<String, dynamic> data, String docId) {
    // Le delivery app écrit 'sender_type', on supporte aussi 'sender_role' par sécurité
    final rawSenderType = data['sender_type'] ?? data['sender_role'] ?? 'courier';
    // Conserver les 3 types tels quels : 'customer', 'courier', 'pharmacy'
    final senderType = (rawSenderType == 'customer' || rawSenderType == 'pharmacy')
        ? rawSenderType as String
        : 'courier';

    return ChatMessage(
      id: docId,
      senderId: data['sender_id']?.toString() ?? '',
      senderType: senderType,
      target: data['target'] as String? ?? '',
      content: data['content'] as String? ?? '',
      timestamp: _parseTimestamp(data['created_at']),
      isRead: data['is_read'] as bool? ?? false,
    );
  }
}
