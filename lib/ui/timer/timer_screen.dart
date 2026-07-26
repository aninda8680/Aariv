import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:math';

import '../../theme/app_theme.dart';
import 'timer_viewmodel.dart';
import '../todo/todo_viewmodel.dart';
import '../../data/database.dart';
import 'timer_history_screen.dart';
import 'timer_stats_view.dart';

class TimerScreen extends ConsumerWidget {
  const TimerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(timerModeStateProvider);
    final timerState = ref.watch(timerControllerProvider);
    final activeTask = ref.watch(activeTaskSelectionProvider);
    final tasksAsync = ref.watch(tasksStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Timer', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 28)),
        actions: [
          IconButton(
            icon: const Icon(Icons.history, color: AppColors.ink, size: 28),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const TimerHistoryScreen()));
            },
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildModeToggle(context, ref, mode),
          Expanded(
            child: Center(
              child: mode == TimerMode.stopwatch
                  ? _buildDigitalDisplay(timerState)
                  : _buildRingProgress(context, timerState, mode),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: BrutalistContainer(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      activeTask?.title ?? 'No Task (Free Focus)',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: const Icon(Icons.menu, color: AppColors.ink),
                    onPressed: () => _showFieldsBottomSheet(context, ref, activeTask, tasksAsync),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          _buildControls(context, ref, timerState),
          const SizedBox(height: 48),
        ],
      ),
    );
  }

  void _showFieldsBottomSheet(BuildContext context, WidgetRef ref, Task? activeTask, AsyncValue<List<Task>> tasksAsync) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            border: const Border(
              top: BorderSide(color: AppColors.ink, width: 4),
              left: BorderSide(color: AppColors.ink, width: 4),
              right: BorderSide(color: AppColors.ink, width: 4),
            ),
          ),
          padding: const EdgeInsets.all(24.0).copyWith(bottom: MediaQuery.of(context).viewInsets.bottom + 24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Task Selection', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20)),
              const SizedBox(height: 16),
              BrutalistContainer(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<Task>(
                    isExpanded: true,
                    hint: const Text('Link to a task...', style: TextStyle(fontWeight: FontWeight.bold)),
                    value: activeTask,
                    icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.ink),
                    items: tasksAsync.when(
                      data: (tasks) {
                        return tasks.map((task) {
                          return DropdownMenuItem<Task>(
                            value: task,
                            child: Text(task.title, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold)),
                          );
                        }).toList()
                          ..insert(0, const DropdownMenuItem<Task>(
                            value: null,
                            child: Text('No Task (Free Focus)', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black54)),
                          ));
                      },
                      loading: () => [],
                      error: (err, stack) => [],
                    ),
                    onChanged: (Task? selected) {
                      ref.read(activeTaskSelectionProvider.notifier).setTask(selected);
                      Navigator.pop(context);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text('Stats', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20)),
              const SizedBox(height: 16),
              const TimerStatsView(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildModeToggle(BuildContext context, WidgetRef ref, TimerMode currentMode) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: BrutalistContainer(
        padding: EdgeInsets.zero,
        child: IntrinsicHeight(
          child: Row(
            children: [
              for (int i = 0; i < TimerMode.values.length; i++) ...[
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      final mode = TimerMode.values[i];
                      ref.read(timerModeStateProvider.notifier).setMode(mode);
                      ref.read(timerControllerProvider.notifier).resetWith(mode == TimerMode.stopwatch ? 0 : 25 * 60);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: TimerMode.values[i] == currentMode ? AppColors.timerAccent : Colors.transparent,
                      ),
                      child: Center(
                        child: Text(
                          TimerMode.values[i].name.toUpperCase(),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12, // slightly smaller to prevent clipping
                            color: TimerMode.values[i] == currentMode ? AppColors.ink : Colors.black54,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                if (i < TimerMode.values.length - 1)
                  Container(width: 1.5, color: AppColors.ink),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRingProgress(BuildContext context, TimerState state, TimerMode mode) {
    final minutes = state.remainingSeconds ~/ 60;
    final seconds = state.remainingSeconds % 60;
    final timeStr = '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';

    return Stack(
      alignment: Alignment.center,
      children: [
        SizedBox(
          width: 250,
          height: 250,
          child: CustomPaint(
            painter: BrutalistRingPainter(
              progress: state.progress,
              color: AppColors.timerAccent,
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              borderColor: AppColors.ink,
              strokeWidth: 24,
            ),
          ),
        ),
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (mode == TimerMode.pomodoro) ...[
              Text(
                state.pomodoroPhase == PomodoroPhase.work 
                    ? 'WORK' 
                    : (state.pomodoroPhase == PomodoroPhase.shortBreak ? 'SHORT BREAK' : 'LONG BREAK'),
                style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 2),
              ),
              if (state.pomodoroPhase == PomodoroPhase.work)
                Text('${(state.cycleCount % 4) + 1}/4', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black54)),
            ],
            Text(
              timeStr,
              style: const TextStyle(
                fontSize: 56,
                fontWeight: FontWeight.w900,
                color: AppColors.ink,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDigitalDisplay(TimerState state) {
    final hours = state.remainingSeconds ~/ 3600;
    final minutes = (state.remainingSeconds % 3600) ~/ 60;
    final seconds = state.remainingSeconds % 60;
    
    String timeStr = '';
    if (hours > 0) timeStr += '${hours.toString().padLeft(2, '0')}:';
    timeStr += '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';

    return BrutalistContainer(
      padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 32),
      child: Text(
        timeStr,
        style: const TextStyle(
          fontSize: 64,
          fontWeight: FontWeight.w900,
          letterSpacing: 4,
          color: AppColors.ink,
        ),
      ),
    );
  }

  Widget _buildControls(BuildContext context, WidgetRef ref, TimerState state) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: BrutalistButton(
              color: state.isRunning ? AppColors.todoAccent : AppColors.timerAccent,
              onPressed: () {
                if (state.isRunning) {
                  ref.read(timerControllerProvider.notifier).pause();
                } else {
                  ref.read(timerControllerProvider.notifier).start();
                }
              },
              child: Text(state.isRunning ? 'PAUSE' : 'START', style: const TextStyle(fontSize: 20)),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 1,
            child: BrutalistButton(
              color: Theme.of(context).scaffoldBackgroundColor,
              onPressed: () => ref.read(timerControllerProvider.notifier).stop(),
              child: const Icon(Icons.stop, color: AppColors.ink),
            ),
          ),
        ],
      ),
    );
  }
}

class BrutalistRingPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color backgroundColor;
  final Color borderColor;
  final double strokeWidth;

  BrutalistRingPainter({
    required this.progress,
    required this.color,
    required this.backgroundColor,
    required this.borderColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Background ring
    final bgPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawCircle(center, radius, bgPaint);

    // Progress arc
    final progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt;
    
    final sweepAngle = 2 * pi * progress;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant BrutalistRingPainter oldDelegate) {
    return oldDelegate.progress != progress ||
           oldDelegate.color != color ||
           oldDelegate.backgroundColor != backgroundColor;
  }
}
