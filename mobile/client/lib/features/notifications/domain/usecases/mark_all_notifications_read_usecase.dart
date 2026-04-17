import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/notifications_repository.dart';

/// Use case: marquer toutes les notifications comme lues
class MarkAllNotificationsReadUseCase {
  final NotificationsRepository repository;

  MarkAllNotificationsReadUseCase(this.repository);

  Future<Either<Failure, void>> call() {
    return repository.markAllAsRead();
  }
}
