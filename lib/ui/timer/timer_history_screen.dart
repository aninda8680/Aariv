import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/database.dart';
import '../../providers/database_provider.dart';
import '../../theme/app_theme.dart';
import 'package:intl/intl.dart';
import 'package:drift/drift.dart' as drift;

final focusSessionsProvider = StreamProvider<List<FocusSession>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.select(db.focusSessions).watch();
});

class TimerHistoryScreen extends ConsumerWidget {
  const TimerHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionsAsync = ref.watch(focusSessionsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Session History', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 24)),
      ),
      body: sessionsAsync.when(
        data: (sessions) {
          if (sessions.isEmpty) {
            return const Center(
              child: Text('No focus sessions yet.', style: TextStyle(fontSize: 16, color: Colors.black54, fontWeight: FontWeight.bold)),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: sessions.length,
            itemBuilder: (context, index) {
              final session = sessions[index];
              return _buildSessionTile(context, ref, session);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.ink)),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }

  Widget _buildSessionTile(BuildContext context, WidgetRef ref, FocusSession session) {
    final minutes = session.durationSeconds ~/ 60;
    final dateStr = DateFormat('MMM dd, yyyy - HH:mm').format(session.startedAt);

    return BrutalistContainer(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                session.mode.toUpperCase(),
                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
              ),
              Text(
                '$minutes min',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.timerAccent),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(dateStr, style: const TextStyle(color: Colors.black54, fontSize: 12, fontWeight: FontWeight.bold)),
          if (session.notes != null && session.notes!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(session.notes!, style: const TextStyle(fontSize: 14)),
          ],
          if (session.tags != null && session.tags!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              children: session.tags!.split(',').map((tag) => Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.timerAccent.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: AppColors.ink),
                  ),
                  child: Text(tag.trim(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                ),
              )).toList(),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              IconButton(
                icon: const Icon(Icons.edit, size: 20),
                onPressed: () => _showEditSheet(context, ref, session),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 16),
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 20, color: AppColors.error),
                onPressed: () {
                  ref.read(databaseProvider).delete(ref.read(databaseProvider).focusSessions).delete(session);
                },
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          )
        ],
      ),
    );
  }

  void _showEditSheet(BuildContext context, WidgetRef ref, FocusSession session) {
    final notesController = TextEditingController(text: session.notes);
    final tagsController = TextEditingController(text: session.tags);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          margin: const EdgeInsets.all(16).copyWith(bottom: MediaQuery.of(context).viewInsets.bottom + 16),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            border: Border.all(color: AppColors.ink, width: 3),
            boxShadow: const [BoxShadow(color: AppColors.ink, offset: Offset(4, 4))],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('EDIT SESSION', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
              const SizedBox(height: 16),
              TextField(
                controller: notesController,
                decoration: const InputDecoration(
                  labelText: 'Notes',
                  border: OutlineInputBorder(borderSide: BorderSide(color: AppColors.ink, width: 2)),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: tagsController,
                decoration: const InputDecoration(
                  labelText: 'Tags (comma separated)',
                  border: OutlineInputBorder(borderSide: BorderSide(color: AppColors.ink, width: 2)),
                ),
              ),
              const SizedBox(height: 24),
              BrutalistButton(
                color: AppColors.timerAccent,
                onPressed: () {
                  final db = ref.read(databaseProvider);
                  db.update(db.focusSessions).replace(session.copyWith(
                    notes: drift.Value(notesController.text.isNotEmpty ? notesController.text : null),
                    tags: drift.Value(tagsController.text.isNotEmpty ? tagsController.text : null),
                  ));
                  Navigator.pop(ctx);
                },
                child: const Text('SAVE'),
              ),
            ],
          ),
        );
      },
    );
  }
}
