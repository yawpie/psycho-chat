import 'package:dio/dio.dart';
import 'package:psycho_chat/data/datasources/local/app_database.dart';
import 'package:psycho_chat/data/models/chat_message_model.dart';
import 'package:psycho_chat/data/models/user_model.dart';

class BackendRemoteDataSource {
  final Dio dio;
  BackendRemoteDataSource({required this.dio});

  Future<UserModel> login(String username, String password) async {
    print("Base URL: ${dio.options.baseUrl}");
    final response = await dio.post(
      '/auth/login',
      data: {'username': username.trim(), 'password': password},
    );
    final Map<String, dynamic> data = response.data;
    print(data);
    return UserModel.fromJson(data);
  }

  Future<void> register(String username, String password) async {
    final response = await dio.post(
      '/auth/register',
      data: {'username': username, 'password': password},
    );
    print(response.data);
  }

  Future<void> createConversation(String user1, String user2) async {
    // throw UnimplementedError();
    // Simulate a network call to create a conversation between two users
    // await Future.delayed(const Duration(seconds: 1));
    // In a real implementation, you would make an HTTP request to your backend here
    // to create the conversation and return the conversation ID or details.
    final response = await dio.post(
      '/convo/create',
      data: {'user1': user1, 'user2': user2},
    );
    print(response.data);
  }

  Future<List<ConversationModel>> getConversationsForUser(
    String username,
  ) async {
    final responseConvo = await dio.get(
      '/convo',
      queryParameters: {'username': username},
    );
    print(responseConvo.data);
    return (responseConvo.data as List)
        .map((json) => ConversationModel.fromJson(json, username))
        .toList();
  }

  Future<List<MessageModel>> getMessagesForConversation(
    int conversationId,
  ) async {
    final response = await dio.get('/convo/$conversationId');
    return (response.data as List)
        .map((json) => MessageModel.fromJson(json))
        .toList();
  }

  Future<MessageModel> getLastMessageFromConvo(int conversationId) async {
    final response = await dio.get('/convo/$conversationId/last');
    return MessageModel.fromJson(response.data);
  }
}
