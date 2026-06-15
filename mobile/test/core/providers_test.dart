// Validates: Requirements 1.3
//
// Properti 4: Provider dependency graph bebas sirkular
//
// Untuk semua kombinasi pemanggilan ref.watch/read di providers.dart,
// tidak ada provider yang secara langsung maupun tidak langsung bergantung
// pada dirinya sendiri.

import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:psycho_chat/core/providers.dart';
import 'package:psycho_chat/data/datasources/local/app_database.dart';
import 'package:psycho_chat/data/datasources/remote/backend_remote_datasource.dart';
import 'package:dio/dio.dart';

/// Creates a test [AppDatabase] backed by an in-memory SQLite database.
AppDatabase _buildInMemoryDatabase() {
  return AppDatabase.forTesting(NativeDatabase.memory());
}

void main() {
  // ---------------------------------------------------------------------------
  // Properti 4: Dependency graph bebas sirkular
  //
  // Memverifikasi bahwa membaca semua provider dalam ProviderContainer tidak
  // melempar ProviderException siklus (circular dependency). Riverpod
  // mendeteksi siklus saat provider pertama kali di-resolve, sehingga
  // membaca setiap provider sudah cukup untuk memvalidasi properti ini.
  // ---------------------------------------------------------------------------
  group('Properti 4: Provider dependency graph bebas sirkular', () {
    late ProviderContainer container;

    setUp(() {
      // Override leaf providers yang membutuhkan platform resource (SQLite
      // file, jaringan) agar test dapat berjalan tanpa emulator.
      container = ProviderContainer(
        overrides: [
          // Override AppDatabase dengan in-memory instance
          appDatabaseProvider.overrideWithValue(_buildInMemoryDatabase()),
          // Override BackendRemoteDatasource dengan instance menggunakan Dio default
          backendRemoteDatasourceProvider.overrideWithValue(
            BackendRemoteDataSource(dio: Dio()),
          ),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    test(
      'membaca semua datasource provider tidak melempar ProviderException siklus',
      () {
        // Tidak ada assertion eksplisit — jika ada siklus, Riverpod akan
        // melempar StateError/ProviderException sebelum nilai dikembalikan.
        expect(() {
          container.read(appDatabaseProvider);
          container.read(backendRemoteDatasourceProvider);
          container.read(conversationLocalDataSourceProvider);
          container.read(messageLocalDataSourceProvider);
        }, returnsNormally);
      },
    );

    test(
      'membaca semua repository provider tidak melempar ProviderException siklus',
      () {
        expect(() {
          container.read(authRepositoryProvider);
          container.read(convoRepositoryProvider);
          container.read(chatRepositoryProvider);
        }, returnsNormally);
      },
    );

    test(
      'membaca semua use case provider tidak melempar ProviderException siklus',
      () {
        expect(() {
          container.read(loginUseCaseProvider);
          container.read(messageUseCaseProvider);
        }, returnsNormally);
      },
    );

    test(
      'membaca seluruh provider graph sekaligus tidak melempar ProviderException siklus',
      () {
        // Membaca semua provider dalam satu langkah untuk memvalidasi bahwa
        // seluruh DAG dapat di-resolve tanpa siklus.
        expect(() {
          container.read(appDatabaseProvider);
          container.read(backendRemoteDatasourceProvider);
          container.read(conversationLocalDataSourceProvider);
          container.read(messageLocalDataSourceProvider);
          container.read(authRepositoryProvider);
          container.read(convoRepositoryProvider);
          container.read(chatRepositoryProvider);
          container.read(loginUseCaseProvider);
          container.read(messageUseCaseProvider);
        }, returnsNormally);
      },
    );
  });
}
