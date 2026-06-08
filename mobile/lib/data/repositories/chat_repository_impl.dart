import 'package:psycho_chat/data/datasources/websocket_remote_datasource.dart';
import 'package:psycho_chat/domain/entities/chat_message.dart';
import 'package:psycho_chat/domain/repositories/chat_repository.dart';

class ChatRepositoryImpl implements ChatRepository {
  ChatRepositoryImpl({WebSocketRemoteDatasource? datasource})
    : _datasource = datasource ?? WebSocketRemoteDatasource();

  final WebSocketRemoteDatasource _datasource;

  @override
  Stream<ChatMessage> get messageStream => _datasource.messageStream;

  @override
  bool get isConnected => _datasource.isConnected;

  @override
  Future<void> connect() => _datasource.connect();

  @override
  void sendMessage(String text) => _datasource.sendMessage(text);

  @override
  Future<void> disconnect() => _datasource.disconnect();
}
