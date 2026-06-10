import 'package:psycho_chat/domain/entities/chat_message.dart';
import 'package:psycho_chat/domain/repositories/convo_repository.dart';

class MessageUseCase {
  final ConvoRepository _convoRepository;
  MessageUseCase(this._convoRepository);

  Future<void> sendMessage(
    int conversationId,
    String sender,
    String text,
  ) async {
    return _convoRepository.sendMessage(conversationId, sender, text);
  }

  Future<List<Message>> getMessagesForConversation(int conversationId) async {
    return _convoRepository.getMessagesForConversation(conversationId);
  }

  Future<List<Conversation>> getConversationsForUser(String username) async {
    return _convoRepository.getConversationsForUser(username);
  }
}
