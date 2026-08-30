import 'package:flutter/material.dart';
import '../../core/l10n.dart';
import '../../core/theme.dart';

import '../../data/scope.dart';
import '../../widgets/common.dart';
import '../library/item_detail.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return StateRefresher(
      builder: (context, state) {
        final recent = state.recentItems.take(3).toList();
        return SafeArea(
          bottom: false,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 110),
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Builder(builder: (ctx) {
                    return GestureDetector(
                      onTap: () => Scaffold.of(ctx).openDrawer(),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.borderSoft),
                          color: AppColors.surface.withOpacity(0.5),
                        ),
                        child: Icon(Icons.menu_rounded,
                            size: 22, color: AppColors.textSecondary),
                      ),
                    );
                  }),
                  SizedBox(width: 44),
                  GestureDetector(
                    onTap: () => Navigator.pushNamed(context, '/search'),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.borderSoft),
                        color: AppColors.surface.withOpacity(0.5),
                      ),
                      child: Icon(Icons.search_rounded,
                          size: 22, color: AppColors.textSecondary),
                    ),
                  ),

                ],
              ),
              const SizedBox(height: 22),
              Text(t(context, 'welcome'), style: AppText.pageTitle),
              const SizedBox(height: 20),

              _AiCard(onAsk: (q) {
                Navigator.pushNamed(context, '/ai-focus', arguments: q);
              }),
              const SizedBox(height: 8),

              const SectionHeader('Quick Actions'),
              Row(
                children: [
                  _quickAction(context, Icons.document_scanner_outlined,
                      t(context, 'scan'), () => Navigator.pushNamed(context, '/scan')),
                  const SizedBox(width: 12),
                  _quickAction(context, Icons.sticky_note_2_outlined, t(context, 'note'),
                      () => Navigator.pushNamed(context, '/note-new')),
                  const SizedBox(width: 12),
                  _quickAction(context, Icons.upload_file_outlined, t(context, 'upload'),
                      () => Navigator.pushNamed(context, '/upload')),
                ],
              ),

              SectionHeader(
                t(context, 'recentActivity'),
                action: t(context, 'seeAll'),
                onAction: () =>
                    Navigator.pushNamed(context, '/recent'),
              ),

              if (recent.isEmpty)
                AppCard(
                  child: Column(
                    children: [
                      Icon(Icons.auto_awesome_outlined,
                          size: 36, color: AppColors.textFaint),
                      const SizedBox(height: 12),
                      Text(t(context, 'noActivityYet'), style: AppText.cardTitle),
                      const SizedBox(height: 6),
                      Text(
                        t(context, 'noActivityHint'),
                        style: AppText.body,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              else
                ...recent.map((i) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: ItemTile(
                        item: i,
                        onTap: () => openItem(context, i),
                      ),
                    )),
            ],
          ),
        );
      },
    );
  }

  Widget _quickAction(
      BuildContext context, IconData icon, String label, VoidCallback onTap) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.card),
          child: Ink(
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.card),
              border: Border.all(color: AppColors.borderSoft),
            ),
            child: Column(
              children: [
                Icon(icon, color: AppColors.accentSoft, size: 24),
                const SizedBox(height: 8),
                Text(label, style: AppText.label),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AiCard extends StatefulWidget {
  final void Function(String) onAsk;
  const _AiCard({required this.onAsk});

  @override
  State<_AiCard> createState() => _AiCardState();
}

class _AiCardState extends State<_AiCard> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: AppColors.aiGradient,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.accent.withOpacity(0.5)),
        ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.auto_awesome,
                    color: Colors.white, size: 20),
              ),
              const SizedBox(width: 10),
              Text('AI Assistant',
                  style: AppText.cardTitle.copyWith(color: Colors.white)),
              const Spacer(),
              Text('Online',
                  style: AppText.caption.copyWith(color: Colors.white70)),
            ],
          ),
          const SizedBox(height: 16),
          Text('Ask anything...',
              style: AppText.body.copyWith(
                  color: Colors.white.withOpacity(0.85), fontSize: 16)),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _ctrl,
                  style: AppText.bodyStrong.copyWith(color: Colors.white),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.black.withOpacity(0.25),
                    hintText: 'e.g. Find my train ticket',
                    hintStyle: AppText.body.copyWith(color: Colors.white54),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.field),
                      borderSide:
                          BorderSide(color: Colors.white.withOpacity(0.2)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.field),
                      borderSide:
                          const BorderSide(color: Colors.white70, width: 1.4),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                  ),
                  onSubmitted: (v) => widget.onAsk(v),
                ),
              ),
              SizedBox(width: 10),
              GestureDetector(
                onTap: () => widget.onAsk(_ctrl.text.trim()),
                child: Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(AppRadius.field),
                  ),
                  child: Icon(Icons.arrow_upward_rounded,
                      color: AppColors.accentDeep, size: 22),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
