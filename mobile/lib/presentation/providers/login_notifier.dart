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

  Future<void> login(String username, String password) async {
    state = const LoginState(status: LoginStatus.loading);
    try {
      await ref.read(loginUseCaseProvider).call(username, password);
      print("usecase login selesai...");
      // Set usernameProvider SEBELUM mengubah login state, agar saat listener
      // loginNotifierProvider memicu navigasi / fetchConversations, username
      // sudah tersedia di StateProvider.
      ref.read(usernameProvider.notifier).state = username;
      state = LoginState(status: LoginStatus.success, username: username);
      print("state berubah menjadi: ${state.username}");
    } catch (e) {
      state = LoginState(status: LoginStatus.error, errorMessage: e.toString());
    }
  }

  Future<void> logout() async {
    state = const LoginState(status: LoginStatus.loading);
    try {
      await ref.read(authRepositoryProvider).logout();
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
