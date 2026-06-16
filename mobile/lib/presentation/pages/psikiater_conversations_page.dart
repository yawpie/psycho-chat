import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:psycho_chat/presentation/pages/chat_page.dart';
import 'package:psycho_chat/presentation/pages/intro_page.dart';
import 'package:psycho_chat/presentation/pages/pasien_create_page.dart';
import 'package:psycho_chat/presentation/pages/settings_page.dart';
import 'package:psycho_chat/presentation/providers/conversations_notifier.dart';
import 'package:psycho_chat/presentation/providers/login_notifier.dart';
import 'package:psycho_chat/presentation/widgets/convo_item.dart';

class PsikiaterConversationsPage extends ConsumerStatefulWidget {
  const PsikiaterConversationsPage({super.key});

  @override
  ConsumerState<PsikiaterConversationsPage> createState() =>
      _PsikiaterConversationsPageState();
}

class _PsikiaterConversationsPageState
    extends ConsumerState<PsikiaterConversationsPage> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(conversationsNotifierProvider.notifier).fetchConversations();
      print("fetch convo berhasil");
    });
    // ref.read(conversationsNotifierProvider.notifier).fetchConversations();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200) {
        // Pagination can be implemented here in the future
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(conversationsNotifierProvider);

    print("isLoading: ${state.isLoading}");
    print("error: ${state.errorMessage}");
    print("conversations: ${state.conversations.length}");

    ref.listen(loginNotifierProvider, (previous, next) {
      final isCurrentRoute = ModalRoute.of(context)?.isCurrent ?? false;
      final shouldRedirect =
          previous?.status == LoginStatus.loading &&
          next.status == LoginStatus.idle &&
          isCurrentRoute;

      if (shouldRedirect) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const IntroPage()),
          (_) => false,
        );
      }
    });
    if (state.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('PsychoChat - Psikiater'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsPage()),
              );
            },
          ),
        ],
      ),
      floatingActionButton: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton(
            shape: CircleBorder(), // Membuat tombol lebih besar
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const PasienCreatePage(),
                ),
              );
            },
            tooltip: 'Tambah Pasien Baru',
            child: const Icon(Icons.add),
          ),
          SizedBox(width: 16), // Jarak antara tombol
          FloatingActionButton(
            shape: CircleBorder(), // Membuat tombol lebih besar
            onPressed: () async {
              await ref
                  .read(conversationsNotifierProvider.notifier)
                  .fetchAndSetupEncryptionKeys();

              if (!context.mounted) return;

              final error = ref
                  .read(conversationsNotifierProvider)
                  .errorMessage;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    error != null
                        ? 'Gagal fetch keys: $error'
                        : 'Encryption keys berhasil di-setup untuk semua percakapan',
                  ),
                  backgroundColor: error != null ? Colors.red : Colors.green,
                ),
              );
            },
            tooltip: 'Fetch keys',
            child: const Icon(Icons.key),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref
              .read(conversationsNotifierProvider.notifier)
              .fetchConversations();
        },
        child: state.conversations.isEmpty
            ? ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 300),
                  Center(child: Text('Belum ada percakapan')),
                ],
              )
            : ListView.builder(
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                itemCount: state.conversations.length,
                itemBuilder: (_, i) => ConvoItem(
                  convoId: state.conversations[i].id,
                  convoTitle:
                      state.conversations[i].displayName?.isNotEmpty == true
                      ? state.conversations[i].displayName!
                      : state.conversations[i].receiver,
                  lastMessagePreview: '',
                  onTap: (convoId) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChatPage(
                          convoId: convoId,
                          receiver: state.conversations[i].receiver,
                        ),
                      ),
                    );
                  },
                ),
              ),
      ),
    );
  }
}
