import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:psycho_chat/core/providers.dart';

enum LoginStatus { idle, loading, success, error }

class LoginState {
  final LoginStatus status;
  final String? errorMessage;
  final String? username;

  const LoginState({
    this.status = LoginStatus.idle,
    this.errorMessage,
    this.username,
  });
}

class LoginNotifier extends Notifier<LoginState> {
  @override
  LoginState build() => const LoginState();

  String _generateUsername(String fullName) {
    final baseUsername =
        fullName.trim().replaceAll(' ', '').toLowerCase() +
        DateTime.now().millisecondsSinceEpoch.toString().substring(7);
    return baseUsername.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');
  }

  Future<bool> checkLoginStatus() async {
    state = const LoginState(status: LoginStatus.loading);
    try {
      final username = await ref.read(authRepositoryProvider).getUsername();
      if (username == null) {
        state = const LoginState(status: LoginStatus.idle);
        return false;
      }
      final role = await ref.read(authRepositoryProvider).getUserRole();
      final convoId = await ref.read(authRepositoryProvider).getPasienConvoId();
      ref.read(usernameProvider.notifier).state = username;
      ref.read(userRoleProvider.notifier).state = role;
      if (role == 'PASIEN' && convoId != null) {
        ref.read(pasienConvoIdProvider.notifier).state = convoId;
      }
      state = LoginState(status: LoginStatus.success, username: username);
      return true;
    } catch (e) {
      state = LoginState(status: LoginStatus.error, errorMessage: e.toString());
      return false;
    }
  }

  Future<void> login(String username, String password) async {
    state = const LoginState(status: LoginStatus.loading);
    try {
      await ref.read(loginUseCaseProvider).login(username, password);
      print("LoginNotifier: Login successful for user: $username");
      // Set usernameProvider SEBELUM mengubah login state, agar saat listener
      // loginNotifierProvider memicu navigasi / fetchConversations, username
      // sudah tersedia di StateProvider.
      ref.read(usernameProvider.notifier).state = username;

      // Setup kunci enkripsi SEBELUM state berubah ke success agar kunci
      // sudah siap saat user membuka chat page. Kegagalan tidak menghentikan login.
      await _setupEncryptionKeysInBackground(username, password);

      state = LoginState(status: LoginStatus.success, username: username);
    } catch (e) {
      print("LoginNotifier: Login error: ${e.toString()}");
      if (e.toString().contains("bad response")) {
        state = const LoginState(
          status: LoginStatus.error,
          errorMessage: "Username atau password salah",
        );
      } else {
        state = LoginState(status: LoginStatus.error, errorMessage: "Error");
      }
      rethrow;
    }
  }

  /// Fetch conversations lalu derive kunci enkripsi untuk setiap percakapan.
  Future<void> _setupEncryptionKeysInBackground(
    String username,
    String password,
  ) async {
    try {
      await ref.read(messageUseCaseProvider).fetchConvosForUser(username);
      await ref
          .read(encryptionUseCaseProvider)
          .setupEncryptionKeysForAllConversations(
            username: username,
            password: password,
          );
    } catch (e) {
      print("Error setting up encryption keys: $e");
      rethrow;
      // Kegagalan setup kunci tidak menghentikan sesi
    }
  }

  Future<String?> register(String fullName, String password) async {
    state = const LoginState(status: LoginStatus.loading);
    final strippedUsername = _generateUsername(fullName);
    try {
      final responseUsername = await ref
          .read(registerUseCaseProvider)
          .register(strippedUsername, password);
      state = const LoginState(status: LoginStatus.idle);
      return responseUsername;
    } catch (e) {
      if (e.toString().contains("bad response")) {
        state = const LoginState(
          status: LoginStatus.error,
          errorMessage: "Username sudah terdaftar",
        );
      } else {
        state = LoginState(status: LoginStatus.error, errorMessage: "Error");
      }
      return null;
    }
  }

  Future<String?> createNewPasien(String fullName, String password) async {
    state = const LoginState(status: LoginStatus.loading);
    final createdBy = ref.read(usernameProvider);
    if (createdBy == null) {
      state = const LoginState(
        status: LoginStatus.error,
        errorMessage: 'User not found. Please log in again.',
      );
      return null;
    }

    final pasienUsername = _generateUsername(fullName);
    try {
      await ref
          .read(authRepositoryProvider)
          .createNewPasien(pasienUsername, createdBy, password, fullName);
      state = const LoginState(status: LoginStatus.idle);
      return pasienUsername;
    } catch (e) {
      state = LoginState(status: LoginStatus.error, errorMessage: e.toString());
      return null;
    }
  }

  Future<void> loginAsGuest(String password) async {
    state = const LoginState(status: LoginStatus.loading);
    try {
      final conversationId = await ref
          .read(loginUseCaseProvider)
          .pasienLogin(password);

      final username = await ref.read(authRepositoryProvider).getUsername();

      ref.read(usernameProvider.notifier).state = username;
      ref.read(userRoleProvider.notifier).state = 'PASIEN';
      ref.read(pasienConvoIdProvider.notifier).state = conversationId;

      // Derive kunci enkripsi pasien SEBELUM state success agar kunci sudah
      // siap saat chat page dibuka.
      await _setupPasienEncryptionKey(conversationId, password);

      state = LoginState(status: LoginStatus.success, username: username);
    } catch (e) {
      state = LoginState(
        status: LoginStatus.error,
        errorMessage: 'Password tidak valid. Coba lagi.',
      );
    }
  }

  Future<void> _setupPasienEncryptionKey(
    String conversationId,
    String password,
  ) async {
    try {
      await ref
          .read(encryptionUseCaseProvider)
          .setupEncryptionKeyForConversation(
            conversationId: conversationId,
            password: password,
          );
    } catch (_) {
      // Kegagalan setup kunci tidak menghentikan sesi
    }
  }

  Future<void> logout() async {
    state = const LoginState(status: LoginStatus.loading);
    try {
      await ref.read(authRepositoryProvider).logout();
      // Hapus semua kunci enkripsi dari secure storage saat logout
      await ref.read(encryptionUseCaseProvider).clearAllEncryptionKeys();
      ref.read(usernameProvider.notifier).state = null;
      ref.read(userRoleProvider.notifier).state = null;
      ref.read(pasienConvoIdProvider.notifier).state = null;
      state = const LoginState(status: LoginStatus.idle);
    } catch (e) {
      state = LoginState(status: LoginStatus.error, errorMessage: e.toString());
    }
  }
}

final loginNotifierProvider = NotifierProvider<LoginNotifier, LoginState>(
  LoginNotifier.new,
);
