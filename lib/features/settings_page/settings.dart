import 'package:flutter/material.dart';

import '../../core/utils/styles/fonts.dart';
import '../../core/utils/styles/images.dart';
import '../../core/utils/colors.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({
    super.key,
    required this.selectedColor,
    required this.onColorChanged,
  });

  final Color selectedColor;
  final ValueChanged<Color> onColorChanged;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Image.asset(
            AppImages.mainLogo,
            width: 145,
            height: 44,
            fit: BoxFit.contain,
            alignment: Alignment.centerLeft,
          ),
        ),
        const SizedBox(height: 28),
        const Text('Settings', style: AppFonts.title),
        const SizedBox(height: 18),
        const Text('Preferences', style: AppFonts.section),
        const SizedBox(height: 10),
        _SettingsTile(
          icon: Icons.dark_mode_outlined,
          title: 'Dark appearance',
          subtitle: 'Use the Task Tracker dark theme',
          trailing: Switch(value: true, onChanged: null),
        ),
        _SettingsTile(
          icon: Icons.language_outlined,
          title: 'Language',
          subtitle: 'English',
          trailing: const Icon(
            Icons.chevron_right,
            color: AppColors.textDisabled,
          ),
        ),
        const SizedBox(height: 24),
        const Text('Colors', style: AppFonts.section),
        const SizedBox(height: 10),
        _ColorPanel(
          selectedColor: selectedColor,
          onColorChanged: onColorChanged,
        ),
      ],
    );
  }
}

class _ColorPanel extends StatelessWidget {
  const _ColorPanel({
    required this.selectedColor,
    required this.onColorChanged,
  });

  final Color selectedColor;
  final ValueChanged<Color> onColorChanged;

  static const _colors = [
    Color(0xFF3FB950),
    Color(0xFF0D99FF),
    Color(0xFF00E5FF),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Wrap(
        spacing: 14,
        runSpacing: 14,
        children: [
          for (final color in _colors)
            GestureDetector(
              onTap: () => onColorChanged(color),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 42,
                height: 42,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: selectedColor.toARGB32() == color.toARGB32()
                        ? AppColors.textPrimary
                        : Colors.transparent,
                    width: 2,
                  ),
                ),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.trailing,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.6)),
      ),
      child: ListTile(
        leading: Icon(icon, color: Theme.of(context).colorScheme.secondary),
        title: Text(title, style: AppFonts.bodyMedium),
        subtitle: Text(
          subtitle,
          style: AppFonts.caption.copyWith(color: AppColors.textSecondary),
        ),
        trailing: trailing,
      ),
    );
  }
}
