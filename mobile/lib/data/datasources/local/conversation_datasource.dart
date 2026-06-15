import 'package:drift/drift.dart';
import 'package:psycho_chat/data/datasources/local/app_database.dart';
import 'package:psycho_chat/data/models/chat_message_model.dart'
    as message_model;

class ConversationLocalDataSource {
  final AppDatabase database;
  final String? currentUsername; // Placeholder untuk username saat ini
  ConversationLocalDataSource({
    required this.database,
    required this.currentUsername,
  });

  Future<List<Conversation>> getConversations() {
    return database.select(database.conversations).get();
  }

  Future<void> createConversation(String receiver) {
    return database
        .into(database.conversations)
        .insert(ConversationsCompanion.insert(receiver: receiver));
  }

  Future<void> writeRemoteConvoToLocal(
    List<message_model.ConversationModel> conversations,
  ) async {
    try {
      if (currentUsername == null) {
        throw Exception('Current username is not set');
      }
      print("banyak convo dari remote: ${conversations.length}");
      for (var convo in conversations) {
        await database
            .into(database.conversations)
            .insertOnConflictUpdate(
              ConversationsCompanion(
                id: Value(convo.id),
                receiver: Value(convo.receiver),
                password: Value(convo.password),
                createdAt: Value(convo.createdAt),
              ),
            );
      }
    } catch (e) {
      print(e);
      throw Exception('Failed to write remote conversations to local database');
    }
  }

  Future<void> writeRemoteMessagesToLocal(
    List<message_model.MessageModel> messages,
  ) async {
    try {
      print("mengisi pesan...");
      for (var message in messages) {
        print("mengisi pesan: $message");
        await database
            .into(database.messages)
            .insertOnConflictUpdate(
              MessagesCompanion(
                id: Value(message.id),
                conversationId: Value(message.conversationId),
                sender: Value(message.sender),
                message: Value(message.message),
                createdAt: Value(message.createdAt),
                status: Value(message.status),
              ),
            );
      }
    } catch (e) {
      print(e);
      throw Exception('Failed to write remote messages to local database');
    }
  }

  Future<List<Conversation>> getConversationsFromLocal() {
    if (currentUsername == null) {
      throw Exception('Current username is not set');
    }
    return database.select(database.conversations).get();
  }

  Future<void> deleteConversation(int id) {
    return (database.delete(
      database.conversations,
    )..where((c) => c.id.equals(id))).go();
  }
}
