import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

import 'core/l10n.dart';
import 'core/theme.dart';
import 'data/app_state.dart';
import 'data/scope.dart';
import 'features/ai/ai_chat.dart';
import 'features/home/recent.dart';
import 'features/library/item_detail.dart';
import 'features/library/library.dart';
import 'features/notes/notes.dart';
import 'features/profile/profile.dart';
import 'features/reminders/reminder_new.dart';
import 'features/reminders/reminders_page.dart';
import 'features/screenshots/scan.dart';
import 'features/screenshots/upload.dart';
import 'features/search/search.dart';
import 'features/shell/lock_screen.dart';
import 'features/shell/shell.dart';
import 'features/tasks/task_new.dart';
import 'features/tasks/tasks.dart';

class AppRoot extends StatefulWidget {
  final AppState state;
  const AppRoot({super.key, required this.state});

  @override
  State<AppRoot> createState() => _AppRootState();
}

class _AppRootState extends State<AppRoot> with WidgetsBindingObserver {
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _bootstrap();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      final s = widget.state;
      if ((s.appLockEnabled || s.biometricsEnabled) && s.sessionUnlocked) {
        s.lockNow();
      }
    }
  }

  Future<void> _bootstrap() async {
    await widget.state.load();
    if (mounted) setState(() => _ready = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _requestNotificationPermissionOnce();
    });
  }

  Future<void> _requestNotificationPermissionOnce() async {
    if (widget.state.notifPermAsked) return;
    try {
      await Permission.notification.request();
    } catch (_) {
    }
    await widget.state.markNotifPermAsked();
  }

  void _applySystemUI() {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness:
          AppColors.isLight ? Brightness.dark : Brightness.light,
      systemNavigationBarColor: AppColors.bg,
      systemNavigationBarIconBrightness:
          AppColors.isLight ? Brightness.dark : Brightness.light,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return AppScope(
      state: widget.state,
      child: AnimatedBuilder(
        animation: widget.state,
        builder: (context, _) {
          AppColors.apply(widget.state.themeKey);
          _applySystemUI();
          return MaterialApp(
            title: 'Auvia',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.current,
            onUnknownRoute: (_) =>
                MaterialPageRoute(builder: (_) => const MainShell()),
            locale: Locale(widget.state.langCode),
            supportedLocales: supportedLocales,
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            home: !_ready
                ? _splash()
                : _LockedGate(
                    locked: (widget.state.appLockEnabled ||
                            widget.state.biometricsEnabled) &&
                        !widget.state.sessionUnlocked,
                  ),
            routes: {
          '/shell': (_) => const MainShell(),
          '/ai': (_) => const AiChatScreen(),
          '/ai-focus': (ctx) {
            final arg = ModalRoute.of(ctx)?.settings.arguments;
            return AiFocusScreen(prompt: arg is String ? arg : '');
          },
          '/tasks-page': (_) => const TasksScreen(),
          '/library-page': (_) => const LibraryScreen(),
          '/notes-page': (_) => const NotesScreen(),
          '/note-new': (_) => const NoteEditScreen(),
          '/reminders-page': (_) => const RemindersPage(),
          '/reminder-new': (ctx) {
            final arg = ModalRoute.of(ctx)?.settings.arguments;
            return ReminderNewScreen(
                prefilledTitle: arg is String ? arg : null);
          },
          '/scan': (_) => const ScanScreen(),
          '/upload': (_) => const UploadScreen(),
          '/task-new': (_) => const TaskNewScreen(),
          '/search': (_) => const SearchScreen(),
          '/profile': (_) => const ProfileScreen(),
          '/recent': (_) => const RecentScreen(),
          '/document': (ctx) {
            final id = ModalRoute.of(ctx)?.settings.arguments as String;
            return DocumentDetailScreen(itemId: id);
          },
          '/note-edit': (ctx) {
            final id = ModalRoute.of(ctx)?.settings.arguments as String?;
            return NoteEditScreen(noteId: id);
          },
          '/category': (ctx) {
            final arg = ModalRoute.of(ctx)?.settings.arguments;
            return CategoryScreen(filter: arg);
          },
            },
          );
        },
      ),
    );
  }

  Widget _splash() {
    return Scaffold(
      body: Center(
        child: Container(
          width: 84,
          height: 84,
          decoration: BoxDecoration(
            gradient: AppColors.aiGradient,
            borderRadius: BorderRadius.circular(24),
          ),
          child: const Icon(Icons.auto_awesome, color: Colors.white, size: 38),
        ),
      ),
    );
  }
}

class AiFocusScreen extends StatelessWidget {
  final String prompt;
  const AiFocusScreen({super.key, required this.prompt});

  @override
  Widget build(BuildContext context) {
    return AiChatScreen(initialPrompt: prompt);
  }
}

class _LockedGate extends StatelessWidget {
  final bool locked;
  const _LockedGate({required this.locked});

  @override
  Widget build(BuildContext context) {
    return locked ? LockScreen() : MainShell();
  }
}
