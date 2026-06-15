import 'package:psycho_chat/domain/entities/chat_message.dart';

abstract class ConvoRepository {
  Future<void> createConversation(String sender, String receiver, String? password);
  Future<List<Conversation>> getConversationsForUser(String username);
  Future<List<Message>> getMessagesForConversation(int conversationId);
  Future<void> fetchMessages(int conversationId);
  Future<void> fetchConvosForUser(String username);
  Future<void> sendMessage(
    int conversationId,
    String sender,
    String text,
    String receiver,
  );
  // Future<void> formatSenderAndReceiver();
}
