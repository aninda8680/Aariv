import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart';

part 'database.g.dart';

class Tasks extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text().withLength(min: 1, max: 255)();
  TextColumn get notes => text().nullable()();
  DateTimeColumn get dueDate => dateTime().nullable()();
  IntColumn get priority => integer().withDefault(const Constant(0))(); // 0: None, 1: Low, 2: Medium, 3: High
  TextColumn get category => text().nullable()();
  BoolColumn get isCompleted => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

class FocusSessions extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get taskId => integer().nullable().references(Tasks, #id)();
  IntColumn get durationSeconds => integer()();
  TextColumn get mode => text()(); // Pomodoro, Stopwatch, Countdown
  DateTimeColumn get startedAt => dateTime()();
  DateTimeColumn get completedAt => dateTime().nullable()();
}

class Transactions extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get type => text()(); // income, expense
  RealColumn get amount => real()();
  TextColumn get category => text()();
  TextColumn get note => text().nullable()();
  DateTimeColumn get date => dateTime()();
}

class Settings extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {key};
}

@DriftDatabase(tables: [Tasks, FocusSessions, Transactions, Settings])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'aariv_db.sqlite'));

    // Make sqlite3 pick a more suitable location for temporary files - the
    // one from the system may be inaccessible due to sandboxing.
    final cachebase = (await getTemporaryDirectory()).path;
    // We can't access /tmp on Android, which sqlite3 would try by default.
    // Explicitly tell it about the correct temporary directory.
    sqlite3.tempDirectory = cachebase;

    return NativeDatabase.createInBackground(file);
  });
}
