import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:psycho_chat/core/constants/app_constants.dart';
import 'package:psycho_chat/core/providers.dart';
import 'package:psycho_chat/core/theme/app_theme.dart';
import 'package:psycho_chat/presentation/pages/intro_page.dart';
import 'package:psycho_chat/presentation/providers/notification_listener.dart';

class PsychoChatApp extends ConsumerWidget {
  const PsychoChatApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(notificationListenerProvider);
    final isDark = ref.watch(isDarkModeProvider);
    return MaterialApp(
      title: AppConstants.appTitle,
      debugShowCheckedModeBanner: false,
      theme: isDark ? AppTheme.darkTheme : AppTheme.lightTheme,
      home: const IntroPage(),
    );
  }
}
