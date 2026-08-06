import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../theme/app_theme.dart';
import 'profile_viewmodel.dart';
import '../../providers/database_provider.dart';
import '../timer/timer_settings_viewmodel.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(profileSettingsProvider);
    final notifier = ref.read(profileSettingsProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 28)),
      ),
      body: ListView(
        physics: const ClampingScrollPhysics(), // Less bounce if it does scroll
        padding: const EdgeInsets.all(12),
        children: [
          _buildHeader(context, settings, notifier),
          const SizedBox(height: 16),
          const Text('SETTINGS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 12),
          _buildSettingsGroup(
            title: 'Appearance',
            children: [
              _buildSettingTile(
                icon: settings.isDarkMode ? Icons.dark_mode_outlined : Icons.light_mode_outlined,
                title: 'Dark Mode (WIP)',
                trailing: Switch(
                  value: settings.isDarkMode,
                  onChanged: (val) => notifier.toggleDarkMode(),
                  activeThumbColor: AppColors.ink,
                  activeTrackColor: AppColors.todoAccent,
                ),
              ),
              const Divider(color: AppColors.ink, height: 1, thickness: 1.5),
              _buildSettingTile(
                icon: Icons.palette_outlined,
                title: 'Theme',
                subtitle: settings.themeName == 'beige' ? 'Classic Beige' : 'Default Off-White',
                onTap: () => _showThemeDialog(context, notifier, settings.themeName),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildSettingsGroup(
            title: 'Timer Defaults',
            children: [
              _buildSettingTile(
                icon: Icons.access_time,
                title: 'Pomodoro Duration',
                subtitle: '${settings.pomodoroMinutes} minutes',
                onTap: () => _showPomodoroDialog(context, ref, notifier, settings.pomodoroMinutes),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildSettingsGroup(
            title: 'Expense Defaults',
            children: [
              _buildSettingTile(
                icon: Icons.money,
                title: 'Currency',
                subtitle: settings.currency,
                onTap: () => _showCurrencyDialog(context, notifier, settings.currency),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildSettingsGroup(
            title: 'Data Management',
            children: [
              _buildSettingTile(
                icon: Icons.delete_outline,
                title: 'Clear All Data',
                titleColor: AppColors.error,
                onTap: () => _showClearDataConfirm(context, ref),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildSettingsGroup(
            title: 'Legal',
            children: [
              _buildSettingTile(
                icon: Icons.privacy_tip_outlined,
                title: 'Privacy Policy',
                onTap: () => _showPrivacyPolicy(context),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, ProfileSettings settings, ProfileSettingsNotifier notifier) {
    return Row(
      children: [
        GestureDetector(
          onTap: () => _showEmojiDialog(context, notifier),
          child: BrutalistContainer(
            padding: const EdgeInsets.all(16),
            color: AppColors.todoAccent,
            child: Text(settings.avatarEmoji, style: const TextStyle(fontSize: 48)),
          ),
        ),
        const SizedBox(width: 24),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Hello,', style: TextStyle(color: Colors.black54, fontWeight: FontWeight.bold, fontSize: 16)),
              GestureDetector(
                onTap: () => _showNameDialog(context, notifier, settings.displayName),
                child: Row(
                  children: [
                    Text(settings.displayName, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 32)),
                    const SizedBox(width: 8),
                    const Icon(Icons.edit_outlined, size: 16, color: Colors.black54),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsGroup({required String title, required List<Widget> children}) {
    return BrutalistContainer(
      color: Colors.white,
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }

  Widget _buildSettingTile({
    required IconData icon,
    required String title,
    String? subtitle,
    Color titleColor = AppColors.ink,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Row(
          children: [
            Icon(icon, color: titleColor),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: titleColor)),
                  if (subtitle != null)
                    Text(subtitle, style: const TextStyle(color: Colors.black54, fontSize: 12)),
                ],
              ),
            ),
            ?trailing,
          ],
        ),
      ),
    );
  }

  void _showEmojiDialog(BuildContext context, ProfileSettingsNotifier notifier) {
    // Basic dialog for Phase 1
    final emojis = ['🚀', '🔥', '⚡', '💻', '☕', '💡', '🧠', '🌿'];
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.zero,
          side: const BorderSide(color: AppColors.ink, width: 3),
        ),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        title: const Text('Pick an Avatar', style: TextStyle(fontWeight: FontWeight.w900)),
        content: Wrap(
          spacing: 16,
          runSpacing: 16,
          children: emojis.map((e) => GestureDetector(
            onTap: () {
              notifier.updateAvatarEmoji(e);
              Navigator.pop(ctx);
            },
            child: Text(e, style: const TextStyle(fontSize: 32)),
          )).toList(),
        ),
      )
    );
  }

  void _showNameDialog(BuildContext context, ProfileSettingsNotifier notifier, String currentName) {
    final controller = TextEditingController(text: currentName);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.zero,
          side: const BorderSide(color: AppColors.ink, width: 3),
        ),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        title: const Text('Display Name', style: TextStyle(fontWeight: FontWeight.w900)),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            border: OutlineInputBorder(borderSide: BorderSide(color: AppColors.ink, width: 2)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('CANCEL', style: TextStyle(color: AppColors.ink, fontWeight: FontWeight.bold)),
          ),
          BrutalistButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                notifier.updateDisplayName(controller.text);
                Navigator.pop(ctx);
              }
            },
            child: const Text('SAVE'),
          ),
        ],
      )
    );
  }

  void _showPomodoroDialog(BuildContext context, WidgetRef ref, ProfileSettingsNotifier notifier, int currentMinutes) {
    final controller = TextEditingController(text: currentMinutes.toString());
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.zero,
          side: BorderSide(color: AppColors.ink, width: 3),
        ),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        title: const Text('Pomodoro Duration (Minutes)', style: TextStyle(fontWeight: FontWeight.w900)),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            border: OutlineInputBorder(borderSide: BorderSide(color: AppColors.ink, width: 2)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('CANCEL', style: TextStyle(color: AppColors.ink, fontWeight: FontWeight.bold)),
          ),
          BrutalistButton(
            onPressed: () {
              final mins = int.tryParse(controller.text);
              if (mins != null && mins > 0) {
                notifier.updatePomodoroMinutes(mins);
                // Sync with timer's database settings
                final timerSettingsAsync = ref.read(timerSettingsProvider);
                if (timerSettingsAsync.value != null) {
                  ref.read(timerSettingsProvider.notifier).updateSettings(
                    timerSettingsAsync.value!.copyWith(pomodoroMinutes: mins)
                  );
                }
                Navigator.pop(ctx);
              }
            },
            child: const Text('SAVE'),
          ),
        ],
      )
    );
  }

  void _showCurrencyDialog(BuildContext context, ProfileSettingsNotifier notifier, String currentCurrency) {
    final currencies = ['₹', '\$', '€', '£', '¥'];
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.zero,
          side: BorderSide(color: AppColors.ink, width: 3),
        ),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        title: const Text('Select Currency', style: TextStyle(fontWeight: FontWeight.w900)),
        content: Wrap(
          spacing: 16,
          runSpacing: 16,
          children: currencies.map((c) => GestureDetector(
            onTap: () {
              notifier.updateCurrency(c);
              Navigator.pop(ctx);
            },
            child: BrutalistContainer(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              color: c == currentCurrency ? AppColors.expenseAccent : Colors.white,
              child: Text(c, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            ),
          )).toList(),
        ),
      )
    );
  }

  void _showClearDataConfirm(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.zero,
          side: const BorderSide(color: AppColors.ink, width: 3),
        ),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        title: const Text('CLEAR ALL DATA?', style: TextStyle(fontWeight: FontWeight.w900, color: AppColors.error)),
        content: const Text('This will delete all tasks, timer sessions, and expenses permanently. It cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('CANCEL', style: TextStyle(color: AppColors.ink, fontWeight: FontWeight.bold)),
          ),
          BrutalistButton(
            color: AppColors.error,
            onPressed: () async {
              final db = ref.read(databaseProvider);
              await db.delete(db.tasks).go();
              await db.delete(db.transactions).go();
              await db.delete(db.focusSessions).go();
              if (context.mounted) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('All data cleared.', style: TextStyle(fontWeight: FontWeight.bold)), backgroundColor: AppColors.ink),
                );
              }
            },
            child: const Text('DELETE EVERYTHING', style: TextStyle(color: Colors.white)),
          ),
        ],
      )
    );
  }

  void _showThemeDialog(BuildContext context, ProfileSettingsNotifier notifier, String currentTheme) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.zero,
          side: BorderSide(color: AppColors.ink, width: 3),
        ),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        title: const Text('SELECT THEME', style: TextStyle(fontWeight: FontWeight.w900)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildThemeOption(ctx, notifier, 'default', 'Default Off-White', const Color(0xFFFAF9F6), currentTheme == 'default'),
            const SizedBox(height: 12),
            _buildThemeOption(ctx, notifier, 'beige', 'Classic Beige', const Color(0xFFF5F5DC), currentTheme == 'beige'),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeOption(BuildContext context, ProfileSettingsNotifier notifier, String value, String label, Color color, bool isSelected) {
    return GestureDetector(
      onTap: () {
        notifier.updateThemeName(value);
        Navigator.pop(context);
      },
      child: BrutalistContainer(
        color: color,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shadowOffset: isSelected ? 2 : 4,
        borderWidth: isSelected ? 3.5 : 2,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
            if (isSelected) const Icon(Icons.check, color: AppColors.ink),
          ],
        ),
      ),
    );
  }

  void _showPrivacyPolicy(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.zero,
          side: const BorderSide(color: AppColors.ink, width: 3),
        ),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        title: const Text('Privacy Policy', style: TextStyle(fontWeight: FontWeight.w900)),
        content: const SingleChildScrollView(
          child: Text(
            'This application is fully local. We do not collect, store, track, or share any personal data or usage metrics.\n\n'
            'All your tasks, timer history, and expense records are stored securely on your local device.\n\n'
            'Since there are no servers, your data is entirely yours and never leaves your phone.',
            style: TextStyle(fontSize: 14),
          ),
        ),
        actions: [
          BrutalistButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('GOT IT'),
          ),
        ],
      )
    );
  }
}
