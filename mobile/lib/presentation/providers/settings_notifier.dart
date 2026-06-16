import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:psycho_chat/core/providers.dart';
import 'package:psycho_chat/presentation/providers/conversations_notifier.dart';

class SettingsNotifier extends Notifier<void> {
  @override
  void build() {}
/// untuk tombol hapus data di settings page
  Future<void> clearAllData() async {
    ref.read(settingsUseCaseProvider).clearAllConversationsData();
    ref.read(settingsUseCaseProvider).clearAllMessages();
    await ref.read(conversationsNotifierProvider.notifier).clearConversations();
  }
}

final settingsNotifierProvider = NotifierProvider<SettingsNotifier, void>(
  () => SettingsNotifier(),
);