import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/providers/core_providers.dart';
import '../../domain/entities/chat_message_entity.dart';
import '../../domain/repositories/chat_repository.dart';
import '../datasources/chat_remote_datasource.dart';
import '../models/chat_message_model.dart';

/// Implémentation concrète du repository de chat
class ChatRepositoryImpl implements ChatRepository {
  final ChatRemoteDataSource _dataSource;

  ChatRepositoryImpl(this._dataSource);

  @override
  Future<Either<Failure, List<ChatMessageEntity>>> getMessages(
    int deliveryId,
    SenderType participantType,
    int participantId,
  ) async {
    try {
      final result = await _dataSource.getMessages(
        deliveryId,
        participantType.toApiString(),
        participantId,
      );
      return Right(result.map(_mapToEntity).toList());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, ChatMessageEntity>> sendMessage(
    int deliveryId,
    SenderType receiverType,
    int receiverId,
    String message,
  ) async {
    try {
      final result = await _dataSource.sendMessage(
        deliveryId,
        receiverType.toApiString(),
        receiverId,
        message,
      );
      return Right(_mapToEntity(result));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, int>> getUnreadCount(int deliveryId) async {
    try {
      final count = await _dataSource.getUnreadCount(deliveryId);
      return Right(count);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> markAsRead(
    int deliveryId,
    SenderType senderType,
    int senderId,
  ) async {
    try {
      await _dataSource.markAsRead(
        deliveryId,
        senderType.toApiString(),
        senderId,
      );
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  /// Convertit un ChatMessageModel en ChatMessageEntity
  ChatMessageEntity _mapToEntity(ChatMessageModel model) {
    return ChatMessageEntity(
      id: model.id,
      message: model.message,
      senderType: model.senderType.toSenderType(),
      senderId: model.senderId,
      isMine: model.isMine,
      readAt: model.readAt,
      createdAt: model.createdAt,
    );
  }
}

/// Provider du datasource chat
final chatRemoteDataSourceProvider = Provider<ChatRemoteDataSource>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return ChatRemoteDataSourceImpl(apiClient: apiClient);
});

/// Provider du repository chat
final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  final dataSource = ref.watch(chatRemoteDataSourceProvider);
  return ChatRepositoryImpl(dataSource);
});
