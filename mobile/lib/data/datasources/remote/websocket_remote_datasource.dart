import 'dart:async';

import 'package:socket_io_client/socket_io_client.dart' as IO;

import 'package:psycho_chat/core/constants/app_constants.dart';
import 'package:psycho_chat/data/models/chat_message_model.dart';

class WebSocketRemoteDatasource {
  IO.Socket? _socket;
  final _messageController = StreamController<MessageModel>.broadcast();
  bool _isConnected = false;

  Stream<MessageModel> get messageStream => _messageController.stream;
  bool get isConnected => _isConnected;

  Future<void> connect() async {
    await disconnect();

    try {
      // Create socket.io client connection
      _socket = IO.io(
        AppConstants.webSocketUrl,
        IO.OptionBuilder()
            .setTransports(['websocket'])
            .disableAutoConnect()
            .build(),
      );

      // Set up event listeners
      _socket!.onConnect((_) {
        _isConnected = true;
      });

      _socket!.onDisconnect((_) {
        _setDisconnected();
      });

      _socket!.onConnectError((_) {
        _setDisconnected();
      });

      _socket!.onError((_) {
        _setDisconnected();
      });

      // Listen for 'message' events from server
      _socket!.on('message', (data) {
        _onData(data);
      });

      // Connect to the server
      _socket!.connect();

      // Wait a bit for connection to establish
      await Future.delayed(const Duration(milliseconds: 500));
    } catch (_) {
      _isConnected = false;
    }
  }

  void _onData(dynamic data) {
    try {
      if (data is Map<String, dynamic>) {
        _messageController.add(MessageModel.fromJson(data));
      } else {
        _messageController.add(MessageModel.system(data.toString()));
      }
    } catch (_) {
      _messageController.add(MessageModel.system(data.toString()));
    }
  }

  void sendMessage(String text) {
    if (text.isEmpty || _socket == null || !_isConnected) return;
    // Emit 'message' event to server
    _socket!.emit('message', text);
  }

  Future<void> disconnect() async {
    _isConnected = false;
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
}
