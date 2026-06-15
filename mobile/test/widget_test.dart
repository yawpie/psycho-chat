import 'package:flutter_test/flutter_test.dart';
import 'package:psycho_chat/data/models/chat_message_model.dart';

void main() {
  test('ChatMessageModel parses JSON payload', () {
    final message = MessageModel.fromJson(<String, dynamic>{
      'id': '1',
      'sender': 'system',
      'text': 'hello',
      'timestamp': '2026-05-18T15:00:00.000Z',
    });

    expect(message.id, '1');
    expect(message.sender, 'system');
    expect(message.message, 'hello');
    expect(
      message.createdAt.toUtc().toIso8601String(),
      '2026-05-18T15:00:00.000Z',
    );
  });
}
