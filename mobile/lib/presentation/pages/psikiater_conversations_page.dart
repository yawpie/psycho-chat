import 'package:flutter/material.dart';
import 'package:psycho_chat/core/di/injection.dart';
import 'package:psycho_chat/domain/usecases/message.dart';
import 'package:psycho_chat/presentation/widgets/convo_item.dart';

class PsikiaterConversationsPage extends StatefulWidget {
  const PsikiaterConversationsPage({super.key});
  // final MessageUseCase messageUseCase;
  @override
  State<PsikiaterConversationsPage> createState() =>
      _PsikiaterConversationsPageState();
}

class _PsikiaterConversationsPageState
    extends State<PsikiaterConversationsPage> {
  final MessageUseCase messageUseCase = getIt<MessageUseCase>();
  final ScrollController _scrollController = ScrollController();

  List<Map<String, String>> conversations = [];
  bool _isLoading = false;
  int _page = 1;

  @override
  void initState() {
    super.initState();
    // _fetchMoreData(); // Initial load

    // Attach listener to track scroll updates
    _scrollController.addListener(() {
      // Check if user scrolled near the bottom (within 200 pixels)
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200) {
        // _fetchMoreData();
      }
    });
  }

  //todo implement fetching conversations from repository and display them in the listview using convoitem widget
  void fetchConversations() {
    // Implement fetching conversations from repository here
    setState(() {
      _isLoading = true;
    });
    const username = "psikiater_username"; // Replace with actual username
    messageUseCase.getConversationsForUser(username);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(
        controller: _scrollController,
        children: [
          ConvoItem(
            convoId: "1",
            convoTitle: "Conversation with User A",
            lastMessagePreview: "Last message preview goes here...",
          ),
          ConvoItem(
            convoId: "2",
            convoTitle: "Conversation with User B",
            lastMessagePreview: "Last message preview goes here...",
          ),
          // Add more ConvoItems as needed
        ],
      ),
    );
  }
}
