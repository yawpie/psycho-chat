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
      ref.read(usernameProvider.notifier).state = username;
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
      print("usecase login selesai...");
      // Set usernameProvider SEBELUM mengubah login state, agar saat listener
      // loginNotifierProvider memicu navigasi / fetchConversations, username
      // sudah tersedia di StateProvider.
      ref.read(usernameProvider.notifier).state = username;
      state = LoginState(status: LoginStatus.success, username: username);
      print("state berubah menjadi: ${state.username}");
    } catch (e) {
      if (e.toString().contains("bad response")) {
        state = const LoginState(
          status: LoginStatus.error,
          errorMessage: "Username atau password salah",
        );
      } else {
        state = LoginState(status: LoginStatus.error, errorMessage: "Error");
      }
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
      await ref.read(loginUseCaseProvider).pasienLogin(password);
      ref.read(usernameProvider.notifier).state = "pasien";
      state = const LoginState(status: LoginStatus.success, username: "pasien");
    } catch (e) {
      state = LoginState(status: LoginStatus.error, errorMessage: e.toString());
    }
  }

  Future<void> logout() async {
    state = const LoginState(status: LoginStatus.loading);
    try {
      await ref.read(authRepositoryProvider).logout();
      ref.read(isDarkModeProvider.notifier).state = false;
      ref.read(usernameProvider.notifier).state = null;
      state = const LoginState(status: LoginStatus.idle);
    } catch (e) {
      state = LoginState(status: LoginStatus.error, errorMessage: e.toString());
    }
  }
}

final loginNotifierProvider = NotifierProvider<LoginNotifier, LoginState>(
  LoginNotifier.new,
);
