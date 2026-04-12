/// Modèle de message de chat avec le coursier
class ChatMessage {
  final String id;
  final String senderId;
  final String senderType; // 'customer' or 'courier'
  final String content;
  final DateTime timestamp;
  final bool isRead;

  const ChatMessage({
    required this.id,
    required this.senderId,
    required this.senderType,
    required this.content,
    required this.timestamp,
    this.isRead = false,
  });

  bool get isFromCustomer => senderType == 'customer';
  bool get isFromCourier => senderType == 'courier';

  /// Aliases for UI compatibility
  bool get isMine => isFromCustomer;
  String get message => content;
  DateTime get createdAt => timestamp;
  DateTime? get readAt => isRead ? timestamp : null;

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id']?.toString() ?? '',
      senderId: json['sender_id']?.toString() ?? '',
      senderType: json['sender_type'] as String? ?? 'customer',
      content: json['content'] as String? ?? '',
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp'].toString()) ?? DateTime.now()
          : DateTime.now(),
      isRead: json['is_read'] as bool? ?? false,
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

  factory ChatMessage.fromFirestore(Map<String, dynamic> data, String docId) {
    return ChatMessage(
      id: docId,
      senderId: data['sender_id']?.toString() ?? '',
      senderType: data['sender_role'] == 'customer' ? 'customer' : 'courier',
      content: data['content'] as String? ?? '',
      timestamp: data['created_at'] != null
          ? (data['created_at'] is DateTime
              ? data['created_at'] as DateTime
              : DateTime.tryParse(data['created_at'].toString()) ?? DateTime.now())
          : DateTime.now(),
      isRead: data['is_read'] as bool? ?? false,
    );
  }
}
