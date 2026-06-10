// ignore_for_file: library_prefixes

import 'package:psycho_chat/domain/entities/chat_message.dart' as MessageEntity;
import 'package:psycho_chat/data/datasources/local/app_database.dart' as DbData;

class MessageModel extends MessageEntity.Message {
  const MessageModel({
    required super.id,
    required super.sender,
    required super.text,
    required super.timestamp,
    required super.status,
    required super.conversationId,
  });

  static MessageEntity.Message fromDrift(DbData.Message data) {
    return MessageEntity.Message(
      id: data.id.toString(),
      conversationId: data.conversationId.toString(),
      sender: data.sender,
      text: data.message,
      timestamp: data.timestamp,
      status: data.status,
    );
  }

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id:
          json['id']?.toString() ??
          DateTime.now().microsecondsSinceEpoch.toString(),
      sender: json['sender']?.toString() ?? 'system',
      text: json['text']?.toString() ?? '',
      timestamp:
          DateTime.tryParse(json['timestamp']?.toString() ?? '') ??
          DateTime.now(),
      status: json['status']?.toString() ?? 'sent',
      conversationId: json['conversationId']?.toString() ?? '',
    );
  }

  factory MessageModel.system(String text) {
    return MessageModel(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      sender: 'system',
      text: text,
      timestamp: DateTime.now(),
      status: 'sent',
      conversationId: '',
    );
  }
}

class ConversationModel extends MessageEntity.Conversation {
  const ConversationModel({required super.id, required super.user1, required super.user2, super.password});

  static MessageEntity.Conversation fromDrift(
    DbData.Conversation data,
    List<MessageEntity.Message> messages,
  ) {
    return MessageEntity.Conversation(
      id: data.id.toString(),
      user1: data.user1,
      user2: data.user2,
      password: data.password,
    );
  }

  
}
