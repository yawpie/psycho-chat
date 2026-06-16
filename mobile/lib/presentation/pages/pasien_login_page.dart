import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:psycho_chat/presentation/pages/chat_page.dart';
import 'package:psycho_chat/presentation/providers/login_notifier.dart';

class PasienLoginPage extends ConsumerStatefulWidget {
  const PasienLoginPage({super.key});

  @override
  ConsumerState<PasienLoginPage> createState() => _PasienLoginPageState();
}

class _PasienLoginPageState extends ConsumerState<PasienLoginPage> {
  final passwordController = TextEditingController();

  bool obscurePassword = true;

  static const primaryPurple = Color(0xFFB57BEA);
  static const darkPurple = Color(0xFF7D4BC7);

  void _handleSubmit() async {
    final password = passwordController.text;
    if (password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Password tidak boleh kosong"),
        ),
      );
      return;
    }
    try {
      await ref.read(loginNotifierProvider.notifier).login("pasien", password);
      print("Login berhasil");
    } catch (e) {
      print("Login gagal");
    }
  }

  @override
  Widget build(BuildContext context) {
    final loginState = ref.watch(loginNotifierProvider);
    return Scaffold(
      backgroundColor: const Color(0xFFF8F2FF),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              children: [
                const SizedBox(height: 20),

                // Logo
                Image.asset("assets/images/logo.png", width: 140),

                const SizedBox(height: 20),

                const Text(
                  "Welcome Back",
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: darkPurple,
                  ),
                ),

                const SizedBox(height: 10),

                Text(
                  "Masukkan password Anda\nuntuk melanjutkan sesi konsultasi",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade700, height: 1.5),
                ),

                const SizedBox(height: 40),

                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: .05),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      TextField(
                        controller: passwordController,
                        obscureText: obscurePassword,
                        decoration: InputDecoration(
                          labelText: "Password",
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            onPressed: () {
                              setState(() {
                                obscurePassword = !obscurePassword;
                              });
                            },
                            icon: Icon(
                              obscurePassword
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            // login
                            
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryPurple,
                            elevation: 0,
                          ),
                          child: const Text(
                            "Masuk",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                Text(
                  "PsychoChat",
                  style: TextStyle(
                    color: Colors.grey.shade500,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
