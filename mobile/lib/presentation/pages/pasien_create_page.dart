import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:psycho_chat/core/encryption/aes_gcm_service.dart';
import 'package:psycho_chat/core/providers.dart';
import 'package:psycho_chat/presentation/providers/conversations_notifier.dart';
import 'package:psycho_chat/presentation/providers/login_notifier.dart';

class PasienCreatePage extends ConsumerStatefulWidget {
  const PasienCreatePage({super.key});

  @override
  ConsumerState<PasienCreatePage> createState() => _PasienCreatePageState();
}

class _PasienCreatePageState extends ConsumerState<PasienCreatePage> {
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isPasswordGenerated = false;

  void _handleGeneratePassword() async {
    setState(() {
      _isLoading = true;
    });
    final generatedPassword = await AesGcmService.generateKey();
    _passwordController.text = generatedPassword;
    setState(() {
      _isLoading = false;
    });
    setState(() {
      _isPasswordGenerated = true;
    });
  }

  Future<void> _handleSubmitPatient() async {
    final fullName = _fullNameController.text.trim();
    final password = _passwordController.text.trim();
    if (fullName.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Nama lengkap dan password harus diisi")),
      );
      return;
    }
    setState(() {
      _isLoading = true;
    });
    try {
      final String? newPatient = await ref
          .read(loginNotifierProvider.notifier)
          .createNewPasien(fullName, password);
      if (newPatient == null) {
        throw Exception("Failed to create patient");
      }
      if (!mounted) return;

      // Fetch percakapan terbaru untuk mendapatkan conversationId yang baru dibuat
      await ref
          .read(conversationsNotifierProvider.notifier)
          .fetchConversations();
      if (!mounted) return;

      // Derive dan simpan kunci enkripsi untuk percakapan baru ini.
      // Cari percakapan dengan pasien yang baru dibuat berdasarkan receiver = newPatient.
      final conversations = ref
          .read(conversationsNotifierProvider)
          .conversations;
      final newConvo = conversations
          .where((c) => c.receiver == newPatient)
          .firstOrNull;

      if (newConvo != null) {
        // Selalu gunakan password plaintext yang diinput psikiater sebagai
        // material PBKDF2 — jangan gunakan convo.password dari server karena
        // itu adalah bcrypt hash yang akan menghasilkan kunci berbeda.
        await ref
            .read(encryptionUseCaseProvider)
            .setupEncryptionKeyForConversation(
              conversationId: newConvo.id,
              password: password,
            );
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Pasien berhasil dibuat")));
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Gagal membuat pasien: $e")));
      return;
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text("Create Patient")),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Nama Lengkap Pasien",
              style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
            ),
            TextField(
              controller: _fullNameController,
              decoration: InputDecoration(hintText: "Nama Pasien"),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isLoading ? null : _handleGeneratePassword,
              style: ElevatedButton.styleFrom(
                foregroundColor: theme.colorScheme.onPrimary,
                backgroundColor: theme.colorScheme.primary,
                minimumSize: const Size(double.infinity, 48),
              ),

              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text("Generate Password"),
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _passwordController,
                    decoration: InputDecoration(
                      hintText: "Generated Password...",
                    ),
                    readOnly: true,
                  ),
                ),
                SizedBox(width: 8),
                IconButton(
                  icon: Icon(Icons.content_copy),
                  style: IconButton.styleFrom(
                    padding: EdgeInsets.all(12),
                    foregroundColor: theme.colorScheme.onPrimaryContainer,
                    backgroundColor: theme.colorScheme.primaryContainer,
                    shape: CircleBorder(side: BorderSide.none),
                  ),
                  onPressed: () {
                    _fullNameController.text.isEmpty ||
                            _passwordController.text.isEmpty
                        ? ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                "Generate password terlebih dahulu",
                              ),
                            ),
                          )
                        : Clipboard.setData(
                            ClipboardData(text: _passwordController.value.text),
                          );
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Password copied to clipboard"),
                      ),
                    );
                  },
                ),
              ],
            ),
            _isPasswordGenerated
                ? Text(
                    "Password ini akan digunakan untuk login pasien. Pastikan untuk menyimpan password ini dengan aman.",
                    style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                  )
                : SizedBox.shrink(),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isLoading ? null : _handleSubmitPatient,
              style: ElevatedButton.styleFrom(
                foregroundColor: theme.colorScheme.onPrimary,
                backgroundColor: theme.colorScheme.primary,
                minimumSize: const Size(double.infinity, 48),
              ),

              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text("Simpan Pasien"),
            ),
          ],
        ),
      ),
    );
  }
}
