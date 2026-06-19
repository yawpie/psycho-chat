import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:psycho_chat/data/datasources/local/app_database.dart';
import 'package:psycho_chat/data/models/chat_message_model.dart';
import 'package:psycho_chat/data/models/chat_message_model.dart'
    as message_model;

class MessageLocalDataSource {
  final AppDatabase database;

  MessageLocalDataSource(this.database);

  Future<List<Message>> getMessages() {
    return database.select(database.messages).get();
  }

  Future<List<Message>> getMessagesForConversation(String conversationId) {
    return (database.select(
      database.messages,
    )..where((m) => m.conversationId.equals(conversationId))).get();
  }

  Future<void> clearMessagesForConversation(String conversationId) {
    return (database.delete(
      database.messages,
    )..where((m) => m.conversationId.equals(conversationId))).go();
  }

  Future<void> clearAllMessages() {
    return database.delete(database.messages).go();
  }

  Future<int> createMessage(
    String conversationId,
    String sender,
    String message,
    DateTime timestamp,
    String status,
    String clientMessageId,
  ) {
    return database
        .into(database.messages)
        .insertOnConflictUpdate(
          MessagesCompanion(
            conversationId: Value(conversationId),
            clientMessageId: Value(clientMessageId),
            sender: Value(sender),
            message: Value(message),
            createdAt: Value(timestamp),
            status: Value(status),
          ),
        );
  }

  Future<void> deleteMessage(String id) {
    return (database.delete(
      database.messages,
    )..where((m) => m.id.equals(id))).go();
  }

  Future<void> updateMessageStatus(String clientMessageId, String status) async {
    if (kDebugMode)
    {debugPrint(
      'Updating message status for clientMessageId $clientMessageId to $status',
    );}
    await (database.update(database.messages)
          ..where((m) => m.clientMessageId.equals(clientMessageId)))
        .write(MessagesCompanion(status: Value(status)));
  }

  Future<void> markMessageSynced(
    String clientMessageId,
    String backendMessageId,
  ) async {
    await (database.update(
      database.messages,
    )..where((m) => m.clientMessageId.equals(clientMessageId))).write(
      MessagesCompanion(
        id: Value(backendMessageId),
        status: const Value('received'),
      ),
    );
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
                clientMessageId: Value(message.clientMessageId),
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
}
