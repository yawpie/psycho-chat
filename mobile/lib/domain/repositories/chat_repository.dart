import 'package:psycho_chat/domain/entities/chat_message.dart';

abstract class ChatRepository {
  Stream<Message> get messageStream;
  bool get isConnected;

  Future<void> connect();
  void sendMessage(String text);
  Future<void> disconnect();
}
