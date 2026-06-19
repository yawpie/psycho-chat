import 'package:psycho_chat/domain/entities/chat_message.dart';

abstract class ChatRepository {
  Stream<Message> get messageStream;
  bool get isConnected;

  Future<void> connect(String username);
  void sendMessage(
    String text,
    String username,
    String receiver,
    String conversationId,
    String clientMessageId,
  );
  Future<Message> submitMessageToBackend({
    required String conversationId,
    required String sender,
    required String text,
    required String clientMessageId,
  });
  Future<List<Message>> syncConversationMessages(String conversationId);
  Future<void> fetchMessages(String conversationId);
  Future<List<Message>> getMessagesForConversation(String conversationId);

  Future<void> updateMessageStatus(String clientMessageId, String status);
  Future<void> disconnect();
  Future<void> clearLocalConversations();
}
