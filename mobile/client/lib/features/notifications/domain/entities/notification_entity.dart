import 'package:equatable/equatable.dart';

/// Entité Notification (couche Domain)
class NotificationEntity extends Equatable {
  final String id;
  final String type;
  final String title;
  final String body;
  final Map<String, dynamic>? data;
  final bool isRead;
  final DateTime createdAt;

  const NotificationEntity({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    this.data,
    required this.isRead,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [id, type, title, isRead, createdAt];
}
