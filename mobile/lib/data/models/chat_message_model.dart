import 'package:psycho_chat/domain/entities/chat_message.dart';

class MessageModel extends Message {
  const MessageModel({
    required super.id,
    required super.sender,
    required super.text,
    required super.timestamp,
    required super.status,
  });

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
    );
  }

  factory MessageModel.system(String text) {
    return MessageModel(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      sender: 'system',
      text: text,
      timestamp: DateTime.now(),
      status: 'sent',
    );
  }
}
