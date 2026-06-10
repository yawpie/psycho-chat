import 'package:get_it/get_it.dart';
import 'package:psycho_chat/core/network/dio_client.dart';
import 'package:psycho_chat/data/datasources/local/app_database.dart';
import 'package:psycho_chat/data/datasources/local/local_datasource.dart';
import 'package:psycho_chat/data/datasources/remote/backend_remote_datasource.dart';

Future<void> registerDatasourceModule(GetIt getIt) async {
  // Database
  getIt.registerLazySingleton<AppDatabase>(
    () => AppDatabase(),
  );

  // Remote
  getIt.registerLazySingleton<BackendRemoteDatasource>(
    () => BackendRemoteDatasource(
      dio: DioClient.dio,
    ),
  );

  // Local
  getIt.registerLazySingleton<ConversationLocalDataSource>(
    () => ConversationLocalDataSource(
      getIt<AppDatabase>(),
    ),
  );

  getIt.registerLazySingleton<MessageLocalDataSource>(
    () => MessageLocalDataSource(
      getIt<AppDatabase>(),
    ),
  );
}