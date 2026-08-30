class Fmt {
  static const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];
  static const fullDays = [
    'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'
  ];

  static String monthDay(DateTime d) =>
      '${months[d.month - 1]} ${d.day}';

  static String dayMonthYear(DateTime d) =>
      '${d.day} ${months[d.month - 1]} ${d.year}';

  static String time12(DateTime d) {
    final h = d.hour % 12 == 0 ? 12 : d.hour % 12;
    final am = d.hour < 12 ? 'AM' : 'PM';
    final m = d.minute.toString().padLeft(2, '0');
    return '$h:$m $am';
  }

  static String dateWithTime(DateTime d) =>
      '${dayMonthYear(d)} · ${time12(d)}';

  static String relative(DateTime d) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(d.year, d.month, d.day);
    final diff = today.difference(day).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    if (diff > 1 && diff < 7) return '${diff}d ago';
    if (diff < 0 && diff > -1) return 'Tomorrow';
    if (diff <= -2) return 'In ${-diff}d';
    return monthDay(d);
  }

  static String weekdayName(DateTime d) => fullDays[d.weekday - 1];

  static String greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }
}
