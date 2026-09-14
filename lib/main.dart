import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'features/home_page/home.dart';
import 'core/utils/styles/fonts.dart';
import 'core/utils/colors.dart';

void main() {
  runApp(const TaskTrackerApp());
}

class TaskTrackerApp extends StatefulWidget {
  const TaskTrackerApp({super.key});

  @override
  State<TaskTrackerApp> createState() => _TaskTrackerAppState();
}

class _TaskTrackerAppState extends State<TaskTrackerApp> {
  static const _colorStorageKey = 'task_tracker_accent_color';
  Color _accentColor = AppColors.accent;

  @override
  void initState() {
    super.initState();
    _loadAccentColor();
  }

  Future<void> _loadAccentColor() async {
    final preferences = await SharedPreferences.getInstance();
    final value = preferences.getInt(_colorStorageKey);
    if (value != null && mounted) {
      setState(() => _accentColor = Color(value));
    }
  }

  Future<void> _changeAccentColor(Color color) async {
    setState(() => _accentColor = color);
    final preferences = await SharedPreferences.getInstance();
    await preferences.setInt(_colorStorageKey, color.toARGB32());
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Task Tracker',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.background,
        fontFamily: AppFonts.family,
        colorScheme: ColorScheme.dark(
          primary: _accentColor,
          secondary: _accentColor,
          surface: AppColors.surface,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.background,
          foregroundColor: AppColors.textPrimary,
          elevation: 0,
        ),
      ),
      home: _WebPhoneFrame(
        child: HomePage(
          selectedColor: _accentColor,
          onColorChanged: _changeAccentColor,
        ),
      ),
    );
  }
}

class _WebPhoneFrame extends StatelessWidget {
  const _WebPhoneFrame({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb) {
      return child;
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        const phoneWidth = 375.0;
        const phoneHeight = 812.0;
        const outerPadding = 24.0;

        final width = (constraints.maxWidth - outerPadding * 2)
            .clamp(280.0, phoneWidth)
            .toDouble();
        final height = (constraints.maxHeight - outerPadding * 2)
            .clamp(560.0, phoneHeight)
            .toDouble();

        return ColoredBox(
          color: const Color(0xFFE8ECF1),
          child: Center(
            child: Container(
              width: width,
              height: height,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: const Color(0xFF080B10),
                borderRadius: BorderRadius.circular(32),
                border: Border.all(color: const Color(0xFF10161D), width: 8),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x40000000),
                    blurRadius: 28,
                    offset: Offset(0, 12),
                  ),
                ],
              ),
              child: child,
            ),
          ),
        );
      },
    );
  }
}
