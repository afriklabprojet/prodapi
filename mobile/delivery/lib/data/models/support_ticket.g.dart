// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'support_ticket.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_SupportTicket _$SupportTicketFromJson(Map<String, dynamic> json) =>
    _SupportTicket(
      id: (json['id'] as num).toInt(),
      userId: (json['user_id'] as num).toInt(),
      subject: json['subject'] as String,
      description: json['description'] as String,
      category: json['category'] as String,
      priority: json['priority'] as String,
      status: json['status'] as String,
      reference: json['reference'] as String?,
      resolvedAt: json['resolved_at'] as String?,
      createdAt: json['created_at'] as String?,
      updatedAt: json['updated_at'] as String?,
      messagesCount: (json['messages_count'] as num?)?.toInt(),
      unreadCount: (json['unread_count'] as num?)?.toInt(),
      latestMessage: json['latest_message'] == null
          ? null
          : SupportMessage.fromJson(
              json['latest_message'] as Map<String, dynamic>,
            ),
      messages: (json['messages'] as List<dynamic>?)
          ?.map((e) => SupportMessage.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$SupportTicketToJson(_SupportTicket instance) =>
    <String, dynamic>{
      'id': instance.id,
      'user_id': instance.userId,
      'subject': instance.subject,
      'description': instance.description,
      'category': instance.category,
      'priority': instance.priority,
      'status': instance.status,
      'reference': instance.reference,
      'resolved_at': instance.resolvedAt,
      'created_at': instance.createdAt,
      'updated_at': instance.updatedAt,
      'messages_count': instance.messagesCount,
      'unread_count': instance.unreadCount,
      'latest_message': instance.latestMessage,
      'messages': instance.messages,
    };

_SupportMessage _$SupportMessageFromJson(Map<String, dynamic> json) =>
    _SupportMessage(
      id: (json['id'] as num).toInt(),
      supportTicketId: (json['support_ticket_id'] as num).toInt(),
      userId: (json['user_id'] as num).toInt(),
      message: json['message'] as String,
      attachment: json['attachment'] as String?,
      isFromSupport: json['is_from_support'] as bool? ?? false,
      readAt: json['read_at'] as String?,
      createdAt: json['created_at'] as String?,
      updatedAt: json['updated_at'] as String?,
      user: json['user'] == null
          ? null
          : SupportUser.fromJson(json['user'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$SupportMessageToJson(_SupportMessage instance) =>
    <String, dynamic>{
      'id': instance.id,
      'support_ticket_id': instance.supportTicketId,
      'user_id': instance.userId,
      'message': instance.message,
      'attachment': instance.attachment,
      'is_from_support': instance.isFromSupport,
      'read_at': instance.readAt,
      'created_at': instance.createdAt,
      'updated_at': instance.updatedAt,
      'user': instance.user,
    };

_SupportUser _$SupportUserFromJson(Map<String, dynamic> json) =>
    _SupportUser(id: (json['id'] as num).toInt(), name: json['name'] as String);

Map<String, dynamic> _$SupportUserToJson(_SupportUser instance) =>
    <String, dynamic>{'id': instance.id, 'name': instance.name};

_SupportStats _$SupportStatsFromJson(Map<String, dynamic> json) =>
    _SupportStats(
      total: (json['total'] as num?)?.toInt() ?? 0,
      open: (json['open'] as num?)?.toInt() ?? 0,
      resolved: (json['resolved'] as num?)?.toInt() ?? 0,
      closed: (json['closed'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$SupportStatsToJson(_SupportStats instance) =>
    <String, dynamic>{
      'total': instance.total,
      'open': instance.open,
      'resolved': instance.resolved,
      'closed': instance.closed,
    };
