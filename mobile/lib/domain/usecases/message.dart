import 'package:psycho_chat/domain/entities/chat_message.dart';
import 'package:psycho_chat/domain/repositories/chat_repository.dart';
import 'package:psycho_chat/domain/repositories/convo_repository.dart';

class MessageUseCase {
  final ConvoRepository _convoRepository;
  final ChatRepository _chatRepository;
  MessageUseCase(this._convoRepository, this._chatRepository);

  Future<void> sendMessage(
    String conversationId,
    String sender,
    String text,
    String receiver,
    String clientMessageId,
  ) async {
    return _chatRepository.sendMessage(
      text,
      sender,
      receiver,
      conversationId,
      clientMessageId,
    );
  }

  Future<List<Message>> getMessagesForConversationFromLocalDb(
    String conversationId,
  ) async {
    return _chatRepository.getMessagesForConversation(conversationId);
  }

  /// Fetch conversations for a user and store them in the local database
  Future<List<Conversation>> getConversationsForUser(String username) async {
    return _convoRepository.getConversationsForUser(username);
  }

  Future<void> fetchMessages(String conversationId) async {
    await _chatRepository.fetchMessages(conversationId);
  }

  Future<void> fetchConvosForUser(String username) async {
    await _convoRepository.fetchConvosForUser(username);
  }

  Future<void> createConversation(String sender, String receiver, String password) async {
    await _convoRepository.createConversation(sender, receiver, password);
  }
}
