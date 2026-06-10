import 'package:flutter/material.dart';

class ConvoItem extends StatelessWidget {
  const ConvoItem({
    super.key,
    required this.convoId,
    required this.convoTitle,
    required this.lastMessagePreview,
  });
  final String convoId;
  final String convoTitle;
  final String lastMessagePreview;

  void handleTap(BuildContext context, String convoTitle) {
    // Handle conversation item tap
    SnackBar snackBar = SnackBar(
      content: Text('Tapped on conversation: $convoTitle'),
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
    print("Conversation item tapped: $convoTitle");
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: ListTile(
        leading: CircleAvatar(child: Icon(Icons.person)),
        title: Text(convoTitle),
        subtitle: Text(lastMessagePreview),
        onTap: () =>
            handleTap(context, convoTitle), // Handle conversation item tap
      ),
    );
  }
}
