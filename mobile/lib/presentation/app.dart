import 'package:flutter/material.dart';

import 'package:psycho_chat/core/constants/app_constants.dart';
import 'package:psycho_chat/core/theme/app_theme.dart';
import 'package:psycho_chat/presentation/pages/chat_page.dart';

class PsychoChatApp extends StatelessWidget {
  const PsychoChatApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appTitle,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const ChatPage(),
    );
  }
}
