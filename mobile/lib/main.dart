import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

void main() => runApp(const PsychoChatApp());

class PsychoChatApp extends StatelessWidget {
  const PsychoChatApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Psycho Chat',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF7C3AED),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const ChatPage(),
    );
  }
}

class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.sender,
    required this.text,
    required this.timestamp,
  });

  final String id;
  final String sender;
  final String text;
  final DateTime timestamp;

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id']?.toString() ?? DateTime.now().microsecondsSinceEpoch.toString(),
      sender: json['sender']?.toString() ?? 'system',
      text: json['text']?.toString() ?? '',
      timestamp: DateTime.tryParse(json['timestamp']?.toString() ?? '') ?? DateTime.now(),
    );
  }
}

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  static final Uri _serverUri = Uri.parse('ws://10.0.2.2:3000');

  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = <ChatMessage>[];

  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _subscription;
  bool _isConnected = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _connect();
  }

  Future<void> _connect() async {
    await _subscription?.cancel();
    _channel?.sink.close();

    setState(() {
      _isConnected = false;
      _error = null;
    });

    try {
      final channel = WebSocketChannel.connect(_serverUri);
      await channel.ready;

      _subscription = channel.stream.listen(
        _handleIncomingMessage,
        onError: (Object error) {
          setState(() {
            _isConnected = false;
            _error = 'Connection error: $error';
          });
        },
        onDone: () {
          if (mounted) {
            setState(() => _isConnected = false);
          }
        },
      );

      setState(() {
        _channel = channel;
        _isConnected = true;
      });
    } catch (error) {
      setState(() {
        _isConnected = false;
        _error = 'Failed to connect to $_serverUri';
      });
    }
  }

  void _handleIncomingMessage(dynamic rawMessage) {
    try {
      final decoded = jsonDecode(rawMessage.toString()) as Map<String, dynamic>;
      setState(() => _messages.add(ChatMessage.fromJson(decoded)));
      _scrollToBottom();
    } catch (_) {
      setState(() {
        _messages.add(ChatMessage(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          sender: 'system',
          text: rawMessage.toString(),
          timestamp: DateTime.now(),
        ));
      });
      _scrollToBottom();
    }
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    final channel = _channel;

    if (text.isEmpty || channel == null || !_isConnected) return;

    channel.sink.add(text);
    _messageController.clear();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
      );
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _channel?.sink.close();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[Color(0xFF12051F), Color(0xFF24103F), Color(0xFF061826)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: <Widget>[
              _Header(isConnected: _isConnected, onReconnect: _connect),
              if (_error != null) _ErrorBanner(message: _error!),
              Expanded(
                child: _messages.isEmpty
                    ? const _EmptyState()
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) => _MessageBubble(message: _messages[index]),
                      ),
              ),
              _Composer(
                controller: _messageController,
                enabled: _isConnected,
                onSend: _sendMessage,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.isConnected, required this.onReconnect});

  final bool isConnected;
  final VoidCallback onReconnect;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(18),
      child: Row(
        children: <Widget>[
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              gradient: const LinearGradient(colors: <Color>[Color(0xFFA78BFA), Color(0xFF22D3EE)]),
              boxShadow: const <BoxShadow>[BoxShadow(color: Color(0x667C3AED), blurRadius: 24)],
            ),
            child: const Icon(Icons.psychology_alt_rounded, color: Colors.white),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text('Psycho Chat', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
                Text(isConnected ? 'Connected to ws://localhost:3000' : 'Disconnected', style: TextStyle(color: isConnected ? const Color(0xFF86EFAC) : const Color(0xFFFCA5A5))),
              ],
            ),
          ),
          IconButton.filledTonal(
            tooltip: 'Reconnect',
            onPressed: onReconnect,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 18),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: const Color(0x33F43F5E), borderRadius: BorderRadius.circular(16)),
      child: Row(children: <Widget>[const Icon(Icons.warning_rounded), const SizedBox(width: 10), Expanded(child: Text(message))]),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Text('Start backend, connect, then send first message.', textAlign: TextAlign.center),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final isSystem = message.sender == 'system';

    return Align(
      alignment: isSystem ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: const BoxConstraints(maxWidth: 320),
        decoration: BoxDecoration(
          color: isSystem ? const Color(0x22FFFFFF) : const Color(0xFF7C3AED),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0x22FFFFFF)),
        ),
        child: Text(message.text, style: const TextStyle(fontSize: 15, height: 1.35)),
      ),
    );
  }
}

class _Composer extends StatelessWidget {
  const _Composer({required this.controller, required this.enabled, required this.onSend});

  final TextEditingController controller;
  final bool enabled;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 18),
      child: Row(
        children: <Widget>[
          Expanded(
            child: TextField(
              controller: controller,
              enabled: enabled,
              onSubmitted: (_) => onSend(),
              decoration: InputDecoration(
                hintText: enabled ? 'Type message...' : 'Waiting for backend...',
                filled: true,
                fillColor: const Color(0x22FFFFFF),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(22), borderSide: BorderSide.none),
              ),
            ),
          ),
          const SizedBox(width: 10),
          FilledButton(
            onPressed: enabled ? onSend : null,
            style: FilledButton.styleFrom(shape: const CircleBorder(), padding: const EdgeInsets.all(18)),
            child: const Icon(Icons.send_rounded),
          ),
        ],
      ),
    );
  }
}
