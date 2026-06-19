// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:psycho_chat/core/configs/app_configs.dart';
import 'package:psycho_chat/core/constants/app_constants.dart';
import 'package:psycho_chat/core/network/dio_client.dart';
import 'package:psycho_chat/core/providers.dart';
import 'package:psycho_chat/presentation/pages/psikiater_conversations_page.dart';
import 'package:psycho_chat/presentation/providers/login_notifier.dart';

class PsikiaterLoginPage extends ConsumerStatefulWidget {
  const PsikiaterLoginPage({super.key});

  @override
  ConsumerState<PsikiaterLoginPage> createState() => _PsikiaterLoginPageState();
}

class _PsikiaterLoginPageState extends ConsumerState<PsikiaterLoginPage> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _showPassword = false;

  @override
  void initState() {
    super.initState();
    // Bersihkan hanya StateProvider in-memory (username, role, convoId)
    // tanpa memanggil logout() yang akan menulis ke SecureStorage dan
    // memicu listener di halaman lain.
    // WidgetsBinding.instance.addPostFrameCallback((_) {
    //   ref.read(usernameProvider.notifier).state = null;
    // });
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    final username = _usernameController.text;
    final password = _passwordController.text;
    print("Username: $username");
    print("Password: $password");
    if (username.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Username dan password tidak boleh kosong"),
        ),
      );
      return;
    }
    try {
      print("AppConfig.backendIp before login: ${AppConfig.backendIp}");
      print("AppConfig.apiBaseUrl = '${AppConfig.apiBaseUrl}'");
      print("DioClient.baseUrl = '${DioClient.dio.options.baseUrl}'");
      await ref.read(loginNotifierProvider.notifier).login(username, password);
      // final loginSuccess = await ref
      //     .read(loginNotifierProvider.notifier)
      //     .checkLoginStatus();
      // if (loginSuccess) {
      //   print("Login berhasil");
      // }
    } catch (e) {
      final String errorMessage;
      if (e is Exception || e.toString().contains('URL')) {
        print("Login error: ${e.toString()}");
        errorMessage =
            "Gagal terhubung ke server. Pastikan backend sudah berjalan dan IP benar.";
      } else {
        errorMessage = "Login gagal. Silakan coba lagi.";
        print("Login error: $e");
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(errorMessage)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loginState = ref.watch(loginNotifierProvider);
    print("LoginState: ${loginState.status}, username: ${loginState.username}");
    ref.listen<LoginState>(loginNotifierProvider, (previous, next) {
      if (next.status == LoginStatus.success) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) => const PsikiaterConversationsPage(),
          ),
          (_) => false,
        );
      }
    });
    final isLoading = loginState.status == LoginStatus.loading;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                // text alignment to left
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Username"),
                  TextField(
                    autofillHints: const [AutofillHints.username],
                    controller: _usernameController,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.person_outline),
                      hintText: "Enter your username",
                      filled: true,
                      fillColor: theme.colorScheme.surfaceContainer,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text("Password"),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          autofillHints: const [AutofillHints.password],
                          controller: _passwordController,

                          decoration: InputDecoration(
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              onPressed: () {
                                setState(() {
                                  _showPassword = !_showPassword;
                                });
                              },
                              icon: Icon(
                                !_showPassword
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                              ),
                            ),
                            hintText: "Enter your password",
                            filled: true,
                            fillColor: theme.colorScheme.surfaceContainer,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          obscureText: !_showPassword,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  ElevatedButton(
                    onPressed: isLoading ? null : _handleSubmit,
                    style: ElevatedButton.styleFrom(
                      foregroundColor: theme.colorScheme.onPrimary,
                      backgroundColor: theme.colorScheme.primary,
                      minimumSize: const Size(double.infinity, 48),
                    ),

                    child: isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text("Login"),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
