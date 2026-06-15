import 'package:psycho_chat/domain/entities/chat_message.dart' as entity;
import 'package:psycho_chat/data/datasources/local/app_database.dart' as drift;

class MessageModel extends entity.Message {
  const MessageModel({
    required super.id,
    required super.sender,
    required super.message,
    required super.createdAt,
    required super.status,
    required super.conversationId,
  });

  static entity.Message fromDrift(drift.Message data) {
    return entity.Message(
      id: data.id,
      conversationId: data.conversationId ?? -1,
      sender: data.sender,
      message: data.message,
      createdAt: data.createdAt,
      status: data.status,
    );
  }

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    final rawId = json['id'];
    final rawConversationId = json['conversationId'];
    final status = json['status']?.toString() ?? 'sent';

    return MessageModel(
      id: rawId is int ? rawId : int.tryParse(rawId?.toString() ?? '') ?? -1,
      sender: json['sender']?.toString() ?? 'system',
      message: json['message']?.toString() ?? 'systemchat',
      createdAt:
          DateTime.tryParse(
            (json['createdAt'] ?? json['timestamp'])?.toString() ?? '',
          ) ??
          DateTime.now(),
      status: json['status']?.toString() ?? 'sent',
      conversationId: rawConversationId is int
          ? rawConversationId
          : int.tryParse(rawConversationId?.toString() ?? '') ?? -1,
    );
  }

  factory MessageModel.system(String text) {
    return MessageModel(
      id: -1,
      sender: 'system',
      message: text,
      createdAt: DateTime.now(),
      status: 'sent',
      conversationId: -1,
    );
  }
}

class ConversationModel extends entity.Conversation {
  const ConversationModel({
    required super.id,
    required super.receiver,
    required super.createdAt,
    super.password,
  });

  static ConversationModel fromDrift(drift.Conversation data) {
    return ConversationModel(
      id: data.id,
      receiver: data.receiver,
      createdAt: data.createdAt,
      password: data.password,
    );
  }

  factory ConversationModel.fromJson(
    Map<String, dynamic> json,
    String currentUsername,
  ) {
    final String receiver;
    print("json user1: ${json['user1']}, json user2: ${json['user2']}, currentUsername: $currentUsername");
    if (json['user1']?.toString() == currentUsername) {
      receiver = json['user2']?.toString() ?? '';
    } else if (json['user2']?.toString() == currentUsername) {
      receiver = json['user1']?.toString() ?? '';
    } else {
      receiver = '';
    }
    print("receiver yang dipilih: $receiver");
    return ConversationModel(
      id: json['id'] is int
          ? json['id']
          : int.tryParse(json['id']?.toString() ?? '') ?? -1,
      receiver: receiver,
      createdAt:
          DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.now(),
      password: json['password']?.toString() ?? '',
    );
  }
}
