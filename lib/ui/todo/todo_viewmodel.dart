import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/database.dart';
import '../../providers/database_provider.dart';
import 'package:drift/drift.dart' as drift;

// Base stream excluding deleted tasks
final tasksStreamProvider = StreamProvider<List<Task>>((ref) {
  final db = ref.watch(databaseProvider);
  return (db.select(db.tasks)..where((t) => t.isDeleted.equals(false))).watch();
});

// Filter state
enum TodoFilter { all, today, upcoming, completed, overdue }

class TodoFilterNotifier extends Notifier<TodoFilter> {
  @override
  TodoFilter build() => TodoFilter.today;
  void setFilter(TodoFilter filter) => state = filter;
}
final todoFilterProvider = NotifierProvider<TodoFilterNotifier, TodoFilter>(TodoFilterNotifier.new);

// Secondary filters
class PriorityFilterNotifier extends Notifier<TaskPriority?> {
  @override
  TaskPriority? build() => null;
}
final priorityFilterProvider = NotifierProvider<PriorityFilterNotifier, TaskPriority?>(PriorityFilterNotifier.new);

class CategoryFilterNotifier extends Notifier<String?> {
  @override
  String? build() => null;
}
final categoryFilterProvider = NotifierProvider<CategoryFilterNotifier, String?>(CategoryFilterNotifier.new);

class SearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';
}
final searchQueryProvider = NotifierProvider<SearchQueryNotifier, String>(SearchQueryNotifier.new);

// Sort state
enum TaskSort { none, dueDate, priority, createdAt, alphabetical }
class TaskSortNotifier extends Notifier<TaskSort> {
  @override
  TaskSort build() => TaskSort.none;
}
final taskSortProvider = NotifierProvider<TaskSortNotifier, TaskSort>(TaskSortNotifier.new);

// Recently deleted (for undo)
class RecentlyDeletedNotifier extends Notifier<Task?> {
  @override
  Task? build() => null;
  void setDeleted(Task? task) => state = task;
}
final recentlyDeletedProvider = NotifierProvider<RecentlyDeletedNotifier, Task?>(RecentlyDeletedNotifier.new);

// Derived filtered and sorted list
final filteredTasksProvider = Provider<AsyncValue<List<Task>>>((ref) {
  final tasksAsync = ref.watch(tasksStreamProvider);
  final filter = ref.watch(todoFilterProvider);
  final priority = ref.watch(priorityFilterProvider);
  final category = ref.watch(categoryFilterProvider);
  final query = ref.watch(searchQueryProvider);
  final sort = ref.watch(taskSortProvider);

  return tasksAsync.whenData((tasks) {
    var result = _applyStatusFilter(tasks, filter);
    
    if (priority != null) {
      result = result.where((t) => t.priority == priority).toList();
    }
    
    if (category != null) {
      result = result.where((t) => t.categoryId == category).toList();
    }
    
    if (query.isNotEmpty) {
      result = result.where((t) =>
        t.title.toLowerCase().contains(query.toLowerCase()) ||
        (t.notes?.toLowerCase().contains(query.toLowerCase()) ?? false)
      ).toList();
    }
    
    return _applySort(result, sort);
  });
});

// Completion counter — derived, not stored
final todayCompletionProvider = Provider<String>((ref) {
  final tasksAsync = ref.watch(tasksStreamProvider);
  return tasksAsync.maybeWhen(
    data: (tasks) {
      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day);
      final todayEnd = todayStart.add(const Duration(days: 1));
      
      final todayTasks = tasks.where((t) {
        if (t.dueDate == null) return true;
        return t.dueDate!.isAfter(todayStart.subtract(const Duration(seconds: 1))) && 
               t.dueDate!.isBefore(todayEnd);
      }).toList();
      
      final done = todayTasks.where((t) => t.isCompleted).length;
      return '$done/${todayTasks.length} done today';
    },
    orElse: () => '0/0 done today',
  );
});

bool _isSameDay(DateTime date1, DateTime date2) {
  return date1.year == date2.year && date1.month == date2.month && date1.day == date2.day;
}

List<Task> _applyStatusFilter(List<Task> tasks, TodoFilter filter) {
  final now = DateTime.now();
  switch (filter) {
    case TodoFilter.all:
      return tasks;
    case TodoFilter.today:
      return tasks.where((t) => !t.isCompleted && (t.dueDate == null || _isSameDay(t.dueDate!, now))).toList();
    case TodoFilter.upcoming:
      return tasks.where((t) => !t.isCompleted && t.dueDate != null && t.dueDate!.isAfter(now) && !_isSameDay(t.dueDate!, now)).toList();
    case TodoFilter.completed:
      return tasks.where((t) => t.isCompleted).toList();
    case TodoFilter.overdue:
      return tasks.where((t) => !t.isCompleted && t.dueDate != null && t.dueDate!.isBefore(now) && !_isSameDay(t.dueDate!, now)).toList();
  }
}

List<Task> _applySort(List<Task> tasks, TaskSort sort) {
  final list = List<Task>.from(tasks);
  switch (sort) {
    case TaskSort.none:
      list.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
      break;
    case TaskSort.dueDate:
      list.sort((a, b) {
        if (a.dueDate == null && b.dueDate == null) return 0;
        if (a.dueDate == null) return 1;
        if (b.dueDate == null) return -1;
        return a.dueDate!.compareTo(b.dueDate!);
      });
      break;
    case TaskSort.priority:
      // High to low
      list.sort((a, b) => b.priority.index.compareTo(a.priority.index));
      break;
    case TaskSort.createdAt:
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      break;
    case TaskSort.alphabetical:
      list.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
      break;
  }
  return list;
}

final todoActionsProvider = Provider<TodoActions>((ref) {
  return TodoActions(ref);
});

class TodoActions {
  final Ref ref;
  TodoActions(this.ref);

  Future<void> addTask(String title, String? notes, DateTime? dueDate, DateTime? dueTime, TaskPriority priority, String? categoryId) async {
    final db = ref.read(databaseProvider);
    // Find max sortOrder
    final maxSort = await (db.selectOnly(db.tasks)..addColumns([db.tasks.sortOrder.max()])).map((row) => row.read(db.tasks.sortOrder.max())).getSingle();
    final newSort = (maxSort ?? 0) + 1;
    
    await db.into(db.tasks).insert(TasksCompanion.insert(
          title: title,
          notes: drift.Value(notes),
          dueDate: drift.Value(dueDate),
          dueTime: drift.Value(dueTime),
          priority: drift.Value(priority),
          categoryId: drift.Value(categoryId),
          sortOrder: drift.Value(newSort),
        ));
  }

  Future<void> updateTask(Task task, {
    String? title, 
    drift.Value<String?> notes = const drift.Value.absent(), 
    drift.Value<DateTime?> dueDate = const drift.Value.absent(), 
    drift.Value<DateTime?> dueTime = const drift.Value.absent(), 
    TaskPriority? priority, 
    drift.Value<String?> categoryId = const drift.Value.absent()
  }) async {
    final db = ref.read(databaseProvider);
    await (db.update(db.tasks)..where((t) => t.id.equals(task.id))).write(
      TasksCompanion(
        title: title != null ? drift.Value(title) : const drift.Value.absent(),
        notes: notes,
        dueDate: dueDate,
        dueTime: dueTime,
        priority: priority != null ? drift.Value(priority) : const drift.Value.absent(),
        categoryId: categoryId,
      )
    );
  }

  Future<void> toggleTaskCompletion(Task task) async {
    final db = ref.read(databaseProvider);
    await (db.update(db.tasks)..where((t) => t.id.equals(task.id)))
        .write(TasksCompanion(
          isCompleted: drift.Value(!task.isCompleted),
          completedAt: drift.Value(!task.isCompleted ? DateTime.now() : null),
        ));
  }

  Future<void> softDeleteTask(Task task) async {
    final db = ref.read(databaseProvider);
    await (db.update(db.tasks)..where((t) => t.id.equals(task.id)))
        .write(const TasksCompanion(isDeleted: drift.Value(true)));
  }
  
  Future<void> restoreTask(Task task) async {
    final db = ref.read(databaseProvider);
    await (db.update(db.tasks)..where((t) => t.id.equals(task.id)))
        .write(const TasksCompanion(isDeleted: drift.Value(false)));
  }

  Future<void> hardDeleteTask(Task task) async {
    final db = ref.read(databaseProvider);
    await (db.delete(db.tasks)..where((t) => t.id.equals(task.id))).go();
  }

  Future<void> reorderTasks(List<Task> tasks, int oldIndex, int newIndex) async {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final item = tasks.removeAt(oldIndex);
    tasks.insert(newIndex, item);
    
    final db = ref.read(databaseProvider);
    await db.transaction(() async {
      for (int i = 0; i < tasks.length; i++) {
        await (db.update(db.tasks)..where((t) => t.id.equals(tasks[i].id)))
            .write(TasksCompanion(sortOrder: drift.Value(i)));
      }
    });
  }
}
