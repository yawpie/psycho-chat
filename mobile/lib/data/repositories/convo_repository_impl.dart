import 'package:psycho_chat/domain/entities/chat_message.dart';
import 'package:psycho_chat/domain/repositories/convo_repository.dart';

class ConvoRepositoryImpl implements ConvoRepository {
  @override
  Future<void> createConversation(String user1, String user2) {
    // Implementation for creating a conversation
    throw UnimplementedError();
  }

  @override
  Future<List<Conversation>> getConversationsForUser(String username) {
    // Implementation for fetching conversations for a user
    throw UnimplementedError();
  }

  @override
  Future<List<Message>> getMessagesForConversation(int conversationId) {
    // Implementation for fetching messages for a conversation
    throw UnimplementedError();
  }

  @override
  Future<void> sendMessage(int conversationId, String sender, String text) {
    // Implementation for sending a message
    throw UnimplementedError();
  }
}