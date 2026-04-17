import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/errors/failure.dart';
import '../datasources/notification_remote_datasource.dart';
import '../models/notification_model.dart';
import '../../../../core/errors/exceptions.dart';

class NotificationRepository {
  final NotificationRemoteDataSource _dataSource;

  NotificationRepository(this._dataSource);

  Future<Either<Failure, List<NotificationModel>>> getNotifications() async {
    try {
      final result = await _dataSource.getNotifications();
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  Future<Either<Failure, void>> markAsRead(String id) async {
    try {
      await _dataSource.markAsRead(id);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  Future<Either<Failure, void>> markAllAsRead() async {
    try {
      await _dataSource.markAllAsRead();
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  Future<Either<Failure, int>> getUnreadCount() async {
    try {
      final count = await _dataSource.getUnreadCount();
      return Right(count);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  final dataSource = ref.watch(notificationRemoteDataSourceProvider);
  return NotificationRepository(dataSource);
});
