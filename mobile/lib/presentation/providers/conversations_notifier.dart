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
}

final conversationsNotifierProvider =
    NotifierProvider<ConversationsNotifier, ConversationsState>(
      ConversationsNotifier.new,
    );
