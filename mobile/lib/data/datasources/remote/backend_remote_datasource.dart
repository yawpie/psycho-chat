import 'package:dio/dio.dart';
import 'package:psycho_chat/data/models/chat_message_model.dart';
import 'package:psycho_chat/data/models/user_model.dart';

class BackendRemoteDataSource {
  final Dio dio;
  BackendRemoteDataSource({required this.dio});

  Future<Map<String, dynamic>> pasienLogin(String password) async {
    final response = await dio.post(
      '/auth/pasien-login',
      data: {'password': password},
    );
    return response.data as Map<String, dynamic>;
  }

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

  Future<String> register(String username, String password) async {
    final response = await dio.post(
      '/auth/register',
      data: {'username': username, 'password': password},
    );
    print(response.data);
    return response.data['username'];
  }

  Future<void> createNewPasien(
    String pasienUsername,
    String createdBy,
    String password,
    String fullName,
  ) async {
    final response = await dio.post(
      '/auth/create-new-pasien',
      data: {
        'pasienUsername': pasienUsername,
        'createdBy': createdBy,
        'password': password,
        'fullName': fullName,
      },
    );
    print(response.data);
  }

  Future<void> createConversation(
    String user1,
    String user2,
    String password,
  ) async {
    // throw UnimplementedError();
    // Simulate a network call to create a conversation between two users
    // await Future.delayed(const Duration(seconds: 1));
    // In a real implementation, you would make an HTTP request to your backend here
    // to create the conversation and return the conversation ID or details.
    final response = await dio.post(
      '/convo/create',
      data: {'user1': user1, 'user2': user2, 'password': password},
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

  Future<List<MessageModel>> getMessageForConversationRemote(
    String conversationId,
  ) async {
    final response = await dio.get('/convo/$conversationId');
    return (response.data as List)
        .map((json) => MessageModel.fromJson(json))
        .toList();
  }

  Future<MessageModel> getLastMessageFromConvo(String conversationId) async {
    final response = await dio.get('/convo/$conversationId/last');
    return MessageModel.fromJson(response.data);
  }

  Future<MessageModel> syncMessageToBackend({
    required String conversationId,
    required String sender,
    required String text,
    required String clientMessageId,
  }) async {
    final response = await dio.post(
      '/messages/sync',
      data: {
        'conversationId': conversationId,
        'sender': sender,
        'text': text,
        'clientMessageId': clientMessageId,
      },
    );

    return MessageModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<String?> getConversationPassword(String conversationId) async {
    try {
      final response = await dio.get('/convo/$conversationId/password');
      print('Fetched password for conversation $conversationId: ${response.data['password']}');
      return response.data['password'] as String?;
    } catch (e) {
      print('Failed to fetch conversation password for $conversationId: $e');
      return null;
    }
  }
}
