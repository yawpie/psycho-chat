import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:psycho_chat/core/providers.dart';

import 'package:psycho_chat/domain/entities/chat_message.dart';
import 'package:psycho_chat/domain/repositories/chat_repository.dart';
import 'package:uuid/uuid.dart';

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

class ChatState {
  final List<Message> messages;
  final bool isConnected;
  final bool isSyncing;
  final String? currentConvoId;
  final String? receiver;

  ChatState copyWith({
    List<Message>? messages,
    bool? isConnected,
    bool? isSyncing,
    String? currentConvoId,
    String? receiver,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      isConnected: isConnected ?? this.isConnected,
      isSyncing: isSyncing ?? this.isSyncing,
      currentConvoId: currentConvoId ?? this.currentConvoId,
      receiver: receiver ?? this.receiver,
    );
  }

  const ChatState({
    this.messages = const [],
    this.isConnected = true, // untuk tes fitur offline-first, default true
    this.isSyncing = false,
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
  void initialize(ChatRepository repository, String convoId, String receiver) {
    _repository = repository;
    // Tunda semua state update ke _connect() agar tidak ada sinkron setState
    // yang memicu rebuild di widget yang belum selesai di-mount.
    _connect(convoId, receiver);
  }

  Future<void> _connect(String convoId, String receiver) async {
    // Batalkan subscription lama agar tidak ada duplikat listener.
    await _subscription?.cancel();
    if (_disposed) return;

    // Baca username dari StateProvider — nilainya sudah di-set secara eksplisit
    // saat login berhasil, jadi selalu tersedia.
    final username = ref.read(usernameProvider);
    if (username == null) {
      throw Exception("Username is null, cannot connect to server");
    }

    final messages = await ref
        .read(messageUseCaseProvider)
        .getMessagesForConversationFromLocalDb(convoId);

    print("Fetched ${messages.length} messages for convo $convoId");
    if (_disposed) return;
    print("Initializing chat state for convo $convoId with receiver $receiver");
    state = ChatState(
      messages: messages,
      isConnected: true,
      isSyncing: false,
      receiver: receiver,
      currentConvoId: convoId,
    );
    print("Chat state initialized with ${state.messages.length} messages");

    print("Current messages in state: ${state.messages.length}");

    // Dengarkan stream pesan masuk dan tambahkan ke state tanpa menghapus
    // pesan yang sudah ada — memenuhi Kebutuhan 5.3.
    _subscription = _repository!.messageStream.listen((message) {
      print("Received message from stream: $message");
      if (_disposed || message.conversationId != state.currentConvoId) {
        return;
      }
      final existingIndex = state.messages.indexWhere(
        (m) => m.clientMessageId == message.clientMessageId,
      );

      if (existingIndex != -1) {
        // update status pesan yang sudah ada
        final updatedMessages = [...state.messages];

        updatedMessages[existingIndex] = Message(
          sender: message.sender,
          message: message.message,
          status: message.status,
          createdAt: message.createdAt,
          conversationId: message.conversationId,
          clientMessageId: message.clientMessageId,
        );

        state = ChatState(
          messages: updatedMessages,
          isConnected: state.isConnected,
          isSyncing: state.isSyncing,
          receiver: state.receiver,
          currentConvoId: state.currentConvoId,
        );
        print(
          'Updated message status for clientMessageId ${message.clientMessageId} to ${message.status}',
        );
        // update status di local db
        _repository!.updateMessageStatus(message.clientMessageId, message.status);
        return;
      }

      // pesan dari user lain
      state = ChatState(
        messages: [...state.messages, message],
        isConnected: state.isConnected,
        isSyncing: state.isSyncing,
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
      isSyncing: state.isSyncing,
      receiver: state.receiver,
      currentConvoId: state.currentConvoId,
    );
  }

  Future<void> refreshMessages() async {
    try {
      if (state.currentConvoId == null) {
        throw Exception("Conversation ID is null");
      }
      await ref
          .read(messageUseCaseProvider)
          .fetchMessages(state.currentConvoId!);
    } catch (e) {
      print(e);
      throw Exception('Failed to refresh messages: $e');
    }
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

      Message tempMessage = Message(
        sender: username,
        message: text,
        status: 'sending', // Status sementara untuk pesan yang baru dikirim
        createdAt: DateTime.now(),
        conversationId: state.currentConvoId!,
        clientMessageId: Uuid().v4(),
      );

      // tampilkan langsung di UI
      state = ChatState(
        messages: [...state.messages, tempMessage],
        isConnected: state.isConnected,
        isSyncing: state.isSyncing,
        receiver: state.receiver,
        currentConvoId: state.currentConvoId,
      );
      print(
        'Sending message: "$text" from "$username" to "${state.receiver}" in convo ${state.currentConvoId}',
      );

      await ref
          .read(messageUseCaseProvider)
          .sendMessage(
            state.currentConvoId!,
            username,
            text,
            state.receiver!,
            tempMessage.clientMessageId,
          );
         tempMessage = tempMessage.copyWith(status: 'sent');
         state = state.copyWith(
           messages: state.messages.map((message) {
             if (message.clientMessageId == tempMessage.clientMessageId) {
               return tempMessage;
             }
             return message;
           }).toList(),
         );
      // final submittedMessage = await ref
      //     .read(chatRepositoryProvider)
      //     .submitMessageToBackend(
      //       conversationId: state.currentConvoId!,
      //       sender: username,
      //       text: text,
      //       clientMessageId: tempMessage.clientMessageId,
      //     );
      // state = state.copyWith(
      //   messages: state.messages.map((message) {
      //     if (message.clientMessageId == tempMessage.clientMessageId) {
      //       return submittedMessage;
      //     }
      //     return message;
      //   }).toList(),
      // );
      // await ref
      //     .read(messageUseCaseProvider)
      //     .fetchMessages(state.currentConvoId!);
    } catch (e) {
      print(e);
      throw Exception(e.toString());
    }
  }

  Future<void> syncMessages() async {
    try {
      if (state.currentConvoId == null) {
        throw Exception("Conversation ID is null");
      }
      if (state.isSyncing) return;

      state = ChatState(
        messages: state.messages,
        isConnected: state.isConnected,
        isSyncing: true,
        receiver: state.receiver,
        currentConvoId: state.currentConvoId,
      );

      final syncedMessages = await ref
          .read(messageUseCaseProvider)
          .syncMessagesToBackend(state.currentConvoId!);

      if (_disposed) return;

      final syncedByClientId = {
        for (final message in syncedMessages) message.clientMessageId: message,
      };

      final updatedMessages = state.messages.map((message) {
        final syncedMessage = syncedByClientId[message.clientMessageId];
        return syncedMessage ?? message;
      }).toList();

      state = ChatState(
        messages: updatedMessages,
        isConnected: state.isConnected,
        isSyncing: false,
        receiver: state.receiver,
        currentConvoId: state.currentConvoId,
      );
    } catch (e) {
      if (_disposed) return;
      state = ChatState(
        messages: state.messages,
        isConnected: state.isConnected,
        isSyncing: false,
        receiver: state.receiver,
        currentConvoId: state.currentConvoId,
      );
      print(e);
      throw Exception('Failed to sync messages: $e');
    }
  }
}

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

final chatNotifierProvider =
    NotifierProvider.autoDispose<ChatNotifier, ChatState>(ChatNotifier.new);
