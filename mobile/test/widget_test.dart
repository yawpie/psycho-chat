import 'package:flutter_test/flutter_test.dart';
import 'package:psycho_chat/main.dart';

void main() {
  test('ChatMessage parses JSON payload', () {
    final message = ChatMessage.fromJson(<String, dynamic>{
      'id': '1',
      'sender': 'system',
      'text': 'hello',
      'timestamp': '2026-05-18T15:00:00.000Z',
    });

    expect(message.id, '1');
    expect(message.sender, 'system');
    expect(message.text, 'hello');
    expect(message.timestamp.toUtc().toIso8601String(), '2026-05-18T15:00:00.000Z');
  });
}
