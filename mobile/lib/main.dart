import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:psycho_chat/core/constants/app_constants.dart';
import 'package:psycho_chat/core/network/dio_client.dart';
import 'package:psycho_chat/presentation/app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  const storage = FlutterSecureStorage();
  final storedBackendIp = await storage.read(
    key: AppConstants.backendIpStorageKey,
  );
  if (storedBackendIp != null && storedBackendIp.trim().isNotEmpty) {
    AppConstants.ip = storedBackendIp.trim();
    DioClient.updateBaseUrl();
  }
  runApp(const ProviderScope(child: PsychoChatApp()));
}
