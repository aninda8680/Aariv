import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('sharedPreferencesProvider must be overridden');
});

class ProfileSettings {
  final String displayName;
  final String avatarEmoji;
  final String currency;
  final bool isDarkMode;
  final int pomodoroMinutes;
  final String themeName; // 'default' or 'beige'

  ProfileSettings({
    required this.displayName,
    required this.avatarEmoji,
    required this.currency,
    required this.isDarkMode,
    required this.pomodoroMinutes,
    required this.themeName,
  });

  ProfileSettings copyWith({
    String? displayName,
    String? avatarEmoji,
    String? currency,
    bool? isDarkMode,
    int? pomodoroMinutes,
    String? themeName,
  }) {
    return ProfileSettings(
      displayName: displayName ?? this.displayName,
      avatarEmoji: avatarEmoji ?? this.avatarEmoji,
      currency: currency ?? this.currency,
      isDarkMode: isDarkMode ?? this.isDarkMode,
      pomodoroMinutes: pomodoroMinutes ?? this.pomodoroMinutes,
      themeName: themeName ?? this.themeName,
    );
  }
}

final profileSettingsProvider = NotifierProvider<ProfileSettingsNotifier, ProfileSettings>(ProfileSettingsNotifier.new);

class ProfileSettingsNotifier extends Notifier<ProfileSettings> {
  @override
  ProfileSettings build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    
    return ProfileSettings(
      displayName: prefs.getString('displayName') ?? 'Student',
      avatarEmoji: prefs.getString('avatarEmoji') ?? '🚀',
      currency: prefs.getString('currency') ?? '₹',
      isDarkMode: prefs.getBool('isDarkMode') ?? false,
      pomodoroMinutes: prefs.getInt('pomodoroMinutes') ?? 25,
      themeName: prefs.getString('themeName') ?? 'default',
    );
  }

  Future<void> updateDisplayName(String name) async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setString('displayName', name);
    state = state.copyWith(displayName: name);
  }

  Future<void> updateAvatarEmoji(String emoji) async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setString('avatarEmoji', emoji);
    state = state.copyWith(avatarEmoji: emoji);
  }

  Future<void> updateCurrency(String currency) async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setString('currency', currency);
    state = state.copyWith(currency: currency);
  }

  Future<void> toggleDarkMode() async {
    final prefs = ref.read(sharedPreferencesProvider);
    final newValue = !state.isDarkMode;
    await prefs.setBool('isDarkMode', newValue);
    state = state.copyWith(isDarkMode: newValue);
  }

  Future<void> updatePomodoroMinutes(int minutes) async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setInt('pomodoroMinutes', minutes);
    state = state.copyWith(pomodoroMinutes: minutes);
  }

  Future<void> updateThemeName(String themeName) async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setString('themeName', themeName);
    state = state.copyWith(themeName: themeName);
  }
  
  // Data management functions (clear all) can be implemented here interacting with db
}
