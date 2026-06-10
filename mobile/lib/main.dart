import 'package:flutter/material.dart';
import 'package:psycho_chat/core/di/injection.dart';
import 'package:psycho_chat/presentation/app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await setupInjection();
  runApp(const PsychoChatApp());
}
