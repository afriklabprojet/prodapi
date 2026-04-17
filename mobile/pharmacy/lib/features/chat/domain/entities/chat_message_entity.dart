/// Entité représentant un message de chat
class ChatMessageEntity {
  final int id;
  final String message;
  final SenderType senderType;
  final int senderId;
  final bool isMine;
  final DateTime? readAt;
  final DateTime createdAt;

  const ChatMessageEntity({
    required this.id,
    required this.message,
    required this.senderType,
    required this.senderId,
    required this.isMine,
    this.readAt,
    required this.createdAt,
  });

  /// Indique si le message a été lu
  bool get isRead => readAt != null;

  /// Formatage de l'heure de création
  String get timeFormatted {
    final hour = createdAt.hour.toString().padLeft(2, '0');
    final minute = createdAt.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  ChatMessageEntity copyWith({
    int? id,
    String? message,
    SenderType? senderType,
    int? senderId,
    bool? isMine,
    DateTime? readAt,
    DateTime? createdAt,
  }) {
    return ChatMessageEntity(
      id: id ?? this.id,
      message: message ?? this.message,
      senderType: senderType ?? this.senderType,
      senderId: senderId ?? this.senderId,
      isMine: isMine ?? this.isMine,
      readAt: readAt ?? this.readAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

/// Type d'expéditeur d'un message
enum SenderType {
  pharmacy,
  courier,
  customer,
  unknown,
}

/// Extension pour convertir String en SenderType
extension SenderTypeExtension on String {
  SenderType toSenderType() {
    switch (toLowerCase()) {
      case 'pharmacy':
        return SenderType.pharmacy;
      case 'courier':
        return SenderType.courier;
      case 'customer':
        return SenderType.customer;
      default:
        return SenderType.unknown;
    }
  }
}

/// Extension pour convertir SenderType en String
extension SenderTypeToString on SenderType {
  String toApiString() {
    switch (this) {
      case SenderType.pharmacy:
        return 'pharmacy';
      case SenderType.courier:
        return 'courier';
      case SenderType.customer:
        return 'customer';
      case SenderType.unknown:
        return 'unknown';
    }
  }
}
