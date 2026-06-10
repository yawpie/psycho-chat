# Dokumen Kebutuhan: Migrasi State Management & DI dari get_it ke Riverpod Modern

## Pendahuluan

Aplikasi Flutter `psycho_chat` saat ini menggunakan `get_it` sebagai service locator untuk dependency injection. Migrasi ini mengganti `get_it` sepenuhnya dengan `flutter_riverpod`, memperbaiki masalah state yang tidak terhubung ke UI, dan memastikan semua halaman presentation menggunakan DI yang konsisten. Struktur clean architecture yang sudah ada (domain, data, presentation layer) tidak diubah.

---

## Glosarium

- **DI (Dependency Injection)**: Mekanisme penyediaan dependensi ke sebuah komponen dari luar, bukan diinstansiasi langsung di dalam komponen tersebut.
- **Provider**: Unit injeksi Riverpod yang mendeskripsikan cara membuat sebuah nilai/objek.
- **ProviderScope**: Widget root Riverpod yang harus membungkus seluruh widget tree agar semua provider dapat diakses.
- **Notifier**: Kelas Riverpod yang mengelola state yang dapat berubah, diakses melalui `NotifierProvider`.
- **ConsumerWidget / ConsumerStatefulWidget**: Varian widget Flutter dari Riverpod yang memiliki akses ke `ref` untuk membaca dan mengamati provider.
- **getIt**: Library service locator lama yang akan dihapus sepenuhnya.
- **AppDatabase**: Instans database Drift lokal aplikasi.
- **BackendRemoteDatasource**: Datasource yang berkomunikasi dengan backend via Dio/HTTP.
- **LoginUseCase**: Use case yang mengeksekusi proses autentikasi pengguna.
- **MessageUseCase**: Use case yang mengelola pengambilan dan pengiriman pesan/percakapan.
- **ChatRepository**: Repository abstrak untuk koneksi dan komunikasi WebSocket.
- **LoginNotifier**: Notifier yang mengelola state proses login.
- **ConversationsNotifier**: Notifier yang mengelola state daftar percakapan.
- **ChatNotifier**: Notifier yang mengelola state koneksi WebSocket dan daftar pesan.

---

## Kebutuhan

### Kebutuhan 1: Setup Provider Terpusat

**User Story:** Sebagai developer, saya ingin semua dependency dari datasource hingga use case didaftarkan di satu file terpusat menggunakan Riverpod, sehingga dependency graph aplikasi mudah dipahami dan dipelihara.

#### Kriteria Penerimaan

1. THE Provider Terpusat SHALL mendaftarkan `AppDatabase`, `BackendRemoteDatasource`, `ConversationLocalDataSource`, `MessageLocalDataSource`, `AuthRepositoryImpl`, `ConvoRepositoryImpl`, `LoginUseCase`, `MessageUseCase`, dan `ChatRepositoryImpl` masing-masing sebagai sebuah `Provider` di file `lib/core/providers.dart`.

2. WHEN sebuah provider membutuhkan dependency lain, THE Provider Terpusat SHALL menggunakan `ref.watch()` untuk mengambil dependency tersebut dari provider lain yang sudah terdaftar di file yang sama.

3. THE Provider Terpusat SHALL mendefinisikan dependency dalam urutan yang membentuk Directed Acyclic Graph (DAG) — tidak ada provider yang secara langsung maupun tidak langsung bergantung pada dirinya sendiri.

4. THE Provider Terpusat SHALL menggantikan seluruh fungsionalitas `lib/core/di/datasource_module.dart`, `lib/core/di/repository_module.dart`, dan `lib/core/di/usecase_module.dart`.

---

### Kebutuhan 2: Migrasi Entry Point Aplikasi

**User Story:** Sebagai developer, saya ingin entry point aplikasi tidak lagi menggunakan `get_it`, sehingga booting aplikasi lebih sederhana dan bebas dari inisialisasi manual.

#### Kriteria Penerimaan

1. WHEN aplikasi dijalankan, THE `main.dart` SHALL membungkus `PsychoChatApp` dengan `ProviderScope` sebagai widget paling luar.

2. THE `main.dart` SHALL tidak memanggil `setupInjection()` atau fungsi inisialisasi `get_it` manapun.

3. THE `app.dart` SHALL tidak mengimpor `injection.dart` dan SHALL tidak menginstansiasi `Injection()`.

4. THE `app.dart` SHALL menampilkan `IntroPage` sebagai halaman awal tanpa meneruskan parameter use case melalui konstruktor.

---

### Kebutuhan 3: Migrasi Halaman Login Psikiater

**User Story:** Sebagai psikiater, saya ingin dapat login ke aplikasi dengan state yang terkelola dengan baik, sehingga saya mendapat umpan balik yang jelas saat login sedang diproses, berhasil, atau gagal.

#### Kriteria Penerimaan

1. THE `PsikiaterLoginPage` SHALL diubah menjadi `ConsumerStatefulWidget` yang mengakses `LoginNotifier` melalui `ref.read(loginNotifierProvider.notifier)`.

2. WHEN pengguna menekan tombol login, THE `LoginNotifier` SHALL mengubah state menjadi `LoginStatus.loading` sebelum memanggil `LoginUseCase`.

3. WHEN `LoginUseCase` mengembalikan hasil berhasil, THE `LoginNotifier` SHALL mengubah state menjadi `LoginStatus.success`.

4. IF `LoginUseCase` melempar exception, THEN THE `LoginNotifier` SHALL mengubah state menjadi `LoginStatus.error` dan menyimpan pesan error di field `errorMessage`.

5. WHEN state `loginNotifierProvider` berubah menjadi `LoginStatus.success`, THE `PsikiaterLoginPage` SHALL menavigasi pengguna ke `PsikiaterConversationsPage`.

6. THE `PsikiaterLoginPage` SHALL tidak menggunakan `getIt<LoginUseCase>()` atau menginstansiasi `LoginUseCase` secara langsung.

---

### Kebutuhan 4: Migrasi Halaman Percakapan

**User Story:** Sebagai psikiater, saya ingin melihat daftar percakapan yang diambil dari repository secara nyata, bukan data hardcoded, sehingga saya dapat memantau semua percakapan pasien.

#### Kriteria Penerimaan

1. THE `PsikiaterConversationsPage` SHALL diubah menjadi `ConsumerStatefulWidget` yang mengamati `conversationsNotifierProvider`.

2. WHEN `PsikiaterConversationsPage` pertama kali di-mount, THE `ConversationsNotifier` SHALL memanggil `MessageUseCase.getConversationsForUser()` untuk mengambil data percakapan.

3. WHEN `ConversationsNotifier` sedang memuat data, THE `PsikiaterConversationsPage` SHALL menampilkan indikator loading.

4. WHEN `ConversationsNotifier` berhasil memuat data, THE `PsikiaterConversationsPage` SHALL menampilkan daftar percakapan menggunakan widget `ConvoItem` dengan data dari `ConversationsState.conversations`.

5. IF pengambilan data percakapan gagal, THEN THE `ConversationsNotifier` SHALL menyimpan pesan error di `ConversationsState.errorMessage`.

6. THE `PsikiaterConversationsPage` SHALL tidak menggunakan `getIt<MessageUseCase>()` dan SHALL tidak menampilkan data percakapan hardcoded.

---

### Kebutuhan 5: Migrasi Halaman Chat

**User Story:** Sebagai pasien, saya ingin halaman chat menggunakan dependency injection yang konsisten, sehingga `ChatRepository` tidak diinstansiasi langsung di dalam widget.

#### Kriteria Penerimaan

1. THE `ChatPage` SHALL diubah menjadi `ConsumerStatefulWidget` yang mendapatkan `ChatRepository` melalui `ref.read(chatRepositoryProvider)`.

2. WHEN `ChatPage` pertama kali di-mount, THE `ChatNotifier` SHALL menerima instance `ChatRepository` dari provider dan memanggil `connect()` untuk memulai koneksi WebSocket.

3. WHEN pesan baru diterima dari stream `ChatRepository`, THE `ChatNotifier` SHALL menambahkan pesan tersebut ke `ChatState.messages` tanpa menghapus pesan yang sudah ada sebelumnya.

4. WHEN status koneksi `ChatRepository` berubah, THE `ChatNotifier` SHALL memperbarui `ChatState.isConnected` agar mencerminkan status terkini.

5. THE `ChatPage` SHALL tidak menginstansiasi `ChatRepositoryImpl()` secara langsung.

---

### Kebutuhan 6: Penghapusan get_it

**User Story:** Sebagai developer, saya ingin `get_it` dihapus sepenuhnya dari proyek, sehingga tidak ada dua sistem DI yang berjalan bersamaan.

#### Kriteria Penerimaan

1. THE `pubspec.yaml` SHALL menambahkan `flutter_riverpod: ^2.6.1` ke bagian `dependencies`.

2. THE `pubspec.yaml` SHALL menghapus `get_it` dari bagian `dependencies`.

3. THE Proyek SHALL menghapus folder `lib/core/di/` beserta seluruh isinya (`injection.dart`, `datasource_module.dart`, `repository_module.dart`, `usecase_module.dart`).

4. WHEN semua perubahan selesai diterapkan, THE Proyek SHALL dapat dikompilasi tanpa error yang berkaitan dengan `get_it` atau `Injection`.
