// ignore_for_file: library_prefixes

import 'package:psycho_chat/data/datasources/local/local_datasource.dart';
import 'package:psycho_chat/data/models/chat_message_model.dart';
import 'package:psycho_chat/domain/entities/chat_message.dart';
import 'package:psycho_chat/domain/repositories/convo_repository.dart';
import 'package:psycho_chat/data/datasources/local/app_database.dart' as DbData;

class ConvoRepositoryImpl implements ConvoRepository {
  final ConversationLocalDataSource _convoDataSource;
  final MessageLocalDataSource _messageDataSource;
  ConvoRepositoryImpl({
    required this._convoDataSource,
    required this._messageDataSource,
  });

  @override
  Future<void> createConversation(String user1, String user2) async {
    // Implementation for creating a conversation
    return _convoDataSource.createConversation(user1, user2);
  }

  @override
  Future<List<Conversation>> getConversationsForUser(String username) async {
    // Implementation for fetching conversations for a user
    List<DbData.Conversation> getConvoRes = await _convoDataSource
        .getConversationsForUser(username);
    List<Conversation> convertedConvos = [];
    for (var convo in getConvoRes) {
      convertedConvos.add(ConversationModel.fromDrift(convo, []));
    }
    return convertedConvos;
  }

  @override
  Future<List<Message>> getMessagesForConversation(int conversationId) async {
    // Implementation for fetching messages for a conversation
    List<DbData.Message> getMessagesRes =
        await _messageDataSource.getMessagesForConversation(conversationId);
    List<Message> convertedMessages = [];
    for (var message in getMessagesRes) {
      convertedMessages.add(MessageModel.fromDrift(message));
    }
    return convertedMessages;
  }

  @override
  Future<void> sendMessage(int conversationId, String sender, String text) async {
    // Implementation for sending a message
    return _messageDataSource.createMessage(
      conversationId,
      sender,
      text,
      DateTime.now(),
      "sent",
    );
  }
}
