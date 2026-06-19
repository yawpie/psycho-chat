import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:psycho_chat/core/providers.dart';
import 'package:psycho_chat/presentation/pages/pasien_chat_page.dart';
import 'package:psycho_chat/presentation/pages/pasien_login_page.dart';
import 'package:psycho_chat/presentation/pages/psikiater_conversations_page.dart';
import 'package:psycho_chat/presentation/pages/psikiater_login_page.dart';
import 'package:psycho_chat/presentation/providers/login_notifier.dart';
import 'package:psycho_chat/presentation/providers/settings_notifier.dart';

class IntroPage extends ConsumerStatefulWidget {
  const IntroPage({super.key});

  @override
  ConsumerState<IntroPage> createState() => _IntroPageState();
}

class _IntroPageState extends ConsumerState<IntroPage> {
  bool _loginChecked = false;
  bool _isCheckingLogin = true;
  final _backendLinkController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkBackendIp();
      _checkLogin();
    });
  }

  Future<void> _checkBackendIp() async {
    try {
      final backendIp = await ref
          .read(settingsNotifierProvider.notifier)
          .getBackendIp();
      if (!mounted) return;
      _backendLinkController.text = backendIp;
    } on Exception catch (e) {
      print("Error loading backend IP: $e");
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error loading backend IP: $e')));
    }
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
            SingleChildScrollView(
              padding: EdgeInsets.only(
                left: 32,
                right: 32,
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: IgnorePointer(
                ignoring: _isCheckingLogin,
                child: Opacity(
                  opacity: _isCheckingLogin ? 0.45 : 1,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight:
                          MediaQuery.of(context).size.height -
                          MediaQuery.of(context).padding.top,
                    ),
                    child: IntrinsicHeight(
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
                                    builder: (context) =>
                                        const PasienLoginPage(),
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
                          const SizedBox(height: 16),
                          TextField(
                            controller: _backendLinkController,
                            decoration: InputDecoration(
                              hintText: "Link Backend (untuk testing)",
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: const BorderSide(width: 2),
                              ),
                              disabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: const BorderSide(width: 2),
                              ),
                            ),
                          ),
                          SizedBox(height: 8),
                          ElevatedButton(
                            onPressed: _isLoading
                                ? null
                                : () async {
                                    final link = _backendLinkController.text
                                        .trim();
                                    if (link.isNotEmpty) {
                                      if (!mounted) return;
                                      setState(() {
                                        _isLoading = true;
                                      });
                                      try {
                                        await ref
                                            .read(
                                              settingsNotifierProvider.notifier,
                                            )
                                            .updateBackendIp(link)
                                            .then((_) {
                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                const SnackBar(
                                                  content: Text(
                                                    "Backend IP updated successfully",
                                                  ),
                                                ),
                                              );
                                            });
                                      } catch (e) {
                                        print("error updating backend IP: $e");
                                        if (!mounted) {
                                          return;
                                        }
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              "Error updating backend IP: $e",
                                            ),
                                          ),
                                        );
                                      } finally {
                                        setState(() {
                                          _isLoading = false;
                                        });
                                      }
                                    }
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFB57BEA),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text(
                                    "Connect to Backend",
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
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
