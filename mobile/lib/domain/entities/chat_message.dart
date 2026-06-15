class Message {
  const Message({
    required this.id,
    required this.sender,
    required this.message,
    required this.createdAt,
    required this.status,
    required this.conversationId,
  });

  final int id;
  final String sender;
  final String message;
  final DateTime createdAt;
  final String status;
  final int conversationId;
}

class Conversation {
  final int id;
  final String receiver;
  final DateTime createdAt;
  final String? password;

  const Conversation({
    required this.id,
    required this.receiver,
    required this.createdAt,
    this.password,
  });
}
