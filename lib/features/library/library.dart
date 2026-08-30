import 'package:flutter/material.dart';
import '../../core/l10n.dart';
import '../../core/theme.dart';
import '../../data/models.dart';
import '../../data/app_state.dart';
import '../../data/scope.dart';
import '../../widgets/common.dart';

class LibraryScreen extends StatelessWidget {
  final bool embedded;
  const LibraryScreen({super.key, this.embedded = false});

  @override
  Widget build(BuildContext context) {
    return StateRefresher(
      builder: (context, state) {
        return SafeArea(
          bottom: false,
          child: ListView(
            padding: EdgeInsets.fromLTRB(20, embedded ? 8 : 0, 20, 40),
            children: [
              if (!embedded)
                Padding(
                  padding: EdgeInsets.only(bottom: 8),
                  child: Text('Library', style: AppText.pageTitle),
                ),
              GestureDetector(
                onTap: () => Navigator.pushNamed(context, '/search'),
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
                      Icon(Icons.search_rounded,
                          color: AppColors.textFaint, size: 22),
                      const SizedBox(width: 10),
                      Text(t(context, 'searchEverything'), style: AppText.body),
                    ],
                  ),
                ),
              ),

              Row(
                children: [
                  Expanded(child: SectionHeader(t(context, 'categories'))),
                  GestureDetector(
                    onTap: () => _newCategoryDialog(context, state),
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        gradient: AppColors.fabGradient,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.add_rounded,
                          color: Colors.white, size: 22),
                    ),
                  ),
                ],
              ),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.55,
                children: [
                  if (!state.isCategoryHidden('screenshot'))
                    _category(context, state, ItemType.screenshot,
                        state.countType(ItemType.screenshot)),
                  if (!state.isCategoryHidden('document'))
                    _category(context, state, ItemType.document,
                        state.countType(ItemType.document)),
                  if (!state.isCategoryHidden('note'))
                    _category(context, state, ItemType.note,
                        state.countType(ItemType.note)),
                  if (!state.isCategoryHidden('receipt'))
                    _category(context, state, ItemType.receipt,
                        state.countType(ItemType.receipt)),
                  if (!state.isCategoryHidden('ticket'))
                    _category(context, state, ItemType.ticket,
                        state.countType(ItemType.ticket)),
                  ...state.customCategories
                      .map((name) => _customCategory(context, state, name)),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _category(BuildContext context, AppState state, ItemType type,
      int count) {
    final icon = ItemTypeBadge.icon(type);
    final color = ItemTypeBadge.color(type);
    final label = itemTypePlural(context, type);

    return AppCard(
      padding: const EdgeInsets.all(14),
      onTap: () {
        Navigator.pushNamed(context, '/category', arguments: type);
      },
      onLongPress: () => _confirmDeleteCategory(
          context, state, itemTypePlural(context, type), type.name),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 22),
              const Spacer(),
              Text('$count',
                  style: AppText.cardTitle.copyWith(
                      color: AppColors.textSecondary, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 10),
          Text(label,
              style: AppText.cardTitle.copyWith(fontSize: 14),
              overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  void _confirmDeleteCategory(
      BuildContext context, AppState state, String label, String key) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(label, style: AppText.sectionHeading),
        content: Text(t(context, 'discard'), style: AppText.body),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(t(context, 'cancel')),
          ),
          TextButton(
            onPressed: () {
              state.hideCategory(key);
              Navigator.pop(ctx);
            },
            child: Text(t(context, 'discard'),
                style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
  }

  Widget _customCategory(
      BuildContext context, AppState state, String name) {
    return AppCard(
      padding: const EdgeInsets.all(14),
      onTap: () => Navigator.pushNamed(context, '/category',
          arguments: '__custom:$name'),
      onLongPress: () => _confirmRemoveCategory(context, state, name),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(Icons.folder_special_outlined,
                  color: AppColors.accentSoft, size: 22),
              const Spacer(),
              Text('${state.countCustomCategory(name)}',
                  style: AppText.cardTitle.copyWith(
                      color: AppColors.textSecondary, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 10),
          Text(name,
              style: AppText.cardTitle.copyWith(fontSize: 14),
              overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  Future<void> _newCategoryDialog(
      BuildContext context, AppState state) async {
    final ctrl = TextEditingController();
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(t(context, 'categories'),
            style: AppText.sectionHeading),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          style: AppText.bodyStrong,
          decoration:
              InputDecoration(hintText: 'Travel, Work, Ideas...'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(t(context, 'cancel')),
          ),
          TextButton(
            onPressed: () {
              state.addCustomCategory(ctrl.text);
              Navigator.pop(ctx);
            },
            child: Text(t(context, 'save')),
          ),
        ],
      ),
    );
  }

  void _confirmRemoveCategory(
      BuildContext context, AppState state, String name) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(name, style: AppText.sectionHeading),
        content: Text(t(context, 'discard'), style: AppText.body),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(t(context, 'cancel')),
          ),
          TextButton(
            onPressed: () {
              state.removeCustomCategory(name);
              Navigator.pop(ctx);
            },
            child: Text(t(context, 'discard'),
                style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
  }
}
