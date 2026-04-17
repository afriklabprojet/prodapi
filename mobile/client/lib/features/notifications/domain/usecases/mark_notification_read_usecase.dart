import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/notifications_repository.dart';

/// Use case: marquer une notification comme lue
class MarkNotificationAsReadUseCase {
  final NotificationsRepository repository;

  MarkNotificationAsReadUseCase(this.repository);

  Future<Either<Failure, void>> call(String notificationId) {
    return repository.markAsRead(notificationId);
  }
}
