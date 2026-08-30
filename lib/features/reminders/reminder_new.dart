import 'package:flutter/material.dart' hide RepeatMode;
import '../../core/fmt.dart';
import '../../core/l10n.dart';
import '../../core/theme.dart';
import '../../data/models.dart';
import '../../data/scope.dart';
import '../../widgets/common.dart';

String _repeatLabel(BuildContext context, RepeatMode m) {
  switch (m) {
    case RepeatMode.never: return t(context, 'never');
    case RepeatMode.daily: return t(context, 'daily');
    case RepeatMode.weekly: return t(context, 'weekly');
    case RepeatMode.monthly: return t(context, 'monthly');
  }
}

class ReminderNewScreen extends StatefulWidget {
  final String? prefilledTitle;
  const ReminderNewScreen({super.key, this.prefilledTitle});

  @override
  State<ReminderNewScreen> createState() => _ReminderNewScreenState();
}

class _ReminderNewScreenState extends State<ReminderNewScreen> {
  late final TextEditingController _title;
  DateTime _when =
      DateTime.now().add(const Duration(days: 1)).copyWith(hour: 10, minute: 0);
  RepeatMode _repeat = RepeatMode.never;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _title = TextEditingController(text: widget.prefilledTitle ?? '');
  }

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _when,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (d == null) return;
    if (!mounted) return;
    final t = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_when),
    );
    if (t == null) return;
    setState(() {
      _when = DateTime(d.year, d.month, d.day, t.hour, t.minute);
    });
  }

  void _save() {
    if (_saving) return;
    final state = AppScope.of(context);
    if (_title.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(t(context, 'reminderTitle'))));
      return;
    }
    setState(() => _saving = true);
    state.addReminder(_title.text.trim(), _when, repeat: _repeat);
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t(context, 'reminderSaved'))));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
          children: [
            TopBar(title: t(context, 'remindersT')),
            const SizedBox(height: 16),

            Text(t(context, 'reminderTitle'), style: AppText.label),
            const SizedBox(height: 8),
            TextField(
              controller: _title,
              autofocus: widget.prefilledTitle == null,
              style: AppText.bodyStrong,
              decoration:
                  const InputDecoration(hintText: 'Pay electricity bill'),
            ),

            const SizedBox(height: 20),
            Text(t(context, 'dateL'), style: AppText.label),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _dateChip(t(context, 'today'), 0),
                _dateChip(t(context, 'tomorrow'), 1),
                _dateChip(t(context, 'weekly'), _daysUntil(5)),
              ],
            ),
            const SizedBox(height: 10),
            GestureDetector(
              onTap: _pickDate,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppRadius.field),
                  border: Border.all(color: AppColors.borderSoft),
                ),
                child: Row(
                  children: [
                    Icon(Icons.calendar_today_rounded,
                        color: AppColors.textSecondary, size: 20),
                    const SizedBox(width: 12),
                    Text(
                      '${Fmt.weekdayName(_when)} · ${Fmt.dateWithTime(_when)}',
                      style: AppText.bodyStrong,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),
            Text(t(context, 'repeat'), style: AppText.label),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () => _pickRepeat(),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppRadius.field),
                  border: Border.all(color: AppColors.borderSoft),
                ),
                child: Row(
                  children: [
                    Text(_repeatLabel(context, _repeat), style: AppText.bodyStrong),
                    const Spacer(),
                    Icon(Icons.chevron_right_rounded,
                        color: AppColors.textFaint),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 28),
            PrimaryButton(
              label: t(context, 'saveReminder'),
              icon: Icons.alarm_rounded,
              onTap: _save,
            ),
          ],
        ),
      ),
    );
  }

  int _daysUntil(int weekday) {
    final now = DateTime.now().weekday;
    return (weekday - now) % 7 == 0 ? 7 : (weekday - now) % 7;
  }

  Widget _dateChip(String label, int offsetDays) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _when = DateTime(
                  DateTime.now().year,
                  DateTime.now().month,
                  DateTime.now().day + offsetDays,
                  _when.hour,
                  _when.minute)
              .copyWith();
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: AppColors.surfaceAlt,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border),
        ),
        child: Text(label,
            style: AppText.label.copyWith(color: AppColors.textPrimary)),
      ),
    );
  }

  Future<void> _pickRepeat() async {
    final choice = await showModalBottomSheet<RepeatMode>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(height: 14),
            Text(t(context, 'repeat'), style: AppText.sectionHeading),
            SizedBox(height: 8),
            ...RepeatMode.values.map(
              (m) => ListTile(
                title: Text(_repeatLabel(context, m), style: AppText.bodyStrong),
                trailing: m == _repeat
                    ? Icon(Icons.check_rounded,
                        color: AppColors.accentSoft)
                    : null,
                onTap: () => Navigator.pop(ctx, m),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
    if (choice != null) setState(() => _repeat = choice);
  }
}
