import 'dart:async';
import 'dart:convert';

import 'package:web_socket_channel/web_socket_channel.dart';

import 'package:psycho_chat/core/constants/app_constants.dart';
import 'package:psycho_chat/data/models/chat_message_model.dart';

class WebSocketRemoteDatasource {
  WebSocketChannel? _channel;
  final _messageController = StreamController<ChatMessageModel>.broadcast();
  bool _isConnected = false;

  Stream<ChatMessageModel> get messageStream => _messageController.stream;
  bool get isConnected => _isConnected;

  Future<void> connect() async {
    await disconnect();

    try {
      final uri = Uri.parse(AppConstants.webSocketUrl);
      final channel = WebSocketChannel.connect(uri);
      await channel.ready;

      channel.stream.listen(
        _onData,
        onError: (_) => _setDisconnected(),
        onDone: _setDisconnected,
      );

      _channel = channel;
      _isConnected = true;
    } catch (_) {
      _isConnected = false;
    }
  }

  void _onData(dynamic rawMessage) {
    try {
      final decoded = jsonDecode(rawMessage.toString()) as Map<String, dynamic>;
      _messageController.add(ChatMessageModel.fromJson(decoded));
    } catch (_) {
      _messageController.add(ChatMessageModel.system(rawMessage.toString()));
    }
  }

  void sendMessage(String text) {
    if (text.isEmpty || _channel == null || !_isConnected) return;
    _channel!.sink.add(text);
  }

  Future<void> disconnect() async {
    _isConnected = false;
    _channel?.sink.close();
    _channel = null;
  }

  void _setDisconnected() {
    _isConnected = false;
  }

  void dispose() {
    disconnect();
    _messageController.close();
  }
}
