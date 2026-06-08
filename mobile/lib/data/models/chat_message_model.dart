import 'package:psycho_chat/domain/entities/chat_message.dart';

class ChatMessageModel extends ChatMessage {
  const ChatMessageModel({
    required super.id,
    required super.sender,
    required super.text,
    required super.timestamp,
  });

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) {
    return ChatMessageModel(
      id:
          json['id']?.toString() ??
          DateTime.now().microsecondsSinceEpoch.toString(),
      sender: json['sender']?.toString() ?? 'system',
      text: json['text']?.toString() ?? '',
      timestamp:
          DateTime.tryParse(json['timestamp']?.toString() ?? '') ??
          DateTime.now(),
    );
  }

  factory ChatMessageModel.system(String text) {
    return ChatMessageModel(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      sender: 'system',
      text: text,
      timestamp: DateTime.now(),
    );
  }
}
