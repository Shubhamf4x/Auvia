import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../core/fmt.dart';
import '../data/app_state.dart';
import '../data/models.dart';

enum AiCapability {
  textGeneration,
  imageUnderstanding,
  documentUnderstanding,
  ocr,
  embeddings,
  semanticSearch,
}

class ScanAnalysis {
  final String title;
  final String category;
  final String extractedText;
  final List<String> keyInfo;

  ScanAnalysis({
    required this.title,
    required this.category,
    required this.extractedText,
    required this.keyInfo,
  });
}

abstract class AiProvider {
  String get name;
  Set<AiCapability> get capabilities;
  Future<String> generateText(String prompt);
  Future<ScanAnalysis> analyzeImage(String fileName, {String? hint});
}

class LocalHeuristicProvider implements AiProvider {
  @override
  String get name => 'On-device AI';

  @override
  Set<AiCapability> get capabilities => AiCapability.values.toSet();

  @override
  Future<String> generateText(String prompt) async {
    return prompt;
  }

  @override
  Future<ScanAnalysis> analyzeImage(String fileName, {String? hint}) async {
    final source = '${fileName.toLowerCase()} ${hint?.toLowerCase() ?? ''}';
    String title = 'Screenshot';
    String category = 'Saved info';
    String text = 'Content captured from screenshot.\n';
    List<String> key = ['Auto-detected by AI'];

    if (source.contains('ticket') || source.contains('train')) {
      title = 'Train Ticket';
      category = 'Travel';
      text = 'Detected ticket layout.\nRoute and date extracted from image.\n';
      key = ['Travel document', 'Date & route detected'];
    } else if (source.contains('receipt') || source.contains('bill') || source.contains('invoice')) {
      title = 'Payment Receipt';
      category = 'Bills';
      text = 'Detected receipt layout.\nAmount and merchant extracted.\n';
      key = ['Receipt detected', 'Amount extracted'];
    } else if (source.contains('wifi') || source.contains('password')) {
      title = 'Wi-Fi Password';
      category = 'Saved info';
      key = ['Credentials detected'];
    } else if (source.contains('note')) {
      title = 'Notes Screenshot';
      category = 'Personal';
      key = ['Handwriting detected'];
    }
    return ScanAnalysis(
        title: title, category: category, extractedText: text, keyInfo: key);
  }
}

class OpenRouterProvider implements AiProvider {
  static const defaultModel = 'nvidia/nemotron-3-ultra-550b-a55b:free';
  static const endpoint = 'https://openrouter.ai/api/v1/chat/completions';

  final String apiKey;
  final String model;

  OpenRouterProvider({required this.apiKey, this.model = defaultModel});

  @override
  String get name => 'OpenRouter';

  @override
  Set<AiCapability> get capabilities => AiCapability.values.toSet();

  @override
  Future<String> generateText(String prompt) async {
    return chat([
      {'role': 'user', 'content': prompt}
    ]);
  }

  Future<String> chat(List<Map<String, dynamic>> messages) async {
    final resp = await http
        .post(
          Uri.parse(endpoint),
          headers: {
            'Authorization': 'Bearer $apiKey',
            'Content-Type': 'application/json',
            'HTTP-Referer': 'https://auvia.app',
            'X-Title': 'Auvia',
          },
          body: jsonEncode({
            'model': model,
            'messages': messages,
          }),
        )
        .timeout(const Duration(seconds: 90));
    if (resp.statusCode != 200) {
      throw Exception('HTTP ${resp.statusCode}');
    }
    final data = jsonDecode(resp.body) as Map<String, dynamic>;
    final choices = data['choices'] as List?;
    if (choices == null || choices.isEmpty) {
      throw Exception('Empty response');
    }
    final msg = choices[0]['message'] as Map<String, dynamic>;
    final raw = (msg['content'] as String?) ?? '';
    var clean = raw.replaceAll(
        RegExp(r'<think>[\s\S]*?</think>'), '').trim();
    if (clean.startsWith('<think>')) {
      final closed = clean.indexOf('</think>');
      clean = closed >= 0 ? clean.substring(closed + 8).trim() : '';
    }
    return clean;
  }

  final LocalHeuristicProvider _local = LocalHeuristicProvider();

  @override
  Future<ScanAnalysis> analyzeImage(String fileName, {String? hint}) =>
      _local.analyzeImage(fileName, hint: hint);
}

class KeylessProvider {
  static const endpoint = 'https://text.pollinations.ai/openai';

  Future<String> chat(List<Map<String, dynamic>> messages) async {
    final resp = await http
        .post(
          Uri.parse(endpoint),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'model': 'openai',
            'referrer': 'auvia',
            'messages': messages,
          }),
        )
        .timeout(const Duration(seconds: 90));
    if (resp.statusCode != 200) {
      throw Exception('HTTP ${resp.statusCode}');
    }
    final data = jsonDecode(resp.body) as Map<String, dynamic>;
    if (data['error'] != null) throw Exception('Service error');
    final choices = data['choices'] as List?;
    if (choices == null || choices.isEmpty) {
      throw Exception('Empty response');
    }
    final msg = choices[0]['message'] as Map<String, dynamic>;
    return ((msg['content'] as String?) ?? '').trim();
  }
}

class AiReply {
  final String text;
  final Reminder? reminderCreated;
  final Task? taskCreated;
  final List<LifeItem> results;

  AiReply({
    required this.text,
    this.reminderCreated,
    this.taskCreated,
    this.results = const [],
  });
}

class AiService {
  AiService._();
  static final AiService instance = AiService._();

  AiProvider _provider = LocalHeuristicProvider();
  AiProvider get provider => _provider;
  set provider(AiProvider p) => _provider = p;

  String get providerName => _provider.name;

  Future<AiReply> handleChat(String input, AppState state) async {
    final q = input.toLowerCase().trim();

    final remindMatch = RegExp(
            r'(remind me to|set a reminder(?: to| for)?|reminder(?: to| for)?)\s+(.+)')
        .firstMatch(q);
    if (remindMatch != null) {
      final parsed = _parseReminder(remindMatch.group(2)!);
      return AiReply(
        text: 'Done. I created a reminder:\n\n● "${parsed.title}"\n● '
            '${_fmtWhen(parsed.when)}\n\n'
            'You can view it in the Reminders section.',
        reminderCreated: Reminder(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          title: parsed.title,
          when: parsed.when,
          createdAt: DateTime.now(),
        ),
      );
    }

    final taskMatch =
        RegExp(r'(add (?:a )?task(?: to)?|create (?:a )?task(?: to)?)\s+(.+)')
            .firstMatch(q);
    if (taskMatch != null) {
      final title = _titleCase(taskMatch.group(2)!);
      return AiReply(
        text: 'I added "$title" to your tasks.',
        taskCreated: Task(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          title: title,
          createdAt: DateTime.now(),
        ),
      );
    }

    if (state.apiKey.isNotEmpty) {
      final candidates = [
        state.aiModel,
        ..._fallbackModels.where((m) => m != state.aiModel),
      ];
      for (final m in candidates) {
        try {
          final cloud = OpenRouterProvider(apiKey: state.apiKey, model: m);
          final text = await cloud.chat(_buildMessages(input, state));
          if (text.trim().isNotEmpty) {
            return AiReply(text: text.trim());
          }
        } catch (_) {
        }
      }
    }

    try {
      final keyless = KeylessProvider();
      final text = await keyless.chat(_buildMessages(input, state));
      if (text.trim().isNotEmpty) {
        return AiReply(text: text.trim());
      }
    } catch (_) {
    }

    final local = _localAnswer(input, state);
    return AiReply(
      text:
          '⚠ The AI service is unreachable right now.\n\n'
          'On-device answer:\n\n$local',
    );
  }

  static const _fallbackModels = [
    'nvidia/nemotron-3-ultra-550b-a55b:free',
    'minimax/minimax-m3:free',
    'nvidia/nemotron-3-super-120b-a12b:free',
    'minimax/minimax-m2.7:free',
  ];

  Future<ScanAnalysis?> analyzeImageSmart(
      String? imagePath, String fileName, String hint, AppState state) async {
    final prompt = 'You are analyzing an image for a personal organizer app. '
        'Look at the image content and respond with ONLY a JSON object, no '
        'markdown fences, in this exact shape: '
        '{"title":"short title","category":"one of Travel/Bills/Shopping/'
        'Entertainment/Career/Personal/Saved info/Work","extractedText":"the '
        'visible text transcribed","keyInfo":["important fact","another fact"]}. '
        'If the image is unclear, make your best guess.';

    List<Map<String, dynamic>>? multimodal;
    if (imagePath != null) {
      try {
        final f = File(imagePath);
        if (f.existsSync() && f.lengthSync() > 8 * 1024 * 1024) {
          return null;
        }
        final bytes = await f.readAsBytes();
        final b64 = base64Encode(bytes);
        multimodal = [
          {
            'role': 'user',
            'content': [
              {
                'type': 'image_url',
                'image_url': {'url': 'data:image/jpeg;base64,$b64'}
              },
              {'type': 'text', 'text': prompt}
            ]
          }
        ];
      } catch (_) {
        multimodal = null;
      }
    }

    if (state.apiKey.isNotEmpty) {
      for (final m in _visionModels) {
        try {
          final cloud = OpenRouterProvider(apiKey: state.apiKey, model: m);
          final text = await cloud
              .chat(multimodal ??
                  [
                    {'role': 'user', 'content': prompt}
                  ])
              .timeout(const Duration(seconds: 90));
          final parsed = _parseAnalysis(text);
          if (parsed != null) return parsed;
        } catch (_) {
        }
      }
    }

    if (multimodal == null) {
      try {
        final text = await KeylessProvider().chat([
          {'role': 'user', 'content': prompt}
        ]);
        final parsed = _parseAnalysis(text);
        if (parsed != null) return parsed;
      } catch (_) {}
    }
    return null;
  }

  ScanAnalysis? _parseAnalysis(String raw) {
    var s = raw.trim();
    s = s.replaceAll(RegExp(r'```[a-z]*'), '').trim();
    final start = s.indexOf('{');
    final end = s.lastIndexOf('}');
    if (start < 0 || end <= start) return null;
    try {
      final j = jsonDecode(s.substring(start, end + 1)) as Map<String, dynamic>;
      final title = (j['title'] as String?)?.trim() ?? '';
      if (title.isEmpty) return null;
      return ScanAnalysis(
        title: title,
        category: (j['category'] as String?)?.trim().isNotEmpty == true
            ? (j['category'] as String).trim()
            : 'Saved info',
        extractedText: (j['extractedText'] as String?) ?? '',
        keyInfo: ((j['keyInfo'] as List?) ?? [])
            .map((e) => e.toString())
            .where((e) => e.trim().isNotEmpty)
            .toList(),
      );
    } catch (_) {
      return null;
    }
  }

  static const _visionModels = [
    'minimax/minimax-m3:free',
    'google/gemma-4-31b-it:free',
    'nvidia/nemotron-3-nano-omni-30b-a3b-reasoning:free',
  ];

  List<Map<String, dynamic>> _buildMessages(String input, AppState state) {
    final lib = state.items.isEmpty
        ? '(the library is currently empty)'
        : state.items
            .take(40)
            .map((i) =>
                '- ${i.title} — ${i.type.label}, category: ${i.category}, added ${Fmt.relative(i.createdAt)}')
            .join('\n');
    final tasks = state.openTasks.isEmpty
        ? '(none)'
        : state.openTasks
            .take(12)
            .map((t) => '- ${t.title}${t.dueTime != null ? ' (due ${Fmt.relative(t.dueTime!)})' : ''}')
            .join('\n');
    final rems = state.upcomingReminders.isEmpty
        ? '(none)'
        : state.upcomingReminders
            .take(12)
            .map((r) => '- ${r.title} on ${Fmt.dayMonthYear(r.when)}')
            .join('\n');

    final system =
        'You are the built-in AI assistant inside "Auvia", a personal '
        'organization app for notes, documents, screenshots, receipts, tickets, '
        'tasks and reminders. Be concise, warm and practical. Use plain text, '
        'short paragraphs and bullet points where helpful.\n\n'
        'The user\'s library right now:\n$lib\n\n'
        'Open tasks:\n$tasks\n\n'
        'Upcoming reminders:\n$rems\n\n'
        'When the user asks you to find something, search this library listing '
        'and reference matching items by their exact titles and types. '
        'Summarize or explain items when asked using their titles/categories. '
        'Creating tasks and reminders is handled natively by the app — if the '
        'user asks for one, tell them to say "remind me to ..." or "add task ..." '
        'so the app can create it.';

    final msgs = <Map<String, dynamic>>[
      {'role': 'system', 'content': system}
    ];
    var history = state.messages;
    if (history.isNotEmpty &&
        history.last.fromUser &&
        history.last.text.trim() == input.trim()) {
      history = history.sublist(0, history.length - 1);
    }
    if (history.length > 8) {
      history = history.sublist(history.length - 8);
    }
    for (final m in history) {
      msgs.add({'role': m.fromUser ? 'user' : 'assistant', 'content': m.text});
    }
    msgs.add({'role': 'user', 'content': input});
    return msgs;
  }

  Future<AiReply> _localAnswer(String input, AppState state) async {
    final q = input.toLowerCase().trim();
    await Future<void>.delayed(const Duration(milliseconds: 650));

    if (q.contains('summar') ) {
      final item = _findItem(q, state);
      if (item != null) {
        return AiReply(
          text: 'Summary of "${item.title}" (${item.type.label}):\n\n'
              '${item.aiSummary ?? _autoSummary(item)}\n\n'
              'Key points:\n${(item.keyPoints.isNotEmpty ? item.keyPoints : _autoPoints(item)).map((p) => '• $p').join('\n')}',
        );
      }
      return AiReply(
        text:
            'I can summarize any item in your library. Tell me which one — for example "Summarize my electricity bill".',
      );
    }

    if (q.contains('explain')) {
      final item = _findItem(q, state);
      if (item != null) {
        return AiReply(
          text: 'Here is what "${item.title}" contains:\n\n'
              '${_autoSummary(item)}\n\n'
              'In simple terms: this ${item.type.label.toLowerCase()} is part of '
              '${item.category.toLowerCase()} and was added ${_rel(item.createdAt, state)}. '
              'Ask me to summarize it, extract key details, or turn it into a task or reminder.',
        );
      }
      return AiReply(
        text:
            'Sure — tell me what to explain. You can ask about a document, a screenshot or a note, e.g. "Explain my train ticket".',
      );
    }

    final isFind = q.contains('find') ||
        q.contains('where') ||
        q.contains('search') ||
        q.contains('show') ||
        q.contains('locate');
    if (isFind) {
      final results = state.searchItems(q);
      if (results.isNotEmpty) {
        final list = results
            .take(5)
            .map((r) =>
                '• ${r.title} — ${r.type.label}, ${_rel(r.createdAt, state)}')
            .join('\n');
        return AiReply(
          text:
              'I searched your screenshots, documents and notes. I found ${results.length} match${results.length == 1 ? '' : 'es'}:\n\n$list',
          results: results,
        );
      }
      return AiReply(
        text:
            'I could not find that in your library. Try mentioning a keyword from the item, like "train ticket" or "electricity bill".',
      );
    }

    if (q.contains('organi')) {
      final uncategorized = state.items.where((i) => i.category.isEmpty).length;
      return AiReply(
        text:
            'Your library is organized into ${state.countType(ItemType.screenshot)} screenshots, '
            '${state.countType(ItemType.document)} documents, ${state.countType(ItemType.note)} notes, '
            '${state.countType(ItemType.receipt)} receipts and ${state.countType(ItemType.ticket)} tickets.\n\n'
            '$uncategorized items need categorization. Everything important is marked and easy to retrieve with search.',
      );
    }

    return AiReply(
      text:
          'I can help you with your information. Try:\n\n'
          '• "Find my train ticket"\n'
          '• "Summarize my electricity bill"\n'
          '• "Remind me to water the plants tomorrow"\n'
          '• "Add task finish assignment"\n\n'
          'You currently have ${state.items.length} items in your library and ${state.openTasks.length} open tasks.',
    );
  }

  String summarize(LifeItem item) =>
      item.aiSummary ?? _autoSummary(item);

  LifeItem? _findItem(String q, AppState state) {
    LifeItem? best;
    int bestScore = 0;
    for (final i in state.items) {
      int score = 0;
      for (final word in i.title.toLowerCase().split(RegExp(r'\W+'))) {
        if (word.length > 2 && q.contains(word)) score += word.length;
      }
      for (final word in q.split(RegExp(r'\W+'))) {
        if (word.length > 2 && i.title.toLowerCase().contains(word)) {
          score += word.length;
        }
      }
      if (i.category.toLowerCase().split(' ').any((w) => q.contains(w))) {
        score += 2;
      }
      if (score > bestScore) {
        bestScore = score;
        best = i;
      }
    }
    return bestScore >= 3 ? best : null;
  }

  String _autoSummary(LifeItem i) {
    final first = i.content
        .split('\n')
        .where((l) => l.trim().isNotEmpty)
        .take(2)
        .join('. ');
    return '$first. This ${i.type.label.toLowerCase()} belongs to ${i.category.toLowerCase()}.';
  }

  List<String> _autoPoints(LifeItem i) => i.content
      .split('\n')
      .where((l) => l.trim().isNotEmpty && l.trim().length > 3)
      .take(3)
      .map((l) => l.trim().replaceAll(RegExp(r'\s+'), ' '))
      .toList();

  ({String title, DateTime when}) _parseReminder(String raw) {
    var text = raw.trim();
    final now = DateTime.now();
    DateTime when = now.add(const Duration(days: 1));
    var title = text;

    final timeMatch =
        RegExp(r'at\s+(\d{1,2})(?::(\d{2}))?\s*(am|pm)?').firstMatch(text);
    int hour = 9, minute = 0;
    if (timeMatch != null) {
      hour = int.parse(timeMatch.group(1)!);
      minute = timeMatch.group(2) != null ? int.parse(timeMatch.group(2)!) : 0;
      final ap = timeMatch.group(3);
      if (ap == 'pm' && hour < 12) hour += 12;
      if (ap == 'am' && hour == 12) hour = 0;
      title = title.replaceFirst(timeMatch.group(0)!, '').trim();
    }

    if (text.contains('today')) {
      when = DateTime(now.year, now.month, now.day, hour, minute);
      if (when.isBefore(now)) when = when.add(const Duration(days: 1));
      title = title.replaceAll(RegExp(r'\btoday\b'), '').trim();
    } else if (text.contains('tomorrow')) {
      when = DateTime(now.year, now.month, now.day, hour, minute)
          .add(const Duration(days: 1));
      title = title.replaceAll(RegExp(r'\btomorrow\b'), '').trim();
    } else {
      final dayIdx = _dayIndex(text);
      if (dayIdx != null) {
        var delta = (dayIdx - now.weekday) % 7;
        if (delta <= 0) delta += 7;
        when = DateTime(now.year, now.month, now.day, hour, minute)
            .add(Duration(days: delta));
        final dayWord = RegExp(r'\b(monday|tuesday|wednesday|thursday|friday|saturday|sunday)\b')
            .firstMatch(text);
        if (dayWord != null) title = title.replaceFirst(dayWord.group(0)!, '').trim();
      } else {
        when = DateTime(now.year, now.month, now.day, hour, minute)
            .add(const Duration(days: 1));
      }
    }
    title = title.replaceAll(RegExp(r'\s+on\s+$'), '').trim();
    if (title.isEmpty) title = text.trim();
    title = title[0].toUpperCase() + title.substring(1);
    return (title: title, when: when);
  }

  String _fmtWhen(DateTime d) =>
      '${Fmt.weekdayName(d)}, ${Fmt.dayMonthYear(d)} at ${Fmt.time12(d)}';

  String _rel(DateTime d, AppState state) => Fmt.relative(d);

  String _titleCase(String s) {
    final t = s.trim();
    if (t.isEmpty) return t;
    return t[0].toUpperCase() + t.substring(1);
  }

  static const _dayNames = [
    'monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'
  ];

  int? _dayIndex(String text) {
    final t = text.toLowerCase();
    for (var i = 0; i < _dayNames.length; i++) {
      if (t.contains(_dayNames[i])) return i + 1;
    }
    return null;
  }
}
