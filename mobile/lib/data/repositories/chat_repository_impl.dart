import 'package:psycho_chat/core/encryption/aes_gcm_service.dart';
import 'package:psycho_chat/data/datasources/local/app_database.dart'
    as db_data;
import 'package:psycho_chat/data/datasources/local/message_datasource.dart';
import 'package:psycho_chat/data/datasources/local/secure_datasource.dart';
import 'package:psycho_chat/data/datasources/remote/backend_remote_datasource.dart';
import 'package:psycho_chat/data/datasources/remote/websocket_remote_datasource.dart';
import 'package:psycho_chat/data/models/chat_message_model.dart';
import 'package:psycho_chat/domain/entities/chat_message.dart';
import 'package:psycho_chat/domain/repositories/chat_repository.dart';

class ChatRepositoryImpl implements ChatRepository {
  ChatRepositoryImpl(
    this._websocketDatasource,
    this._messageLocalDataSource,
    this._backendDatasource,
    this._secureDataSource,
  );
  final WebSocketRemoteDatasource _websocketDatasource;
  final MessageLocalDataSource _messageLocalDataSource;
  final BackendRemoteDataSource _backendDatasource;
  final SecureDataSource _secureDataSource;

  /// Stream pesan masuk dengan dekripsi otomatis sebelum diteruskan ke UI.
  @override
  Stream<Message> get messageStream =>
      _websocketDatasource.messageStream.asyncMap(_decryptIncomingMessage);

  @override
  bool get isConnected => _websocketDatasource.isConnected;

  @override
  Future<void> connect(String username) =>
      _websocketDatasource.connect(username);

  // ---------------------------------------------------------------------------
  // Send — enkripsi sebelum kirim
  // ---------------------------------------------------------------------------

  @override
  void sendMessage(
    String text,
    String username,
    String receiver,
    String conversationId,
    String clientMessageId,
  ) {
    // Jalankan enkripsi secara async tanpa memblokir UI
    _sendEncrypted(
      text: text,
      username: username,
      receiver: receiver,
      conversationId: conversationId,
      clientMessageId: clientMessageId,
    );
  }

  Future<void> _sendEncrypted({
    required String text,
    required String username,
    required String receiver,
    required String conversationId,
    required String clientMessageId,
  }) async {
    // Simpan plaintext di local DB untuk tampilan UI pengirim
    await _messageLocalDataSource.createMessage(
      conversationId,
      username,
      text,
      DateTime.now(),
      'pending',
      clientMessageId,
    );

    // Ambil kunci enkripsi percakapan dari secure storage
    final base64Key = await _secureDataSource.getEncryptionKey(
      conversationId: conversationId,
    );

    final String payload;
    if (base64Key != null) {
      // Enkripsi teks menggunakan AES-GCM sebelum dikirim ke server
      payload = await AesGcmService.encrypt(
        plainText: text,
        base64Key: base64Key,
      );
    } else {
      // Tidak ada kunci — kirim plaintext (percakapan tanpa enkripsi)
      payload = text;
    }

    _websocketDatasource.sendMessage(
      payload,
      username,
      receiver,
      conversationId,
      clientMessageId,
    );
  }

  @override
  Future<MessageModel> submitMessageToBackend({
    required String conversationId,
    required String sender,
    required String text,
    required String clientMessageId,
  }) async {
    final response = await _backendDatasource.syncMessageToBackend(
      conversationId: conversationId,
      sender: sender,
      text: text,
      clientMessageId: clientMessageId,
    );
    print('Message synced to backend: ${response.id}');
    // Update local DB dengan ID dari backend dan status 'synced'
    await _messageLocalDataSource.updateMessageStatus(
      clientMessageId,
      'received',
    );
    return response;
  }

  @override
  Future<List<Message>> syncConversationMessages(String conversationId) async {
    final localMessages = await _messageLocalDataSource
        .getMessagesForConversation(conversationId);

    final unsyncedMessages = localMessages
        .where((message) => message.id == null)
        .toList();

    if (unsyncedMessages.isEmpty) {
      return [];
    }

    final syncedMessages = <Message>[];

    for (final localMessage in unsyncedMessages) {
      final syncedMessage = await _backendDatasource.syncMessageToBackend(
        conversationId: localMessage.conversationId,
        sender: localMessage.sender,
        text: localMessage.message,
        clientMessageId: localMessage.clientMessageId,
      );

      await _messageLocalDataSource.updateMessageStatus(
        localMessage.clientMessageId,
        'received',
      );

      syncedMessages.add(syncedMessage);
    }

    return syncedMessages;
  }

  // ---------------------------------------------------------------------------
  // Receive — dekripsi pesan masuk dari stream WebSocket
  // ---------------------------------------------------------------------------

  Future<Message> _decryptIncomingMessage(Message message) async {
    if (!AesGcmService.isEncrypted(message.message)) {
      return message;
    }

    try {
      final base64Key = await _secureDataSource.getEncryptionKey(
        conversationId: message.conversationId,
      );
      print(
        'STEP 1: Received encrypted message ${message.message}, base64Key: $base64Key',
      );

      if (base64Key == null) {
        return _withMessage(
          message,
          '[Pesan terenkripsi — kunci tidak tersedia]',
        );
      }

      final plainText = await AesGcmService.decrypt(
        encryptedPayload: message.message,
        base64Key: base64Key,
      );
      await _messageLocalDataSource.createMessage(
        message.conversationId,
        message.sender,
        plainText,
        message.createdAt,
        message.status,
        message.clientMessageId,
      );
      return _withMessage(message, plainText);
    } catch (e) {
      print('Failed to decrypt message ${message.id}: $e');
      // Tag verifikasi gagal atau format ciphertext rusak
      return _withMessage(message, '[Pesan tidak dapat didekripsi]');
    }
  }

  // ---------------------------------------------------------------------------
  // Fetch dari remote — dekripsi pesan yang tersimpan di server
  // ---------------------------------------------------------------------------

  @override
  Future<void> fetchMessages(String conversationId) async {
    try {
      final remoteMessages = await _backendDatasource
          .getMessageForConversationRemote(conversationId);

      final base64Key = await _secureDataSource.getEncryptionKey(
        conversationId: conversationId,
      );

      final decryptedMessages = await Future.wait(
        remoteMessages.map((msg) async {
          if (!AesGcmService.isEncrypted(msg.message) || base64Key == null) {
            return msg;
          }
          try {
            final plainText = await AesGcmService.decrypt(
              encryptedPayload: msg.message,
              base64Key: base64Key,
            );
            return MessageModel(
              id: msg.id,
              sender: msg.sender,
              message: plainText,
              createdAt: msg.createdAt,
              status: msg.status,
              conversationId: msg.conversationId,
              clientMessageId: msg.clientMessageId,
            );
          } catch (_) {
            return MessageModel(
              id: msg.id,
              sender: msg.sender,
              message: '[Pesan tidak dapat didekripsi]',
              createdAt: msg.createdAt,
              status: msg.status,
              conversationId: msg.conversationId,
              clientMessageId: msg.clientMessageId,
            );
          }
        }),
      );

      await _messageLocalDataSource.writeRemoteMessagesToLocal(
        decryptedMessages,
      );
    } catch (e) {
      throw Exception('Failed to fetch messages: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Lainnya
  // ---------------------------------------------------------------------------

  @override
  Future<void> disconnect() => _websocketDatasource.disconnect();

  @override
  Future<void> updateMessageStatus(String clientMessageId, String status) =>
      _messageLocalDataSource.updateMessageStatus(clientMessageId, status);

  @override
  Future<List<Message>> getMessagesForConversation(
    String conversationId,
  ) async {
    try {
      final List<db_data.Message> dbMessages = await _messageLocalDataSource
          .getMessagesForConversation(conversationId);
      return dbMessages.map((m) => MessageModel.fromDrift(m)).toList();
    } catch (e) {
      throw Exception('Failed to get messages for conversation: $e');
    }
  }

  @override
  Future<void> clearLocalConversations() async {
    try {
      await _messageLocalDataSource.clearAllMessages();
    } catch (e) {
      throw Exception('Failed to clear local conversations: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Helper
  // ---------------------------------------------------------------------------

  Message _withMessage(Message original, String newText) {
    return Message(
      id: original.id,
      sender: original.sender,
      message: newText,
      createdAt: original.createdAt,
      status: original.status,
      conversationId: original.conversationId,
      clientMessageId: original.clientMessageId,
    );
  }
}
