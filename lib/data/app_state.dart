import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/secrets.dart';
import 'models.dart';

class AppState extends ChangeNotifier {
  static const _kItems = 'alu_items';
  static const _kTasks = 'alu_tasks';
  static const _kReminders = 'alu_reminders';
  static const _kMessages = 'alu_messages';
  static const _kMigrated = 'alu_migrated_v2';
  static const _kName = 'alu_name';
  static const _kEmail = 'alu_email';
  static const _kAvatar = 'alu_avatar';
  static const _kNotifAsked = 'alu_notif_asked';
  static const _kAppLock = 'alu_app_lock';
  static const _kBiometrics = 'alu_biometrics';
  static const _kTheme = 'alu_theme';
  static const _kLang = 'alu_lang';
  static const _kCustomCats = 'alu_custom_cats';
  static const _kHiddenCats = 'alu_hidden_cats';
  static const _kAiModel = 'alu_ai_model';
  static const _ssApiKey = 'auvia_ai_key';

  /// Input limits (single validation choke point for user content).
  static const maxTitleLength = 200;
  static const maxBodyLength = 20000;
  static const maxCategoryLength = 40;

  List<LifeItem> items = [];
  List<Task> tasks = [];
  List<Reminder> reminders = [];
  List<ChatMessage> messages = [];
  List<String> customCategories = [];
  List<String> hiddenCategories = [];

  String userName = 'Guest';
  String userEmail = 'you@local';
  String? avatarPath;
  bool appLockEnabled = false;
  bool biometricsEnabled = false;
  bool notifPermAsked = false;
  String themeKey = 'light';
  String langCode = 'en';

  /// AI gateway key. Lives in Keystore-backed secure storage, never in
  /// plaintext prefs. Falls back to the compiled default until the user
  /// overrides it (or clears it).
  String apiKey = Secrets.compiledAiKey;
  String aiModel = Secrets.compiledAiModel;

  /// Runtime only: cleared on every app start.
  bool sessionUnlocked = false;

  static const _secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  /// Sanitizes user text: trims, strips control characters and caps length.
  static String _sanitize(String raw, int maxLen) {
    var s = raw.trim().replaceAll(RegExp(r'[\x00-\x08\x0B\x0C\x0E-\x1F]'), '');
    if (s.length > maxLen) s = s.substring(0, maxLen);
    return s;
  }

  /// Category names must never contain the '|' storage delimiter.
  static String _sanitizeCategory(String raw) =>
      _sanitize(raw, maxCategoryLength).replaceAll('|', '/');

  late SharedPreferences _prefs;

  Future<void> load() async {
    _prefs = await SharedPreferences.getInstance();

    items = _decode(_kItems, LifeItem.fromJson);
    tasks = _decode(_kTasks, Task.fromJson);
    reminders = _decode(_kReminders, Reminder.fromJson);
    messages = _decode(_kMessages, ChatMessage.fromJson);

    // One-time migration: remove pre-1.4 sample content.
    if (!(_prefs.getBool(_kMigrated) ?? false)) {
      const sampleItems = {'s1', 's2', 'd1', 'r1', 't1', 'n1', 'n2'};
      const sampleTasks = {'tk1', 'tk2', 'tk3', 'tk4'};
      items.removeWhere((i) => sampleItems.contains(i.id));
      tasks.removeWhere((t) => sampleTasks.contains(t.id));
      reminders.removeWhere((r) => r.id == 'rm1');
      messages.clear();
      await _saveAll();
      await _prefs.setBool(_kMigrated, true);
    }

    userName =
        _sanitize(_prefs.getString(_kName) ?? 'Guest', maxTitleLength);
    userEmail = _prefs.getString(_kEmail) ?? 'you@local';
    avatarPath = _prefs.getString(_kAvatar);
    notifPermAsked = _prefs.getBool(_kNotifAsked) ?? false;
    appLockEnabled = _prefs.getBool(_kAppLock) ?? false;
    biometricsEnabled = _prefs.getBool(_kBiometrics) ?? false;
    themeKey = _prefs.getString(_kTheme) ?? 'light';
    langCode = _prefs.getString(_kLang) ?? 'en';
    customCategories =
        (_prefs.getString(_kCustomCats) ?? '')
            .split('|')
            .where((s) => s.trim().isNotEmpty)
            .toList();
    hiddenCategories =
        (_prefs.getString(_kHiddenCats) ?? '')
            .split('|')
            .where((s) => s.trim().isNotEmpty)
            .toList();
    aiModel = _prefs.getString(_kAiModel) ?? Secrets.compiledAiModel;
    // The key lives in Keystore-backed secure storage; prefs are never used.
    try {
      final stored = await _secureStorage.read(key: _ssApiKey);
      if (stored != null && stored.trim().isNotEmpty) {
        apiKey = stored.trim();
      } else {
        apiKey = Secrets.compiledAiKey;
      }
    } catch (_) {
      // Secure storage unavailable (rare device/OS issue) — fall back to
      // the compiled default rather than failing startup.
      apiKey = Secrets.compiledAiKey;
    }
    sessionUnlocked = false;
    notifyListeners();
  }

  List<T> _decode<T>(String key, T Function(Map<String, dynamic>) f) {
    final raw = _prefs.getString(key);
    if (raw == null) return [];
    try {
      final list = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
      return list.map(f).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> _saveAll() async {
    String enc(List<dynamic> l) =>
        jsonEncode(l.map((e) => e.toJson()).toList());
    await _prefs.setString(_kItems, enc(items));
    await _prefs.setString(_kTasks, enc(tasks));
    await _prefs.setString(_kReminders, enc(reminders));
    await _prefs.setString(_kMessages, enc(messages));
  }

  String _id() => DateTime.now().microsecondsSinceEpoch.toString();

  /// Copies a picked image into the app's documents directory so it
  /// survives cache clears and OS temp cleanup. Returns the new path.
  Future<String?> persistImage(String? sourcePath) async {
    if (sourcePath == null || sourcePath.isEmpty) return null;
    try {
      final src = File(sourcePath);
      if (!src.existsSync()) return sourcePath;
      final docs = await getApplicationDocumentsDirectory();
      final dir = Directory('${docs.path}/media');
      if (!dir.existsSync()) dir.createSync(recursive: true);
      final dest = File(
          '${dir.path}/img_${DateTime.now().microsecondsSinceEpoch}.jpg');
      await src.copy(dest.path);
      return dest.path;
    } catch (_) {
      return sourcePath;
    }
  }

  // ---- Library items ----

  List<LifeItem> itemsOfType(ItemType t) {
    final l = items.where((i) => i.type == t).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return l;
  }

  List<LifeItem> get recentItems {
    final l = [...items]..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return l;
  }

  int countType(ItemType t) => items.where((i) => i.type == t).length;

  int countImportant() => items.where((i) => i.important).length;

  void addItem(LifeItem item) {
    items.add(item);
    _saveAll();
    notifyListeners();
  }

  void updateItem(LifeItem item) {
    _saveAll();
    notifyListeners();
  }

  void toggleImportant(LifeItem item) {
    item.important = !item.important;
    _saveAll();
    notifyListeners();
  }

  void deleteItem(String id) {
    items.removeWhere((i) => i.id == id);
    _saveAll();
    notifyListeners();
  }

  void addCustomCategory(String name) {
    final n = _sanitizeCategory(name);
    if (n.isEmpty || customCategories.contains(n) || items.any((i) => i.category == n)) return;
    customCategories.add(n);
    _prefs.setString(_kCustomCats, customCategories.join('|'));
    notifyListeners();
  }

  bool isCategoryHidden(String key) => hiddenCategories.contains(key);

  Future<void> hideCategory(String key) async {
    if (!hiddenCategories.contains(key)) hiddenCategories.add(key);
    await _prefs.setString(_kHiddenCats, hiddenCategories.join('|'));
    notifyListeners();
  }

  Future<void> unhideCategory(String key) async {
    hiddenCategories.remove(key);
    await _prefs.setString(_kHiddenCats, hiddenCategories.join('|'));
    notifyListeners();
  }

  void removeCustomCategory(String name) {
    customCategories.remove(name);
    _prefs.setString(_kCustomCats, customCategories.join('|'));
    notifyListeners();
  }

  int countCustomCategory(String name) =>
      items.where((i) => i.category == name).length;

  List<LifeItem> searchItems(String query) {
    if (query.trim().isEmpty) return [];
    final l = items.where((i) => i.matches(query)).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return l;
  }

  // ---- Notes ----

  LifeItem createNote(String title, String body) {
    final safeTitle = _sanitize(title, maxTitleLength);
    final safeBody = _sanitize(body, maxBodyLength);
    final n = LifeItem(
      id: _id(),
      type: ItemType.note,
      title: safeTitle.isEmpty ? 'Untitled note' : safeTitle,
      category: 'Personal',
      content: safeBody,
      createdAt: DateTime.now(),
    );
    addItem(n);
    return n;
  }

  // ---- Tasks ----

  List<Task> get openTasks =>
      tasks.where((t) => !t.done).toList()
        ..sort((a, b) => (a.dueTime ?? a.createdAt)
            .compareTo(b.dueTime ?? b.createdAt));

  List<Task> get doneTasks => tasks.where((t) => t.done).toList();

  void addTask(String title,
      {TaskPriority priority = TaskPriority.normal, DateTime? due}) {
    tasks.add(Task(
      id: _id(),
      title: _sanitize(title, maxTitleLength),
      priority: priority,
      dueTime: due,
      createdAt: DateTime.now(),
    ));
    _saveAll();
    notifyListeners();
  }

  void toggleTask(Task t) {
    t.done = !t.done;
    _saveAll();
    notifyListeners();
  }

  void deleteTask(String id) {
    tasks.removeWhere((t) => t.id == id);
    _saveAll();
    notifyListeners();
  }

  // ---- Reminders ----

  List<Reminder> get upcomingReminders {
    final l = reminders.where((r) => !r.fired).toList()
      ..sort((a, b) => a.when.compareTo(b.when));
    return l;
  }

  void addReminder(String title, DateTime when,
      {RepeatMode repeat = RepeatMode.never}) {
    reminders.add(Reminder(
      id: _id(),
      title: _sanitize(title, maxTitleLength),
      when: when,
      repeat: repeat,
      createdAt: DateTime.now(),
    ));
    _saveAll();
    notifyListeners();
  }

  void deleteReminder(String id) {
    reminders.removeWhere((r) => r.id == id);
    _saveAll();
    notifyListeners();
  }

  // ---- Chat ----

  void addMessage(ChatMessage m) {
    messages.add(m);
    _saveAll();
    notifyListeners();
  }

  void clearChat() {
    messages.clear();
    _saveAll();
    notifyListeners();
  }

  // ---- Profile ----

  Future<void> updateProfile(
      {String? name, String? email, String? avatar}) async {
    if (name != null && name.trim().isNotEmpty) {
      userName = _sanitize(name, maxTitleLength);
    }
    if (email != null && email.trim().isNotEmpty) userEmail = email.trim();
    if (avatar != null) avatarPath = avatar.isEmpty ? null : avatar;
    await _prefs.setString(_kName, userName);
    await _prefs.setString(_kEmail, userEmail);
    if (avatarPath == null) {
      await _prefs.remove(_kAvatar);
    } else {
      await _prefs.setString(_kAvatar, avatarPath!);
    }
    notifyListeners();
  }


  Future<void> markNotifPermAsked() async {
    notifPermAsked = true;
    await _prefs.setBool(_kNotifAsked, true);
    notifyListeners();
  }

  Future<void> setAppLock(bool v) async {
    appLockEnabled = v;
    await _prefs.setBool(_kAppLock, v);
    notifyListeners();
  }

  Future<void> setBiometrics(bool v) async {
    biometricsEnabled = v;
    await _prefs.setBool(_kBiometrics, v);
    notifyListeners();
  }

  void unlockSession() {
    sessionUnlocked = true;
    notifyListeners();
  }

  Future<void> setTheme(String key) async {
    themeKey = key;
    await _prefs.setString(_kTheme, key);
    notifyListeners();
  }

  Future<void> setLang(String code) async {
    langCode = code;
    await _prefs.setString(_kLang, code);
    notifyListeners();
  }

  /// Immediately engage the lock gate (used when App Lock is enabled).
  void lockNow() {
    sessionUnlocked = false;
    notifyListeners();
  }

  Future<void> setAiConfig({String? key, String? model}) async {
    if (key != null) {
      final trimmed = key.trim();
      // Reject absurd sizes; a real key is well under this.
      apiKey = trimmed.length > 300 ? trimmed.substring(0, 300) : trimmed;
      try {
        if (apiKey.isEmpty) {
          await _secureStorage.delete(key: _ssApiKey);
          apiKey = Secrets.compiledAiKey;
        } else {
          await _secureStorage.write(key: _ssApiKey, value: apiKey);
        }
      } catch (_) {
        // Secure storage write failed — keep the in-memory value for this
        // session so the feature still works.
      }
    }
    if (model != null && model.trim().isNotEmpty) {
      aiModel = model.trim();
      await _prefs.setString(_kAiModel, aiModel);
    }
    notifyListeners();
  }
}
