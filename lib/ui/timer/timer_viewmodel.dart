import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/database.dart';
import '../../providers/database_provider.dart';
import 'package:drift/drift.dart' as drift;

enum TimerMode { pomodoro, stopwatch, countdown }

final timerModeStateProvider = NotifierProvider<TimerModeState, TimerMode>(TimerModeState.new);

class TimerModeState extends Notifier<TimerMode> {
  @override
  TimerMode build() => TimerMode.pomodoro;

  void setMode(TimerMode mode) => state = mode;
}

final activeTaskSelectionProvider = NotifierProvider<ActiveTaskSelection, Task?>(ActiveTaskSelection.new);

class ActiveTaskSelection extends Notifier<Task?> {
  @override
  Task? build() => null;

  void setTask(Task? task) => state = task;
}

class TimerState {
  final int remainingSeconds;
  final bool isRunning;
  final int initialSeconds;

  TimerState({
    required this.remainingSeconds,
    required this.isRunning,
    required this.initialSeconds,
  });

  TimerState copyWith({
    int? remainingSeconds,
    bool? isRunning,
    int? initialSeconds,
  }) {
    return TimerState(
      remainingSeconds: remainingSeconds ?? this.remainingSeconds,
      isRunning: isRunning ?? this.isRunning,
      initialSeconds: initialSeconds ?? this.initialSeconds,
    );
  }
  
  double get progress => initialSeconds > 0 ? (initialSeconds - remainingSeconds) / initialSeconds : 0.0;
}

final timerControllerProvider = NotifierProvider<TimerController, TimerState>(TimerController.new);

class TimerController extends Notifier<TimerState> {
  Timer? _timer;
  DateTime? _startedAt;

  @override
  TimerState build() {
    ref.onDispose(() {
      _timer?.cancel();
    });
    return TimerState(remainingSeconds: 25 * 60, isRunning: false, initialSeconds: 25 * 60);
  }

  void start() {
    if (state.isRunning) return;
    _startedAt ??= DateTime.now();
    state = state.copyWith(isRunning: true);
    
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final mode = ref.read(timerModeStateProvider);
      
      if (mode == TimerMode.pomodoro || mode == TimerMode.countdown) {
        if (state.remainingSeconds > 0) {
          state = state.copyWith(remainingSeconds: state.remainingSeconds - 1);
        } else {
          stop();
          _recordSession();
        }
      } else if (mode == TimerMode.stopwatch) {
        state = state.copyWith(remainingSeconds: state.remainingSeconds + 1);
      }
    });
  }

  void pause() {
    _timer?.cancel();
    state = state.copyWith(isRunning: false);
  }

  void stop() {
    _timer?.cancel();
    if (state.isRunning || state.remainingSeconds != state.initialSeconds) {
       _recordSession();
    }
    
    final mode = ref.read(timerModeStateProvider);
    final initial = mode == TimerMode.stopwatch ? 0 : 25 * 60; // default 25 for pomodoro
    state = TimerState(remainingSeconds: initial, isRunning: false, initialSeconds: initial);
    _startedAt = null;
  }

  Future<void> _recordSession() async {
    if (_startedAt == null) return;
    final db = ref.read(databaseProvider);
    final activeTask = ref.read(activeTaskSelectionProvider);
    final mode = ref.read(timerModeStateProvider);
    
    int duration = mode == TimerMode.stopwatch 
        ? state.remainingSeconds 
        : (state.initialSeconds - state.remainingSeconds);
        
    if (duration > 10) {
      await db.into(db.focusSessions).insert(FocusSessionsCompanion.insert(
        taskId: drift.Value(activeTask?.id),
        durationSeconds: duration,
        mode: mode.name,
        startedAt: _startedAt!,
        completedAt: drift.Value(DateTime.now()),
      ));
    }
  }

  void resetWith(int seconds) {
    _timer?.cancel();
    _startedAt = null;
    state = TimerState(remainingSeconds: seconds, isRunning: false, initialSeconds: seconds);
  }
}
