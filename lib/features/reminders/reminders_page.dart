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

class RemindersPage extends StatelessWidget {
  const RemindersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return StateRefresher(
      builder: (context, state) {
        final list = state.upcomingReminders;
        return Scaffold(
          body: SafeArea(
            bottom: false,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
              children: [
                TopBar(title: t(context, 'remindersT'), showProfile: false),
                const SizedBox(height: 10),
                if (list.isEmpty)
                  AppCard(
                    child: Column(
                      children: [
                        Icon(Icons.alarm_rounded,
                            size: 40, color: AppColors.textFaint),
                        const SizedBox(height: 12),
                        Text(t(context, 'noReminders'), style: AppText.cardTitle),
                        const SizedBox(height: 6),
                        Text(
                            'Ask AI, or create one from the + menu.',
                            style: AppText.body),
                      ],
                    ),
                  )
                else
                  ...list.map((r) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: AppCard(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
                          child: Row(
                            children: [
                              Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF472B6)
                                      .withOpacity(0.14),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                      color: const Color(0xFFF472B6)
                                          .withOpacity(0.35)),
                                ),
                                child: const Icon(Icons.alarm_rounded,
                                    color: Color(0xFFF472B6), size: 21),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(r.title, style: AppText.cardTitle),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${Fmt.weekdayName(r.when)}, ${Fmt.dayMonthYear(r.when)} · ${Fmt.time12(r.when)} · ${_repeatLabel(context, r.repeat)}',
                                      style: AppText.caption,
                                    ),
                                  ],
                                ),
                              ),
                              GestureDetector(
                                onTap: () => state.deleteReminder(r.id),
                                child: Icon(Icons.close_rounded,
                                    size: 18, color: AppColors.textFaint),
                              ),
                            ],
                          ),
                        ),
                      )),
              ],
            ),
          ),
        );
      },
    );
  }
}
