import 'package:psycho_chat/data/datasources/local/app_database.dart' as DbData;
import 'package:psycho_chat/data/datasources/local/message_datasource.dart';
import 'package:psycho_chat/data/datasources/remote/backend_remote_datasource.dart';
import 'package:psycho_chat/data/datasources/remote/websocket_remote_datasource.dart';
import 'package:psycho_chat/data/models/chat_message_model.dart';
import 'package:psycho_chat/domain/entities/chat_message.dart';
import 'package:psycho_chat/domain/repositories/chat_repository.dart';

class ChatRepositoryImpl implements ChatRepository {
  ChatRepositoryImpl(
    this._websocketDatasource,
    this._messageLocalDataSource,
    this._backendDatasource,
  );
  final WebSocketRemoteDatasource _websocketDatasource;
  final MessageLocalDataSource _messageLocalDataSource;
  final BackendRemoteDataSource _backendDatasource;

  @override
  Stream<Message> get messageStream => _websocketDatasource.messageStream;

  @override
  bool get isConnected => _websocketDatasource.isConnected;

  @override
  Future<void> connect(String username) =>
      _websocketDatasource.connect(username);

  @override
  void sendMessage(
    String text,
    String username,
    String receiver,
    String conversationId,
    String clientMessageId,
  ) {
    _messageLocalDataSource.createMessage(
      conversationId,
      username,
      text,
      DateTime.now(),
      'pending',
      clientMessageId,
    );
    _websocketDatasource.sendMessage(
      text,
      username,
      receiver,
      conversationId,
      clientMessageId,
    );
  }

  @override
  Future<void> disconnect() => _websocketDatasource.disconnect();

  @override
  Future<void> updateMessageStatus(String clientMessageId, String status) =>
      _messageLocalDataSource.updateMessageStatus(clientMessageId, status);

  @override
  Future<void> fetchMessages(String conversationId) async {
    try {
      final messages = await _backendDatasource.getMessageForConversationRemote(
        conversationId,
      );
      // final convoExists = await _convoLocalDataSource.checkIfConversationExists(conversationId);
      await _messageLocalDataSource.writeRemoteMessagesToLocal(messages);
    } catch (e) {
      print(e);
      throw Exception('Failed to fetch messages: $e');
    }
  }

  @override
  Future<List<Message>> getMessagesForConversation(
    String conversationId,
  ) async {
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
  Future<void> clearLocalConversations() async {
    try {
      await _messageLocalDataSource.clearAllMessages();
    } catch (e) {
      print(e);
      throw Exception('Failed to clear local conversations: $e');
    }
  }
}
