import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
part 'app_database.g.dart';

class Conversations extends Table {
  TextColumn get id => text()();
  TextColumn get receiver => text().withLength(min: 1, max: 50)();
  TextColumn get displayName => text().nullable()();
  TextColumn get password => text().withLength(min: 0, max: 255).nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

class Messages extends Table {
  TextColumn get id => text().nullable()();
  TextColumn get clientMessageId => text()();
  TextColumn get conversationId => text().references(Conversations, #id)();
  TextColumn get sender => text().withLength(min: 1, max: 50)();
  TextColumn get message => text()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  TextColumn get status => text()
      .withLength(min: 1, max: 20)
      .withDefault(const Constant('pending'))();

  @override
  Set<Column> get primaryKey => {clientMessageId};
}

@DriftDatabase(tables: [Conversations, Messages])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(driftDatabase(name: 'psycho_chat'));

  /// Constructor for testing — accepts any [QueryExecutor] (e.g. in-memory).
  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 5;
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
