import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../core/l10n.dart';
import '../../data/scope.dart';
import '../ai/ai_chat.dart';
import '../home/home.dart';
import '../library/library.dart';
import '../tasks/tasks.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    // Rebuild on every state change (incl. theme switch) so the
    // bottom nav bar and drawer always match the active palette.
    return StateRefresher(
      builder: (context, state) {
        final pages = [
          const HomeScreen(),
          const LibraryScreen(embedded: true),
          const AiChatScreen(embedded: true),
          const TasksScreen(embedded: true),
        ];

        return Scaffold(
          drawer: _buildDrawer(context),
          body: IndexedStack(index: _index, children: pages),
          bottomNavigationBar: Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.borderSoft),
              ),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
                child: Row(
                  children: [
                    _navItem(Icons.home_outlined, Icons.home_rounded, t(context, 'home'), 0),
                    _navItem(Icons.folder_outlined, Icons.folder_rounded,
                        t(context, 'library'), 1),
                    _qrButton(),
                    _navItem(Icons.auto_awesome_outlined, Icons.auto_awesome,
                        t(context, 'ai'), 2),
                    _navItem(Icons.check_circle_outline_rounded,
                        Icons.check_circle_rounded, t(context, 'tasks'), 3),

                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// Raised QR / scan action between Library and AI.
  Widget _qrButton() {
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => Navigator.pushNamed(context, '/scan'),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Transform.translate(
              offset: const Offset(0, -14),
              child: Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  gradient: AppColors.fabGradient,
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: Colors.white.withOpacity(0.18), width: 1.5),
                  ),
                child: const Icon(Icons.qr_code_scanner_rounded,
                    color: Colors.white, size: 25),
              ),
            ),
            Transform.translate(
              offset: const Offset(0, -6),
              child: Text(t(context, 'scan'),
                  style: AppText.caption.copyWith(
                      fontSize: 10.5, color: AppColors.accentSoft)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    final state = AppScope.of(context);
    return Drawer(
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(right: Radius.circular(24)),
      ),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: AppColors.aiGradient,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.auto_awesome,
                        color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Text(state.userName, style: AppText.cardTitle),
                ],

              ),
            ),
            const Divider(),
            _drawerItem(context, Icons.sticky_note_2_outlined, t(context, 'notesL'), () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/notes-page');
            }),
            _drawerItem(context, Icons.upload_file_outlined, t(context, 'upload'), () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/upload');
            }),
            _drawerItem(context, Icons.alarm_rounded, t(context, 'remindersT'), () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/reminders-page');
            }),
            _drawerItem(context, Icons.account_circle_outlined, t(context, 'profile'), () {

              Navigator.pop(context);
              Navigator.pushNamed(context, '/profile');
            }),
          ],
        ),
      ),
    );
  }

  Widget _drawerItem(
      BuildContext context, IconData icon, String label, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: AppColors.textSecondary, size: 22),
      title: Text(label, style: AppText.cardTitle),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      onTap: onTap,
    );
  }

  Widget _navItem(
      IconData outline, IconData filled, String label, int i) {
    final active = _index == i;
    final color = active ? AppColors.accentSoft : AppColors.textFaint;
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => setState(() => _index = i),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
              decoration: BoxDecoration(
                color: active ? AppColors.accentDim : Colors.transparent,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(active ? filled : outline, color: color, size: 23),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: AppText.caption.copyWith(
                fontSize: 11,
                color: color,
                fontWeight: active ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
