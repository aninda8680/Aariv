import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/database.dart';
import '../../providers/database_provider.dart';
import 'package:drift/drift.dart' as drift;
import '../../services/notification_service.dart';
import 'timer_settings_viewmodel.dart';

enum TimerMode { pomodoro, stopwatch, countdown }
enum PomodoroPhase { work, shortBreak, longBreak }

final timerModeStateProvider = NotifierProvider<TimerModeState, TimerMode>(TimerModeState.new);

class TimerModeState extends Notifier<TimerMode> {
  @override
  TimerMode build() => TimerMode.pomodoro;

  void setMode(TimerMode mode) {
    if (state != mode) {
      state = mode;
      ref.read(timerControllerProvider.notifier).resetToDefault();
    }
  }
}

final activeTaskSelectionProvider = NotifierProvider<ActiveTaskSelection, Task?>(ActiveTaskSelection.new);

class ActiveTaskSelection extends Notifier<Task?> {
  @override
  Task? build() => null;

  void setTask(Task? task) => state = task;
}

class TimerState {
  final bool isRunning;
  final int initialSeconds;
  final PomodoroPhase pomodoroPhase;
  final int cycleCount;

  final DateTime? startedAt;
  final int pausedSeconds;
  final int remainingSeconds; // visually displayed remaining time

  TimerState({
    required this.isRunning,
    required this.initialSeconds,
    required this.pomodoroPhase,
    required this.cycleCount,
    this.startedAt,
    this.pausedSeconds = 0,
    required this.remainingSeconds,
  });

  TimerState copyWith({
    bool? isRunning,
    int? initialSeconds,
    PomodoroPhase? pomodoroPhase,
    int? cycleCount,
    DateTime? startedAt,
    bool clearStartedAt = false,
    int? pausedSeconds,
    int? remainingSeconds,
  }) {
    return TimerState(
      isRunning: isRunning ?? this.isRunning,
      initialSeconds: initialSeconds ?? this.initialSeconds,
      pomodoroPhase: pomodoroPhase ?? this.pomodoroPhase,
      cycleCount: cycleCount ?? this.cycleCount,
      startedAt: clearStartedAt ? null : (startedAt ?? this.startedAt),
      pausedSeconds: pausedSeconds ?? this.pausedSeconds,
      remainingSeconds: remainingSeconds ?? this.remainingSeconds,
    );
  }
  
  double get progress => initialSeconds > 0 ? (initialSeconds - remainingSeconds) / initialSeconds : 0.0;
}

final timerControllerProvider = NotifierProvider<TimerController, TimerState>(TimerController.new);

class TimerController extends Notifier<TimerState> {
  Timer? _timer;

  @override
  TimerState build() {
    ref.onDispose(() {
      _timer?.cancel();
    });
    
    // Default initial state
    return TimerState(
      isRunning: false,
      initialSeconds: 25 * 60,
      pomodoroPhase: PomodoroPhase.work,
      cycleCount: 0,
      remainingSeconds: 25 * 60,
      pausedSeconds: 0,
    );
  }

  void resetToDefault() {
    _timer?.cancel();
    final mode = ref.read(timerModeStateProvider);
    final settingsAsync = ref.read(timerSettingsProvider);
    final settings = settingsAsync.value ?? TimerSettings();
    
    int initial = 0;
    if (mode == TimerMode.pomodoro) initial = settings.pomodoroMinutes * 60;
    if (mode == TimerMode.countdown) initial = 25 * 60; // Generic custom default

    state = TimerState(
      isRunning: false,
      initialSeconds: initial,
      pomodoroPhase: PomodoroPhase.work,
      cycleCount: 0,
      remainingSeconds: initial,
      pausedSeconds: 0,
    );
  }

  void start() {
    if (state.isRunning) return;
    
    state = state.copyWith(
      isRunning: true,
      startedAt: DateTime.now(),
    );
    
    _scheduleCompletionNotification();
    
    _timer = Timer.periodic(const Duration(milliseconds: 500), _tick);
  }

  void _tick(Timer timer) {
    if (!state.isRunning || state.startedAt == null) return;
    
    final mode = ref.read(timerModeStateProvider);
    final elapsedSession = DateTime.now().difference(state.startedAt!).inSeconds;
    final totalElapsed = state.pausedSeconds + elapsedSession;

    if (mode == TimerMode.stopwatch) {
      state = state.copyWith(remainingSeconds: totalElapsed);
    } else {
      final remaining = state.initialSeconds - totalElapsed;
      if (remaining <= 0) {
        // Complete phase
        state = state.copyWith(remainingSeconds: 0);
        _handlePhaseCompletion();
      } else {
        state = state.copyWith(remainingSeconds: remaining);
      }
    }
  }

  void _handlePhaseCompletion() {
    _timer?.cancel();
    _recordSession();
    
    final mode = ref.read(timerModeStateProvider);
    if (mode == TimerMode.pomodoro) {
      _advancePomodoroPhase();
    } else {
      state = state.copyWith(isRunning: false, clearStartedAt: true);
    }
  }
  
  void _advancePomodoroPhase() {
    final settings = ref.read(timerSettingsProvider).value ?? TimerSettings();
    
    PomodoroPhase nextPhase;
    int nextInitial;
    int nextCycles = state.cycleCount;

    if (state.pomodoroPhase == PomodoroPhase.work) {
      nextCycles++;
      if (nextCycles % settings.cyclesBeforeLongBreak == 0) {
        nextPhase = PomodoroPhase.longBreak;
        nextInitial = settings.longBreakMinutes * 60;
      } else {
        nextPhase = PomodoroPhase.shortBreak;
        nextInitial = settings.shortBreakMinutes * 60;
      }
    } else {
      nextPhase = PomodoroPhase.work;
      nextInitial = settings.pomodoroMinutes * 60;
    }

    state = TimerState(
      isRunning: false,
      initialSeconds: nextInitial,
      pomodoroPhase: nextPhase,
      cycleCount: nextCycles,
      remainingSeconds: nextInitial,
      pausedSeconds: 0,
    );

    if (settings.autoStartNextPhase) {
      start(); // Optionally add a 5s delay here if we want auto-start countdown
    }
  }

  void pause() {
    if (!state.isRunning || state.startedAt == null) return;
    _timer?.cancel();
    
    final elapsedSession = DateTime.now().difference(state.startedAt!).inSeconds;
    NotificationService().cancelNotification(1); // cancel scheduled alert
    
    state = state.copyWith(
      isRunning: false,
      pausedSeconds: state.pausedSeconds + elapsedSession,
      clearStartedAt: true,
    );
  }

  void stop() {
    _timer?.cancel();
    NotificationService().cancelNotification(1);
    
    if (state.isRunning || state.pausedSeconds > 0) {
       _recordSession();
    }
    resetToDefault();
  }
  
  void resetWith(int seconds) {
    _timer?.cancel();
    NotificationService().cancelNotification(1);
    state = TimerState(
      isRunning: false,
      initialSeconds: seconds,
      pomodoroPhase: state.pomodoroPhase,
      cycleCount: state.cycleCount,
      remainingSeconds: seconds,
      pausedSeconds: 0,
    );
  }

  void _scheduleCompletionNotification() {
    final mode = ref.read(timerModeStateProvider);
    if (mode == TimerMode.stopwatch) return;
    
    final remaining = state.initialSeconds - state.pausedSeconds;
    if (remaining > 0) {
      NotificationService().scheduleTimerCompletionNotification(
        1,
        'Timer Complete!',
        'Your focus session has ended.',
        DateTime.now().add(Duration(seconds: remaining)),
      );
    }
  }

  Future<void> _recordSession() async {
    final mode = ref.read(timerModeStateProvider);
    int totalElapsed = state.pausedSeconds;
    if (state.startedAt != null) {
      totalElapsed += DateTime.now().difference(state.startedAt!).inSeconds;
    }
    
    if (totalElapsed > 10 && (mode == TimerMode.stopwatch || state.pomodoroPhase == PomodoroPhase.work)) {
      final db = ref.read(databaseProvider);
      final activeTask = ref.read(activeTaskSelectionProvider);
      
      await db.into(db.focusSessions).insert(FocusSessionsCompanion.insert(
        taskId: drift.Value(activeTask?.id),
        durationSeconds: totalElapsed,
        mode: mode.name,
        startedAt: state.startedAt ?? DateTime.now().subtract(Duration(seconds: totalElapsed)),
        completedAt: drift.Value(DateTime.now()),
      ));
    }
  }
}
