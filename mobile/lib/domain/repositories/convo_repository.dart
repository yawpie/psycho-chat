import 'package:psycho_chat/domain/entities/chat_message.dart';

abstract class ConvoRepository {
  Future<void> createConversation(
    String sender,
    String receiver,
    String? password,
  );
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

  /// Fetch password for a single conversation from remote and return it.
  Future<String?> fetchConversationPassword(String conversationId);

  // Future<void> formatSenderAndReceiver();
}
