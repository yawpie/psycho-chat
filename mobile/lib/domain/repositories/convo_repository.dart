import 'package:psycho_chat/domain/entities/chat_message.dart';

abstract class ConvoRepository {
  Future<void> createConversation(String sender, String receiver, String? password);
  Future<List<Conversation>> getConversationsForUser(String username);
  Future<void> fetchConvosForUser(String username);
  Future<void> sendMessage(
    String conversationId,
    String sender,
    String text,
    String receiver,
    String clientMessageId,
  );
  Future<void> clearAll();
  // Future<void> formatSenderAndReceiver();
}
