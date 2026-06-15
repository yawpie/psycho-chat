import 'package:psycho_chat/domain/entities/user.dart';

abstract class AuthRepository {
  Future<User> login(String username, String password);
  Future<void> register(String email, String password);
  Future<void> logout();
  Future<String> getUsername();
}
