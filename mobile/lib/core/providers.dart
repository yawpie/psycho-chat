import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:psycho_chat/core/network/dio_client.dart';
import 'package:psycho_chat/core/notifications/local_notification_service.dart';
import 'package:psycho_chat/data/datasources/local/app_database.dart';
import 'package:psycho_chat/data/datasources/local/conversation_datasource.dart';
import 'package:psycho_chat/data/datasources/local/message_datasource.dart';
import 'package:psycho_chat/data/datasources/local/secure_datasource.dart';
import 'package:psycho_chat/data/datasources/remote/backend_remote_datasource.dart';
import 'package:psycho_chat/data/datasources/remote/websocket_remote_datasource.dart';
import 'package:psycho_chat/data/repositories/auth_repository_impl.dart';
import 'package:psycho_chat/data/repositories/chat_repository_impl.dart';
import 'package:psycho_chat/data/repositories/convo_repository_impl.dart';
import 'package:psycho_chat/domain/repositories/auth_repository.dart';
import 'package:psycho_chat/domain/repositories/chat_repository.dart';
import 'package:psycho_chat/domain/repositories/convo_repository.dart';
import 'package:psycho_chat/domain/usecases/encryption.dart';
import 'package:psycho_chat/domain/usecases/login.dart';
import 'package:psycho_chat/domain/usecases/message.dart';
import 'package:psycho_chat/domain/usecases/settings.dart';

// ---------------------------------------------------------------------------
// Datasource providers
// ---------------------------------------------------------------------------

/// Drift database — single instance for the entire app.
final appDatabaseProvider = Provider<AppDatabase>((_) => AppDatabase());

/// Remote datasource backed by Dio HTTP client.
final backendRemoteDatasourceProvider = Provider<BackendRemoteDataSource>(
  (_) => BackendRemoteDataSource(dio: DioClient.dio),
);

/// Local datasource for conversations table.
final conversationLocalDataSourceProvider =
    Provider<ConversationLocalDataSource>(
      (ref) => ConversationLocalDataSource(
        database: ref.watch(appDatabaseProvider),
        currentUsername: ref.watch(usernameProvider),
      ),
    );

/// Local datasource for messages table.
final messageLocalDataSourceProvider = Provider<MessageLocalDataSource>(
  (ref) => MessageLocalDataSource(ref.watch(appDatabaseProvider)),
);

final websocketRemoteDatasourceProvider = Provider<WebSocketRemoteDatasource>(
  (ref) => WebSocketRemoteDatasource(),
);

final localNotificationServiceProvider = Provider<LocalNotificationService>(
  (_) => LocalNotificationService(),
);

// ---------------------------------------------------------------------------
// Repository providers
// ---------------------------------------------------------------------------

/// Auth repository backed by remote datasource.
final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepositoryImpl(
    backendRemoteDatasource: ref.watch(backendRemoteDatasourceProvider),
    secureDataSource: ref.watch(secureDataSourceProvider),
  ),
);

/// Conversation / message repository backed by local datasources.
final convoRepositoryProvider = Provider<ConvoRepository>(
  (ref) => ConvoRepositoryImpl(
    backendRemoteDataSource: ref.watch(backendRemoteDatasourceProvider),
    convoLocalDataSource: ref.watch(conversationLocalDataSourceProvider),
    messageLocalDataSource: ref.watch(messageLocalDataSourceProvider),
    webSocketRemoteDatasource: ref.watch(websocketRemoteDatasourceProvider),
    currentUsername: ref.watch(usernameProvider),
  ),
);

/// Chat (WebSocket) repository — enkripsi E2E via AES-GCM.
final chatRepositoryProvider = Provider<ChatRepository>(
  (ref) => ChatRepositoryImpl(
    ref.watch(websocketRemoteDatasourceProvider),
    ref.watch(messageLocalDataSourceProvider),
    ref.watch(backendRemoteDatasourceProvider),
    ref.watch(secureDataSourceProvider),
  ),
);

// ---------------------------------------------------------------------------
// Use case providers
// ---------------------------------------------------------------------------

/// Use case for login / register authentication flows.
final loginUseCaseProvider = Provider<LoginUseCase>(
  (ref) => LoginUseCase(
    authRepository: ref.watch(authRepositoryProvider),
    convoRepository: ref.watch(convoRepositoryProvider),
  ),
);

/// Use case for fetching conversations and messages.
final messageUseCaseProvider = Provider<MessageUseCase>(
  (ref) => MessageUseCase(
    ref.watch(convoRepositoryProvider),
    ref.watch(chatRepositoryProvider),
  ),
);

/// Use case for registering a new user.
final registerUseCaseProvider = Provider<RegisterUseCase>(
  (ref) => RegisterUseCase(repository: ref.watch(authRepositoryProvider)),
);
final settingsUseCaseProvider = Provider<SettingsUseCase>(
  (ref) => SettingsUseCase(
    chatRepository: ref.watch(chatRepositoryProvider),
    convoRepository: ref.watch(convoRepositoryProvider),
  ),
);

/// Use case untuk manajemen kunci enkripsi end-to-end per percakapan.
final encryptionUseCaseProvider = Provider<EncryptionUseCase>(
  (ref) => EncryptionUseCase(
    secureDataSource: ref.watch(secureDataSourceProvider),
    convoRepository: ref.watch(convoRepositoryProvider),
  ),
);

final secureStorageProvider = Provider((_) => const FlutterSecureStorage());

final secureDataSourceProvider = Provider(
  (ref) => SecureDataSource(storage: ref.watch(secureStorageProvider)),
);

/// Username disimpan secara eksplisit via StateProvider, bukan derived dari
/// loginNotifierProvider. Ini menghindari race condition saat Riverpod
/// me-re-evaluate provider chain selama perubahan widget tree.
final usernameProvider = StateProvider<String?>((ref) => null);
final isDarkModeProvider = StateProvider<bool>((ref) => false);

/// ConversationId pasien yang sedang login — null jika bukan pasien.
final pasienConvoIdProvider = StateProvider<String?>((ref) => null);

/// Role user yang sedang login: 'PASIEN' atau 'PSIKIATER'. Null jika belum login.
final userRoleProvider = StateProvider<String?>((ref) => null);
