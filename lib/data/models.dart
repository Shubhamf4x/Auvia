enum ItemType { screenshot, document, note, receipt, ticket }

extension ItemTypeX on ItemType {
  String get label {
    switch (this) {
      case ItemType.screenshot:
        return 'Screenshot';
      case ItemType.document:
        return 'Document';
      case ItemType.note:
        return 'Note';
      case ItemType.receipt:
        return 'Receipt';
      case ItemType.ticket:
        return 'Ticket';
    }
  }
}

enum TaskPriority { low, normal, high }

class LifeItem {
  final String id;
  ItemType type;
  String title;
  String category;
  String content;
  String? aiSummary;
  List<String> keyPoints;
  String? imagePath;
  bool important;
  final DateTime createdAt;

  LifeItem({
    required this.id,
    required this.type,
    required this.title,
    required this.category,
    required this.content,
    this.aiSummary,
    List<String>? keyPoints,
    this.imagePath,
    this.important = false,
    required this.createdAt,
  }) : keyPoints = keyPoints ?? [];

  bool matches(String query) {
    final q = query.toLowerCase().trim();
    if (q.isEmpty) return false;
    return title.toLowerCase().contains(q) ||
        content.toLowerCase().contains(q) ||
        category.toLowerCase().contains(q) ||
        type.label.toLowerCase().contains(q);
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.index,
        'title': title,
        'category': category,
        'content': content,
        'aiSummary': aiSummary,
        'keyPoints': keyPoints,
        'imagePath': imagePath,
        'important': important,
        'createdAt': createdAt.millisecondsSinceEpoch,
      };

  static LifeItem fromJson(Map<String, dynamic> j) => LifeItem(
        id: j['id'],
        type: ItemType.values[j['type']],
        title: j['title'],
        category: j['category'],
        content: j['content'],
        aiSummary: j['aiSummary'],
        keyPoints: (j['keyPoints'] as List?)?.cast<String>() ?? [],
        imagePath: j['imagePath'],
        important: j['important'] ?? false,
        createdAt: DateTime.fromMillisecondsSinceEpoch(j['createdAt']),
      );
}

class Task {
  final String id;
  String title;
  TaskPriority priority;
  DateTime? dueTime;
  bool done;
  final DateTime createdAt;

  Task({
    required this.id,
    required this.title,
    this.priority = TaskPriority.normal,
    this.dueTime,
    this.done = false,
    required this.createdAt,
  });

  String get priorityLabel {
    switch (priority) {
      case TaskPriority.high:
        return 'High priority';
      case TaskPriority.normal:
        return 'Normal';
      case TaskPriority.low:
        return 'Low priority';
    }
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'priority': priority.index,
        'dueTime': dueTime?.millisecondsSinceEpoch,
        'done': done,
        'createdAt': createdAt.millisecondsSinceEpoch,
      };

  static Task fromJson(Map<String, dynamic> j) => Task(
        id: j['id'],
        title: j['title'],
        priority: TaskPriority.values[j['priority'] ?? 1],
        dueTime: j['dueTime'] == null
            ? null
            : DateTime.fromMillisecondsSinceEpoch(j['dueTime']),
        done: j['done'] ?? false,
        createdAt: DateTime.fromMillisecondsSinceEpoch(j['createdAt']),
      );
}

enum RepeatMode { never, daily, weekly, monthly }

extension RepeatModeX on RepeatMode {
  String get label {
    switch (this) {
      case RepeatMode.never:
        return 'Never';
      case RepeatMode.daily:
        return 'Daily';
      case RepeatMode.weekly:
        return 'Weekly';
      case RepeatMode.monthly:
        return 'Monthly';
    }
  }
}

class Reminder {
  final String id;
  String title;
  DateTime when;
  RepeatMode repeat;
  bool fired;
  final DateTime createdAt;

  Reminder({
    required this.id,
    required this.title,
    required this.when,
    this.repeat = RepeatMode.never,
    this.fired = false,
    required this.createdAt,
  });

  String get repeatLabel {
    switch (repeat) {
      case RepeatMode.never:
        return 'Never';
      case RepeatMode.daily:
        return 'Daily';
      case RepeatMode.weekly:
        return 'Weekly';
      case RepeatMode.monthly:
        return 'Monthly';
    }
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'when': when.millisecondsSinceEpoch,
        'repeat': repeat.index,
        'fired': fired,
        'createdAt': createdAt.millisecondsSinceEpoch,
      };

  static Reminder fromJson(Map<String, dynamic> j) => Reminder(
        id: j['id'],
        title: j['title'],
        when: DateTime.fromMillisecondsSinceEpoch(j['when']),
        repeat: RepeatMode.values[j['repeat'] ?? 0],
        fired: j['fired'] ?? false,
        createdAt: DateTime.fromMillisecondsSinceEpoch(j['createdAt']),
      );
}

class ChatMessage {
  final String id;
  final String text;
  final bool fromUser;
  final DateTime at;

  ChatMessage({
    required this.id,
    required this.text,
    required this.fromUser,
    required this.at,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'text': text,
        'fromUser': fromUser,
        'at': at.millisecondsSinceEpoch,
      };

  static ChatMessage fromJson(Map<String, dynamic> j) => ChatMessage(
        id: j['id'],
        text: j['text'],
        fromUser: j['fromUser'],
        at: DateTime.fromMillisecondsSinceEpoch(j['at']),
      );
}
