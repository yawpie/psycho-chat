import 'package:dio/dio.dart';
import 'package:psycho_chat/core/configs/app_configs.dart';

class DioClient {
  static final Dio dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {'Content-Type': 'application/json'},
    ),
  );

  static void updateBaseUrl() {
    dio.options.baseUrl = AppConfig.apiBaseUrl;
  }
}
