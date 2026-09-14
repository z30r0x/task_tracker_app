import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:device_frame/device_frame.dart';
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
      home: _PortfolioAppWrapper(
        child: HomePage(
          selectedColor: _accentColor,
          onColorChanged: _changeAccentColor,
        ),
      ),
    );
  }
}

class _PortfolioAppWrapper extends StatelessWidget {
  const _PortfolioAppWrapper({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final isDesktopWeb = kIsWeb && MediaQuery.sizeOf(context).width > 600;
    if (!isDesktopWeb) {
      return child;
    }

    return Scaffold(
      backgroundColor: const Color(0xFF1E1E1E),
      body: Center(
        child: DeviceFrame(
          device: Devices.ios.iPhone13,
          isFrameVisible: true,
          orientation: Orientation.portrait,
          screen: child,
        ),
      ),
    );
  }
}
