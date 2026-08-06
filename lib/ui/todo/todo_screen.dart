import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' as drift;

import '../../theme/app_theme.dart';
import '../../data/database.dart';
import 'todo_viewmodel.dart';

class TodoScreen extends ConsumerWidget {
  const TodoScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(todoFilterProvider);
    final tasksAsync = ref.watch(filteredTasksProvider);
    final sort = ref.watch(taskSortProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Todo', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 28)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Consumer(
              builder: (context, ref, child) {
                final completion = ref.watch(todayCompletionProvider);
                return Center(child: Text(completion, style: const TextStyle(fontWeight: FontWeight.bold)));
              },
            ),
          )
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildFilterChips(context, ref, filter),
          Expanded(
            child: tasksAsync.when(
              data: (tasks) {
                if (tasks.isEmpty) {
                  return const Center(
                    child: Text('No tasks here.\nTime to chill or add something.', 
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 16, color: Colors.black54, fontWeight: FontWeight.w600)),
                  );
                }
                
                if (sort == TaskSort.none) {
                  return ReorderableListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: tasks.length,
                    onReorderItem: (oldIndex, newIndex) {
                      ref.read(todoActionsProvider).reorderTasks(List.from(tasks), oldIndex, newIndex);
                    },
                    itemBuilder: (context, index) {
                      final task = tasks[index];
                      return _buildTaskCard(context, ref, task, key: ValueKey(task.id));
                    },
                  );
                } else {
                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: tasks.length,
                    itemBuilder: (context, index) {
                      final task = tasks[index];
                      return _buildTaskCard(context, ref, task, key: ValueKey(task.id));
                    },
                  );
                }
              },
              loading: () => const Center(child: CircularProgressIndicator(color: AppColors.ink)),
              error: (err, stack) => Center(child: Text('Error: $err')),
            ),
          ),
        ],
      ),
      floatingActionButton: SizedBox(
        width: 180,
        height: 50,
        child: BrutalistButton(
          onPressed: () => _showAddEditTaskSheet(context, ref),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.add, color: AppColors.ink),
              SizedBox(width: 8),
              Text('ADD TASK'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChips(BuildContext context, WidgetRef ref, TodoFilter currentFilter) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? Colors.white : AppColors.ink;
    
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: TodoFilter.values.map((filter) {
          final isSelected = filter == currentFilter;
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: GestureDetector(
              onTap: () => ref.read(todoFilterProvider.notifier).setFilter(filter),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.todoAccent : Theme.of(context).scaffoldBackgroundColor,
                  border: Border.all(color: borderColor, width: 2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  filter.name.toUpperCase(),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isSelected ? AppColors.ink : (isDark ? Colors.white70 : Colors.black87),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTaskCard(BuildContext context, WidgetRef ref, Task task, {required Key key}) {
    return Dismissible(
      key: key,
      background: Container(
        color: AppColors.todoAccent,
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 16),
        child: const Icon(Icons.check, color: AppColors.ink),
      ),
      secondaryBackground: Container(
        color: AppColors.error,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        child: const Icon(Icons.delete, color: AppColors.ink),
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          ref.read(todoActionsProvider).toggleTaskCompletion(task);
          return false; // Let the state update trigger the removal from the 'todo' list
        } else {
          ref.read(recentlyDeletedProvider.notifier).setDeleted(task);
          ref.read(todoActionsProvider).softDeleteTask(task);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Task deleted'),
              action: SnackBarAction(
                label: 'UNDO',
                onPressed: () {
                  final deleted = ref.read(recentlyDeletedProvider);
                  if (deleted != null) {
                    ref.read(todoActionsProvider).restoreTask(deleted);
                  }
                },
              ),
              duration: const Duration(seconds: 4),
            ),
          );
          return true;
        }
      },
      child: GestureDetector(
        onTap: () => _showAddEditTaskSheet(context, ref, task: task),
        child: BrutalistContainer(
          margin: const EdgeInsets.only(bottom: 16),
          color: task.isCompleted ? null : Colors.white,
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () => ref.read(todoActionsProvider).toggleTaskCompletion(task),
                child: Container(
                  margin: const EdgeInsets.only(right: 12, top: 2),
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: task.isCompleted ? AppColors.todoAccent : Colors.transparent,
                    border: Border.all(color: AppColors.ink, width: 2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: task.isCompleted
                      ? const Icon(Icons.check, size: 16, color: AppColors.ink)
                      : null,
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    if (task.categoryId != null || task.priority.index > 0)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Wrap(
                          spacing: 8,
                          children: [
                            if (task.priority.index > 0)
                              _buildTag(task.priority.name, AppColors.error.withValues(alpha: task.priority == TaskPriority.high ? 1.0 : 0.5)),
                            if (task.categoryId != null)
                              _buildTag(task.categoryId!, AppColors.expenseAccent),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              const Icon(Icons.drag_indicator, color: Colors.black26),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color,
        border: Border.all(color: AppColors.ink, width: 1.5),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }

  void _showAddEditTaskSheet(BuildContext context, WidgetRef ref, {Task? task}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AddEditTaskSheet(task: task),
    );
  }
}

class AddEditTaskSheet extends ConsumerStatefulWidget {
  final Task? task;
  const AddEditTaskSheet({super.key, this.task});

  @override
  ConsumerState<AddEditTaskSheet> createState() => _AddEditTaskSheetState();
}

class _AddEditTaskSheetState extends ConsumerState<AddEditTaskSheet> {
  late TextEditingController titleController;
  late TextEditingController notesController;
  TaskPriority priority = TaskPriority.none;
  String? categoryId;

  @override
  void initState() {
    super.initState();
    titleController = TextEditingController(text: widget.task?.title ?? '');
    notesController = TextEditingController(text: widget.task?.notes ?? '');
    priority = widget.task?.priority ?? TaskPriority.none;
    categoryId = widget.task?.categoryId;
  }

  @override
  void dispose() {
    titleController.dispose();
    notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.task != null;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return BrutalistContainer(
      margin: const EdgeInsets.all(16).copyWith(bottom: MediaQuery.of(context).viewInsets.bottom + 16),
      color: isDark ? AppColors.background : Theme.of(context).scaffoldBackgroundColor,
      padding: const EdgeInsets.all(24),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(isEdit ? 'EDIT TASK' : 'NEW TASK', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
            const SizedBox(height: 16),
            TextField(
              controller: titleController,
              style: const TextStyle(color: AppColors.ink),
              decoration: InputDecoration(
                hintText: 'What needs to be done?',
                hintStyle: const TextStyle(color: Colors.black54),
                border: OutlineInputBorder(
                  borderSide: const BorderSide(color: AppColors.ink, width: 2),
                  borderRadius: BorderRadius.circular(0),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: AppColors.ink, width: 2.5),
                  borderRadius: BorderRadius.circular(0),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: notesController,
              maxLines: 3,
              style: const TextStyle(color: AppColors.ink),
              decoration: InputDecoration(
                hintText: 'Notes (optional)',
                hintStyle: const TextStyle(color: Colors.black54),
                border: OutlineInputBorder(
                  borderSide: const BorderSide(color: AppColors.ink, width: 2),
                  borderRadius: BorderRadius.circular(0),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: AppColors.ink, width: 2.5),
                  borderRadius: BorderRadius.circular(0),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Priority Dropdown
            DropdownButtonFormField<TaskPriority>(
              initialValue: priority,
              style: const TextStyle(color: AppColors.ink),
              dropdownColor: AppColors.background,
              decoration: const InputDecoration(
                labelText: 'Priority',
                labelStyle: TextStyle(color: AppColors.ink),
                border: OutlineInputBorder(borderSide: BorderSide(color: AppColors.ink, width: 2)),
              ),
              items: TaskPriority.values.map((p) => DropdownMenuItem(value: p, child: Text(p.name.toUpperCase()))).toList(),
              onChanged: (v) {
                if (v != null) setState(() => priority = v);
              },
            ),
            const SizedBox(height: 24),
            BrutalistButton(
              onPressed: () {
                if (titleController.text.isNotEmpty) {
                  if (isEdit) {
                    ref.read(todoActionsProvider).updateTask(
                      widget.task!,
                      title: titleController.text,
                      notes: notesController.text.isEmpty ? const drift.Value.absent() : drift.Value(notesController.text),
                      priority: priority,
                      categoryId: categoryId != null ? drift.Value(categoryId) : const drift.Value.absent(),
                    );
                  } else {
                    ref.read(todoActionsProvider).addTask(
                      titleController.text,
                      notesController.text.isEmpty ? null : notesController.text,
                      null, // dueDate
                      null, // dueTime
                      priority,
                      categoryId,
                    );
                  }
                  Navigator.pop(context);
                }
              },
              child: Text(isEdit ? 'SAVE CHANGES' : 'SAVE TASK'),
            ),
          ],
        ),
      ),
    );
  }
}
