// Validates: Requirements 4.4
//
// Properti 2: Conversations state setelah fetch konsisten dengan data
//
// Untuk semua list percakapan yang dikembalikan repository,
// ConversationsState.conversations setelah fetchConversations() selesai
// mengandung tepat elemen yang sama — tidak lebih, tidak kurang.

import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:psycho_chat/core/providers.dart';
import 'package:psycho_chat/domain/entities/chat_message.dart';
import 'package:psycho_chat/domain/repositories/convo_repository.dart';
import 'package:psycho_chat/domain/usecases/message.dart';
import 'package:psycho_chat/presentation/providers/conversations_notifier.dart';

// ---------------------------------------------------------------------------
// Mock ConvoRepository implementations
// ---------------------------------------------------------------------------

/// Mock yang mengembalikan daftar percakapan yang diberikan.
class _FixedConvoRepository implements ConvoRepository {
  final List<Conversation> _conversations;
  const _FixedConvoRepository(this._conversations);

  @override
  Future<List<Conversation>> getConversationsForUser(String username) async {
    return _conversations;
  }

  @override
  Future<void> createConversation(String user1, String user2) async {}

  @override
  Future<List<Message>> getMessagesForConversation(int conversationId) async {
    return [];
  }

  @override
  Future<void> sendMessage(
    int conversationId,
    String sender,
    String text,
  ) async {}
}

/// Mock yang selalu melempar exception.
class _FailingConvoRepository implements ConvoRepository {
  final String message;
  const _FailingConvoRepository(this.message);

  @override
  Future<List<Conversation>> getConversationsForUser(String username) async {
    throw Exception(message);
  }

  @override
  Future<void> createConversation(String user1, String user2) async {
    throw Exception(message);
  }

  @override
  Future<List<Message>> getMessagesForConversation(int conversationId) async {
    throw Exception(message);
  }

  @override
  Future<void> sendMessage(
    int conversationId,
    String sender,
    String text,
  ) async {
    throw Exception(message);
  }
}

// ---------------------------------------------------------------------------
// Helper
// ---------------------------------------------------------------------------

/// Buat [ProviderContainer] yang mengoverride [convoRepositoryProvider] dan
/// [messageUseCaseProvider] dengan implementasi mock.
ProviderContainer _buildContainer(ConvoRepository mockRepo) {
  return ProviderContainer(
    overrides: [
      convoRepositoryProvider.overrideWithValue(mockRepo),
      messageUseCaseProvider.overrideWith(
        (ref) => MessageUseCase(ref.watch(convoRepositoryProvider)),
      ),
    ],
  );
}

/// Generator string alfanumerik acak.
String _randomString(Random rng, int length) {
  const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
  return List.generate(length, (_) => chars[rng.nextInt(chars.length)]).join();
}

/// Generate list [Conversation] acak dengan ukuran [count].
List<Conversation> _randomConversations(Random rng, int count) {
  return List.generate(
    count,
    (i) => Conversation(
      id: _randomString(rng, 8),
      user1: _randomString(rng, 6),
      user2: _randomString(rng, 6),
    ),
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  // Biji acak tetap agar pengujian deterministik dan dapat direproduksi.
  final rng = Random(42);

  // Jumlah sampel list percakapan acak yang diuji.
  const sampleCount = 50;

  group('Properti 2: Conversations state setelah fetch konsisten dengan data', () {
    // -----------------------------------------------------------------------
    // State awal
    // -----------------------------------------------------------------------
    test(
      'state awal ConversationsNotifier memiliki list kosong dan tidak loading',
      () {
        final container = _buildContainer(_FixedConvoRepository([]));
        addTearDown(container.dispose);

        final state = container.read(conversationsNotifierProvider);
        expect(state.conversations, isEmpty);
        expect(state.isLoading, isFalse);
        expect(state.errorMessage, isNull);
      },
    );

    // -----------------------------------------------------------------------
    // Properti utama: state.conversations setelah fetch mengandung tepat
    // elemen yang sama dengan yang dikembalikan repository.
    // -----------------------------------------------------------------------
    test('fetchConversations() menghasilkan state.conversations yang identik '
        'dengan data repository untuk $sampleCount list acak', () async {
      for (var i = 0; i < sampleCount; i++) {
        // Ukuran list: 0 sampai 20 item
        final size = rng.nextInt(21);
        final expectedConvos = _randomConversations(rng, size);

        final container = _buildContainer(
          _FixedConvoRepository(expectedConvos),
        );
        addTearDown(container.dispose);

        final notifier = container.read(conversationsNotifierProvider.notifier);
        await notifier.fetchConversations('user_${_randomString(rng, 5)}');

        final state = container.read(conversationsNotifierProvider);

        // Jumlah elemen harus persis sama
        expect(
          state.conversations.length,
          expectedConvos.length,
          reason:
              'Sample $i: expected ${expectedConvos.length} conversations, '
              'got ${state.conversations.length}',
        );

        // Setiap elemen harus identik (berdasarkan id)
        for (var j = 0; j < expectedConvos.length; j++) {
          expect(
            state.conversations[j].id,
            expectedConvos[j].id,
            reason:
                'Sample $i, item $j: id mismatch. '
                'Expected "${expectedConvos[j].id}", '
                'got "${state.conversations[j].id}"',
          );
          expect(
            state.conversations[j].user1,
            expectedConvos[j].user1,
            reason: 'Sample $i, item $j: user1 mismatch',
          );
          expect(
            state.conversations[j].user2,
            expectedConvos[j].user2,
            reason: 'Sample $i, item $j: user2 mismatch',
          );
        }

        // isLoading harus false setelah selesai
        expect(
          state.isLoading,
          isFalse,
          reason: 'Sample $i: isLoading should be false after fetch',
        );

        // errorMessage harus null pada sukses
        expect(
          state.errorMessage,
          isNull,
          reason: 'Sample $i: errorMessage should be null on success',
        );
      }
    });

    // -----------------------------------------------------------------------
    // Loading: state intermediate adalah isLoading=true sebelum use case
    // menyelesaikan eksekusinya.
    // -----------------------------------------------------------------------
    test(
      'fetchConversations() menetapkan isLoading=true sebelum use case selesai',
      () async {
        var loadingObserved = false;
        final slowRepo = _SlowConvoRepository(
          onCalled: () => loadingObserved = true,
        );

        final container = _buildContainer(slowRepo);
        addTearDown(container.dispose);

        final notifier = container.read(conversationsNotifierProvider.notifier);

        // Mulai fetch — jangan di-await
        final fetchFuture = notifier.fetchConversations('test_user');

        // Saat ini use case sedang berjalan, state harus loading
        expect(container.read(conversationsNotifierProvider).isLoading, isTrue);

        await fetchFuture;

        // Verifikasi repository sempat dipanggil
        expect(loadingObserved, isTrue);

        // Setelah selesai, isLoading harus false
        expect(
          container.read(conversationsNotifierProvider).isLoading,
          isFalse,
        );
      },
    );

    // -----------------------------------------------------------------------
    // Error: ketika repository gagal, errorMessage terisi dan conversations
    // tetap kosong.
    // -----------------------------------------------------------------------
    test(
      'fetchConversations() dengan repository gagal menyimpan errorMessage '
      'dan conversations tetap kosong untuk $sampleCount error acak',
      () async {
        for (var i = 0; i < sampleCount; i++) {
          final errMsg = 'error_${_randomString(rng, 10)}';
          final container = _buildContainer(_FailingConvoRepository(errMsg));
          addTearDown(container.dispose);

          final notifier = container.read(
            conversationsNotifierProvider.notifier,
          );
          await notifier.fetchConversations('user_${_randomString(rng, 5)}');

          final state = container.read(conversationsNotifierProvider);

          expect(
            state.errorMessage,
            isNotNull,
            reason: 'Sample $i: errorMessage should not be null on failure',
          );
          expect(
            state.conversations,
            isEmpty,
            reason: 'Sample $i: conversations should be empty on failure',
          );
          expect(
            state.isLoading,
            isFalse,
            reason: 'Sample $i: isLoading should be false after failed fetch',
          );
        }
      },
    );

    // -----------------------------------------------------------------------
    // List kosong: repository mengembalikan list kosong → state juga kosong.
    // -----------------------------------------------------------------------
    test(
      'fetchConversations() dengan list kosong menghasilkan state kosong',
      () async {
        final container = _buildContainer(_FixedConvoRepository([]));
        addTearDown(container.dispose);

        final notifier = container.read(conversationsNotifierProvider.notifier);
        await notifier.fetchConversations('user_empty');

        final state = container.read(conversationsNotifierProvider);
        expect(state.conversations, isEmpty);
        expect(state.isLoading, isFalse);
        expect(state.errorMessage, isNull);
      },
    );
  });
}

// ---------------------------------------------------------------------------
// Mock lambat untuk menguji state loading
// ---------------------------------------------------------------------------

class _SlowConvoRepository implements ConvoRepository {
  final void Function() onCalled;
  _SlowConvoRepository({required this.onCalled});

  @override
  Future<List<Conversation>> getConversationsForUser(String username) async {
    onCalled();
    await Future<void>.delayed(Duration.zero);
    return [];
  }

  @override
  Future<void> createConversation(String user1, String user2) async {}

  @override
  Future<List<Message>> getMessagesForConversation(int conversationId) async {
    return [];
  }

  @override
  Future<void> sendMessage(
    int conversationId,
    String sender,
    String text,
  ) async {}
}
