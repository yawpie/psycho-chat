import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:psycho_chat/core/providers.dart';
import 'package:psycho_chat/presentation/providers/chat_notifier.dart';
import 'package:psycho_chat/presentation/widgets/message_bubble.dart';
import 'package:psycho_chat/presentation/widgets/message_composer.dart';

class ChatPage extends ConsumerStatefulWidget {
  const ChatPage({super.key, required this.convoId, required this.receiver, this.isPsikiater = false});
  final String convoId;
  final String receiver;
  final bool isPsikiater;

  @override
  ConsumerState<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends ConsumerState<ChatPage> {
  final ScrollController _scrollController = ScrollController();
  late final String _currentConvoId;
  late final String username;
  @override
  void initState() {
    super.initState();
    _currentConvoId = widget.convoId;
    username = ref.read(usernameProvider)!;
    // Gunakan addPostFrameCallback agar ref dapat diakses dengan aman di luar
    // build — Kebutuhan 5.1 & 5.2.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final repo = ref.read(chatRepositoryProvider);
      ref
          .read(chatNotifierProvider.notifier)
          .initialize(repo, _currentConvoId, widget.receiver);
    });
  }

  void _sendMessage(String text) {
    ref.read(chatNotifierProvider.notifier).sendMessage(text);
  }

  void _reconnect() {
    final repo = ref.read(chatRepositoryProvider);
    ref
        .read(chatNotifierProvider.notifier)
        .initialize(repo, _currentConvoId, widget.receiver);
  }

  void _refresh() {
    final repo = ref.read(chatRepositoryProvider);
    ref
        .read(chatNotifierProvider.notifier)
        .initialize(repo, _currentConvoId, widget.receiver);
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
    });
  }

  @override
  void dispose() {
    // autoDispose pada chatNotifierProvider sudah menangani cleanup secara otomatis.
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Watch state dari chatNotifierProvider — Kebutuhan 5.1.
    final chatState = ref.watch(chatNotifierProvider);
    final messages = chatState.messages;
    final isConnected = chatState.isConnected;
    final receiver = widget.receiver;

    // Auto-scroll ketika ada pesan baru.
    if (messages.isNotEmpty) {
      _scrollToBottom();
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          receiver,
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
        ),
        centerTitle: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Icon(
              Icons.circle,
              size: 10,
              color: isConnected ? Colors.green : Colors.red,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh, size: 20),
            onPressed: _refresh,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: messages.isEmpty
                ? const Center(
                    child: Text(
                      'No messages yet',
                      style: TextStyle(color: Colors.white38),
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
                      sender: receiver,
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
