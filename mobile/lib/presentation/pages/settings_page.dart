import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:psycho_chat/core/constants/app_constants.dart';
import 'package:psycho_chat/core/providers.dart';
import 'package:psycho_chat/presentation/helper/confirmation_dialog_helper.dart';
import 'package:psycho_chat/presentation/pages/intro_page.dart';
import 'package:psycho_chat/presentation/providers/login_notifier.dart';
import 'package:psycho_chat/presentation/providers/settings_notifier.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});
  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  bool isLoading = false;
  bool isSavingBackendIp = false;
  final TextEditingController backendIpController = TextEditingController();

  @override
  void initState() {
    super.initState();
    Future.microtask(_loadBackendIp);
  }

  @override
  void dispose() {
    backendIpController.dispose();
    super.dispose();
  }

  Future<void> _loadBackendIp() async {
    final backendIp = await ref
        .read(settingsNotifierProvider.notifier)
        .getBackendIp();
    if (!mounted) return;
    backendIpController.text = backendIp;
  }
  // validasi format link tanpa protokol http/https, hanya IP address atau domain sederhana
  bool _isValidLink(String value) {
    // final ipv4Pattern = RegExp(
    //   r'^(25[0-5]|2[0-4]\d|1?\d?\d)(\.(25[0-5]|2[0-4]\d|1?\d?\d)){3}$',
    // );
    // contoh domain: "3dfd-103-156-165-116.ngrok-free.app"
    final ipv4Pattern = RegExp(
      r'^(?:(?:25[0-5]|2[0-4]\d|1?\d?\d)(?:\.(?!$)|$)){4}$',
    );
    final domainPattern = RegExp(
      r'^[a-zA-Z0-9]([a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9]([a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])?)*$',
    );
    return ipv4Pattern.hasMatch(value.trim()) || domainPattern.hasMatch(value.trim());
  }

  Future<void> _saveBackendIp() async {
    final backendIp = backendIpController.text.trim();
    if (!_isValidLink(backendIp)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Masukkan IP address atau domain yang valid')),
      );
      return;
    }

    setState(() {
      isSavingBackendIp = true;
    });

    try {
      await ref
          .read(settingsNotifierProvider.notifier)
          .updateBackendIp(backendIp);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Backend IP disimpan: $backendIp')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menyimpan backend IP: $error')),
      );
    } finally {
      if (mounted) {
        setState(() {
          isSavingBackendIp = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = ref.watch(isDarkModeProvider);

    ref.listen(loginNotifierProvider, (previous, next) {
      final isCurrentRoute = ModalRoute.of(context)?.isCurrent ?? false;
      final shouldRedirect =
          previous?.status == LoginStatus.loading &&
          next.status == LoginStatus.idle &&
          isCurrentRoute;

      if (shouldRedirect) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const IntroPage()),
          (_) => false,
        );
      }
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Pengaturan')),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              'Koneksi Backend (jangan tuliskan http:// atau https://, cukup IP address atau domain)',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: backendIpController,
              keyboardType: TextInputType.url,
              inputFormatters: [
                // FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                FilteringTextInputFormatter.deny(RegExp(r'\s')),
              ],
              decoration: const InputDecoration(
                labelText: 'IP address backend',
                hintText: '192.168.1.108',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Saat ini: ${AppConstants.ip}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
                const SizedBox(width: 12),
                FilledButton(
                  onPressed: isSavingBackendIp ? null : _saveBackendIp,
                  child: isSavingBackendIp
                      ? const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Simpan'),
                ),
              ],
            ),
          ),
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
                ref.read(isDarkModeProvider.notifier).state = false;
                ref.read(loginNotifierProvider.notifier).logout();
              }
            },
          ),
        ],
      ),
    );
  }
}
