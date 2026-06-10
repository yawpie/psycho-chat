import 'package:get_it/get_it.dart';

import 'package:psycho_chat/domain/repositories/auth_repository.dart';
import 'package:psycho_chat/domain/repositories/convo_repository.dart';

import 'package:psycho_chat/domain/usecases/login.dart';
import 'package:psycho_chat/domain/usecases/message.dart';

Future<void> registerUseCaseModule(GetIt getIt) async {
  getIt.registerFactory(
    () => LoginUseCase(repository: getIt<AuthRepository>()),
  );

  getIt.registerFactory(
    () => MessageUseCase(getIt<ConvoRepository>()),
  );
}
