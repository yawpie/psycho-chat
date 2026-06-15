import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:psycho_chat/core/providers.dart';

import 'package:psycho_chat/domain/entities/chat_message.dart';
import 'package:psycho_chat/domain/repositories/chat_repository.dart';

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

class ChatState {
  final List<Message> messages;
  final bool isConnected;
  final int? currentConvoId;
  final String? receiver;
  

  const ChatState({
    this.messages = const [],
    this.isConnected = false,
    this.currentConvoId,
    this.receiver,
  });
}

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

class ChatNotifier extends AutoDisposeNotifier<ChatState> {
  ChatRepository? _repository;
  StreamSubscription<Message>? _subscription;
  bool _disposed = false;

  @override
  ChatState build() {
    ref.onDispose(() {
      _disposed = true;
      _subscription?.cancel();
    });
    return const ChatState();
  }

  /// Inisialisasi: dipanggil dari [ConsumerStatefulWidget.initState] via
  /// `ref.read(chatNotifierProvider.notifier).initialize(repo)`.
  void initialize(ChatRepository repository, int convoId, String receiver) {
    _repository = repository;
    // Tunda semua state update ke _connect() agar tidak ada sinkron setState
    // yang memicu rebuild di widget yang belum selesai di-mount.
    _connect(convoId, receiver);
  }

  Future<void> _connect(int convoId, String receiver) async {
    // Batalkan subscription lama agar tidak ada duplikat listener.
    await _subscription?.cancel();
    if (_disposed) return;

    // Baca username dari StateProvider — nilainya sudah di-set secara eksplisit
    // saat login berhasil, jadi selalu tersedia.
    final username = ref.read(usernameProvider);
    if (username == null) {
      throw Exception("Username is null, cannot connect to server");
    }

    await ref.read(messageUseCaseProvider).fetchMessages(convoId);
    if (_disposed) return;

    final messages = await ref
        .read(messageUseCaseProvider)
        .getMessagesForConversation(convoId);
    if (_disposed) return;

    state = ChatState(
      messages: messages,
      isConnected: false,
      receiver: receiver,
      currentConvoId: convoId,
    );

    // Dengarkan stream pesan masuk dan tambahkan ke state tanpa menghapus
    // pesan yang sudah ada — memenuhi Kebutuhan 5.3.
    _subscription = _repository!.messageStream.listen((message) {
      if (_disposed || message.conversationId != state.currentConvoId) return;
      state = ChatState(
        messages: [...state.messages, message],
        isConnected: true,
        receiver: state.receiver,
        currentConvoId: state.currentConvoId,
      );
    });

    await _repository!.connect(username);
    if (_disposed) return;
    // Perbarui status koneksi setelah connect() selesai — Kebutuhan 5.4.
    state = ChatState(
      messages: state.messages,
      isConnected: _repository!.isConnected,
      receiver: state.receiver,
      currentConvoId: state.currentConvoId,
    );
  }

  /// Kirim pesan jika koneksi aktif dan teks tidak kosong.
  void sendMessage(String text) async {
    try {
      final username = ref.read(usernameProvider);
      if (text.trim().isEmpty || !state.isConnected) return;
      if (username == null) {
        throw Exception("Username is null");
      }

      if (_repository == null) {
        throw Exception("Repository not initialized");
      }

      if (state.receiver == null) {
        throw Exception("Receiver is null");
      }

      if (state.currentConvoId == null) {
        throw Exception("Conversation ID is null");
      }
      print(
        'Sending message: "$text" from "$username" to "${state.receiver}" in convo ${state.currentConvoId}',
      );
      // _repository!.sendMessage(
      //   text,
      //   username,
      //   state.receiver!,
      //   state.currentConvoId!,
      // );

      await ref
          .read(messageUseCaseProvider)
          .sendMessage(state.currentConvoId!, username, text, state.receiver!);
    } catch (e) {
      print(e);
      throw Exception(e.toString());
    }
  }
}

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

final chatNotifierProvider =
    NotifierProvider.autoDispose<ChatNotifier, ChatState>(ChatNotifier.new);
