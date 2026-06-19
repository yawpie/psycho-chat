import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:psycho_chat/core/encryption/aes_gcm_service.dart';

class SecureDataSource {
  final FlutterSecureStorage storage;
  SecureDataSource({required this.storage});

  Future<String?> read({required String key}) async {
    return await storage.read(key: key);
  }

  Future<void> write({required String key, required String value}) async {
    await storage.write(key: key, value: value);
  }

  Future<String?> readBackendIp() async {
    return await storage.read(key: 'backend_ip');
  }

  Future<void> writeBackendIp(String backendIp) async {
    await storage.write(key: 'backend_ip', value: backendIp);
    print("Backend IP saved to secure storage: $backendIp");
  }

  Future<void> delete({required String key}) async {
    await storage.delete(key: key);
  }

  Future<void> deleteAll() async {
    await storage.deleteAll();
  }

  // ---------------------------------------------------------------------------
  // Encryption key helpers
  // ---------------------------------------------------------------------------

  /// Simpan kunci enkripsi AES-256 untuk sebuah percakapan.
  ///
  /// Kunci disimpan dengan format `enc_key_{conversationId}` di secure storage.
  Future<void> saveEncryptionKey({
    required String conversationId,
    required String base64Key,
  }) async {
    await storage.write(key: 'enc_key_$conversationId', value: base64Key);
  }

  /// Ambil kunci enkripsi AES-256 untuk sebuah percakapan.
  ///
  /// Mengembalikan `null` jika kunci belum pernah disimpan.
  Future<String?> getEncryptionKey({required String conversationId}) async {
    return await storage.read(key: 'enc_key_$conversationId');
  }

  /// Hapus kunci enkripsi untuk sebuah percakapan (misal saat logout).
  Future<void> deleteEncryptionKey({required String conversationId}) async {
    await storage.delete(key: 'enc_key_$conversationId');
  }

  /// Derive kunci enkripsi dari [password] + [conversationId] sebagai salt,
  /// lalu simpan di secure storage dan kembalikan kunci Base64-nya.
  ///
  /// Juga menyimpan [password] plaintext untuk keperluan re-derive kunci
  /// saat login ulang.
  Future<String> deriveAndSaveEncryptionKey({
    required String conversationId,
    required String password,
  }) async {
    final base64Key = await AesGcmService.deriveKeyFromPassword(
      password: password,
      salt: conversationId,
    );
    await saveEncryptionKey(
      conversationId: conversationId,
      base64Key: base64Key,
    );
    // Simpan juga plaintext password agar bisa re-derive kunci setelah login ulang
    await storage.write(key: 'enc_pwd_$conversationId', value: password);
    return base64Key;
  }

  /// Ambil password plaintext percakapan yang tersimpan.
  ///
  /// Dipakai untuk re-derive kunci saat login ulang.
  Future<String?> getConversationPassword({
    required String conversationId,
  }) async {
    return await storage.read(key: 'enc_pwd_$conversationId');
  }

  // ---------------------------------------------------------------------------
  // Pasien session helpers
  // ---------------------------------------------------------------------------

  /// Simpan session pasien: username + conversationId setelah login berhasil.
  Future<void> savePasienSession({
    required String username,
    required String conversationId,
  }) async {
    await storage.write(key: 'username', value: username);
    await storage.write(key: 'pasien_convo_id', value: conversationId);
    await storage.write(key: 'user_role', value: 'PASIEN');
  }

  /// Ambil conversationId pasien yang tersimpan.
  Future<String?> getPasienConvoId() async {
    return await storage.read(key: 'pasien_convo_id');
  }

  /// Ambil role user yang sedang login ('PASIEN' atau 'PSIKIATER').
  Future<String?> getUserRole() async {
    return await storage.read(key: 'user_role');
  }

  /// Simpan role psikiater saat login biasa.
  Future<void> savePsikiaterSession({required String username}) async {
    await storage.write(key: 'username', value: username);
    await storage.write(key: 'user_role', value: 'PSIKIATER');
  }
}
