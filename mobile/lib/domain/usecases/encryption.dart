import 'package:psycho_chat/data/datasources/local/secure_datasource.dart';
import 'package:psycho_chat/domain/entities/chat_message.dart';
import 'package:psycho_chat/domain/repositories/convo_repository.dart';

/// Use case untuk mengelola kunci enkripsi end-to-end per percakapan.
///
/// Kunci AES-256 diturunkan dari password percakapan menggunakan PBKDF2,
/// dengan conversationId sebagai salt — sehingga setiap percakapan memiliki
/// kunci yang unik meski password sama.
class EncryptionUseCase {
  EncryptionUseCase({
    required SecureDataSource secureDataSource,
    required ConvoRepository convoRepository,
  }) : _secureDataSource = secureDataSource,
       _convoRepository = convoRepository;

  final SecureDataSource _secureDataSource;
  final ConvoRepository _convoRepository;

  /// Derive kunci enkripsi dari [password] + [conversationId] sebagai salt,
  /// lalu simpan di secure storage.
  ///
  /// Dipanggil:
  /// - Oleh psikiater setelah membuat pasien baru
  /// - Oleh pasien setelah login berhasil
  Future<String> setupEncryptionKeyForConversation({
    required String conversationId,
    required String password,
  }) async {
    return await _secureDataSource.deriveAndSaveEncryptionKey(
      conversationId: conversationId,
      password: password,
    );
  }

  /// Setup kunci enkripsi untuk semua percakapan milik user setelah login ulang.
  ///
  /// Menggunakan password plaintext yang tersimpan di secure storage
  /// (disimpan saat percakapan pertama kali dibuat). Jika tidak ada,
  /// fallback ke [password] login — hanya cocok jika password login = password
  /// percakapan (kasus pasien yang hanya punya satu percakapan).
  Future<void> setupEncryptionKeysForAllConversations({
    required String username,
    required String password,
  }) async {
    final conversations = await _convoRepository.getConversationsForUser(
      username,
    );
    await Future.wait(
      conversations.map((Conversation convo) async {
        // Jika kunci sudah ada di secure storage, tidak perlu re-derive
        final existingKey = await _secureDataSource.getEncryptionKey(
          conversationId: convo.id,
        );
        if (existingKey != null) return;

        // Ambil password plaintext yang disimpan saat percakapan dibuat
        final storedPassword = await _secureDataSource.getConversationPassword(
          conversationId: convo.id,
        );

        // Gunakan stored password jika ada, fallback ke password login
        final materialPassword = storedPassword ?? password;

        await _secureDataSource.deriveAndSaveEncryptionKey(
          conversationId: convo.id,
          password: materialPassword,
        );
      }),
    );
  }

  /// Cek apakah kunci enkripsi sudah tersedia untuk sebuah percakapan.
  Future<bool> hasEncryptionKey({required String conversationId}) async {
    final key = await _secureDataSource.getEncryptionKey(
      conversationId: conversationId,
    );
    return key != null;
  }

  /// Hapus semua kunci enkripsi saat logout.
  Future<void> clearAllEncryptionKeys() async {
    await _secureDataSource.deleteAll();
  }
}
