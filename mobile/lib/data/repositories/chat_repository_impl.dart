import 'package:psycho_chat/data/datasources/remote/websocket_remote_datasource.dart';
import 'package:psycho_chat/domain/entities/chat_message.dart';
import 'package:psycho_chat/domain/repositories/chat_repository.dart';

class ChatRepositoryImpl implements ChatRepository {
  ChatRepositoryImpl({required WebSocketRemoteDatasource datasource})
    : _datasource = datasource;

  final WebSocketRemoteDatasource _datasource;

  @override
  Stream<Message> get messageStream => _datasource.messageStream;

  @override
  bool get isConnected => _datasource.isConnected;

  @override
  Future<void> connect(String username) => _datasource.connect(username);

  @override
  void sendMessage(
    String text,
    String username,
    String receiver,
    int conversationId,
  ) => _datasource.sendMessage(text, username, receiver, conversationId);

  @override
  Future<void> disconnect() => _datasource.disconnect();
}
