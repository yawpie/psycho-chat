import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:psycho_chat/core/configs/app_configs.dart';
import 'package:socket_io_client/socket_io_client.dart' as socket_io;

import 'package:psycho_chat/core/constants/app_constants.dart';
import 'package:psycho_chat/data/models/chat_message_model.dart';

class WebSocketRemoteDatasource {
  socket_io.Socket? _socket;
  final _messageController = StreamController<MessageModel>.broadcast();
  bool _isConnected = false;
  String? _connectedUsername;
  Future<void>? _connectionFuture;

  Stream<MessageModel> get messageStream => _messageController.stream;
  bool get isConnected => _isConnected;

  Future<void> connect(String username) async {
    if (_isConnected && _connectedUsername == username) return;
    if (_connectionFuture != null && _connectedUsername == username) {
      return _connectionFuture;
    }

    _connectedUsername = username;
    final connectionFuture = _connect(username);
    _connectionFuture = connectionFuture;
    try {
      await connectionFuture;
    } finally {
      if (identical(_connectionFuture, connectionFuture)) {
        _connectionFuture = null;
      }
    }
  }

  Future<void> _connect(String username) async {
    await disconnect(clearUsername: false);
    final completer = Completer<void>();

    try {
      _socket = socket_io.io(
        AppConfig.websocketUrl,
        socket_io.OptionBuilder()
            .setTransports(['websocket'])
            .disableAutoConnect()
            .build(),
      );

      _socket!.onConnect((_) {
        _socket!.emit('register', username);
        _isConnected = true;
        if (!completer.isCompleted) completer.complete();
      });

      _socket!.onDisconnect((_) {
        _setDisconnected();
      });

      _socket!.onReconnect((handler) {
        _socket!.emit('register', username);
        _isConnected = true;
      });

      _socket!.onConnectError((error) {
        _setDisconnected();
        if (!completer.isCompleted) {
          completer.completeError(
            Exception('WebSocket connection failed: $error'),
          );
        }
      });

      _socket!.onError((error) {
        _setDisconnected();
        if (!completer.isCompleted) {
          completer.completeError(Exception('WebSocket error: $error'));
        }
      });

      _socket!.on('receiver_message', (data) {
        print('Websocket: Received message: $data');
        _onData(data);
      });

      _socket!.on('message_status_update', (data) {
        debugPrint('Received message status update: $data');
        print('Websocket: status update: $data');
        // _onMessageStatusUpdate(data);
        // _onData(data);
      });
      _socket!.connect();
      await completer.future.timeout(const Duration(seconds: 5));
    } catch (_) {
      _isConnected = false;
      await disconnect();
      rethrow;
    }
  }

  void _onData(dynamic data) {
    try {
      if (data is Map<String, dynamic>) {
        _messageController.add(MessageModel.fromJson(data));
      } else if (data is Map) {
        _messageController.add(
          MessageModel.fromJson(Map<String, dynamic>.from(data)),
        );
      } else {
        _messageController.add(MessageModel.system(data.toString()));
      }
      print('Emitted message to stream: $data');
      _socket!.emit('message_delivered', {
        'clientMessageId': data['clientMessageId'],
        'receiver': data['receiver'],
      });
    } catch (_) {
      _messageController.add(MessageModel.system(data.toString()));
    }
  }

  void _fetchPendingMessages(String conversationId) {
    _socket!.emit('fetch_messages', conversationId);
  }

  void sendMessage(
    String text,
    String senderUsername,
    String receiver,
    String conversationId,
    String clientMessageId,
  ) {
    debugPrint('Sending message: $text');
    if (text.isEmpty || _socket == null || !_isConnected) return;
    _socket!.emit('send_message', {
      'text': text,
      'sender': senderUsername,
      'receiver': receiver,
      'conversationId': conversationId,
      'clientMessageId': clientMessageId,
    });
  }

  Future<void> disconnect({bool clearUsername = true}) async {
    _isConnected = false;
    if (clearUsername) _connectedUsername = null;
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
  }

  void _setDisconnected() {
    _isConnected = false;
  }

  void dispose() {
    disconnect();
    _messageController.close();
  }
  
  void _onMessageStatusUpdate(data) {
    // Handle message status update
    print('Received message status update: $data');
    // You can add logic here to update the message status in your app
    try {
      if (data is Map<String, dynamic>) {
        _messageController.add(MessageModel.fromJson(data));
      } else if (data is Map) {
        _messageController.add(
          MessageModel.fromJson(Map<String, dynamic>.from(data)),
        );
      } else {
        _messageController.add(MessageModel.system(data.toString()));
      }
    } catch (e) {
      _messageController.add(MessageModel.system(data.toString()));
    }
  }
}
