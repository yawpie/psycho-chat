// Validates: Requirements 3.3, 3.4
//
// Properti 1: Login state transition adalah deterministik
//
// Untuk semua pasangan (username, password), memanggil login() pada
// LoginNotifier dengan hasil sukses selalu menghasilkan
// LoginStatus.success, dan dengan hasil error selalu menghasilkan
// LoginStatus.error — tidak ada transisi ke state lain.

import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:psycho_chat/core/providers.dart';
import 'package:psycho_chat/domain/entities/user.dart';
import 'package:psycho_chat/domain/repositories/auth_repository.dart';
import 'package:psycho_chat/domain/usecases/login.dart';
import 'package:psycho_chat/presentation/providers/login_notifier.dart';

// ---------------------------------------------------------------------------
// Mock AuthRepository implementations
// ---------------------------------------------------------------------------

/// Mock yang selalu berhasil — mengembalikan [User] dummy.
class _SuccessAuthRepository implements AuthRepository {
  @override
  Future<User> login(String username, String password) async {
    return User(id: 'mock-id', username: username);
  }

  @override
  Future<void> register(String email, String password) async {}
}

/// Mock yang selalu gagal — melempar exception dengan pesan tertentu.
class _FailureAuthRepository implements AuthRepository {
  final String message;
  const _FailureAuthRepository(this.message);

  @override
  Future<User> login(String username, String password) async {
    throw Exception(message);
  }

  @override
  Future<void> register(String email, String password) async {
    throw Exception(message);
  }
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// Buat [ProviderContainer] yang mengoverride [authRepositoryProvider] dan
/// [loginUseCaseProvider] dengan implementasi mock.
ProviderContainer _buildContainer(AuthRepository mockRepo) {
  return ProviderContainer(
    overrides: [
      authRepositoryProvider.overrideWithValue(mockRepo),
      loginUseCaseProvider.overrideWith(
        (ref) => LoginUseCase(repository: ref.watch(authRepositoryProvider)),
      ),
    ],
  );
}

/// Generator string alfanumerik acak dengan panjang [length].
String _randomString(Random rng, int length) {
  const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
  return List.generate(length, (_) => chars[rng.nextInt(chars.length)]).join();
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  // Biji acak tetap agar pengujian deterministik dan dapat direproduksi.
  final rng = Random(42);

  // Jumlah pasangan (username, password) acak yang diuji per properti.
  const sampleCount = 50;

  group('Properti 1: Login state transition adalah deterministik', () {
    // -----------------------------------------------------------------------
    // State awal (idle)
    // -----------------------------------------------------------------------
    test('state awal LoginNotifier adalah LoginStatus.idle', () {
      final container = _buildContainer(_SuccessAuthRepository());
      addTearDown(container.dispose);

      final state = container.read(loginNotifierProvider);
      expect(state.status, LoginStatus.idle);
      expect(state.errorMessage, isNull);
    });

    // -----------------------------------------------------------------------
    // Sukses: untuk semua (username, password) acak dengan mock sukses,
    // state akhir selalu LoginStatus.success.
    // -----------------------------------------------------------------------
    test('login() dengan repository sukses selalu menghasilkan '
        'LoginStatus.success untuk $sampleCount pasangan acak', () async {
      for (var i = 0; i < sampleCount; i++) {
        final username = _randomString(rng, rng.nextInt(15) + 3);
        final password = _randomString(rng, rng.nextInt(20) + 6);

        final container = _buildContainer(_SuccessAuthRepository());
        addTearDown(container.dispose);

        final notifier = container.read(loginNotifierProvider.notifier);
        await notifier.login(username, password);

        final state = container.read(loginNotifierProvider);
        expect(
          state.status,
          LoginStatus.success,
          reason:
              'Expected success for username="$username", '
              'password="$password" (sample $i)',
        );
        expect(
          state.errorMessage,
          isNull,
          reason: 'errorMessage should be null on success (sample $i)',
        );
      }
    });

    // -----------------------------------------------------------------------
    // Error: untuk semua (username, password) acak dengan mock gagal,
    // state akhir selalu LoginStatus.error dan errorMessage tidak null.
    // -----------------------------------------------------------------------
    test('login() dengan repository gagal selalu menghasilkan '
        'LoginStatus.error untuk $sampleCount pasangan acak', () async {
      for (var i = 0; i < sampleCount; i++) {
        final username = _randomString(rng, rng.nextInt(15) + 3);
        final password = _randomString(rng, rng.nextInt(20) + 6);
        final errorMsg = 'error_${_randomString(rng, 8)}';

        final container = _buildContainer(_FailureAuthRepository(errorMsg));
        addTearDown(container.dispose);

        final notifier = container.read(loginNotifierProvider.notifier);
        await notifier.login(username, password);

        final state = container.read(loginNotifierProvider);
        expect(
          state.status,
          LoginStatus.error,
          reason:
              'Expected error for username="$username", '
              'password="$password" (sample $i)',
        );
        expect(
          state.errorMessage,
          isNotNull,
          reason: 'errorMessage should not be null on error (sample $i)',
        );
      }
    });

    // -----------------------------------------------------------------------
    // Loading: state intermediate adalah LoginStatus.loading sebelum
    // use case menyelesaikan eksekusinya.
    // -----------------------------------------------------------------------
    test(
      'login() menetapkan LoginStatus.loading sebelum use case selesai',
      () async {
        // Gunakan completer untuk menahan eksekusi use case.
        var loadingObserved = false;

        final slowRepo = _SlowAuthRepository(
          onCalled: () => loadingObserved = true,
        );
        final container = _buildContainer(slowRepo);
        addTearDown(container.dispose);

        final notifier = container.read(loginNotifierProvider.notifier);

        // Mulai login — jangan di-await dulu.
        final loginFuture = notifier.login('user', 'pass');

        // Saat ini use case sedang "berjalan" (Future belum selesai).
        // State seharusnya loading.
        expect(
          container.read(loginNotifierProvider).status,
          LoginStatus.loading,
        );

        // Tunggu selesai.
        await loginFuture;

        // Verifikasi bahwa repository sempat dipanggil.
        expect(loadingObserved, isTrue);
      },
    );

    // -----------------------------------------------------------------------
    // Idempoten: memanggil login() berulang kali dengan sukses tetap menghasilkan
    // LoginStatus.success — tidak ada transisi ke state lain yang tidak diharapkan.
    // -----------------------------------------------------------------------
    test('memanggil login() berkali-kali dengan sukses selalu berakhir di '
        'LoginStatus.success', () async {
      final container = _buildContainer(_SuccessAuthRepository());
      addTearDown(container.dispose);

      final notifier = container.read(loginNotifierProvider.notifier);

      for (var i = 0; i < 5; i++) {
        await notifier.login(_randomString(rng, 8), _randomString(rng, 10));
        expect(
          container.read(loginNotifierProvider).status,
          LoginStatus.success,
          reason: 'Expected success after call $i',
        );
      }
    });
  });
}

// ---------------------------------------------------------------------------
// Mock lambat untuk menguji state loading
// ---------------------------------------------------------------------------

class _SlowAuthRepository implements AuthRepository {
  final void Function() onCalled;
  _SlowAuthRepository({required this.onCalled});

  @override
  Future<User> login(String username, String password) async {
    onCalled();
    // Simulasi latensi jaringan minimal agar state loading dapat diobservasi.
    await Future<void>.delayed(Duration.zero);
    return User(id: 'slow-id', username: username);
  }

  @override
  Future<void> register(String email, String password) async {}
}
