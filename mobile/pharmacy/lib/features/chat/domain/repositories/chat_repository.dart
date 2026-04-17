import 'package:dartz/dartz.dart';
import '../../../../core/errors/failure.dart';
import '../entities/chat_message_entity.dart';

/// Interface abstraite du repository de chat
abstract class ChatRepository {
  /// Récupère les messages d'un chat de livraison
  Future<Either<Failure, List<ChatMessageEntity>>> getMessages(
    int deliveryId,
    SenderType participantType,
    int participantId,
  );
  
  /// Envoie un message
  Future<Either<Failure, ChatMessageEntity>> sendMessage(
    int deliveryId,
    SenderType receiverType,
    int receiverId,
    String message,
  );
  
  /// Récupère le nombre de messages non lus
  Future<Either<Failure, int>> getUnreadCount(int deliveryId);
  
  /// Marque les messages comme lus
  Future<Either<Failure, void>> markAsRead(
    int deliveryId,
    SenderType senderType,
    int senderId,
  );
}
