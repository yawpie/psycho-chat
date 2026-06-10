import 'package:drift/drift.dart';
import 'package:psycho_chat/data/datasources/local/app_database.dart';

class UserLocalDataSource {
  final AppDatabase database;

  UserLocalDataSource(this.database);

  Future<List<User>> getUsers() {
    return database.select(
      database.users,
    ).get();
  }

  Future<void> createUser(
    String username,
  ) {
    return database
        .into(database.users)
        .insert(
          UsersCompanion.insert(
            username: username,
          ),
        );
  }

  Future<void> deleteUser(
    int id,
  ) {
    return (database.delete(database.users)
          ..where((u) => u.id.equals(id)))
        .go();
  }
}

class ConversationLocalDataSource {
  final AppDatabase database;

  ConversationLocalDataSource(this.database);

  Future<List<Conversation>> getConversations() {
    return database.select(
      database.conversations,
    ).get();
  }

  Future<void> createConversation(
    String user1,
    String user2,
  ) {
    return database
        .into(database.conversations)
        .insert(
          ConversationsCompanion.insert(
            user1: user1,
            user2: user2,
          ),
        );
  }

  Future<List<Conversation>> getConversationsForUser(String username) {
    return (database.select(database.conversations)
          ..where((c) => c.user1.equals(username) | c.user2.equals(username)))
        .get();
  }

  Future<void> deleteConversation(
    int id,
  ) {
    return (database.delete(database.conversations)
          ..where((c) => c.id.equals(id)))
        .go();
  }
}

class MessageLocalDataSource {
  final AppDatabase database;

  MessageLocalDataSource(this.database);

  Future<List<Message>> getMessages() {
    return database.select(
      database.messages,
    ).get();
  }

  Future<List<Message>> getMessagesForConversation(int conversationId) {
    return (database.select(database.messages)
          ..where((m) => m.conversationId.equals(conversationId)))
        .get();
  }

  Future<void> createMessage(
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
            timestamp: timestamp,
            status: status,
          ),
        );
  }

  Future<void> deleteMessage(
    int id,
  ) {
    return (database.delete(database.messages)
          ..where((m) => m.id.equals(id)))
        .go();
  }
}