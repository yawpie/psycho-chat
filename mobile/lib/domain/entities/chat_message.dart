class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.sender,
    required this.text,
    required this.timestamp,
  });

  final String id;
  final String sender;
  final String text;
  final DateTime timestamp;
}
