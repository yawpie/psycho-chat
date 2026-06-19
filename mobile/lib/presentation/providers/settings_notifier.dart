import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:psycho_chat/core/configs/app_configs.dart';
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
      return AppConfig.backendIp ?? '';
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
    AppConfig.backendIp = normalizedBackendIp;
    print("Backend IP updated to: ${AppConfig.backendIp}");
    DioClient.updateBaseUrl();
    print("Dio base URL updated to: ${DioClient.dio.options.baseUrl}");
    await ref.read(websocketRemoteDatasourceProvider).disconnect();
  }
}

final settingsNotifierProvider = NotifierProvider<SettingsNotifier, void>(
  () => SettingsNotifier(),
);
