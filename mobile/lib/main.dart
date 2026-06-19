import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:psycho_chat/core/configs/app_configs.dart';
import 'package:psycho_chat/core/constants/app_constants.dart';
import 'package:psycho_chat/core/network/dio_client.dart';
import 'package:psycho_chat/presentation/app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  const storage = FlutterSecureStorage();

  final storedBackendIp = await storage.read(
    key: AppConstants.backendIpStorageKey,
  );

  if (storedBackendIp != null &&
      storedBackendIp.trim().isNotEmpty) {
    AppConfig.backendIp = storedBackendIp.trim();

    print("Stored IP: ${AppConfig.backendIp}");

    DioClient.updateBaseUrl();

    print("Base URL: ${DioClient.dio.options.baseUrl}");
  }

  runApp(
    const ProviderScope(
      child: PsychoChatApp(),
    ),
  );
}
