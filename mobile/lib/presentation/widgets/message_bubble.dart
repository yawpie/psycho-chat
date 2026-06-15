import 'package:flutter/material.dart';

import 'package:psycho_chat/domain/entities/chat_message.dart';

class MessageBubble extends StatelessWidget {
  const MessageBubble({
    super.key,
    required this.message,
    required this.sender,
    required this.loggedUser,
  });
  final String sender;
  final String loggedUser;
  final Message message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isSystem = message.sender == 'system';
    final loggedUserSent = message.sender == loggedUser;
    late final Alignment alignment;
    if (isSystem) {
      alignment = Alignment.center;
    } else if (!loggedUserSent) {
      alignment = Alignment.centerLeft;
    } else {
      alignment = Alignment.centerRight;
    }

    return Align(
      alignment: alignment,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        // menyesuaikan dengan tema
        decoration: BoxDecoration(
          color: !loggedUserSent
              ? theme.colorScheme.surfaceContainer
              : theme.colorScheme.primary,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSystem
                ? Colors.redAccent
                : !loggedUserSent
                ? const Color(0xFF7C3AED)
                : theme.colorScheme.primary,
          ),
        ),
        child: Text(
          message.message,
          style: TextStyle(
            fontSize: 14,
            height: 1.3,
            color: isSystem
                ? Colors.redAccent
                : loggedUserSent
                ? Colors.white
                : theme.colorScheme.onSurface,
          ),
        ),
      ),
    );
  }
}
