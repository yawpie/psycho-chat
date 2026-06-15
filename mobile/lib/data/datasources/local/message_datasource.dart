import 'package:drift/drift.dart';
import 'package:psycho_chat/data/datasources/local/app_database.dart';

class MessageLocalDataSource {
  final AppDatabase database;

  MessageLocalDataSource(this.database);

  Future<List<Message>> getMessages() {
    return database.select(database.messages).get();
  }

  Future<List<Message>> getMessagesForConversation(int conversationId) {
    return (database.select(
      database.messages,
    )..where((m) => m.conversationId.equals(conversationId))).get();
  }

  Future<int> createMessage(
    int conversationId,
    String sender,
    String message,
    DateTime timestamp,
    String status,
  ) {
    return database
        .into(database.messages)
        .insert(
          MessagesCompanion.insert(
            conversationId: Value(conversationId),
            sender: sender,
            message: message,
            createdAt: Value(timestamp),
            status: Value(status),
          ),
        );
  }

  Future<void> deleteMessage(int id) {
    return (database.delete(
      database.messages,
    )..where((m) => m.id.equals(id))).go();
  }

  Future<void> updateMessageStatus(int messageId, String status) async {
    await (database.update(database.messages)
          ..where((m) => m.id.equals(messageId)))
        .write(MessagesCompanion(status: Value(status)));
  }
}