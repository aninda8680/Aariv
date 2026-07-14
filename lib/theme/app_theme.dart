import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const Color background = Color(0xFFFAF9F6);
  static const Color beigeBackground = Color(0xFFF5F5DC);
  static const Color ink = Color(0xFF1A1A1A);
  static const Color todoAccent = Color(0xFFFFD93D);
  static const Color timerAccent = Color(0xFFFF6B4A);
  static const Color expenseAccent = Color(0xFF3DDC97);
  static const Color error = Color(0xFFFF3B3B);
}

class AppTheme {
  static ThemeData getTheme(String themeName) {
    final bgColor = themeName == 'beige' ? AppColors.beigeBackground : AppColors.background;
    return ThemeData(
      scaffoldBackgroundColor: bgColor,
      colorScheme: ColorScheme.light(
        primary: AppColors.ink,
        secondary: AppColors.todoAccent,
        surface: bgColor,
        error: AppColors.error,
        onPrimary: bgColor,
        onSecondary: AppColors.ink,
        onSurface: AppColors.ink,
        onError: bgColor,
      ),
      textTheme: GoogleFonts.interTextTheme().apply(
        bodyColor: AppColors.ink,
        displayColor: AppColors.ink,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: bgColor,
        foregroundColor: AppColors.ink,
        elevation: 0,
        centerTitle: false,
        scrolledUnderElevation: 0,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: bgColor,
        selectedItemColor: AppColors.ink,
        unselectedItemColor: Colors.black54,
        elevation: 0,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}

// Brutalist Shared Components

class BrutalistContainer extends StatelessWidget {
  final Widget child;
  final Color? color;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double shadowOffset;
  final double borderWidth;

  const BrutalistContainer({
    super.key,
    required this.child,
    this.color,
    this.borderRadius = 0,
    this.padding = const EdgeInsets.all(16),
    this.margin,
    this.shadowOffset = 4,
    this.borderWidth = 2.5,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? Theme.of(context).scaffoldBackgroundColor;
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        color: effectiveColor,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: AppColors.ink, width: borderWidth),
        boxShadow: [
          BoxShadow(
            color: AppColors.ink,
            offset: Offset(shadowOffset, shadowOffset),
            blurRadius: 0,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Padding(
        padding: padding ?? EdgeInsets.zero,
        child: child,
      ),
    );
  }
}

class BrutalistButton extends StatefulWidget {
  final VoidCallback onPressed;
  final Widget child;
  final Color color;
  final double borderRadius;

  const BrutalistButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.color = AppColors.todoAccent,
    this.borderRadius = 8,
  });

  @override
  State<BrutalistButton> createState() => _BrutalistButtonState();
}

class _BrutalistButtonState extends State<BrutalistButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onPressed();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        margin: EdgeInsets.only(
          top: _isPressed ? 4.0 : 0.0,
          left: _isPressed ? 4.0 : 0.0,
          right: _isPressed ? 0.0 : 4.0,
          bottom: _isPressed ? 0.0 : 4.0,
        ),
        decoration: BoxDecoration(
          color: widget.color,
          borderRadius: BorderRadius.circular(widget.borderRadius),
          border: Border.all(color: AppColors.ink, width: 2.5),
          boxShadow: _isPressed
              ? []
              : const [
                  BoxShadow(
                    color: AppColors.ink,
                    offset: Offset(4, 4),
                    blurRadius: 0,
                    spreadRadius: 0,
                  ),
                ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        child: DefaultTextStyle(
          style: const TextStyle(
            color: AppColors.ink,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
          child: Center(
            heightFactor: 1.0,
            child: widget.child,
          ),
        ),
      ),
    );
  }
}
