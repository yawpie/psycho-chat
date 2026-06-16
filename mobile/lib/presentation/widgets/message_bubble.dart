import 'package:flutter/material.dart';

import 'package:psycho_chat/domain/entities/chat_message.dart';

class MessageBubble extends StatelessWidget {
  const MessageBubble({
    super.key,
    required this.message,
    required this.sender,
    required this.loggedUser,
    required this.status,
  });
  final String status;
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
      child: IntrinsicWidth(
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.69,
          ),
          // menyesuaikan dengan tema
          decoration: BoxDecoration(
            color: !loggedUserSent
                ? theme.colorScheme.surfaceContainer
                : theme.colorScheme.primary,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(18),
              topRight: const Radius.circular(18),
              bottomLeft: Radius.circular(loggedUserSent ? 18 : 4),
              bottomRight: Radius.circular(loggedUserSent ? 4 : 18),
            ),
            border: Border.all(
              color: isSystem
                  ? Colors.redAccent
                  : !loggedUserSent
                  ? const Color(0xFF7C3AED)
                  : theme.colorScheme.primary,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: loggedUserSent
                ? CrossAxisAlignment.end
                : CrossAxisAlignment.start,
            children: [
              Text(
                message.message,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.3,
                  color: loggedUserSent
                      ? Colors.white
                      : theme.colorScheme.onSurface,
                ),
              ),
              // SizedBox(width: 4),
              Align(
                alignment: Alignment.bottomRight,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      message.createdAt.toLocal().toString().substring(11, 16),
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(width: 4),
                    if (loggedUserSent)
                      Icon(
                        status == 'pending'
                            ? Icons.access_time
                            : status == 'sent'
                            ? Icons.done
                            : status == 'received'
                            ? Icons.done_all
                            : Icons.access_time,
                        size: 16,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
