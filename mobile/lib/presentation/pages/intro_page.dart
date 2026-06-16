import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:psycho_chat/core/providers.dart';
import 'package:psycho_chat/presentation/pages/pasien_chat_page.dart';
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
  bool _loginChecked = false;
  bool _isCheckingLogin = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkLogin();
    });
  }

  Future<void> _checkLogin() async {
    // Guard: jangan jalankan ulang jika sudah pernah jalan di lifecycle ini
    if (_loginChecked) return;
    _loginChecked = true;

    try {
      final isLoggedIn = await ref
          .read(loginNotifierProvider.notifier)
          .checkLoginStatus();

      if (!mounted) return;

      if (isLoggedIn) {
        final role = ref.read(userRoleProvider);
        if (role == 'PASIEN') {
          final convoId = ref.read(pasienConvoIdProvider);
          final username = ref.read(usernameProvider);
          if (convoId != null && username != null) {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(
                builder: (_) =>
                    PasienChatPage(convoId: convoId, pasienUsername: username),
              ),
              (_) => false,
            );
            return;
          }
        }
        // Default: psikiater
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const PsikiaterConversationsPage()),
          (_) => false,
        );
        return;
      }

      if (mounted) {
        setState(() {
          _isCheckingLogin = false;
        });
      }
    } catch (e) {
      debugPrint('Check login failed: $e');
      if (mounted) {
        setState(() {
          _isCheckingLogin = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F2FF),
      body: SafeArea(
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: IgnorePointer(
                ignoring: _isCheckingLogin,
                child: Opacity(
                  opacity: _isCheckingLogin ? 0.45 : 1,
                  child: Column(
                    children: [
                      const Spacer(),

                      // Logo
                      Image.asset('assets/images/logo.png', width: 180),

                      const SizedBox(height: 20),

                      const Text(
                        "PsychoChat",
                        style: TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF7D4BC7),
                        ),
                      ),

                      const SizedBox(height: 12),

                      const Text(
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
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
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
                                builder: (context) =>
                                    const PsikiaterLoginPage(),
                              ),
                            );
                          },
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(
                              color: Color(0xFFB57BEA),
                              width: 2,
                            ),
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

                      const Text(
                        "Versi 1.0.0",
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),

                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
            if (_isCheckingLogin)
              const Positioned.fill(
                child: IgnorePointer(
                  child: Center(
                    child: SizedBox(
                      width: 28,
                      height: 28,
                      child: CircularProgressIndicator(strokeWidth: 2.5),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
