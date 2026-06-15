import 'package:flutter/material.dart';

class MessageComposer extends StatefulWidget {
  const MessageComposer({
    super.key,
    required this.isConnected,
    required this.onSend,
  });

  final bool isConnected;
  final ValueChanged<String> onSend;

  @override
  State<MessageComposer> createState() => _MessageComposerState();
}

class _MessageComposerState extends State<MessageComposer> {
  final TextEditingController _controller = TextEditingController();

  void _handleSend() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    widget.onSend(text);
    _controller.clear();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 8, 16),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              enabled: widget.isConnected,
              onSubmitted: (_) => _handleSend(),
              style: const TextStyle(fontSize: 15),
              decoration: InputDecoration(
                hintText: widget.isConnected ? 'Message...' : 'Disconnected',
                filled: true,
                fillColor: theme.colorScheme.surfaceContainer,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: widget.isConnected ? _handleSend : null,
            icon: const Icon(Icons.send, size: 20),
            style: IconButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: theme.colorScheme.onPrimary,
              disabledBackgroundColor: theme.colorScheme.surfaceContainer,
              shape: const CircleBorder(),
              padding: const EdgeInsets.all(12),
            ),
          ),
        ],
      ),
    );
  }
}
