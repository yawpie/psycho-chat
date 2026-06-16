import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:psycho_chat/core/providers.dart';
import 'package:psycho_chat/presentation/pages/intro_page.dart';
import 'package:psycho_chat/presentation/pages/settings_page.dart';
import 'package:psycho_chat/presentation/providers/chat_notifier.dart';
import 'package:psycho_chat/presentation/providers/login_notifier.dart';
import 'package:psycho_chat/presentation/widgets/message_bubble.dart';
import 'package:psycho_chat/presentation/widgets/message_composer.dart';

/// Halaman chat khusus pasien.
///
/// Pasien hanya bisa melihat halaman ini setelah login —
/// tidak ada akses ke halaman lain kecuali logout.
class PasienChatPage extends ConsumerStatefulWidget {
  const PasienChatPage({
    super.key,
    required this.convoId,
    required this.pasienUsername,
  });

  final String convoId;
  final String pasienUsername;

  @override
  ConsumerState<PasienChatPage> createState() => _PasienChatPageState();
}

class _PasienChatPageState extends ConsumerState<PasienChatPage> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Fetch conversations agar bisa tahu username psikiater (receiver)
      await ref
          .read(messageUseCaseProvider)
          .fetchConvosForUser(widget.pasienUsername);

      final convos = await ref
          .read(messageUseCaseProvider)
          .getConversationsForUser(widget.pasienUsername);

      // Pasien hanya punya satu conversation
      final receiver = convos.isNotEmpty ? convos.first.receiver : '';

      if (!mounted) return;
      final repo = ref.read(chatRepositoryProvider);
      ref
          .read(chatNotifierProvider.notifier)
          .initialize(repo, widget.convoId, receiver);
    });
  }

  void _sendMessage(String text) {
    ref.read(chatNotifierProvider.notifier).sendMessage(text);
  }

  void _syncMessages() {
    ref.read(chatNotifierProvider.notifier).syncMessages();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
    });
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Keluar'),
        content: const Text('Apakah Anda yakin ingin keluar?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(loginNotifierProvider.notifier).logout();
            },
            child: const Text('Keluar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatNotifierProvider);
    final messages = chatState.messages;
    final isConnected = chatState.isConnected;
    final isSyncing = chatState.isSyncing;
    final username = ref.watch(usernameProvider) ?? widget.pasienUsername;

    if (messages.isNotEmpty) {
      _scrollToBottom();
    }

    // Navigasi ke IntroPage saat logout
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
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text(
          'Konsultasi',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
        ),
        centerTitle: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: Icon(
              Icons.circle,
              size: 10,
              color: isConnected ? Colors.green : Colors.red,
            ),
          ),
          IconButton(
            icon: isSyncing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.sync),
            onPressed: isSyncing ? null : _syncMessages,
            tooltip: 'Sync ke backend',
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsPage()),
              );
            },
            tooltip: 'Pengaturan',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _showLogoutDialog,
            tooltip: 'Keluar',
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: messages.isEmpty
                ? const Center(
                    child: Text(
                      'Belum ada pesan. Mulai konsultasi Anda.',
                      style: TextStyle(color: Colors.black45),
                      textAlign: TextAlign.center,
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    itemCount: messages.length,
                    itemBuilder: (_, i) => MessageBubble(
                      message: messages[i],
                      sender: chatState.receiver ?? '',
                      loggedUser: username,
                      status: messages[i].status,
                    ),
                  ),
          ),
          MessageComposer(isConnected: isConnected, onSend: _sendMessage),
        ],
      ),
    );
  }
}
