import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../theme/app_theme.dart';
import '../../data/database.dart';
import 'todo_viewmodel.dart';

class TodoScreen extends ConsumerWidget {
  const TodoScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(todoFilterStateProvider);
    final tasksAsync = ref.watch(todoListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Todo', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 28)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Consumer(
              builder: (context, ref, child) {
                // In a real app we'd query today's completion specifically for the top bar
                return const Text("3/7 done today", style: TextStyle(fontWeight: FontWeight.bold));
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
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: tasks.length,
                  itemBuilder: (context, index) {
                    final task = tasks[index];
                    return _buildTaskCard(context, ref, task);
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator(color: AppColors.ink)),
              error: (err, stack) => Center(child: Text('Error: $err')),
            ),
          ),
        ],
      ),
      floatingActionButton: SizedBox(
        width: 160,
        height: 50,
        child: BrutalistButton(
          onPressed: () => _showAddTaskSheet(context, ref),
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
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: TodoFilter.values.map((filter) {
          final isSelected = filter == currentFilter;
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: GestureDetector(
              onTap: () => ref.read(todoFilterStateProvider.notifier).setFilter(filter),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.todoAccent : Theme.of(context).scaffoldBackgroundColor,
                  border: Border.all(color: AppColors.ink, width: 2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  filter.name.toUpperCase(),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isSelected ? AppColors.ink : Colors.black87,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTaskCard(BuildContext context, WidgetRef ref, Task task) {
    return BrutalistContainer(
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
                color: task.isCompleted ? AppColors.todoAccent : Theme.of(context).scaffoldBackgroundColor,
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
                if (task.category != null || task.priority > 0)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Wrap(
                      spacing: 8,
                      children: [
                        if (task.priority > 0)
                          _buildTag(task.priority == 3 ? 'High' : task.priority == 2 ? 'Medium' : 'Low', AppColors.error.withValues(alpha: task.priority == 3 ? 1 : 0.5)),
                        if (task.category != null)
                          _buildTag(task.category!, AppColors.expenseAccent),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 20),
            onPressed: () => ref.read(todoActionsProvider).deleteTask(task),
          ),
        ],
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

  void _showAddTaskSheet(BuildContext context, WidgetRef ref) {
    final titleController = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          margin: const EdgeInsets.all(16).copyWith(bottom: MediaQuery.of(context).viewInsets.bottom + 16),
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            border: Border.all(color: AppColors.ink, width: 3),
            boxShadow: const [BoxShadow(color: AppColors.ink, offset: Offset(4, 4))],
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('NEW TASK', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
              const SizedBox(height: 16),
              TextField(
                controller: titleController,
                decoration: InputDecoration(
                  hintText: 'What needs to be done?',
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
              const SizedBox(height: 24),
              BrutalistButton(
                onPressed: () {
                  if (titleController.text.isNotEmpty) {
                    ref.read(todoActionsProvider).addTask(titleController.text, null, null, 0, null);
                    Navigator.pop(ctx);
                  }
                },
                child: const Text('SAVE TASK'),
              ),
            ],
          ),
        );
      },
    );
  }
}
