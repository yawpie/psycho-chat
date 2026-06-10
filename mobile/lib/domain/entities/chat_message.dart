class Message {
  const Message({
    required this.id,
    required this.sender,
    required this.text,
    required this.timestamp,
    required this.status,
  });

  final String id;
  final String sender;
  final String text;
  final DateTime timestamp;
  final String status;
}

class Conversation {
  final String id;
  final List<Message> messages;

  const Conversation({
    required this.id,
    required this.messages,
  });
}
