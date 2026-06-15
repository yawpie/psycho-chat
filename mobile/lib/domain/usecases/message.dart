import 'package:psycho_chat/domain/entities/chat_message.dart';
import 'package:psycho_chat/domain/repositories/chat_repository.dart';
import 'package:psycho_chat/domain/repositories/convo_repository.dart';

class MessageUseCase {
  final ConvoRepository _convoRepository;
  final ChatRepository _chatRepository;
  MessageUseCase(this._convoRepository, this._chatRepository);

  Future<void> sendMessage(
    int conversationId,
    String sender,
    String text,
    String receiver,
  ) async {
    return _chatRepository.sendMessage(text, sender, receiver, conversationId);
  }

  Future<List<Message>> getMessagesForConversation(int conversationId) async {
    return _convoRepository.getMessagesForConversation(conversationId);
  }
  /// Fetch conversations for a user and store them in the local database
  Future<List<Conversation>> getConversationsForUser(String username) async {
    return _convoRepository.getConversationsForUser(username);
  }

  Future<void> fetchMessages(int conversationId) async {
    await _convoRepository.fetchMessages(conversationId);
  }
  Future<void> fetchConvosForUser(String username) async {
    await _convoRepository.fetchConvosForUser(username);
  }
}
