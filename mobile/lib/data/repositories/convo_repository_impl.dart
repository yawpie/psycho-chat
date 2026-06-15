// ignore_for_file: library_prefixes

import 'package:psycho_chat/data/datasources/local/conversation_datasource.dart';
import 'package:psycho_chat/data/datasources/local/message_datasource.dart';
import 'package:psycho_chat/data/datasources/remote/backend_remote_datasource.dart';
import 'package:psycho_chat/data/datasources/remote/websocket_remote_datasource.dart';
import 'package:psycho_chat/data/models/chat_message_model.dart';
import 'package:psycho_chat/domain/entities/chat_message.dart';
import 'package:psycho_chat/domain/repositories/convo_repository.dart';
import 'package:psycho_chat/data/datasources/local/app_database.dart' as DbData;

class ConvoRepositoryImpl implements ConvoRepository {
  final ConversationLocalDataSource _convoLocalDataSource;
  final BackendRemoteDataSource _backendRemoteDataSource;
  final MessageLocalDataSource _messageLocalDataSource;
  final WebSocketRemoteDatasource _webSocketRemoteDatasource;
  final String? currentUsername;
  ConvoRepositoryImpl({
    required this._convoLocalDataSource,
    required this._messageLocalDataSource,
    required this._backendRemoteDataSource,
    required this._webSocketRemoteDatasource,
    required this.currentUsername,
  });

  @override
  Future<void> createConversation(
    String sender,
    String receiver,
    String? password,
  ) async {
    // Implementation for creating a conversation
    try {
      await _convoLocalDataSource.createConversation(receiver);
      await _backendRemoteDataSource.createConversation(sender, receiver);
    } catch (e) {
      print(e);
      throw Exception('Failed to create conversation: $e');
    }
  }

  @override
  Future<List<Conversation>> getConversationsForUser(String username) async {
    // Implementation for fetching conversations for a user
    print("getConversationsForUser called with username: $username");
    try {
      List<DbData.Conversation> getConvoRes = await _convoLocalDataSource
          .getConversationsFromLocal();
      List<Conversation> convertedConvos = [];
      for (var convo in getConvoRes) {
        convertedConvos.add(ConversationModel.fromDrift(convo));
        print(
          "menambahkan ke result convo id: ${convo.id}, receiver: ${convo.receiver}, createdAt: ${convo.createdAt}",
        );
      }
      return convertedConvos;
    } catch (e) {
      print(e);
      throw Exception('Failed to get conversations for user: $e');
    }
  }

  @override
  Future<List<Message>> getMessagesForConversation(int conversationId) async {
    // Implementation for fetching messages for a conversation
    try {
      List<DbData.Message> getMessagesRes = await _messageLocalDataSource
          .getMessagesForConversation(conversationId);
      List<Message> convertedMessages = [];
      for (var message in getMessagesRes) {
        convertedMessages.add(MessageModel.fromDrift(message));
      }
      return convertedMessages;
    } catch (e) {
      print(e);
      throw Exception('Failed to get messages for conversation: $e');
    }
  }

  @override
  Future<void> fetchMessages(int conversationId) async {
    try {
      final messages = await _backendRemoteDataSource
          .getMessagesForConversation(conversationId);
      await _convoLocalDataSource.writeRemoteMessagesToLocal(messages);
    } catch (e) {
      print(e);
      throw Exception('Failed to fetch messages: $e');
    }
  }

  @override
  Future<void> fetchConvosForUser(String username) async {
    try {
      print("fetching ke remote disini...");
      final convos = await _backendRemoteDataSource.getConversationsForUser(
        username,
      );
      print("fetching selesai, hasil:");
      for (var convo in convos) {
        print(
          "convo id: ${convo.id}, receiver: ${convo.receiver}, createdAt: ${convo.createdAt}",
        );
      }

      print("fetching selesai");
      await _convoLocalDataSource.writeRemoteConvoToLocal(convos);
    } catch (e) {
      print(e);
      throw Exception('Failed to fetch conversations for user: $e');
    }
  }

  @override
  Future<void> sendMessage(
    int conversationId,
    String sender,
    String text,
    String receiver,
  ) async {
    // Implementation for sending a message
    try {
      final newMessageId = await _messageLocalDataSource.createMessage(
        conversationId,
        sender,
        text,
        DateTime.now(),
        "sending",
      );
      _webSocketRemoteDatasource.sendMessage(
        text,
        sender,
        receiver,
        conversationId,
      );
      await _messageLocalDataSource.updateMessageStatus(newMessageId, "sent");
    } catch (e) {
      print(e);
      throw Exception('Failed to send message: $e');
    }

    return;
  }

  // menyesuaikan jika user1 ataupun user2 adalah user yang login, mengubah user2 menjadi user1 jika user2 adalah user yang login, dan sebaliknya. Hal ini untuk memudahkan tampilan di UI agar selalu menampilkan lawan bicara sebagai receiver.
  // @override
  // Future<void> formatSenderAndReceiver() async {
  //   try {
  //     await _convoLocalDataSource.formatSenderAndReceiver();
  //   } catch (e) {
  //     print(e);
  //     throw Exception('Failed to format sender and receiver: $e');
  //   }
  // }
}
