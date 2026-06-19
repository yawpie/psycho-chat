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

  Message copyWith({
    String? id,
    String? sender,
    String? message,
    DateTime? createdAt,
    String? status,
    String? conversationId,
    String? clientMessageId,
  }) {
    return Message(
      id: id ?? this.id,
      sender: sender ?? this.sender,
      message: message ?? this.message,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
      conversationId: conversationId ?? this.conversationId,
      clientMessageId: clientMessageId ?? this.clientMessageId,
    );
  }

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
