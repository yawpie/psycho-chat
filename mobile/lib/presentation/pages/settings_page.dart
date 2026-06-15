import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:psycho_chat/core/providers.dart';
import 'package:psycho_chat/presentation/helper/confirmation_dialog_helper.dart';
import 'package:psycho_chat/presentation/providers/login_notifier.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});
  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
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
