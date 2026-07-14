import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/database.dart';
import '../../providers/database_provider.dart';
import 'package:drift/drift.dart' as drift;

enum TodoFilter { all, today, upcoming, completed }

final todoFilterStateProvider = NotifierProvider<TodoFilterState, TodoFilter>(TodoFilterState.new);

class TodoFilterState extends Notifier<TodoFilter> {
  @override
  TodoFilter build() => TodoFilter.today;

  void setFilter(TodoFilter filter) => state = filter;
}

final todoListProvider = StreamProvider<List<Task>>((ref) {
  final db = ref.watch(databaseProvider);
  final filter = ref.watch(todoFilterStateProvider);
  
  final now = DateTime.now();
  final todayStart = DateTime(now.year, now.month, now.day);
  final todayEnd = todayStart.add(const Duration(days: 1));

  switch (filter) {
    case TodoFilter.all:
      return db.select(db.tasks).watch();
    case TodoFilter.completed:
      return (db.select(db.tasks)..where((t) => t.isCompleted.equals(true))).watch();
    case TodoFilter.today:
      return (db.select(db.tasks)
            ..where((t) => 
              t.isCompleted.equals(false) &
              (t.dueDate.isNull() | (t.dueDate.isBiggerOrEqualValue(todayStart) & t.dueDate.isSmallerThanValue(todayEnd)))
            ))
          .watch();
    case TodoFilter.upcoming:
      return (db.select(db.tasks)
            ..where((t) => 
              t.isCompleted.equals(false) & 
              t.dueDate.isBiggerOrEqualValue(todayEnd)
            ))
          .watch();
  }
});

final todoActionsProvider = Provider<TodoActions>((ref) {
  return TodoActions(ref);
});

class TodoActions {
  final Ref ref;
  TodoActions(this.ref);

  Future<void> addTask(String title, String? notes, DateTime? dueDate, int priority, String? category) async {
    final db = ref.read(databaseProvider);
    await db.into(db.tasks).insert(TasksCompanion.insert(
          title: title,
          notes: drift.Value(notes),
          dueDate: drift.Value(dueDate),
          priority: drift.Value(priority),
          category: drift.Value(category),
        ));
  }

  Future<void> toggleTaskCompletion(Task task) async {
    final db = ref.read(databaseProvider);
    await (db.update(db.tasks)..where((t) => t.id.equals(task.id)))
        .write(TasksCompanion(isCompleted: drift.Value(!task.isCompleted)));
  }

  Future<void> deleteTask(Task task) async {
    final db = ref.read(databaseProvider);
    await (db.delete(db.tasks)..where((t) => t.id.equals(task.id))).go();
  }
}
