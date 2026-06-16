import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:psycho_chat/core/providers.dart';
import 'package:psycho_chat/presentation/helper/confirmation_dialog_helper.dart';
import 'package:psycho_chat/presentation/providers/login_notifier.dart';
import 'package:psycho_chat/presentation/providers/settings_notifier.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});
  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  bool isLoading = false;
  @override
  Widget build(BuildContext context) {
    final isDarkMode = ref.watch(isDarkModeProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Pengaturan')),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SwitchListTile(
            title: Text('Mode Gelap'),
            value: isDarkMode,
            onChanged: (newValue) {
              ref.read(isDarkModeProvider.notifier).state = newValue;
            },
          ),
          ListTile(
            title: Text('Hapus data percakapan'),
            subtitle: Text(
              'Hapus semua data percakapan yang tersimpan di perangkat',
            ),
            leading: const Icon(Icons.delete),
            onTap: () async {
              final confirmed = await showConfirmationDialog(
                context,
                title: 'Konfirmasi Hapus Data',
                message:
                    'Apakah Anda yakin ingin menghapus semua data percakapan? Tindakan ini tidak dapat dibatalkan.',
              );
              if (confirmed) {
                // Implementasi penghapusan data percakapan di sini
                // Misalnya, memanggil method di repository untuk menghapus data lokal
                // await ref.read(chatRepositoryProvider).deleteAllConversations();
                setState(() {
                  isLoading = true;
                });
                await ref
                    .read(settingsNotifierProvider.notifier)
                    .clearAllData();
                setState(() {
                  isLoading = false;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Data percakapan telah dihapus'),
                    ),
                  );
                });
              }
            },
          ),
          ListTile(
            title: Text('Keluar'),
            trailing: const Icon(Icons.logout),
            onTap: () async {
              final confirmed = await showConfirmationDialog(
                context,
                title: 'Konfirmasi Keluar',
                message: 'Apakah Anda yakin ingin keluar?',
              );
              if (confirmed) {
                ref.read(loginNotifierProvider.notifier).logout();
              }
            },
          ),
        ],
      ),
    );
  }
}
