import 'package:psycho_chat/domain/entities/chat_message.dart';

abstract class ChatRepository {
  Stream<ChatMessage> get messageStream;
  bool get isConnected;

  Future<void> connect();
  void sendMessage(String text);
  Future<void> disconnect();
}
