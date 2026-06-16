import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:psycho_chat/core/providers.dart';
import 'package:psycho_chat/domain/entities/chat_message.dart';

class ConversationsState {
  final List<Conversation> conversations;
  final bool isLoading;
  final String? errorMessage;

  ConversationsState({
    this.conversations = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  ConversationsState copyWith({
    List<Conversation>? conversations,
    bool? isLoading,
    String? errorMessage,
  }) {
    return ConversationsState(
      conversations: conversations ?? this.conversations,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class ConversationsNotifier extends Notifier<ConversationsState> {
  @override
  ConversationsState build() {
    print("ConversationsNotifier build called");
    // fetchConversations();
    //  print("fetch convo berhasil");
    return ConversationsState();
  }

  Future<void> fetchConversations() async {
    // set loading ke true saat mulai fetch
    state = state.copyWith(isLoading: true, errorMessage: null);
    print("STEP 1: fetchConversations called");
    final username = ref.read(usernameProvider);
    print("STEP 2: username from provider: $username");
    try {
      if (username == null) {
        state = ConversationsState(
          errorMessage: 'User not found. Please log in again.',
          isLoading: false,
        );
        return;
      }
      await ref.read(messageUseCaseProvider).fetchConvosForUser(username);
      print("STEP 3 fetchConvosForUser selesai, data sudah ditulis ke local");
      print("STEP 3.1: sekarang ambil data convo dari local database...");
      final convos = await ref
          .read(messageUseCaseProvider)
          .getConversationsForUser(username);
      print("STEP 4 getConversationsForUser selesai");
      print("jumlah convo = ${convos.length}");

      state = state.copyWith(conversations: convos, isLoading: false);
      print("STEP 5 state updated");
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString(), isLoading: false);
    }
  }

  Future<void> getLocalConversations() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    final username = ref.read(usernameProvider);
    try {
      if (username == null) {
        state = ConversationsState(
          errorMessage: 'User not found. Please log in again.',
          isLoading: false,
        );
        return;
      }
      final convos = await ref
          .read(messageUseCaseProvider)
          .getConversationsForUser(username);
      state = state.copyWith(conversations: convos, isLoading: false);
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString(), isLoading: false);
    }
  }

  Future<void> clearConversations() async {
    try {
      // await ref.read(chatRepositoryProvider).clearLocalConversations();
      state = state.copyWith(conversations: []);
    } catch (e) {
      print(e);
      state = state.copyWith(errorMessage: 'Failed to clear conversations: $e');
    }
  }

  Future<void> createConversationWithPatient(
    String patientUsername,
    String password,
  ) async {
    try {
      final username = ref.read(usernameProvider);
      if (username == null) {
        state = state.copyWith(
          errorMessage: 'User not found. Please log in again.',
        );
        return;
      }
      await ref
          .read(messageUseCaseProvider)
          .createConversation(username, patientUsername, password);
      // Setelah berhasil membuat convo baru, fetch ulang semua convo untuk update UI.
      await getLocalConversations();
    } catch (e) {
      print(e);
      state = state.copyWith(errorMessage: 'Failed to create conversation: $e');
    }
  }
}

final conversationsNotifierProvider =
    NotifierProvider<ConversationsNotifier, ConversationsState>(
      ConversationsNotifier.new,
    );
