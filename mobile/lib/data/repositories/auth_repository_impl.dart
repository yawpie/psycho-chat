import 'package:psycho_chat/data/datasources/remote/backend_remote_datasource.dart';
import 'package:psycho_chat/domain/entities/user.dart';
import 'package:psycho_chat/domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final BackendRemoteDatasource backendRemoteDatasource;

  AuthRepositoryImpl(this.backendRemoteDatasource);
  @override
  Future<User> login(String email, String password) async {
    try {
      return await backendRemoteDatasource.login(email, password);
    } catch (e) {
      return Future.error(e);
    }
  }
  @override
  Future<void> register(String email, String password) async {
    try {
      await backendRemoteDatasource.register(email, password);
    } catch (e) {
      return Future.error(e);
    }
  }
}
