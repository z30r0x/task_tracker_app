import 'package:flutter/material.dart';

import '../../core/utils/styles/fonts.dart';
import '../../core/utils/styles/images.dart';
import '../../core/utils/colors.dart';
import '../home_page/home.dart';

class CompletedTasksPage extends StatelessWidget {
  const CompletedTasksPage({
    super.key,
    required this.tasks,
    required this.onTaskSelected,
    required this.onTaskUncompleted,
  });

  final List<TaskItem> tasks;
  final ValueChanged<TaskItem> onTaskSelected;
  final ValueChanged<TaskItem> onTaskUncompleted;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          sliver: SliverToBoxAdapter(
            child: Image.asset(
              AppImages.mainLogo,
              width: 145,
              height: 44,
              fit: BoxFit.contain,
              alignment: Alignment.centerLeft,
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Completed tasks', style: AppFonts.title),
                const SizedBox(height: 14),
                _StatTile(value: '${tasks.length}', label: 'Completed'),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
          sliver: tasks.isEmpty
              ? const SliverToBoxAdapter(child: Text('No completed tasks yet'))
              : SliverList.builder(
                  itemCount: tasks.length,
                  itemBuilder: (context, index) => _CompletedTaskCard(
                    task: tasks[index],
                    onTap: () => onTaskSelected(tasks[index]),
                    onUncomplete: () => onTaskUncompleted(tasks[index]),
                  ),
                ),
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: AppFonts.stat.copyWith(color: AppColors.success)),
          const SizedBox(height: 7),
          Text(
            label,
            style: AppFonts.caption.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _CompletedTaskCard extends StatelessWidget {
  const _CompletedTaskCard({
    required this.task,
    required this.onTap,
    required this.onUncomplete,
  });

  final TaskItem task;
  final VoidCallback onTap;
  final VoidCallback onUncomplete;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border.withValues(alpha: 0.35)),
          ),
          child: Row(
            children: [
              GestureDetector(
                onTap: onUncomplete,
                child: const Icon(
                  Icons.check_circle,
                  color: AppColors.success,
                  size: 22,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Text(
                  task.title,
                  style: AppFonts.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                    decoration: TextDecoration.lineThrough,
                  ),
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.textDisabled),
            ],
          ),
        ),
      ),
    );
  }
}
