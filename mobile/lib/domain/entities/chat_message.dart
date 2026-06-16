class Message {
  const Message({
    this.id,
    required this.sender,
    required this.message,
    required this.createdAt,
    required this.status,
    required this.conversationId,
    required this.clientMessageId,
  });

  final String? id;
  final String clientMessageId;
  final String sender;
  final String message;
  final DateTime createdAt;
  final String status;
  final String conversationId;
}

class Conversation {
  final String id;
  final String receiver;
  final String? displayName;
  final DateTime createdAt;
  final String? password;

  const Conversation({
    required this.id,
    required this.receiver,
    this.displayName,
    required this.createdAt,
    this.password,
  });
}
