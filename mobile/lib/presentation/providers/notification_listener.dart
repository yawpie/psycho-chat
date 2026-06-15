import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:psycho_chat/core/providers.dart';

final notificationListenerProvider = Provider<void>((ref) {
  final username = ref.watch(usernameProvider);
  if (username == null) return;

  final repository = ref.watch(chatRepositoryProvider);
  final notificationService = ref.watch(localNotificationServiceProvider);

  final subscription = repository.messageStream.listen((message) {
    if (message.sender == username || message.sender == 'system') return;
    unawaited(notificationService.showNewMessage(message));
  });

  unawaited(() async {
    try {
      await notificationService.initialize();
      await notificationService.requestPermissions();
      await repository.connect(username);
    } catch (_) {
      // ChatPage exposes connection status and retry controls to the user.
    }
  }());

  ref.onDispose(() {
    unawaited(subscription.cancel());
    unawaited(repository.disconnect());
  });
});
