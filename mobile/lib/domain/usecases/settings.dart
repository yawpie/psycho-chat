import 'package:psycho_chat/domain/repositories/chat_repository.dart';
import 'package:psycho_chat/domain/repositories/convo_repository.dart';

class SettingsUseCase {
    final ConvoRepository convoRepository;
    final ChatRepository chatRepository;

  SettingsUseCase({required this.convoRepository, required this.chatRepository});

  Future<void> clearAllConversationsData() async {
    // Implementasi untuk membersihkan data percakapan, misalnya saat logout
    // Anda bisa menambahkan metode di repository untuk menghapus data lokal jika diperlukan
     await convoRepository.clearAll();
  }

  Future<void> clearAllMessages() async {
    // Implementasi untuk membersihkan data pesan, misalnya saat logout
    // Anda bisa menambahkan metode di repository untuk menghapus data lokal jika diperlukan
     await chatRepository.clearLocalConversations();
  }
}