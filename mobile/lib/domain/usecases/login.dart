import 'package:psycho_chat/domain/entities/user.dart';
import 'package:psycho_chat/domain/repositories/auth_repository.dart';
import 'package:psycho_chat/domain/repositories/convo_repository.dart';

class LoginUseCase {
  final AuthRepository authRepository;
  final ConvoRepository convoRepository;

  LoginUseCase({required this.authRepository, required this.convoRepository});

  Future<User> login(String email, String password) async {
    try {
      return await authRepository.login(email, password);
    } catch (e) {
      return Future.error(e);
      // throw Exception('Failed to sign in');
    }
  }

  Future<void> logout() async {
    try {
      await authRepository.logout();
      await convoRepository.clearAll();
    } catch (e) {
      return Future.error(e);
      // throw Exception('Failed to log out');
    }
  }

  Future<void> pasienLogin(String password) async {
    // TODO: implement pasien login logic
    throw UnimplementedError('Pasien login is not implemented yet');
  }
}

class RegisterUseCase {
  final AuthRepository repository;

  RegisterUseCase({required this.repository});

  Future<String> register(String username, String password) async {
    try {
      final response = await repository.register(username, password);
      return response;
    } catch (e) {
      return Future.error(e);
      // throw Exception('Failed to sign up');
    }
  }
}
