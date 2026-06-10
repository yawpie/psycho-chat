import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
part 'app_database.g.dart';
class Users extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get username => text().withLength(min: 1, max: 50)();
}

class Conversations extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get user1 => text().withLength(min: 1, max: 50)();
  TextColumn get user2 => text().withLength(min: 1, max: 50)();
  TextColumn get password => text().withLength(min: 0, max: 255).nullable()();
}

class Messages extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get conversationId =>
      integer().nullable().customConstraint('REFERENCES conversations(id)')();
  TextColumn get sender => text().withLength(min: 1, max: 50)();
  TextColumn get message => text()();
  DateTimeColumn get timestamp => dateTime()();
  TextColumn get status => text().withLength(min: 1, max: 20)();

}

@DriftDatabase(
  tables: [Users, Conversations, Messages],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase()
      : super(
          driftDatabase(
            name: 'psycho_chat',
          ),
        );


  @override
  int get schemaVersion => 1;
}