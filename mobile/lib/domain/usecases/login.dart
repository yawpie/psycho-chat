import 'package:psycho_chat/domain/entities/user.dart';
import 'package:psycho_chat/domain/repositories/auth_repository.dart';

class LoginUseCase {
  final AuthRepository repository;

  LoginUseCase({required this.repository});

  Future<User> call(String email, String password) async {
    try {
      return await repository.login(email, password);
    } catch (e) {
      return Future.error(e);
      // throw Exception('Failed to sign in');
    }
  }
}

class RegisterUseCase {
  final AuthRepository repository;

  RegisterUseCase({required this.repository});

  Future<void> call(String email, String password) async {
    try {
      await repository.register(email, password);
    } catch (e) {
      return Future.error(e);
      // throw Exception('Failed to sign up');
    }
  }
}