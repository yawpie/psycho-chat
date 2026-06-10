# Dokumen Desain: Migrasi State Management & DI dari get_it ke Riverpod Modern

## Ikhtisar

Dokumen ini menjabarkan desain teknis migrasi dependency injection dan state management di aplikasi Flutter `psycho_chat` dari `get_it` ke `flutter_riverpod`. Migrasi ini dilakukan dengan mempertahankan clean architecture yang sudah ada, mengganti layer DI dengan provider hierarkis Riverpod, dan menghubungkan state presentation ke UI secara reaktif.

Pendekatan yang dipilih adalah **manual providers** (tanpa `riverpod_annotation` + `build_runner`) karena proyek ini berukuran kecil dan tidak memerlukan overhead code generation tambahan.

---

## Arsitektur Setelah Migrasi

```
lib/
├── core/
│   ├── constants/          # Tidak berubah
│   ├── db/                 # Tidak berubah
│   ├── network/            # Tidak berubah
│   ├── theme/              # Tidak berubah
│   └── providers.dart      # BARU: semua provider infra s.d. use case
├── data/                   # Tidak berubah
├── domain/                 # Tidak berubah
├── presentation/
│   ├── app.dart            # Diperbarui: ProviderScope, hapus Injection()
│   ├── pages/              # Diperbarui: pakai ConsumerWidget/ConsumerStatefulWidget
│   └── providers/          # BARU: Notifier per page
│       ├── login_notifier.dart
│       ├── conversations_notifier.dart
│       └── chat_notifier.dart
└── main.dart               # Diperbarui: hapus setupInjection()
```

Folder `lib/core/di/` dihapus sepenuhnya.

---

## Komponen

### 1. `lib/core/providers.dart` — Provider Infrastruktur

File terpusat yang mendaftarkan semua dependency dari datasource sampai use case menggunakan Riverpod `Provider`.

```dart
// Urutan dependency (dari bawah ke atas):
// AppDatabase → ConversationLocalDataSource, MessageLocalDataSource
// DioClient.dio → BackendRemoteDatasource
// BackendRemoteDatasource → AuthRepositoryImpl
// ConversationLocalDataSource + MessageLocalDataSource → ConvoRepositoryImpl
// AuthRepositoryImpl → LoginUseCase
// ConvoRepositoryImpl → MessageUseCase

final appDatabaseProvider = Provider<AppDatabase>(
  (_) => AppDatabase(),
);

final backendRemoteDatasourceProvider = Provider<BackendRemoteDatasource>(
  (ref) => BackendRemoteDatasource(dio: DioClient.dio),
);

final conversationLocalDataSourceProvider = Provider<ConversationLocalDataSource>(
  (ref) => ConversationLocalDataSource(ref.watch(appDatabaseProvider)),
);

final messageLocalDataSourceProvider = Provider<MessageLocalDataSource>(
  (ref) => MessageLocalDataSource(ref.watch(appDatabaseProvider)),
);

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepositoryImpl(ref.watch(backendRemoteDatasourceProvider)),
);

final convoRepositoryProvider = Provider<ConvoRepository>(
  (ref) => ConvoRepositoryImpl(
    convoDataSource: ref.watch(conversationLocalDataSourceProvider),
    messageDataSource: ref.watch(messageLocalDataSourceProvider),
  ),
);

final loginUseCaseProvider = Provider<LoginUseCase>(
  (ref) => LoginUseCase(repository: ref.watch(authRepositoryProvider)),
);

final messageUseCaseProvider = Provider<MessageUseCase>(
  (ref) => MessageUseCase(ref.watch(convoRepositoryProvider)),
);
```

Semua provider bersifat lazy-initialized secara otomatis oleh Riverpod.

---

### 2. `lib/presentation/providers/login_notifier.dart`

Mengelola state untuk proses login di `PsikiaterLoginPage`.

```dart
enum LoginStatus { idle, loading, success, error }

class LoginState {
  final LoginStatus status;
  final String? errorMessage;
  const LoginState({this.status = LoginStatus.idle, this.errorMessage});
}

class LoginNotifier extends Notifier<LoginState> {
  @override
  LoginState build() => const LoginState();

  Future<void> login(String username, String password) async {
    state = const LoginState(status: LoginStatus.loading);
    try {
      await ref.read(loginUseCaseProvider).call(username, password);
      state = const LoginState(status: LoginStatus.success);
    } catch (e) {
      state = LoginState(status: LoginStatus.error, errorMessage: e.toString());
    }
  }
}

final loginNotifierProvider = NotifierProvider<LoginNotifier, LoginState>(
  LoginNotifier.new,
);
```

---

### 3. `lib/presentation/providers/conversations_notifier.dart`

Mengelola state daftar percakapan di `PsikiaterConversationsPage`.

```dart
class ConversationsState {
  final List<Conversation> conversations;
  final bool isLoading;
  final String? errorMessage;
  const ConversationsState({
    this.conversations = const [],
    this.isLoading = false,
    this.errorMessage,
  });
}

class ConversationsNotifier extends Notifier<ConversationsState> {
  @override
  ConversationsState build() => const ConversationsState();

  Future<void> fetchConversations(String username) async {
    state = const ConversationsState(isLoading: true);
    try {
      final convos = await ref
          .read(messageUseCaseProvider)
          .getConversationsForUser(username);
      state = ConversationsState(conversations: convos);
    } catch (e) {
      state = ConversationsState(errorMessage: e.toString());
    }
  }
}

final conversationsNotifierProvider =
    NotifierProvider<ConversationsNotifier, ConversationsState>(
  ConversationsNotifier.new,
);
```

---

### 4. `lib/presentation/providers/chat_notifier.dart`

Mengelola state koneksi dan pesan di `ChatPage`.

```dart
class ChatState {
  final List<Message> messages;
  final bool isConnected;
  const ChatState({this.messages = const [], this.isConnected = false});
}

class ChatNotifier extends Notifier<ChatState> {
  ChatRepository? _repository;
  StreamSubscription<Message>? _subscription;

  @override
  ChatState build() => const ChatState();

  // Inisialisasi: dipanggil dari ConsumerStatefulWidget.initState via ref.read
  void initialize(ChatRepository repository) {
    _repository = repository;
    _connect();
  }

  Future<void> _connect() async {
    await _subscription?.cancel();
    state = ChatState(messages: state.messages, isConnected: false);
    await _repository!.connect();
    _subscription = _repository!.messageStream.listen((message) {
      state = ChatState(
        messages: [...state.messages, message],
        isConnected: true,
      );
    });
    state = ChatState(messages: state.messages, isConnected: _repository!.isConnected);
  }

  void sendMessage(String text) {
    if (text.trim().isEmpty || !state.isConnected) return;
    _repository?.sendMessage(text.trim());
  }

  void disconnect() {
    _subscription?.cancel();
    _repository?.disconnect();
  }
}

final chatNotifierProvider = NotifierProvider<ChatNotifier, ChatState>(
  ChatNotifier.new,
);
```

> **Catatan**: `ChatRepository` untuk `ChatPage` di-inject melalui provider terpisah karena implementasinya berbeda (WebSocket). Provider-nya didefinisikan di `providers.dart`:
>
> ```dart
> final chatRepositoryProvider = Provider<ChatRepository>(
>   (_) => ChatRepositoryImpl(),
> );
> ```

---

### 5. Perubahan di File Existing

#### `main.dart`

Hapus `setupInjection()` dan tambahkan `ProviderScope`:

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Tidak perlu setupInjection() lagi
  runApp(const ProviderScope(child: PsychoChatApp()));
}
```

#### `presentation/app.dart`

Hapus import `injection.dart` dan `Injection()`:

```dart
class PsychoChatApp extends StatelessWidget {
  const PsychoChatApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appTitle,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const IntroPage(), // Tidak perlu inject loginUseCase
    );
  }
}
```

#### `IntroPage`

Tidak perlu perubahan state management — navigasi statis sudah benar.

#### `PsikiaterLoginPage` → `ConsumerStatefulWidget`

Hapus `getIt<LoginUseCase>()`, gunakan `ref.read(loginNotifierProvider.notifier)`:

```dart
class PsikiaterLoginPage extends ConsumerStatefulWidget { ... }

class _PsikiaterLoginPageState extends ConsumerState<PsikiaterLoginPage> {
  Future<void> _handleSubmit() async {
    await ref.read(loginNotifierProvider.notifier).login(username, password);
    // Dengarkan state perubahan di build() untuk navigasi
  }

  @override
  Widget build(BuildContext context) {
    final loginState = ref.watch(loginNotifierProvider);
    // Navigasi ketika status == success
    // Tampilkan error ketika status == error
    ...
  }
}
```

#### `PsikiaterConversationsPage` → `ConsumerStatefulWidget`

Hapus `getIt<MessageUseCase>()`, ganti ListView hardcoded dengan data dari state:

```dart
class _PsikiaterConversationsPageState
    extends ConsumerState<PsikiaterConversationsPage> {
  @override
  void initState() {
    super.initState();
    // Picu fetch saat widget pertama kali mount
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(conversationsNotifierProvider.notifier)
          .fetchConversations('psikiater_username');
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(conversationsNotifierProvider);
    if (state.isLoading) return const CircularProgressIndicator();
    return ListView.builder(
      itemCount: state.conversations.length,
      itemBuilder: (_, i) => ConvoItem(
        convoId: state.conversations[i].id,
        convoTitle: 'Conversation ${state.conversations[i].id}',
        lastMessagePreview: '',
      ),
    );
  }
}
```

#### `ChatPage` → `ConsumerStatefulWidget`

Hapus `ChatRepositoryImpl()` langsung, gunakan `ref.read(chatRepositoryProvider)`:

```dart
class _ChatPageState extends ConsumerState<ChatPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final repo = ref.read(chatRepositoryProvider);
      ref.read(chatNotifierProvider.notifier).initialize(repo);
    });
  }
  ...
}
```

---

## Dependency Graph

```
ProviderScope (main.dart)
│
├── appDatabaseProvider
│   ├── conversationLocalDataSourceProvider
│   └── messageLocalDataSourceProvider
│       └── convoRepositoryProvider
│           └── messageUseCaseProvider
│               └── conversationsNotifierProvider
│
├── backendRemoteDatasourceProvider
│   └── authRepositoryProvider
│       └── loginUseCaseProvider
│           └── loginNotifierProvider
│
└── chatRepositoryProvider
    └── chatNotifierProvider
```

---

## Penanganan Error

| Skenario                   | Penanganan                                                    |
| -------------------------- | ------------------------------------------------------------- |
| Login gagal (network/auth) | `LoginState.status = error`, `errorMessage` ditampilkan di UI |
| Fetch conversations gagal  | `ConversationsState.errorMessage` ditampilkan, list kosong    |
| WebSocket disconnect       | `ChatState.isConnected = false`, tombol reconnect tersedia    |
| Provider tidak tersedia    | Compile error — Riverpod gagal saat tidak ada `ProviderScope` |

---

## Perubahan `pubspec.yaml`

```yaml
dependencies:
  flutter_riverpod: ^2.6.1 # TAMBAH
  # get_it: ^9.2.1           # HAPUS
```

`build_runner` tetap ada untuk `drift_dev`.

---

## Strategi Testing

- **Unit test**: Notifier diuji dengan `ProviderContainer` dan mock repository
- **Property test**: Berlaku untuk logika transformasi state murni (lihat bagian Correctness Properties)
- **Integration test**: Tidak diperlukan untuk layer DI

---

## Correctness Properties

_Properti adalah karakteristik atau perilaku yang harus berlaku pada semua eksekusi valid sistem — pernyataan formal tentang apa yang seharusnya dilakukan sistem._

### Properti 1: Login state transition adalah deterministik

\*Untuk semua pasangan (username, password), memanggil `login()` pada `LoginNotifier` dengan hasil sukses selalu menghasilkan `LoginStatus.success`, dan dengan hasil error selalu menghasilkan `LoginStatus.error` — tidak ada transisi ke state lain.

**Validates: Requirements 2.1, 2.2**

### Properti 2: Conversations state setelah fetch konsisten dengan data

_Untuk semua list percakapan yang dikembalikan repository, `ConversationsState.conversations` setelah `fetchConversations()` selesai mengandung tepat elemen yang sama — tidak lebih, tidak kurang._

**Validates: Requirements 3.1, 3.2**

### Properti 3: Chat messages hanya bertambah, tidak hilang

_Untuk semua urutan pesan yang diterima dari stream, `ChatState.messages` setelah setiap pesan baru diterima memiliki panjang lebih besar dari sebelumnya, dan semua pesan lama tetap ada di posisi yang sama._

**Validates: Requirements 4.2**

### Properti 4: Provider dependency graph bebas sirkular

_Untuk semua kombinasi pemanggilan `ref.watch/read` di `providers.dart`, tidak ada provider yang secara langsung maupun tidak langsung bergantung pada dirinya sendiri._

**Validates: Requirements 1.1, 1.2**
