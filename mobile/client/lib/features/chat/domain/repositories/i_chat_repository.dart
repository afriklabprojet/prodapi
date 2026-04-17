import '../entities/chat_message.dart';

abstract class IChatRepository {
  Future<List<ChatMessage>> fetchMessages({int? before, int limit = 30});
  Future<ChatMessage> sendMessage({required String localId, required String message, String? target});
  Future<void> markAsRead({required int messageId});
  Stream<ChatMessage> get messageStream;
  Stream<bool> get typingStream;
  Stream<bool> get connectionStream;
  Stream<int> get readReceiptStream;
  void sendTyping();
  Future<void> connectRealtime();
  Future<void> dispose();
}
