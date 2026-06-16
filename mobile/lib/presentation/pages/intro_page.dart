import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:psycho_chat/core/providers.dart';
import 'package:psycho_chat/presentation/pages/pasien_create_page.dart';
import 'package:psycho_chat/presentation/pages/pasien_login_page.dart';
import 'package:psycho_chat/presentation/pages/psikiater_conversations_page.dart';
import 'package:psycho_chat/presentation/pages/psikiater_login_page.dart';
import 'package:psycho_chat/presentation/providers/login_notifier.dart';

class IntroPage extends ConsumerStatefulWidget {
  const IntroPage({super.key});

  @override
  ConsumerState<IntroPage> createState() => _IntroPageState();
}

class _IntroPageState extends ConsumerState<IntroPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkLogin();
    });
  }

  Future<void> _checkLogin() async {
    try {
      final isLoggedIn = await ref
          .read(loginNotifierProvider.notifier)
          .checkLoginStatus();

      if (!mounted) return;

      if (isLoggedIn) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const PsikiaterConversationsPage()),
          (_) => false,
        );
      }
    } catch (e) {
      debugPrint('Check login failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F2FF),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            children: [
              const Spacer(),

              // Logo
              Image.asset('assets/images/logo.png', width: 180),

              const SizedBox(height: 20),

              Text(
                "PsychoChat",
                style: TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF7D4BC7),
                ),
              ),

              const SizedBox(height: 12),

              Text(
                "Temukan dukungan kesehatan mental\nbersama profesional terpercaya",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black54,
                  height: 1.5,
                ),
              ),

              const Spacer(),

              // Pasien Button
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const PasienLoginPage(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFB57BEA),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    "Mulai sebagai Pasien",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Psikiater Button
              SizedBox(
                width: double.infinity,
                height: 55,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const PsikiaterLoginPage(),
                      ),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFB57BEA), width: 2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    "Login sebagai Psikiater",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFB57BEA),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 40),

              Text(
                "Versi 1.0.0",
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
