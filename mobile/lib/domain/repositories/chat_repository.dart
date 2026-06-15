import 'package:psycho_chat/domain/entities/chat_message.dart';

abstract class ChatRepository {
  Stream<Message> get messageStream;
  bool get isConnected;

  Future<void> connect(String username);
  void sendMessage(
    String text,
    String username,
    String receiver,
    int conversationId,
  );
  Future<void> disconnect();
}
