class Message {
  const Message({
    required this.id,
    required this.sender,
    required this.text,
    required this.timestamp,
    required this.status,
    required this.conversationId,
  });

  final String id;
  final String sender;
  final String text;
  final DateTime timestamp;
  final String status;
  final String conversationId;
}

class Conversation {
  final String id;
  // final List<Message> messages;
  final String user1;
  final String user2;
  final String? password;

  const Conversation({
    required this.id,
    // required this.messages,
    required this.user1,
    required this.user2,
    this.password,
  });
}
