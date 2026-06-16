import 'package:psycho_chat/domain/entities/user.dart';

abstract class AuthRepository {
  Future<User> login(String username, String password);
  Future<String> register(String username, String password);
  Future<void> createNewPasien(
    String pasienUsername,
    String createdBy,
    String password,
    String fullName,
  );
  Future<void> logout();
  Future<String?> getUsername();
  Future<String?> getUserRole();
  Future<String?> getPasienConvoId();

  /// Login pasien hanya dengan password. Return {user, conversationId}.
  Future<Map<String, dynamic>> pasienLogin(String password);
}
