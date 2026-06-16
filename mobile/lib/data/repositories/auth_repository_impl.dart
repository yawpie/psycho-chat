import 'package:psycho_chat/data/datasources/remote/backend_remote_datasource.dart';
import 'package:psycho_chat/data/datasources/local/secure_datasource.dart';
import 'package:psycho_chat/domain/entities/user.dart';
import 'package:psycho_chat/domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final BackendRemoteDataSource backendRemoteDatasource;
  final SecureDataSource secureDataSource;

  AuthRepositoryImpl({
    required this.backendRemoteDatasource,
    required this.secureDataSource,
  });
  @override
  Future<User> login(String username, String password) async {
    try {
      await secureDataSource.savePsikiaterSession(username: username);
      final user = await backendRemoteDatasource.login(username, password);
      return user;
    } catch (e) {
      return Future.error(e);
    }
  }

  @override
  Future<String> register(String username, String password) async {
    try {
      final response = await backendRemoteDatasource.register(
        username,
        password,
      );
      return response;
    } catch (e) {
      return Future.error(e);
    }
  }

  @override
  Future<void> createNewPasien(
    String pasienUsername,
    String createdBy,
    String password,
    String fullName,
  ) async {
    try {
      await backendRemoteDatasource.createNewPasien(
        pasienUsername,
        createdBy,
        password,
        fullName,
      );
    } catch (e) {
      return Future.error(e);
    }
  }

  @override
  Future<String?> getUsername() async {
    try {
      final username = await secureDataSource.read(key: 'username');
      if (username == null) {
        return null;
      }
      return username;
    } catch (e) {
      return Future.error(e);
    }
  }

  @override
  Future<void> logout() async {
    try {
      await secureDataSource.delete(key: 'username');
      await secureDataSource.delete(key: 'user_role');
      await secureDataSource.delete(key: 'pasien_convo_id');
    } catch (e) {
      return Future.error(e);
    }
  }

  @override
  Future<String?> getUserRole() async {
    return await secureDataSource.getUserRole();
  }

  @override
  Future<String?> getPasienConvoId() async {
    return await secureDataSource.getPasienConvoId();
  }

  @override
  Future<Map<String, dynamic>> pasienLogin(String password) async {
    try {
      final result = await backendRemoteDatasource.pasienLogin(password);
      final user = result['user'] as Map<String, dynamic>;
      final conversationId = result['conversationId'] as String;
      final username = user['username'] as String;
      await secureDataSource.savePasienSession(
        username: username,
        conversationId: conversationId,
      );
      return result;
    } catch (e) {
      return Future.error(e);
    }
  }
}
