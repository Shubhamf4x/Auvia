import 'package:flutter/material.dart';
import '../../core/fmt.dart';
import '../../core/l10n.dart';
import '../../core/theme.dart';
import '../../data/app_state.dart';
import '../../data/models.dart';
import '../../data/scope.dart';
import '../../widgets/common.dart';

class TasksScreen extends StatefulWidget {
  final bool embedded;
  const TasksScreen({super.key, this.embedded = false});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  DateTime? _selected;

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  List<DateTime> _week() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final monday = today.subtract(Duration(days: today.weekday - 1));
    return List.generate(7, (i) => monday.add(Duration(days: i)));
  }

  String _dayLabel(DateTime d) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(d.year, d.month, d.day);
    final diff = day.difference(today).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Tomorrow';
    if (diff == -1) return 'Yesterday';
    return '${Fmt.weekdayName(d)}, ${Fmt.monthDay(d)}';
  }

  @override
  Widget build(BuildContext context) {
    return StateRefresher(
      builder: (context, state) {
        final open = state.openTasks;
        final done = state.doneTasks;
        final today = <Task>[];
        final upcoming = <Task>[];
        final now = DateTime.now();
        final todayEnd = DateTime(now.year, now.month, now.day, 23, 59);
        for (final t in open) {
          final due = t.dueTime;
          if (due == null || due.isBefore(todayEnd)) {
            today.add(t);
          } else {
            upcoming.add(t);
          }
        }

        final week = _week();
        final daysWithTasks = <int>{};
        for (final t in open) {
          final due = t.dueTime;
          if (due == null) continue;
          for (var i = 0; i < week.length; i++) {
            if (_sameDay(due, week[i])) daysWithTasks.add(i);
          }
        }

        final filtered = _selected == null
            ? <Task>[]
            : open
                .where((t) =>
                    t.dueTime != null && _sameDay(t.dueTime!, _selected!))
                .toList()
              ..sort((a, b) => a.dueTime!.compareTo(b.dueTime!));

        Widget list = ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 110),
          children: [
            Padding(
              padding: EdgeInsets.only(top: 12, bottom: 12),
              child: Text(t(context, 'tasks'), style: AppText.pageTitle),
            ),
            _MiniCalendar(
              week: week,
              selected: _selected,
              daysWithTasks: daysWithTasks,
              sameDay: _sameDay,
              onPick: (d) => setState(() {
                _selected =
                    (_selected != null && _sameDay(_selected!, d)) ? null : d;
              }),
            ),
            if (_selected != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Text('Due ${_dayLabel(_selected!)}',
                        style: AppText.sectionHeading),
                  ),
                  GestureDetector(
                    onTap: () => setState(() => _selected = null),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceAlt,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Text(t(context, 'seeAll'),
                          style: AppText.label.copyWith(fontSize: 12)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (filtered.isEmpty)
                AppCard(
                  child: Column(
                    children: [
                      Icon(Icons.event_busy_rounded,
                          size: 36, color: AppColors.textFaint),
                      const SizedBox(height: 10),
                      Text(t(context, 'noResults'),
                          style: AppText.cardTitle),
                      const SizedBox(height: 4),
                      Text('Tap a day to see its tasks.',
                          style: AppText.body),
                    ],
                  ),
                )
              else
                ...filtered.map((t) => _taskTile(context, state, t)),
            ] else ...[
              SectionHeader(t(context, 'today')),
              if (today.isEmpty && upcoming.isEmpty)
                AppCard(
                  child: Column(
                    children: [
                      Icon(Icons.check_circle_outline_rounded,
                          size: 40, color: AppColors.success),
                      const SizedBox(height: 12),
                      Text(t(context, 'allClear'), style: AppText.cardTitle),
                      const SizedBox(height: 4),
                      Text('No open tasks right now.',
                          style: AppText.body),
                    ],
                  ),
                )
              else ...[
                ...today.map((t) => _taskTile(context, state, t)),
                if (upcoming.isNotEmpty) ...[
                  SectionHeader(t(context, 'upcoming')),
                  ...upcoming.map((t) => _taskTile(context, state, t)),
                ],
              ],
              if (done.isNotEmpty) ...[
                SectionHeader(t(context, 'completed')),
                ...done.map((t) => _taskTile(context, state, t)),
              ],
            ],
          ],
        );

        Widget body = SafeArea(
          bottom: false,
          child: Stack(
            children: [
              list,
              Positioned(
                right: 20,
                bottom: 24,
                child: _addFab(context),
              ),
            ],
          ),
        );

        if (widget.embedded) return body;
        return Scaffold(body: body);
      },
    );
  }

  String _priorityLabel(BuildContext context, TaskPriority p) {
    switch (p) {
      case TaskPriority.high:
        return t(context, 'highP');
      case TaskPriority.normal:
        return t(context, 'normalP');
      case TaskPriority.low:
        return t(context, 'lowP');
    }
  }

  Widget _addFab(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/task-new'),
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          gradient: AppColors.fabGradient,
          shape: BoxShape.circle,
          ),
        child: const Icon(Icons.add_rounded, color: Colors.white, size: 30),
      ),
    );
  }

  Widget _taskTile(BuildContext context, AppState state, Task task) {
    final isToday = task.dueTime != null &&
        task.dueTime!.isBefore(DateTime(
            DateTime.now().year, DateTime.now().month, DateTime.now().day + 1));
    final subtitle = task.done
        ? t(context, 'completed')
        : task.dueTime == null
            ? _priorityLabel(context, task.priority)
            : '${task.priorityLabel} · ${isToday ? Fmt.time12(task.dueTime!) : Fmt.relative(task.dueTime!)}';

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AppCard(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        child: Row(
          children: [
            GestureDetector(
              onTap: () => state.toggleTask(task),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: task.done ? AppColors.accent : Colors.transparent,
                  border: Border.all(
                    color: task.done ? AppColors.accent : AppColors.border,
                    width: 2,
                  ),
                ),
                child: task.done
                    ? const Icon(Icons.check_rounded,
                        size: 18, color: Colors.white)
                    : null,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.title,
                    style: task.done
                        ? AppText.cardTitle.copyWith(
                            decoration: TextDecoration.lineThrough,
                            color: AppColors.textFaint)
                        : AppText.cardTitle,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      if (task.priority == TaskPriority.high && !task.done)
                        Container(
                          width: 6,
                          height: 6,
                          margin: const EdgeInsets.only(right: 6),
                          decoration: BoxDecoration(
                            color: AppColors.warning,
                            shape: BoxShape.circle,
                          ),
                        ),
                      Text(subtitle, style: AppText.caption),
                    ],
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: () => state.deleteTask(task.id),
              child: Icon(Icons.close_rounded,
                  size: 18, color: AppColors.textFaint),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniCalendar extends StatelessWidget {
  final List<DateTime> week;
  final DateTime? selected;
  final Set<int> daysWithTasks;
  final ValueChanged<DateTime> onPick;
  final bool Function(DateTime, DateTime) sameDay;

  const _MiniCalendar({
    required this.week,
    required this.selected,
    required this.daysWithTasks,
    required this.onPick,
    required this.sameDay,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    return Row(
      children: [
        for (var i = 0; i < week.length; i++)
          Expanded(child: _cell(context, week[i], i, now)),
      ],
    );
  }

  Widget _cell(BuildContext context, DateTime d, int i, DateTime now) {
    final isToday = sameDay(d, now);
    final isSelected = selected != null && sameDay(d, selected!);
    final hasTasks = daysWithTasks.contains(i);
    return GestureDetector(
      onTap: () => onPick(d),
      child: Container(
        height: 68,
        margin: const EdgeInsets.symmetric(horizontal: 3),
        decoration: BoxDecoration(
          color: isSelected ? null : AppColors.surface,
          gradient: isSelected ? AppColors.fabGradient : null,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? Colors.transparent
                : isToday
                    ? AppColors.accent
                    : AppColors.borderSoft,
            width: 1.2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.accent.withOpacity(0.35),
                    blurRadius: 12,
                    offset: const Offset(0, 5),
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              Fmt.weekdayName(d).substring(0, 3).toUpperCase(),
              style: AppText.caption.copyWith(
                fontSize: 9.5,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
                color: isSelected ? Colors.white70 : AppColors.textFaint,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${d.day}',
              style: AppText.cardTitle.copyWith(
                fontSize: 15,
                color: isSelected
                    ? Colors.white
                    : isToday
                        ? AppColors.accentSoft
                        : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 5),
            hasTasks
                ? Container(
                    width: 4,
                    height: 4,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isSelected ? Colors.white : AppColors.accentSoft,
                    ),
                  )
                : const SizedBox(height: 4),
          ],
        ),
      ),
    );
  }
}
