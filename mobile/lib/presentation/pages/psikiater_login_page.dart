// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:psycho_chat/presentation/pages/psikiater_conversations_page.dart';
import 'package:psycho_chat/presentation/providers/conversations_notifier.dart';
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
    try {
      await ref.read(loginNotifierProvider.notifier).login(username, password);
      print("Login berhasil");
    } catch (e) {
      print("Login gagal");
    }
  }

  @override
  Widget build(BuildContext context) {
    final loginState = ref.watch(loginNotifierProvider);
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
      appBar: AppBar(title: const Text("Psikiater Login")),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            spacing: 20.0,
            children: [
              TextField(
                controller: _usernameController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: "Username",
                  hintText: "Enter your username",
                ),
              ),
              TextField(
                controller: _passwordController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: "Password",
                  hintText: "Enter your password",
                ),
                obscureText: !_showPassword,
              ),
              CheckboxListTile(
                value: _showPassword,
                onChanged: (value) {
                  setState(() {
                    if (value == null) {
                      _showPassword = false;
                    } else {
                      _showPassword = value;
                    }
                  });
                },
                title: const Text("Show Password"),
              ),
              if (loginState.status == LoginStatus.error &&
                  loginState.errorMessage != null)
                Text(
                  loginState.errorMessage!,
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
              ElevatedButton(
                onPressed: isLoading ? null : _handleSubmit,
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.blue,
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
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}
