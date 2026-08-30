import 'package:flutter/material.dart';
import '../../core/fmt.dart';
import '../../core/l10n.dart';
import '../../core/theme.dart';
import '../../data/models.dart';
import '../../data/scope.dart';
import '../../widgets/common.dart';

class TaskNewScreen extends StatefulWidget {
  const TaskNewScreen({super.key});

  @override
  State<TaskNewScreen> createState() => _TaskNewScreenState();
}

class _TaskNewScreenState extends State<TaskNewScreen> {
  final _title = TextEditingController();
  TaskPriority _priority = TaskPriority.normal;
  int _dayOffset = 0;
  DateTime? _customDate;
  TimeOfDay _time = const TimeOfDay(hour: 17, minute: 0);
  bool _saving = false;

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  DateTime? get _due {
    if (_dayOffset == -1) return null;
    DateTime day;
    if (_dayOffset == -2 && _customDate != null) {
      day = DateTime(
          _customDate!.year, _customDate!.month, _customDate!.day);
    } else {
      final now = DateTime.now();
      day = DateTime(now.year, now.month, now.day)
          .add(Duration(days: _dayOffset.clamp(0, 3650)));
    }
    return DateTime(day.year, day.month, day.day, _time.hour, _time.minute);
  }

  Future<void> _pickTime() async {
    final t = await showTimePicker(context: context, initialTime: _time);
    if (t != null) setState(() => _time = t);
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final d = await showDatePicker(
      context: context,
      initialDate: _customDate ?? now,
      firstDate: now.subtract(const Duration(days: 1)),
      lastDate: now.add(const Duration(days: 730)),
    );
    if (d == null) return;
    setState(() {
      _customDate = d;
      _dayOffset = -2;
    });
  }

  void _save() {
    if (_saving) return;
    if (_title.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter a task title')));
      return;
    }
    setState(() => _saving = true);
    final state = AppScope.of(context);
    state.addTask(_title.text.trim(), priority: _priority, due: _due);
    Navigator.pop(context);
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(t(context, 'taskAdded'))));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
          children: [
            TopBar(title: t(context, 'newTask')),
            const SizedBox(height: 16),
            Text(t(context, 'taskTitle'), style: AppText.label),
            const SizedBox(height: 8),
            TextField(
              controller: _title,
              autofocus: true,
              style: AppText.bodyStrong,
              decoration: const InputDecoration(hintText: 'Submit application'),
            ),
            const SizedBox(height: 20),
            Text(t(context, 'priority'), style: AppText.label),
            const SizedBox(height: 8),
            Row(
              children: [
                _pChip(t(context, 'low'), TaskPriority.low),
                const SizedBox(width: 8),
                _pChip(t(context, 'normal'), TaskPriority.normal),
                const SizedBox(width: 8),
                _pChip(t(context, 'high'), TaskPriority.high),
              ],
            ),
            const SizedBox(height: 20),
            Text(t(context, 'due'), style: AppText.label),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _dChip(t(context, 'noDate'), -1),
                _dChip(t(context, 'today'), 0),
                _dChip(t(context, 'tomorrow'), 1),
                _dateChip(),
              ],
            ),
            if (_dayOffset != -1) ...[
              const SizedBox(height: 10),
              GestureDetector(
                onTap: _pickTime,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 15),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppRadius.field),
                    border: Border.all(color: AppColors.borderSoft),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.schedule_rounded,
                          color: AppColors.textSecondary, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          '${_dayLabel()} · ${_time.format(context)}',
                          style: AppText.bodyStrong,
                        ),
                      ),
                      Icon(Icons.chevron_right_rounded,
                          color: AppColors.textFaint),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 28),
            PrimaryButton(
              label: t(context, 'addTask'),
              icon: Icons.check_rounded,
              onTap: _save,
            ),
            if (_due != null) ...[
              const SizedBox(height: 14),
              Center(
                child: Text(
                  'Due ${Fmt.dateWithTime(_due!)}',
                  style: AppText.caption.copyWith(color: AppColors.textFaint),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _pChip(String label, TaskPriority p) {
    final selected = _priority == p;
    final color = p == TaskPriority.high
        ? AppColors.warning
        : p == TaskPriority.low
            ? AppColors.textFaint
            : AppColors.accentSoft;
    return GestureDetector(
      onTap: () => setState(() => _priority = p),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.accentDim : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: selected ? color : AppColors.borderSoft, width: 1.4),
        ),
        child: Text(label,
            style: AppText.label.copyWith(
                color: selected ? color : AppColors.textSecondary)),
      ),
    );
  }

  Widget _dChip(String label, int offset) {
    final selected = _dayOffset == offset;
    return GestureDetector(
      onTap: () => setState(() => _dayOffset = offset),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.accentDim : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: selected ? AppColors.accent : AppColors.borderSoft,
              width: 1.4),
        ),
        child: Text(label,
            style: AppText.label.copyWith(
                color: selected
                    ? AppColors.accentSoft
                    : AppColors.textSecondary)),
      ),
    );
  }

  Widget _dateChip() {
    final selected = _dayOffset == -2;
    return GestureDetector(
      onTap: _pickDate,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.accentDim : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: selected ? AppColors.accent : AppColors.borderSoft,
              width: 1.4),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.calendar_month_rounded,
                size: 16,
                color: selected
                    ? AppColors.accentSoft
                    : AppColors.textSecondary),
            const SizedBox(width: 6),
            Text(t(context, 'calendar'),
                style: AppText.label.copyWith(
                    color: selected
                        ? AppColors.accentSoft
                        : AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }

  String _dayLabel() {
    if (_dayOffset == -2 && _customDate != null) {
      return '${Fmt.weekdayName(_customDate!)}, ${Fmt.dayMonthYear(_customDate!)}';
    }
    if (_dayOffset == 0) return 'Today';
    return 'Tomorrow';
  }
}
