import 'package:psycho_chat/domain/entities/chat_message.dart' as entity;
import 'package:psycho_chat/data/datasources/local/app_database.dart' as drift;
import 'package:uuid/uuid.dart';

class MessageModel extends entity.Message {
  const MessageModel({
    required super.id,
    required super.sender,
    required super.message,
    required super.createdAt,
    required super.status,
    required super.conversationId,
    required super.clientMessageId,
  });

  static entity.Message fromDrift(drift.Message data) {
    return entity.Message(
      id: data.id,
      clientMessageId: data.clientMessageId,
      conversationId: data.conversationId,
      sender: data.sender,
      message: data.message,
      createdAt: data.createdAt,
      status: data.status,
    );
  }

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    final rawId = json['id'];
    final rawConversationId = json['conversationId'];

    return MessageModel(
      id: rawId is String ? rawId : json['id']?.toString() ?? '',
      clientMessageId: json['clientMessageId'] is String
          ? json['clientMessageId']
          : Uuid().v4(),
      sender: json['sender']?.toString() ?? 'system',
      message: json['message']?.toString() ?? 'systemchat',
      createdAt:
          DateTime.tryParse(
            (json['createdAt'] ?? json['timestamp'])?.toString() ?? '',
          ) ??
          DateTime.now(),
      status: json['status']?.toString() ?? 'sent',
      conversationId: rawConversationId is String
          ? rawConversationId
          : json['conversationId']?.toString() ?? '',
    );
  }

  factory MessageModel.system(String text) {
    return MessageModel(
      id: Uuid().v4(),
      sender: 'system',
      message: text,
      createdAt: DateTime.now(),
      status: 'sent',
      conversationId: Uuid().v4(),
      clientMessageId: Uuid().v4(),
    );
  }
}

class ConversationModel extends entity.Conversation {
  const ConversationModel({
    required super.id,
    required super.receiver,
    super.displayName,
    required super.createdAt,
    super.password,
  });

  static ConversationModel fromDrift(drift.Conversation data) {
    // if (data.id == null) {
    //   throw ArgumentError('Conversation ID cannot be null');
    // }
    return ConversationModel(
      id: data.id,
      receiver: data.receiver,
      displayName: data.displayName,
      createdAt: data.createdAt,
      password: data.password,
    );
  }

  factory ConversationModel.fromJson(
    Map<String, dynamic> json,
    String currentUsername,
  ) {
    final String receiver;
    final String displayName;
    print(
      "json user1: ${json['user1']}, json user2: ${json['user2']}, currentUsername: $currentUsername",
    );
    if (json['user1']?.toString() == currentUsername) {
      receiver = json['user2']?.toString() ?? '';
      displayName = json['user2DisplayName']?.toString() ?? receiver;
    } else if (json['user2']?.toString() == currentUsername) {
      receiver = json['user1']?.toString() ?? '';
      displayName = json['user1DisplayName']?.toString() ?? receiver;
    } else {
      receiver = '';
      displayName = '';
    }
    print("receiver yang dipilih: $receiver");
    return ConversationModel(
      id: json['id'] is String ? json['id'] : Uuid().v4(),
      receiver: receiver,
      displayName: displayName,
      createdAt:
          DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.now(),
      password: json['password']?.toString() ?? '',
    );
  }
}
