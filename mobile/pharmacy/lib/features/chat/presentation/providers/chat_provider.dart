import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/chat_message_entity.dart';
import '../../domain/repositories/chat_repository.dart';
import '../../data/repositories/chat_repository_impl.dart';

/// Paramètres pour le provider de messages
class ChatMessagesParams {
  final int deliveryId;
  final String participantType;
  final int participantId;

  const ChatMessagesParams({
    required this.deliveryId,
    required this.participantType,
    required this.participantId,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChatMessagesParams &&
          runtimeType == other.runtimeType &&
          deliveryId == other.deliveryId &&
          participantType == other.participantType &&
          participantId == other.participantId;

  @override
  int get hashCode =>
      deliveryId.hashCode ^ participantType.hashCode ^ participantId.hashCode;
}

/// Provider famille qui récupère les messages de chat
final chatMessagesProvider = FutureProvider.family
    .autoDispose<List<ChatMessageEntity>, ChatMessagesParams>((ref, params) async {
  final repository = ref.watch(chatRepositoryProvider);
  final senderType = params.participantType.toSenderType();
  final result = await repository.getMessages(
    params.deliveryId,
    senderType,
    params.participantId,
  );
  return result.fold(
    (failure) => throw Exception(failure.message),
    (messages) => messages,
  );
});

/// State pour le notifier d'envoi de messages
class ChatNotifierState {
  final bool isLoading;
  final String? error;

  const ChatNotifierState({this.isLoading = false, this.error});

  ChatNotifierState copyWith({bool? isLoading, String? error}) {
    return ChatNotifierState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Notifier pour envoyer des messages
class ChatNotifier extends StateNotifier<ChatNotifierState> {
  final ChatRepository _repository;

  ChatNotifier(this._repository) : super(const ChatNotifierState());

  Future<void> sendMessage({
    required int deliveryId,
    required String receiverType,
    required int receiverId,
    required String message,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    final senderType = receiverType.toSenderType();
    final result = await _repository.sendMessage(
      deliveryId,
      senderType,
      receiverId,
      message,
    );
    result.fold(
      (failure) => state = state.copyWith(isLoading: false, error: failure.message),
      (_) => state = state.copyWith(isLoading: false),
    );
  }
}

final chatNotifierProvider =
    StateNotifierProvider.autoDispose<ChatNotifier, ChatNotifierState>((ref) {
  final repository = ref.watch(chatRepositoryProvider);
  return ChatNotifier(repository);
});
