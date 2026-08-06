import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'theme/app_theme.dart';
import 'ui/todo/todo_screen.dart';
import 'ui/timer/timer_screen.dart';
import 'ui/timer/timer_viewmodel.dart';
import 'ui/expense/expense_screen.dart';
import 'ui/profile/profile_screen.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'ui/profile/profile_viewmodel.dart';

import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService().init();
  final prefs = await SharedPreferences.getInstance();
  
  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const AarivApp(),
    ),
  );
}

class AarivApp extends ConsumerWidget {
  const AarivApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeName = ref.watch(profileSettingsProvider.select((s) => s.themeName));
    final isDarkMode = ref.watch(profileSettingsProvider.select((s) => s.isDarkMode));
    return MaterialApp(
      title: 'Aariv',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.getTheme(themeName, isDarkMode: isDarkMode),
      home: const MainScreen(),
    );
  }
}

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    // Keep timer alive even when offstage
    ref.listen(timerControllerProvider, (_, __) {});
    final isDarkMode = ref.watch(profileSettingsProvider.select((s) => s.isDarkMode));

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          const TodoScreen(),
          const TimerScreen(),
          const ExpenseScreen(),
          const ProfileScreen(),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.ink, width: 2.5)),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          items: [
            _buildNavItem(Icons.check_box_outlined, 'Todo', 0, AppColors.todoAccent, isDarkMode),
            _buildNavItem(Icons.timer_outlined, 'Timer', 1, AppColors.timerAccent, isDarkMode),
            _buildNavItem(Icons.currency_rupee, 'Expense', 2, AppColors.expenseAccent, isDarkMode),
            _buildNavItem(Icons.person_outline, 'Profile', 3, Colors.white, isDarkMode),
          ],
        ),
      ),
    );
  }

  BottomNavigationBarItem _buildNavItem(IconData icon, String label, int index, Color activeColor, bool isDarkMode) {
    final isActive = _currentIndex == index;
    final borderColor = isDarkMode ? Colors.white : AppColors.ink;
    final iconColor = isActive ? AppColors.ink : (isDarkMode ? Colors.white : AppColors.ink);

    return BottomNavigationBarItem(
      icon: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? activeColor : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: isActive ? Border.all(color: borderColor, width: 2) : Border.all(color: Colors.transparent, width: 2),
        ),
        child: Icon(icon, color: iconColor),
      ),
      label: label, // We might hide this or style it, but material requires it
    );
  }
}
