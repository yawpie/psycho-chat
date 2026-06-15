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
      await secureDataSource.write(key: "username", value: username);
      print("username masuk secureDatasource");
      final user = await backendRemoteDatasource.login(username, password);
      print("user masuk remoteDatasource");
      return user;
    } catch (e) {
      return Future.error(e);
    }
  }

  @override
  Future<void> register(String username, String password) async {
    try {
      await backendRemoteDatasource.register(username, password);
    } catch (e) {
      return Future.error(e);
    }
  }

  @override
  Future<String> getUsername() async {
    try {
      final username = await secureDataSource.read(key: 'username');
      if (username == null) {
        return Future.error('Username not found');
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
    } catch (e) {
      return Future.error(e);
    }
  }
}
