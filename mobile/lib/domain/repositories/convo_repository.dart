import 'package:psycho_chat/domain/entities/chat_message.dart';

abstract class ConvoRepository {
  Future<void> createConversation(String user1, String user2);
  Future<List<Conversation>> getConversationsForUser(String username);
  Future<List<Message>> getMessagesForConversation(int conversationId);
  Future<void> sendMessage(int conversationId, String sender, String text);
}