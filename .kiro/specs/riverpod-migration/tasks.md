# Implementation Plan: Migrasi get_it ke Riverpod

## Overview

Migrasi dilakukan secara bertahap dari bawah ke atas: pertama setup Riverpod di pubspec & entry point, lalu buat provider terpusat, kemudian buat Notifier per halaman, dan terakhir perbarui setiap halaman presentation. Folder `lib/core/di/` dihapus di akhir setelah semua referensinya diganti.

## Tasks

- [ ] 1. Update pubspec.yaml — tambah flutter_riverpod, hapus get_it
  - Tambahkan `flutter_riverpod: ^2.6.1` ke bagian `dependencies`
  - Hapus `get_it: ^9.2.1` dari bagian `dependencies`
  - Jalankan `flutter pub get` untuk mengunduh dependencies baru
  - _Requirements: 6.1, 6.2_

- [ ] 2. Buat `lib/core/providers.dart` — provider infrastruktur terpusat
  - [ ] 2.1 Buat file `lib/core/providers.dart` dengan semua provider dari datasource sampai use case
    - Daftarkan `appDatabaseProvider`, `backendRemoteDatasourceProvider`, `conversationLocalDataSourceProvider`, `messageLocalDataSourceProvider`
    - Daftarkan `authRepositoryProvider`, `convoRepositoryProvider`, `chatRepositoryProvider`
    - Daftarkan `loginUseCaseProvider`, `messageUseCaseProvider`
    - Pastikan setiap provider menggunakan `ref.watch()` untuk dependency-nya
    - _Requirements: 1.1, 1.2, 1.3, 1.4_

  - [ ]\* 2.2 Tulis property test untuk dependency graph (Properti 4)
    - **Properti 4: Provider dependency graph bebas sirkular**
    - Buat `ProviderContainer` di test, read semua provider, pastikan tidak ada `ProviderException` siklik
    - **Validates: Requirements 1.3**

- [ ] 3. Perbarui entry point — `main.dart` dan `app.dart`
  - [ ] 3.1 Perbarui `main.dart`: hapus `setupInjection()`, bungkus app dengan `ProviderScope`
    - Hapus import `injection.dart`
    - Hapus `await setupInjection()`
    - Ubah `runApp(const PsychoChatApp())` menjadi `runApp(const ProviderScope(child: PsychoChatApp()))`
    - _Requirements: 2.1, 2.2_

  - [ ] 3.2 Perbarui `app.dart`: hapus `Injection()`, ubah `IntroPage` tanpa parameter
    - Hapus import `injection.dart`
    - Hapus `loginUseCase: Injection().loginUseCase` dari konstruktor `IntroPage`
    - _Requirements: 2.3, 2.4_

- [ ] 4. Checkpoint — Pastikan aplikasi dapat dikompilasi setelah perubahan entry point
  - Pastikan semua tes berjalan, tidak ada compile error. Tanyakan pada user jika ada pertanyaan.

- [ ] 5. Buat `lib/presentation/providers/login_notifier.dart`
  - [ ] 5.1 Buat file `lib/presentation/providers/login_notifier.dart`
    - Definisikan enum `LoginStatus { idle, loading, success, error }`
    - Definisikan class `LoginState` dengan field `status` dan `errorMessage`
    - Implementasikan `LoginNotifier extends Notifier<LoginState>` dengan method `login(username, password)`
    - Method `login()` harus: set loading → panggil use case → set success atau error
    - Daftarkan `loginNotifierProvider = NotifierProvider<LoginNotifier, LoginState>(...)`
    - _Requirements: 3.1, 3.2, 3.3, 3.4_

  - [ ]\* 5.2 Tulis property test untuk LoginNotifier (Properti 1)
    - **Properti 1: Login state transition adalah deterministik**
    - Gunakan `ProviderContainer` dengan mock `AuthRepository`
    - Generate random username/password, verifikasi bahwa hasil sukses selalu menghasilkan `LoginStatus.success` dan error selalu menghasilkan `LoginStatus.error`
    - **Validates: Requirements 3.3, 3.4**

- [ ] 6. Migrasi `PsikiaterLoginPage` ke ConsumerStatefulWidget
  - Ubah `PsikiaterLoginPage` dari `StatefulWidget` menjadi `ConsumerStatefulWidget`
  - Ubah `_PsikiaterLoginPageState` menjadi `ConsumerState<PsikiaterLoginPage>`
  - Hapus `final LoginUseCase loginUseCase = getIt<LoginUseCase>()`
  - Di `_handleSubmit()`, ganti dengan `ref.read(loginNotifierProvider.notifier).login(...)`
  - Di `build()`, tambahkan `ref.watch(loginNotifierProvider)` untuk memantau state
  - Tambahkan logika navigasi ke `PsikiaterConversationsPage` ketika status `success`
  - Hapus import `injection.dart`
  - _Requirements: 3.1, 3.5, 3.6_

- [ ] 7. Buat `lib/presentation/providers/conversations_notifier.dart`
  - [ ] 7.1 Buat file `lib/presentation/providers/conversations_notifier.dart`
    - Definisikan class `ConversationsState` dengan field `conversations`, `isLoading`, `errorMessage`
    - Implementasikan `ConversationsNotifier extends Notifier<ConversationsState>`
    - Method `fetchConversations(username)`: set loading → panggil use case → set hasil atau error
    - Daftarkan `conversationsNotifierProvider`
    - _Requirements: 4.2, 4.5_

  - [ ]\* 7.2 Tulis property test untuk ConversationsNotifier (Properti 2)
    - **Properti 2: Conversations state setelah fetch konsisten dengan data**
    - Generate random list `Conversation`, mock repository agar return list tersebut
    - Verifikasi `state.conversations` setelah fetch mengandung tepat elemen yang sama
    - **Validates: Requirements 4.4**

- [ ] 8. Migrasi `PsikiaterConversationsPage` ke ConsumerStatefulWidget
  - Ubah page menjadi `ConsumerStatefulWidget`
  - Hapus `final MessageUseCase messageUseCase = getIt<MessageUseCase>()`
  - Di `initState()`, tambahkan `WidgetsBinding.instance.addPostFrameCallback` yang memanggil `ref.read(conversationsNotifierProvider.notifier).fetchConversations(...)`
  - Di `build()`, watch `conversationsNotifierProvider` dan tampilkan loading indicator saat `isLoading == true`
  - Ganti `ListView` hardcoded dengan `ListView.builder` yang menggunakan `state.conversations`
  - Hapus import `injection.dart`
  - _Requirements: 4.1, 4.3, 4.4, 4.6_

- [ ] 9. Checkpoint — Pastikan alur login → daftar percakapan bekerja
  - Pastikan semua tes berjalan, tidak ada compile error. Tanyakan pada user jika ada pertanyaan.

- [ ] 10. Buat `lib/presentation/providers/chat_notifier.dart`
  - [ ] 10.1 Buat file `lib/presentation/providers/chat_notifier.dart`
    - Definisikan class `ChatState` dengan field `messages` dan `isConnected`
    - Implementasikan `ChatNotifier extends Notifier<ChatState>`
    - Method `initialize(ChatRepository)`: simpan repository, panggil `_connect()`
    - Method `_connect()`: batal subscription lama → connect → subscribe stream → update state
    - Method `sendMessage(text)`: validasi koneksi, panggil `repository.sendMessage()`
    - Method `disconnect()`: cancel subscription, panggil `repository.disconnect()`
    - Daftarkan `chatNotifierProvider`
    - _Requirements: 5.2, 5.3, 5.4_

  - [ ]\* 10.2 Tulis property test untuk ChatNotifier (Properti 3)
    - **Properti 3: Chat messages hanya bertambah, tidak hilang**
    - Buat mock stream yang emit urutan pesan secara berurutan
    - Untuk setiap pesan baru yang diterima, verifikasi `messages.length` bertambah 1 dan semua pesan sebelumnya masih ada di indeks yang sama
    - **Validates: Requirements 5.3**

- [ ] 11. Migrasi `ChatPage` ke ConsumerStatefulWidget
  - Ubah `ChatPage` menjadi `ConsumerStatefulWidget`
  - Ubah `_ChatPageState` menjadi `ConsumerState<ChatPage>`
  - Hapus `final ChatRepository _repository = ChatRepositoryImpl()`
  - Di `initState()`, gunakan `WidgetsBinding.instance.addPostFrameCallback` yang membaca `ref.read(chatRepositoryProvider)` dan memanggil `ref.read(chatNotifierProvider.notifier).initialize(repo)`
  - Di `build()`, watch `chatNotifierProvider` untuk `messages` dan `isConnected`
  - Di `dispose()`, panggil `ref.read(chatNotifierProvider.notifier).disconnect()`
  - Hapus import `chat_repository_impl.dart`
  - _Requirements: 5.1, 5.5_

- [ ] 12. Hapus folder `lib/core/di/` dan bersihkan sisa import get_it
  - Hapus file `lib/core/di/injection.dart`
  - Hapus file `lib/core/di/datasource_module.dart`
  - Hapus file `lib/core/di/repository_module.dart`
  - Hapus file `lib/core/di/usecase_module.dart`
  - Hapus folder `lib/core/di/`
  - Cari dan hapus semua sisa import `package:get_it/get_it.dart` dan `package:psycho_chat/core/di/injection.dart` di seluruh proyek
  - _Requirements: 6.3, 6.4_

- [ ] 13. Checkpoint Akhir — Verifikasi kompilasi dan fungsionalitas menyeluruh
  - Pastikan semua tes berjalan, tidak ada compile error terkait `get_it` atau `Injection`. Tanyakan pada user jika ada pertanyaan.

## Task Dependency Graph

```json
{
  "waves": [
    ["1"],
    ["2"],
    ["3"],
    ["4"],
    ["5"],
    ["6"],
    ["7"],
    ["8"],
    ["9"],
    ["10"],
    ["11"],
    ["12"],
    ["13"]
  ]
}
```

## Notes

- Task bertanda `*` bersifat opsional dan dapat dilewati untuk implementasi yang lebih cepat
- Semua property test menggunakan `ProviderContainer` dari Riverpod dan mock repository — tidak memerlukan emulator
- Urutan task dirancang inkremental: setiap task dapat diverifikasi sebelum lanjut ke berikutnya
- `build_runner` untuk Drift tidak perlu dijalankan ulang kecuali ada perubahan di skema database
