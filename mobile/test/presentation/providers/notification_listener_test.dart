import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:psycho_chat/core/notifications/local_notification_service.dart';
import 'package:psycho_chat/core/providers.dart';
import 'package:psycho_chat/domain/entities/chat_message.dart';
import 'package:psycho_chat/domain/repositories/chat_repository.dart';
import 'package:psycho_chat/presentation/providers/notification_listener.dart';

class _FakeNotificationService extends LocalNotificationService {
  final shownMessages = <Message>[];

  @override
  Future<void> initialize() async {}

  @override
  Future<void> requestPermissions() async {}

  @override
  Future<void> showNewMessage(Message message) async {
    shownMessages.add(message);
  }
}

class _FakeChatRepository implements ChatRepository {
  final controller = StreamController<Message>.broadcast();
  bool connected = false;

  @override
  Stream<Message> get messageStream => controller.stream;

  @override
  bool get isConnected => connected;

  @override
  Future<void> connect(String username) async {
    connected = true;
  }

  @override
  Future<void> disconnect() async {
    connected = false;
  }

  @override
  void sendMessage(
    String text,
    String username,
    String receiver,
    int conversationId,
  ) {}
}

Message _message({required int id, required String sender}) => Message(
  id: id,
  sender: sender,
  message: 'message $id',
  createdAt: DateTime(2026),
  status: 'sent',
  conversationId: 1,
);

void main() {
  test('shows notifications only for incoming user messages', () async {
    final repository = _FakeChatRepository();
    final notificationService = _FakeNotificationService();
    final container = ProviderContainer(
      overrides: [
        chatRepositoryProvider.overrideWithValue(repository),
        localNotificationServiceProvider.overrideWithValue(notificationService),
      ],
    );
    addTearDown(() async {
      container.dispose();
      await repository.controller.close();
    });

    container.read(usernameProvider.notifier).state = 'current_user';
    container.read(notificationListenerProvider);
    await Future<void>.delayed(Duration.zero);

    repository.controller.add(_message(id: 1, sender: 'other_user'));
    repository.controller.add(_message(id: 2, sender: 'current_user'));
    repository.controller.add(_message(id: 3, sender: 'system'));
    await Future<void>.delayed(Duration.zero);

    expect(notificationService.shownMessages.map((message) => message.id), [1]);
  });
}
