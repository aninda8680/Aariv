import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart';

part 'database.g.dart';

enum TaskPriority { none, low, medium, high }

class Categories extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  IntColumn get colorValue => integer()(); // stored as ARGB int
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

class Tasks extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text().withLength(min: 1, max: 255)();
  TextColumn get notes => text().nullable()();
  DateTimeColumn get dueDate => dateTime().nullable()();
  DateTimeColumn get dueTime => dateTime().nullable()();
  IntColumn get priority => intEnum<TaskPriority>().withDefault(const Constant(0))(); 
  TextColumn get categoryId => text().nullable().references(Categories, #id)();
  BoolColumn get isCompleted => boolean().withDefault(const Constant(false))();
  DateTimeColumn get completedAt => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
}

class FocusSessions extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get taskId => integer().nullable().references(Tasks, #id)();
  IntColumn get durationSeconds => integer()();
  TextColumn get mode => text()(); // Pomodoro, Stopwatch, Countdown
  DateTimeColumn get startedAt => dateTime()();
  DateTimeColumn get completedAt => dateTime().nullable()();
  TextColumn get notes => text().nullable()();
  TextColumn get tags => text().nullable()();
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

@DriftDatabase(tables: [Tasks, Categories, FocusSessions, Transactions, Settings])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
      },
      onUpgrade: (Migrator m, int from, int to) async {
        if (from < 2) {
          await m.createTable(categories);
          
          await m.alterTable(TableMigration(
            tasks,
            columnTransformer: {
              tasks.categoryId: const CustomExpression('category'), // map old 'category' text to 'categoryId'
            },
            newColumns: [
              tasks.dueTime,
              tasks.completedAt,
              tasks.sortOrder,
              tasks.isDeleted,
              tasks.categoryId,
            ],
          ));
          
          // Migrate unique categories into Categories table.
          // Using 0xFF3DDC97 as default green color (mint from Phase 1)
          await customStatement('''
            INSERT OR IGNORE INTO categories (id, name, color_value, created_at) 
            SELECT DISTINCT category_id, category_id, 4282244247, strftime('%s','now') 
            FROM tasks WHERE category_id IS NOT NULL
          ''');
        }
        if (from < 3) {
          await m.addColumn(focusSessions, focusSessions.notes);
          await m.addColumn(focusSessions, focusSessions.tags);
        }
      },
      beforeOpen: (details) async {
        await customStatement('PRAGMA foreign_keys = ON');
      },
    );
  }
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
