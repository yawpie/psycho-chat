import 'dart:convert';

import 'package:cryptography/cryptography.dart';

class AesGcmService {
  static final AesGcm _algorithm = AesGcm.with256bits();

  /// Encrypt string menggunakan AES-GCM
  ///
  /// [plainText] = data yang akan dienkripsi
  /// [base64Key] = AES key dalam format Base64 (32 byte untuk AES-256)
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

    return jsonEncode(payload);
  }

  /// Decrypt AES-GCM payload
  ///
  /// [encryptedPayload] = hasil encrypt()
  /// [base64Key] = AES key dalam format Base64
  static Future<String> decrypt({
    required String encryptedPayload,
    required String base64Key,
  }) async {
    final payload =
        jsonDecode(encryptedPayload) as Map<String, dynamic>;

    final secretBox = SecretBox(
      base64Decode(payload['ciphertext']),
      nonce: base64Decode(payload['nonce']),
      mac: Mac(base64Decode(payload['tag'])),
    );

    final secretKey = SecretKey(base64Decode(base64Key));

    final decryptedBytes = await _algorithm.decrypt(
      secretBox,
      secretKey: secretKey,
    );

    return utf8.decode(decryptedBytes);
  }

  /// Generate AES-256 key (Base64)
  static Future<String> generateKey() async {
    final key = await _algorithm.newSecretKey();

    final keyBytes = await key.extractBytes();

    return base64Encode(keyBytes);
  }
}