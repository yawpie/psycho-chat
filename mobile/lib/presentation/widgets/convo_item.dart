import 'package:flutter/material.dart';

class ConvoItem extends StatelessWidget {
  const ConvoItem({
    super.key,
    required this.convoId,
    required this.convoTitle,
    required this.lastMessagePreview,
    this.onTap,
  });
  final String convoId;
  final String convoTitle;
  final String lastMessagePreview;
  final Function(String)? onTap;

  void handleTap(BuildContext context, String convoTitle) {
    if (onTap != null) {
      onTap!(convoId);
    } else {
      SnackBar snackBar = SnackBar(
        content: Text('Tapped on conversation: $convoTitle'),
      );
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(child: Icon(Icons.person)),
      title: Text(convoTitle),
      subtitle: Text(lastMessagePreview),
      onTap: () =>
          handleTap(context, convoTitle), // Handle conversation item tap
    );
  }
}
