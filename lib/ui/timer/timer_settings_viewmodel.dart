import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/database.dart';
import '../../providers/database_provider.dart';
import 'package:drift/drift.dart' as drift;

class TimerSettings {
  final int pomodoroMinutes;
  final int shortBreakMinutes;
  final int longBreakMinutes;
  final int cyclesBeforeLongBreak;
  final bool autoStartNextPhase;
  final bool soundEnabled;
  final bool hapticsEnabled;
  final bool allowOvertime;

  TimerSettings({
    this.pomodoroMinutes = 25,
    this.shortBreakMinutes = 5,
    this.longBreakMinutes = 15,
    this.cyclesBeforeLongBreak = 4,
    this.autoStartNextPhase = false,
    this.soundEnabled = true,
    this.hapticsEnabled = true,
    this.allowOvertime = false,
  });

  TimerSettings copyWith({
    int? pomodoroMinutes,
    int? shortBreakMinutes,
    int? longBreakMinutes,
    int? cyclesBeforeLongBreak,
    bool? autoStartNextPhase,
    bool? soundEnabled,
    bool? hapticsEnabled,
    bool? allowOvertime,
  }) {
    return TimerSettings(
      pomodoroMinutes: pomodoroMinutes ?? this.pomodoroMinutes,
      shortBreakMinutes: shortBreakMinutes ?? this.shortBreakMinutes,
      longBreakMinutes: longBreakMinutes ?? this.longBreakMinutes,
      cyclesBeforeLongBreak: cyclesBeforeLongBreak ?? this.cyclesBeforeLongBreak,
      autoStartNextPhase: autoStartNextPhase ?? this.autoStartNextPhase,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      hapticsEnabled: hapticsEnabled ?? this.hapticsEnabled,
      allowOvertime: allowOvertime ?? this.allowOvertime,
    );
  }
}

final timerSettingsProvider = NotifierProvider<TimerSettingsNotifier, AsyncValue<TimerSettings>>(TimerSettingsNotifier.new);

class TimerSettingsNotifier extends Notifier<AsyncValue<TimerSettings>> {
  @override
  AsyncValue<TimerSettings> build() {
    _loadSettings();
    return const AsyncValue.loading();
  }

  Future<void> _loadSettings() async {
    try {
      final db = ref.read(databaseProvider);
      final settingsList = await db.select(db.settings).get();
      final map = {for (var s in settingsList) s.key: s.value};

      final settings = TimerSettings(
        pomodoroMinutes: int.tryParse(map['timer_pomodoroMinutes'] ?? '') ?? 25,
        shortBreakMinutes: int.tryParse(map['timer_shortBreakMinutes'] ?? '') ?? 5,
        longBreakMinutes: int.tryParse(map['timer_longBreakMinutes'] ?? '') ?? 15,
        cyclesBeforeLongBreak: int.tryParse(map['timer_cyclesBeforeLongBreak'] ?? '') ?? 4,
        autoStartNextPhase: (map['timer_autoStartNextPhase'] ?? 'false') == 'true',
        soundEnabled: (map['timer_soundEnabled'] ?? 'true') == 'true',
        hapticsEnabled: (map['timer_hapticsEnabled'] ?? 'true') == 'true',
        allowOvertime: (map['timer_allowOvertime'] ?? 'false') == 'true',
      );

      state = AsyncValue.data(settings);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateSettings(TimerSettings newSettings) async {
    state = AsyncValue.data(newSettings);
    final db = ref.read(databaseProvider);

    await db.transaction(() async {
      await _saveKey(db, 'timer_pomodoroMinutes', newSettings.pomodoroMinutes.toString());
      await _saveKey(db, 'timer_shortBreakMinutes', newSettings.shortBreakMinutes.toString());
      await _saveKey(db, 'timer_longBreakMinutes', newSettings.longBreakMinutes.toString());
      await _saveKey(db, 'timer_cyclesBeforeLongBreak', newSettings.cyclesBeforeLongBreak.toString());
      await _saveKey(db, 'timer_autoStartNextPhase', newSettings.autoStartNextPhase.toString());
      await _saveKey(db, 'timer_soundEnabled', newSettings.soundEnabled.toString());
      await _saveKey(db, 'timer_hapticsEnabled', newSettings.hapticsEnabled.toString());
      await _saveKey(db, 'timer_allowOvertime', newSettings.allowOvertime.toString());
    });
  }

  Future<void> _saveKey(AppDatabase db, String key, String value) async {
    await db.into(db.settings).insertOnConflictUpdate(SettingsCompanion(
      key: drift.Value(key),
      value: drift.Value(value),
    ));
  }
}
