import 'package:drift/drift.dart';
import 'package:psycho_chat/data/datasources/local/app_database.dart';
import 'package:psycho_chat/data/models/chat_message_model.dart'
    as message_model;

class UserLocalDataSource {
  final AppDatabase database;

  UserLocalDataSource(this.database);

  Future<List<User>> getUsers() {
    return database.select(database.users).get();
  }

  Future<void> createUser(String username) {
    return database
        .into(database.users)
        .insert(UsersCompanion.insert(username: username));
  }

  Future<void> deleteUser(int id) {
    return (database.delete(
      database.users,
    )..where((u) => u.id.equals(id))).go();
  }
}