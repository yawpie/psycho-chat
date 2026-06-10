import 'package:dio/dio.dart';
import 'package:psycho_chat/data/models/user_model.dart';


class BackendRemoteDatasource {
  final Dio dio;
  BackendRemoteDatasource({required this.dio});

  Future<UserModel> login(String username, String password) async {
    print("Base URL: ${dio.options.baseUrl}");
    final response = await dio.post( '/auth/login', data: {'username': username.trim(), 'password': password});
    final Map<String, dynamic> data = response.data;
    print(data);
    return UserModel.fromJson(data);
  }

  Future<void> register(String username, String password) async {
    final response = await dio.post( '/auth/register', data: {'username': username, 'password': password});
    print(response.data);
  }

  Future<void> createConversation(String user1, String user2) async {
    throw UnimplementedError();
    // Simulate a network call to create a conversation between two users
    // await Future.delayed(const Duration(seconds: 1));
    // In a real implementation, you would make an HTTP request to your backend here
    // to create the conversation and return the conversation ID or details.
  }
}