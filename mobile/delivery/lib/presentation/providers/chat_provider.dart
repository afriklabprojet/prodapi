import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/chat_message.dart';
import '../../data/repositories/delivery_repository.dart';

final chatMessagesProvider = FutureProvider.family<List<ChatMessage>, ({int orderId, String target})>((ref, args) async {
  final repository = ref.watch(deliveryRepositoryProvider);
  return repository.getMessages(args.orderId, args.target);
});

class ChatNotifier extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncValue.data(null);

  Future<void> sendMessage(int orderId, String content, String target) async {
    final repository = ref.watch(deliveryRepositoryProvider);
    if (content.trim().isEmpty) return;
    state = const AsyncValue.loading();
    try {
      await repository.sendMessage(orderId, content, target);
      // Refresh the message list
      ref.invalidate(chatMessagesProvider((orderId: orderId, target: target)));
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final chatProvider = NotifierProvider<ChatNotifier, AsyncValue<void>>(
  ChatNotifier.new,
);
