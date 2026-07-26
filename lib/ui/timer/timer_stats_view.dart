import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_theme.dart';
import '../../providers/database_provider.dart';

final statsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final db = ref.watch(databaseProvider);
  final now = DateTime.now();
  final todayStart = DateTime(now.year, now.month, now.day);
  final weekStart = todayStart.subtract(Duration(days: now.weekday - 1));

  final sessions = await db.select(db.focusSessions).get();

  int todayMinutes = 0;
  int weekMinutes = 0;
  int totalSessions = sessions.length;
  Set<String> activeDays = {};

  for (var session in sessions) {
    if (session.startedAt.isAfter(todayStart)) {
      todayMinutes += session.durationSeconds ~/ 60;
    }
    if (session.startedAt.isAfter(weekStart)) {
      weekMinutes += session.durationSeconds ~/ 60;
    }
    activeDays.add('${session.startedAt.year}-${session.startedAt.month}-${session.startedAt.day}');
  }

  // Simple streak calc: start from today, go backwards
  int streak = 0;
  DateTime checkDay = todayStart;
  while (true) {
    String key = '${checkDay.year}-${checkDay.month}-${checkDay.day}';
    if (activeDays.contains(key)) {
      streak++;
      checkDay = checkDay.subtract(const Duration(days: 1));
    } else {
      // if today is empty, check yesterday before breaking streak completely
      if (streak == 0) {
        checkDay = checkDay.subtract(const Duration(days: 1));
        String yKey = '${checkDay.year}-${checkDay.month}-${checkDay.day}';
        if (activeDays.contains(yKey)) {
          streak++;
          checkDay = checkDay.subtract(const Duration(days: 1));
          continue;
        }
      }
      break;
    }
  }

  return {
    'todayMinutes': todayMinutes,
    'weekMinutes': weekMinutes,
    'totalSessions': totalSessions,
    'streak': streak,
  };
});

class TimerStatsView extends ConsumerWidget {
  const TimerStatsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(statsProvider);

    return statsAsync.when(
      data: (stats) {
        return Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: BrutalistContainer(
                    color: Colors.white,
                    child: Column(
                      children: [
                        const Text('TODAY (MIN)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.black54)),
                        const SizedBox(height: 8),
                        Text('${stats['todayMinutes']}', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: AppColors.ink)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: BrutalistContainer(
                    color: Colors.white,
                    child: Column(
                      children: [
                        const Text('STREAK (DAYS)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.black54)),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.local_fire_department, color: AppColors.timerAccent, size: 24),
                            const SizedBox(width: 4),
                            Text('${stats['streak']}', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: AppColors.ink)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            BrutalistContainer(
              color: Colors.white,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(
                    children: [
                      const Text('WEEK', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.black54)),
                      Text('${stats['weekMinutes']}m', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20)),
                    ],
                  ),
                  Column(
                    children: [
                      const Text('SESSIONS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.black54)),
                      Text('${stats['totalSessions']}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator(color: AppColors.ink)),
      error: (err, stack) => Center(child: Text('Error: $err')),
    );
  }
}
