import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:psycho_chat/core/constants/app_constants.dart';
import 'package:psycho_chat/core/network/dio_client.dart';
import 'package:psycho_chat/core/providers.dart';
import 'package:psycho_chat/presentation/providers/conversations_notifier.dart';

class SettingsNotifier extends Notifier<void> {
  @override
  void build() {}

  /// untuk tombol hapus data di settings page
  Future<void> clearAllData() async {
    await ref.read(settingsUseCaseProvider).clearAllConversationsData();
    await ref.read(settingsUseCaseProvider).clearAllMessages();
    await ref.read(conversationsNotifierProvider.notifier).clearConversations();
  }

  Future<String> getBackendIp() async {
    final storedBackendIp = await ref
        .read(secureDataSourceProvider)
        .readBackendIp();
    final backendIp = storedBackendIp?.trim();
    if (backendIp == null || backendIp.isEmpty) {
      return AppConstants.ip;
    }
    return backendIp;
  }

  Future<void> updateBackendIp(String backendIp) async {
    final normalizedBackendIp = backendIp.trim();
    if (normalizedBackendIp.isEmpty) {
      throw ArgumentError('Backend IP tidak boleh kosong');
    }

    await ref
        .read(secureDataSourceProvider)
        .writeBackendIp(normalizedBackendIp);
    AppConstants.ip = normalizedBackendIp;
    DioClient.updateBaseUrl();
    await ref.read(websocketRemoteDatasourceProvider).disconnect();
  }
}

final settingsNotifierProvider = NotifierProvider<SettingsNotifier, void>(
  () => SettingsNotifier(),
);
