import 'package:psycho_chat/core/network/dio_client.dart';
import 'package:psycho_chat/data/datasources/remote/backend_remote_datasource.dart';
import 'package:psycho_chat/data/repositories/auth_repository_impl.dart';
import 'package:psycho_chat/domain/usecases/login.dart';

final backendRemoteDatasource = BackendRemoteDatasource(dio: DioClient.dio);
final authRepository = AuthRepositoryImpl(backendRemoteDatasource);

final loginUseCase = LoginUseCase(repository: authRepository);
final registerUseCase = RegisterUseCase(repository: authRepository);
