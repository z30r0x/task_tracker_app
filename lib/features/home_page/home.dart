import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/utils/styles/fonts.dart';
import '../../core/utils/styles/images.dart';
import '../../core/utils/colors.dart';
import '../completed_tasks_page/completed_tasks.dart';
import '../settings_page/settings.dart';

String _formatDate(DateTime date) =>
    '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';

class TaskItem {
  TaskItem({
    required this.title,
    required this.description,
    required this.category,
    required this.priority,
    required this.dueDate,
    this.isCompleted = false,
  });

  String title;
  String description;
  String category;
  String priority;
  DateTime dueDate;
  bool isCompleted;

  Color get priorityColor => switch (priority) {
    'High' => AppColors.priorityHigh,
    'Low' => AppColors.priorityLow,
    _ => AppColors.priorityMedium,
  };

  Map<String, dynamic> toJson() => {
    'title': title,
    'description': description,
    'category': category,
    'priority': priority,
    'dueDate': dueDate.toIso8601String(),
    'isCompleted': isCompleted,
  };

  factory TaskItem.fromJson(Map<String, dynamic> json) => TaskItem(
    title: json['title'] as String,
    description: json['description'] as String,
    category: json['category'] as String,
    priority: json['priority'] as String,
    dueDate: DateTime.parse(json['dueDate'] as String),
    isCompleted: json['isCompleted'] as bool? ?? false,
  );
}

class HomePage extends StatefulWidget {
  const HomePage({
    super.key,
    required this.selectedColor,
    required this.onColorChanged,
  });

  final Color selectedColor;
  final ValueChanged<Color> onColorChanged;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const _tasksStorageKey = 'task_tracker_tasks';
  int _selectedTab = 0;
  String? _selectedCategory;

  final _tasks = <TaskItem>[
    TaskItem(
      title: 'Build daily ETL pipeline for sales data',
      description: 'Extract sales data and load it into the data warehouse.',
      category: 'ETL Pipelines',
      priority: 'High',
      dueDate: DateTime(2026, 9, 14),
    ),
    TaskItem(
      title: 'Review slow SQL queries',
      description: 'Find and optimize the slowest production queries.',
      category: 'SQL Queries',
      priority: 'Medium',
      dueDate: DateTime(2026, 9, 16),
    ),
    TaskItem(
      title: 'Update Power BI dashboard',
      description: 'Refresh the sales dashboard with the latest metrics.',
      category: 'Power BI',
      priority: 'Low',
      dueDate: DateTime(2026, 9, 20),
    ),
  ];
  final _completedTasks = <TaskItem>[
    TaskItem(
      title: 'Create data quality checks',
      description: 'Add validation checks to the daily data workflow.',
      category: 'ETL Pipelines',
      priority: 'Medium',
      dueDate: DateTime(2026, 9, 12),
      isCompleted: true,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    final preferences = await SharedPreferences.getInstance();
    final storedTasks = preferences.getStringList(_tasksStorageKey);
    if (!mounted || storedTasks == null) return;

    final loadedTasks = <TaskItem>[];
    for (final encodedTask in storedTasks) {
      try {
        final task = TaskItem.fromJson(
          jsonDecode(encodedTask) as Map<String, dynamic>,
        );
        loadedTasks.add(task);
      } on FormatException {
        // Ignore malformed entries while preserving valid local tasks.
      } on TypeError {
        // Ignore malformed entries while preserving valid local tasks.
      }
    }
    if (!mounted) return;
    setState(() {
      _tasks
        ..clear()
        ..addAll(loadedTasks.where((task) => !task.isCompleted));
      _completedTasks
        ..clear()
        ..addAll(loadedTasks.where((task) => task.isCompleted));
    });
  }

  Future<void> _saveTasks() async {
    final preferences = await SharedPreferences.getInstance();
    final tasks = [..._tasks, ..._completedTasks];
    await preferences.setStringList(
      _tasksStorageKey,
      tasks.map((task) => jsonEncode(task.toJson())).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(child: _contentForTab()),
            _BottomNavigation(
              selectedIndex: _selectedTab,
              onChanged: (index) => setState(() => _selectedTab = index),
            ),
          ],
        ),
      ),
    );
  }

  Widget _contentForTab() {
    switch (_selectedTab) {
      case 1:
        return CompletedTasksPage(
          tasks: _completedTasks,
          onTaskSelected: _showCompletedTaskDetails,
          onTaskUncompleted: _uncompleteTask,
        );
      case 2:
        return SettingsPage(
          selectedColor: widget.selectedColor,
          onColorChanged: widget.onColorChanged,
        );
      default:
        return _DashboardView(
          tasks: _tasks
              .where(
                (task) =>
                    _selectedCategory == null ||
                    task.category == _selectedCategory,
              )
              .toList(),
          selectedCategory: _selectedCategory,
          onCategorySelected: (category) => setState(
            () => _selectedCategory =
                category == 'All tasks' || _selectedCategory == category
                ? null
                : category,
          ),
          onAddTask: _showAddTaskDialog,
          onTaskSelected: _showTaskDetails,
          onTaskCompleted: _completeTask,
        );
    }
  }

  Future<void> _showCompletedTaskDetails(TaskItem task) async {
    final action = await showDialog<String>(
      context: context,
      builder: (context) => _TaskDetailsDialog(task: task, completed: true),
    );
    if (!mounted || action == null) return;
    if (action == 'delete') {
      setState(() => _completedTasks.remove(task));
      await _saveTasks();
    } else if (action == 'edit') {
      await _editTask(task, completed: true);
    }
  }

  Future<void> _showAddTaskDialog() async {
    final task = await showDialog<TaskItem>(
      context: context,
      builder: (context) => const _AddTaskDialog(),
    );

    if (!mounted || task == null) {
      return;
    }

    setState(() => _tasks.add(task));
    await _saveTasks();
  }

  void _completeTask(TaskItem task) {
    setState(() {
      _tasks.remove(task);
      task.isCompleted = true;
      _completedTasks.add(task);
    });
    _saveTasks();
  }

  void _uncompleteTask(TaskItem task) {
    setState(() {
      _completedTasks.remove(task);
      task.isCompleted = false;
      _tasks.add(task);
    });
    _saveTasks();
  }

  Future<void> _showTaskDetails(TaskItem task) async {
    final action = await showDialog<String>(
      context: context,
      builder: (context) => _TaskDetailsDialog(task: task),
    );

    if (!mounted || action == null) return;
    if (action == 'delete') {
      setState(() => _tasks.remove(task));
      await _saveTasks();
    } else if (action == 'edit') {
      await _editTask(task);
    }
  }

  Future<void> _editTask(TaskItem task, {bool completed = false}) async {
    final updatedTask = await showDialog<TaskItem>(
      context: context,
      builder: (context) => _AddTaskDialog(task: task),
    );
    if (!mounted || updatedTask == null) return;
    setState(() {
      task.title = updatedTask.title;
      task.description = updatedTask.description;
      task.category = updatedTask.category;
      task.priority = updatedTask.priority;
      task.dueDate = updatedTask.dueDate;
      task.isCompleted = completed;
    });
    await _saveTasks();
  }
}

class _DashboardView extends StatelessWidget {
  const _DashboardView({
    required this.tasks,
    required this.selectedCategory,
    required this.onCategorySelected,
    required this.onAddTask,
    required this.onTaskSelected,
    required this.onTaskCompleted,
  });

  final List<TaskItem> tasks;
  final String? selectedCategory;
  final ValueChanged<String> onCategorySelected;
  final VoidCallback onAddTask;
  final ValueChanged<TaskItem> onTaskSelected;
  final ValueChanged<TaskItem> onTaskCompleted;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          sliver: SliverToBoxAdapter(
            child: Row(
              children: [
                const Expanded(child: _Brand()),
                FilledButton.icon(
                  onPressed: onAddTask,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('New task'),
                  style: FilledButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: AppColors.textPrimary,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    textStyle: AppFonts.bodyMedium,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(11),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
          sliver: SliverToBoxAdapter(
            child: Row(
              children: [
                Expanded(
                  child: _StatTile(
                    value: '${tasks.length}',
                    label: 'In progress',
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: _StatTile(
                    value:
                        '${tasks.where((task) => task.priority == 'High').length}',
                    label: 'High priority',
                    valueColor: AppColors.priorityHigh,
                  ),
                ),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
          sliver: SliverToBoxAdapter(
            child: Wrap(
              spacing: 9,
              runSpacing: 8,
              children: [
                GestureDetector(
                  onTap: () => onCategorySelected('All tasks'),
                  child: _FilterChip(
                    label: 'All tasks',
                    selected: selectedCategory == null,
                  ),
                ),
                for (final category in const [
                  'ETL Pipelines',
                  'SQL Queries',
                  'Power BI',
                ])
                  GestureDetector(
                    onTap: () => onCategorySelected(category),
                    child: _FilterChip(
                      label: category,
                      selected: selectedCategory == category,
                    ),
                  ),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 26, 20, 20),
          sliver: SliverList.builder(
            itemCount: tasks.length,
            itemBuilder: (context, index) {
              final task = tasks[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _TaskCard(
                  task: task,
                  onTap: () => onTaskSelected(task),
                  onComplete: () => onTaskCompleted(task),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _Brand extends StatelessWidget {
  const _Brand();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Image.asset(
        AppImages.mainLogo,
        width: 145,
        height: 44,
        fit: BoxFit.contain,
        alignment: Alignment.centerLeft,
      ),
    );
  }
}

class _AddTaskDialog extends StatefulWidget {
  const _AddTaskDialog({this.task});

  final TaskItem? task;

  @override
  State<_AddTaskDialog> createState() => _AddTaskDialogState();
}

class _AddTaskDialogState extends State<_AddTaskDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _category = 'ETL Pipelines';
  String _priority = 'Medium';
  DateTime _dueDate = DateTime.now().add(const Duration(days: 1));

  @override
  void initState() {
    super.initState();
    final task = widget.task;
    if (task != null) {
      _titleController.text = task.title;
      _descriptionController.text = task.description;
      _category = task.category;
      _priority = task.priority;
      _dueDate = task.dueDate;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _saveTask() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    Navigator.of(context).pop(
      TaskItem(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        category: _category,
        priority: _priority,
        dueDate: _dueDate,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surface,
      title: Text(
        widget.task == null ? 'Add new task' : 'Edit task',
        style: AppFonts.section,
      ),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _titleController,
                autofocus: true,
                decoration: const InputDecoration(labelText: 'Task title'),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Enter a task title'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Description'),
              ),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.calendar_today_outlined),
                title: const Text('Due date'),
                subtitle: Text(_formatDate(_dueDate)),
                onTap: () async {
                  final selectedDate = await showDatePicker(
                    context: context,
                    initialDate: _dueDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2100),
                  );
                  if (selectedDate != null) {
                    setState(() => _dueDate = selectedDate);
                  }
                },
              ),
              const SizedBox(height: 4),
              DropdownButtonFormField<String>(
                initialValue: _category,
                decoration: const InputDecoration(labelText: 'Category'),
                items: const ['ETL Pipelines', 'SQL Queries', 'Power BI']
                    .map(
                      (category) => DropdownMenuItem(
                        value: category,
                        child: Text(category),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _category = value);
                  }
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _priority,
                decoration: const InputDecoration(labelText: 'Priority'),
                items: const ['Low', 'Medium', 'High']
                    .map(
                      (priority) => DropdownMenuItem(
                        value: priority,
                        child: Text(priority),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _priority = value);
                  }
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _saveTask,
          child: Text(widget.task == null ? 'Add task' : 'Save changes'),
        ),
      ],
    );
  }
}

class _TaskDetailsDialog extends StatelessWidget {
  const _TaskDetailsDialog({required this.task, this.completed = false});

  final TaskItem task;
  final bool completed;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surface,
      title: Text(task.title, style: AppFonts.section),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            task.description.isEmpty
                ? 'No description provided.'
                : task.description,
            style: AppFonts.body.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 18),
          Text('Category: ${task.category}', style: AppFonts.bodyMedium),
          const SizedBox(height: 8),
          Text('Priority: ${task.priority}', style: AppFonts.bodyMedium),
          const SizedBox(height: 8),
          Text(
            'Due date: ${_formatDate(task.dueDate)}',
            style: AppFonts.bodyMedium,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop('delete'),
          child: const Text(
            'Delete',
            style: TextStyle(color: AppColors.priorityHigh),
          ),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop('edit'),
          child: const Text('Edit'),
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.value,
    required this.label,
    this.valueColor = AppColors.accent,
  });

  final String value;
  final String label;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.55)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: AppFonts.stat.copyWith(color: valueColor)),
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

class _FilterChip extends StatelessWidget {
  const _FilterChip({required this.label, this.selected = false});

  final String label;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: selected
            ? Theme.of(context).colorScheme.secondary.withValues(alpha: 0.15)
            : AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: selected
              ? Theme.of(context).colorScheme.secondary
              : AppColors.border,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        child: Text(
          label,
          style: AppFonts.caption.copyWith(
            color: selected
                ? Theme.of(context).colorScheme.secondary
                : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _TaskCard extends StatelessWidget {
  const _TaskCard({
    required this.task,
    required this.onTap,
    required this.onComplete,
  });

  final TaskItem task;
  final VoidCallback onTap;
  final VoidCallback onComplete;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 16, 12, 16),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border.withValues(alpha: 0.35)),
        ),
        child: Row(
          children: [
            GestureDetector(
              onTap: onComplete,
              child: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.textDisabled, width: 2),
                ),
              ),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(task.title, style: AppFonts.bodyMedium),
                  const SizedBox(height: 8),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: task.priorityColor.withValues(alpha: 0.13),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 4,
                      ),
                      child: Text(
                        task.priority,
                        style: AppFonts.caption.copyWith(
                          color: task.priorityColor,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Due ${_formatDate(task.dueDate)}',
                    style: AppFonts.caption.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.textDisabled),
            const SizedBox(width: 4),
            Container(
              width: 3,
              height: 44,
              decoration: BoxDecoration(
                color: task.priorityColor,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ignore: unused_element
class _CompletedView extends StatelessWidget {
  const _CompletedView({
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
        const SliverPadding(
          padding: EdgeInsets.fromLTRB(20, 20, 20, 0),
          sliver: SliverToBoxAdapter(child: _Brand()),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Completed tasks', style: AppFonts.title),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: _StatTile(
                    value: '${tasks.length}',
                    label: 'Completed',
                    valueColor: AppColors.success,
                  ),
                ),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
          sliver: tasks.isEmpty
              ? const SliverToBoxAdapter(child: _EmptyCompletedState())
              : SliverList.builder(
                  itemCount: tasks.length,
                  itemBuilder: (context, index) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _CompletedTaskCard(
                      task: tasks[index],
                      onTap: () => onTaskSelected(tasks[index]),
                      onUncomplete: () => onTaskUncompleted(tasks[index]),
                    ),
                  ),
                ),
        ),
      ],
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
    return InkWell(
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.title,
                    style: AppFonts.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                      decoration: TextDecoration.lineThrough,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    task.category,
                    style: AppFonts.caption.copyWith(color: AppColors.success),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Completed ${_formatDate(task.dueDate)}',
                    style: AppFonts.caption.copyWith(
                      color: AppColors.textDisabled,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.textDisabled),
          ],
        ),
      ),
    );
  }
}

class _EmptyCompletedState extends StatelessWidget {
  const _EmptyCompletedState();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          const Icon(Icons.task_alt, color: AppColors.textDisabled, size: 34),
          const SizedBox(height: 10),
          Text(
            'No completed tasks yet',
            style: AppFonts.bodyMedium.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

// ignore: unused_element
class _SettingsView extends StatelessWidget {
  const _SettingsView();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      children: [
        const _Brand(),
        const SizedBox(height: 28),
        const Text('Settings', style: AppFonts.title),
        const SizedBox(height: 18),
        const Text('Preferences', style: AppFonts.section),
        const SizedBox(height: 10),
        _SettingsTile(
          icon: Icons.dark_mode_outlined,
          title: 'Dark appearance',
          subtitle: 'Use the Task Tracker dark theme',
          trailing: Switch(value: true, onChanged: (_) {}),
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
        const Text('Workspace', style: AppFonts.section),
        const SizedBox(height: 10),
        _SettingsTile(
          icon: Icons.category_outlined,
          title: 'Task categories',
          subtitle: 'ETL Pipelines, SQL Queries, Power BI',
          trailing: const Icon(
            Icons.chevron_right,
            color: AppColors.textDisabled,
          ),
        ),
        _SettingsTile(
          icon: Icons.info_outline,
          title: 'About Task Tracker',
          subtitle: 'Task Tracker version 1.0.0',
          trailing: const Icon(
            Icons.chevron_right,
            color: AppColors.textDisabled,
          ),
        ),
      ],
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
        leading: Icon(icon, color: AppColors.accent),
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

class _BottomNavigation extends StatelessWidget {
  const _BottomNavigation({
    required this.selectedIndex,
    required this.onChanged,
  });

  final int selectedIndex;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    const items = [
      (Icons.checklist_rounded, 'Tasks'),
      (Icons.task_alt_rounded, 'Completed'),
      (Icons.settings_outlined, 'Settings'),
    ];
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      padding: const EdgeInsets.fromLTRB(10, 9, 10, 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          for (var index = 0; index < items.length; index++)
            Expanded(
              child: InkWell(
                onTap: () => onChanged(index),
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        items[index].$1,
                        color: selectedIndex == index
                            ? Theme.of(context).colorScheme.secondary
                            : AppColors.textSecondary,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        items[index].$2,
                        style: AppFonts.caption.copyWith(
                          color: selectedIndex == index
                              ? Theme.of(context).colorScheme.secondary
                              : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
