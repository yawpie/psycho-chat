import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:psycho_chat/core/providers.dart';
import 'package:psycho_chat/domain/entities/chat_message.dart';
import 'package:psycho_chat/domain/repositories/chat_repository.dart';
import 'package:psycho_chat/domain/repositories/convo_repository.dart';
import 'package:psycho_chat/domain/usecases/message.dart';
import 'package:psycho_chat/presentation/providers/chat_notifier.dart';

class _MockChatRepository implements ChatRepository {
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
  void sendMessage(
    String text,
    String username,
    String receiver,
    int conversationId,
  ) {}

  @override
  Future<void> disconnect() async {
    connected = false;
  }
}

class _FakeConvoRepository implements ConvoRepository {
  @override
  Future<void> createConversation(String user1, String user2) async {}

  @override
  Future<void> fetchConvosForUser(String username) async {}

  @override
  Future<void> fetchMessages(int conversationId) async {}

  @override
  Future<List<Conversation>> getConversationsForUser(String username) async =>
      [];

  @override
  Future<List<Message>> getMessagesForConversation(int conversationId) async =>
      [];

  @override
  Future<void> sendMessage(
    int conversationId,
    String sender,
    String text,
  ) async {}
}

Message _message(int id, int conversationId) => Message(
  id: id,
  sender: 'sender',
  message: 'message $id',
  createdAt: DateTime(2026),
  status: 'sent',
  conversationId: conversationId,
);

ProviderContainer _container() {
  final container = ProviderContainer(
    overrides: [
      messageUseCaseProvider.overrideWithValue(
        MessageUseCase(_FakeConvoRepository()),
      ),
    ],
  );
  container.read(usernameProvider.notifier).state = 'current_user';
  return container;
}

void main() {
  test('appends messages for the active conversation in order', () async {
    final repository = _MockChatRepository();
    final container = _container();
    final providerSubscription = container.listen(
      chatNotifierProvider,
      (_, _) {},
      fireImmediately: true,
    );
    addTearDown(() async {
      providerSubscription.close();
      container.dispose();
      await repository.controller.close();
    });

    container
        .read(chatNotifierProvider.notifier)
        .initialize(repository, 1, 'receiver');
    await Future<void>.delayed(const Duration(milliseconds: 10));

    repository.controller.add(_message(1, 1));
    repository.controller.add(_message(2, 1));
    await Future<void>.delayed(Duration.zero);

    expect(
      container
          .read(chatNotifierProvider)
          .messages
          .map((message) => message.id),
      [1, 2],
    );
  });

  test('ignores messages from another conversation', () async {
    final repository = _MockChatRepository();
    final container = _container();
    final providerSubscription = container.listen(
      chatNotifierProvider,
      (_, _) {},
      fireImmediately: true,
    );
    addTearDown(() async {
      providerSubscription.close();
      container.dispose();
      await repository.controller.close();
    });

    container
        .read(chatNotifierProvider.notifier)
        .initialize(repository, 1, 'receiver');
    await Future<void>.delayed(const Duration(milliseconds: 10));

    repository.controller.add(_message(1, 2));
    await Future<void>.delayed(Duration.zero);

    expect(container.read(chatNotifierProvider).messages, isEmpty);
  });

  test('reports the shared socket connection status', () async {
    final repository = _MockChatRepository();
    final container = _container();
    final providerSubscription = container.listen(
      chatNotifierProvider,
      (_, _) {},
      fireImmediately: true,
    );
    addTearDown(() async {
      providerSubscription.close();
      container.dispose();
      await repository.controller.close();
    });

    container
        .read(chatNotifierProvider.notifier)
        .initialize(repository, 1, 'receiver');
    await Future<void>.delayed(const Duration(milliseconds: 10));

    expect(container.read(chatNotifierProvider).isConnected, isTrue);
  });
}
