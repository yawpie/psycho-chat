import 'dart:convert';

import 'package:cryptography/cryptography.dart';

/// Prefix yang ditambahkan pada ciphertext untuk membedakan pesan terenkripsi
/// dari pesan plaintext biasa.
const _kEncryptedPrefix = 'ENC:';

class AesGcmService {
  static final AesGcm _algorithm = AesGcm.with256bits();

  // ---------------------------------------------------------------------------
  // Enkripsi & Dekripsi
  // ---------------------------------------------------------------------------

  /// Encrypt [plainText] menggunakan AES-GCM.
  ///
  /// Mengembalikan JSON string berisi `ciphertext`, `nonce`, dan `tag`
  /// yang di-prefix dengan [_kEncryptedPrefix] agar mudah dikenali.
  ///
  /// [base64Key] — AES-256 key dalam format Base64 (32 byte).
  static Future<String> encrypt({
    required String plainText,
    required String base64Key,
  }) async {
    final secretKey = SecretKey(base64Decode(base64Key));
    final nonce = _algorithm.newNonce();

    final secretBox = await _algorithm.encrypt(
      utf8.encode(plainText),
      secretKey: secretKey,
      nonce: nonce,
    );

    final payload = {
      'ciphertext': base64Encode(secretBox.cipherText),
      'nonce': base64Encode(secretBox.nonce),
      'tag': base64Encode(secretBox.mac.bytes),
    };

    return '$_kEncryptedPrefix${jsonEncode(payload)}';
  }

  /// Decrypt hasil [encrypt].
  ///
  /// Melempar [Exception] jika tag verifikasi gagal (data dimodifikasi).
  /// [base64Key] — AES-256 key dalam format Base64.
  static Future<String> decrypt({
    required String encryptedPayload,
    required String base64Key,
  }) async {
    // Lepas prefix sebelum parse JSON
    final jsonStr = encryptedPayload.startsWith(_kEncryptedPrefix)
        ? encryptedPayload.substring(_kEncryptedPrefix.length)
        : encryptedPayload;

    final payload = jsonDecode(jsonStr) as Map<String, dynamic>;

    final secretBox = SecretBox(
      base64Decode(payload['ciphertext'] as String),
      nonce: base64Decode(payload['nonce'] as String),
      mac: Mac(base64Decode(payload['tag'] as String)),
    );

    final secretKey = SecretKey(base64Decode(base64Key));

    final decryptedBytes = await _algorithm.decrypt(
      secretBox,
      secretKey: secretKey,
    );

    return utf8.decode(decryptedBytes);
  }

  /// Periksa apakah [text] merupakan ciphertext hasil [encrypt].
  static bool isEncrypted(String text) => text.startsWith(_kEncryptedPrefix);

  // ---------------------------------------------------------------------------
  // Key Management
  // ---------------------------------------------------------------------------

  /// Generate AES-256 key baru, dikembalikan dalam format Base64.
  static Future<String> generateKey() async {
    final key = await _algorithm.newSecretKey();
    final keyBytes = await key.extractBytes();
    return base64Encode(keyBytes);
  }

  /// Turunkan AES-256 key dari [password] dan [salt] menggunakan PBKDF2-HMAC-SHA256.
  ///
  /// [salt] biasanya adalah conversationId sehingga setiap percakapan punya
  /// kunci turunan yang unik meski password sama.
  /// Iterasi 10.000 — cukup untuk keamanan di skenario ini karena password
  /// sudah panjang (44-char Base64 dari generateKey), sekaligus performa
  /// yang wajar di perangkat mobile.
  static Future<String> deriveKeyFromPassword({
    required String password,
    required String salt,
    int iterations = 10000,
  }) async {
    final pbkdf2 = Pbkdf2(
      macAlgorithm: Hmac.sha256(),
      iterations: iterations,
      bits: 256, // 32 byte → AES-256
    );

    final secretKey = await pbkdf2.deriveKey(
      secretKey: SecretKey(utf8.encode(password)),
      nonce: utf8.encode(salt),
    );

    final keyBytes = await secretKey.extractBytes();
    return base64Encode(keyBytes);
  }
}
