import 'package:freezed_annotation/freezed_annotation.dart';

part 'support_ticket.freezed.dart';
part 'support_ticket.g.dart';

@freezed
abstract class SupportTicket with _$SupportTicket {
  const factory SupportTicket({
    required int id,
    @JsonKey(name: 'user_id') required int userId,
    required String subject,
    required String description,
    required String category,
    required String priority,
    required String status,
    String? reference,
    @JsonKey(name: 'resolved_at') String? resolvedAt,
    @JsonKey(name: 'created_at') String? createdAt,
    @JsonKey(name: 'updated_at') String? updatedAt,
    @JsonKey(name: 'messages_count') int? messagesCount,
    @JsonKey(name: 'unread_count') int? unreadCount,
    @JsonKey(name: 'latest_message') SupportMessage? latestMessage,
    List<SupportMessage>? messages,
  }) = _SupportTicket;

  factory SupportTicket.fromJson(Map<String, dynamic> json) =>
      _$SupportTicketFromJson(json);
}

@freezed
abstract class SupportMessage with _$SupportMessage {
  const factory SupportMessage({
    required int id,
    @JsonKey(name: 'support_ticket_id') required int supportTicketId,
    @JsonKey(name: 'user_id') required int userId,
    required String message,
    String? attachment,
    @JsonKey(name: 'is_from_support') @Default(false) bool isFromSupport,
    @JsonKey(name: 'read_at') String? readAt,
    @JsonKey(name: 'created_at') String? createdAt,
    @JsonKey(name: 'updated_at') String? updatedAt,
    SupportUser? user,
  }) = _SupportMessage;

  factory SupportMessage.fromJson(Map<String, dynamic> json) =>
      _$SupportMessageFromJson(json);
}

@freezed
abstract class SupportUser with _$SupportUser {
  const factory SupportUser({required int id, required String name}) =
      _SupportUser;

  factory SupportUser.fromJson(Map<String, dynamic> json) =>
      _$SupportUserFromJson(json);
}

@freezed
abstract class SupportStats with _$SupportStats {
  const factory SupportStats({
    @Default(0) int total,
    @Default(0) int open,
    @Default(0) int resolved,
    @Default(0) int closed,
  }) = _SupportStats;

  factory SupportStats.fromJson(Map<String, dynamic> json) =>
      _$SupportStatsFromJson(json);
}

// Catégories de tickets
enum TicketCategory {
  order('order', 'Commande'),
  delivery('delivery', 'Livraison'),
  payment('payment', 'Paiement'),
  account('account', 'Compte'),
  appBug('app_bug', 'Bug application'),
  other('other', 'Autre');

  final String value;
  final String label;
  const TicketCategory(this.value, this.label);

  static TicketCategory fromValue(String value) {
    return TicketCategory.values.firstWhere(
      (e) => e.value == value,
      orElse: () => TicketCategory.other,
    );
  }
}

// Priorités de tickets
enum TicketPriority {
  low('low', 'Basse'),
  medium('medium', 'Moyenne'),
  high('high', 'Haute');

  final String value;
  final String label;
  const TicketPriority(this.value, this.label);

  static TicketPriority fromValue(String value) {
    return TicketPriority.values.firstWhere(
      (e) => e.value == value,
      orElse: () => TicketPriority.medium,
    );
  }
}

// Statuts de tickets
enum TicketStatus {
  open('open', 'Ouvert'),
  inProgress('in_progress', 'En cours'),
  resolved('resolved', 'Résolu'),
  closed('closed', 'Fermé');

  final String value;
  final String label;
  const TicketStatus(this.value, this.label);

  static TicketStatus fromValue(String value) {
    return TicketStatus.values.firstWhere(
      (e) => e.value == value,
      orElse: () => TicketStatus.open,
    );
  }
}

/// FAQ Item pour le centre d'aide
class FAQItem {
  final String question;
  final String answer;
  final String icon;
  final String? category;

  const FAQItem({
    required this.question,
    required this.answer,
    required this.icon,
    this.category,
  });

  factory FAQItem.fromJson(Map<String, dynamic> json) {
    return FAQItem(
      question: json['question'] as String? ?? '',
      answer: json['answer'] as String? ?? '',
      icon: json['icon'] as String? ?? 'help',
      category: json['category'] as String?,
    );
  }
}
