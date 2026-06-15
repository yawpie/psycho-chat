import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
// import 'app_database.steps.dart';
part 'app_database.g.dart';

class Users extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get username => text().withLength(min: 1, max: 50)();
}

class Conversations extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get receiver => text().withLength(min: 1, max: 50)();
  // TextColumn get user2 => text().withLength(min: 1, max: 50)();
  TextColumn get password => text().withLength(min: 0, max: 255).nullable()();
  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime)();
}

class Messages extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get conversationId =>
      integer().references(Conversations, #id).nullable()();
  TextColumn get sender => text().withLength(min: 1, max: 50)();
  TextColumn get message => text()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  TextColumn get status => text()
      .withLength(min: 1, max: 20)
      .withDefault(const Constant('pending'))();
}

@DriftDatabase(tables: [Users, Conversations, Messages])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(driftDatabase(name: 'psycho_chat'));

  /// Constructor for testing — accepts any [QueryExecutor] (e.g. in-memory).
  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 3;
  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async => m.createAll(),
    onUpgrade: (m, from, to) async {
      await m.deleteTable('messages');
      await m.deleteTable('conversations');
      await m.deleteTable('users');

      await m.createAll();
    },
  );
}

// extension Migrations on GeneratedDatabase {
//   // Extracting the `stepByStep` call into a static field or method ensures that you're not
//   // accidentally referring to the current database schema (via a getter on the database class).
//   // This ensures that each step brings the database into the correct snapshot.
//   OnUpgrade get _schemaUpgrade => stepByStep(
//     from1To2: (m, schema) async {
//       await m.createTable(schema.conversations);
//       await m.createTable(schema.users);
//       await m.createTable(schema.messages);
//     },
//   );
// }
