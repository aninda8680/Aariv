import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'theme/app_theme.dart';
import 'ui/todo/todo_screen.dart';
import 'ui/timer/timer_screen.dart';
import 'ui/expense/expense_screen.dart';
import 'ui/profile/profile_screen.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'ui/profile/profile_viewmodel.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
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
    final themeName = ref.watch(profileSettingsProvider.select((s) => s.themeName)) ?? 'default';
    return MaterialApp(
      title: 'Aariv',
      theme: AppTheme.getTheme(themeName),
      home: const MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
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
            _buildNavItem(Icons.check_box_outlined, 'Todo', 0, AppColors.todoAccent),
            _buildNavItem(Icons.timer_outlined, 'Timer', 1, AppColors.timerAccent),
            _buildNavItem(Icons.currency_rupee, 'Expense', 2, AppColors.expenseAccent),
            _buildNavItem(Icons.person_outline, 'Profile', 3, Theme.of(context).scaffoldBackgroundColor), // No specific accent mentioned for profile
          ],
        ),
      ),
    );
  }

  BottomNavigationBarItem _buildNavItem(IconData icon, String label, int index, Color activeColor) {
    final isActive = _currentIndex == index;
    return BottomNavigationBarItem(
      icon: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? activeColor : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: isActive ? Border.all(color: AppColors.ink, width: 2) : Border.all(color: Colors.transparent, width: 2),
        ),
        child: Icon(icon, color: AppColors.ink),
      ),
      label: label, // We might hide this or style it, but material requires it
    );
  }
}
