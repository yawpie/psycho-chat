import 'package:get_it/get_it.dart';

import 'datasource_module.dart';
import 'repository_module.dart';
import 'usecase_module.dart';

final getIt = GetIt.instance;

Future<void> setupInjection() async {
  await registerDatasourceModule(getIt);
  await registerRepositoryModule(getIt);
  await registerUseCaseModule(getIt);
}