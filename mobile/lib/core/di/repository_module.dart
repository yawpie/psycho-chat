import 'package:get_it/get_it.dart';
import 'package:psycho_chat/data/datasources/local/local_datasource.dart';
import 'package:psycho_chat/data/datasources/remote/backend_remote_datasource.dart';
import 'package:psycho_chat/data/repositories/auth_repository_impl.dart';
import 'package:psycho_chat/data/repositories/convo_repository_impl.dart';
import 'package:psycho_chat/domain/repositories/auth_repository.dart';
import 'package:psycho_chat/domain/repositories/convo_repository.dart';

Future<void> registerRepositoryModule(GetIt getIt) async {
  getIt.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(
      getIt<BackendRemoteDatasource>(),
    ),
  );

  getIt.registerLazySingleton<ConvoRepository>(
    () => ConvoRepositoryImpl(
      convoDataSource: getIt<ConversationLocalDataSource>(),
      messageDataSource: getIt<MessageLocalDataSource>(),
    ),
  );
}