import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/fmt.dart';
import '../../core/l10n.dart';
import '../../core/theme.dart';
import '../../data/models.dart';
import '../../data/app_state.dart';
import '../../data/scope.dart';
import '../../services/ai_service.dart';
import '../../widgets/common.dart';

void openItem(BuildContext context, LifeItem item) {
  if (item.type == ItemType.note) {
    Navigator.pushNamed(context, '/note-edit', arguments: item.id);
  } else {
    Navigator.pushNamed(context, '/document', arguments: item.id);
  }
}

class DocumentDetailScreen extends StatelessWidget {
  final String itemId;
  const DocumentDetailScreen({super.key, required this.itemId});

  @override
  Widget build(BuildContext context) {
    return StateRefresher(
      builder: (context, state) {
        LifeItem? item;
        for (final i in state.items) {
          if (i.id == itemId) item = i;
        }
        if (item == null) {
          return const Scaffold(body: Center(child: Text('Item not found')));
        }
        return _DetailBody(item: item);
      },
    );
  }
}

class _DetailBody extends StatefulWidget {
  final LifeItem item;
  const _DetailBody({required this.item});

  @override
  State<_DetailBody> createState() => _DetailBodyState();
}

class _DetailBodyState extends State<_DetailBody> {
  String? _aiResult;
  bool _busy = false;
  bool _taskAdded = false;

  Future<void> _run(String action) async {
    setState(() => _busy = true);
    await Future<void>.delayed(const Duration(milliseconds: 700));
    final item = widget.item;
    String out;
    switch (action) {
      case 'Summarize':
        out = AiService.instance.summarize(item);
        break;
      case 'Explain':
        out = 'This ${item.type.label.toLowerCase()} is from your '
            '${item.category.toLowerCase()} records.\n\n'
            '${_autoSummary(item)}\n\n'
            'Ask AI anything else about it, or create a task or reminder from it.';
        break;
      case 'Extract':
        final pts = item.keyPoints.isNotEmpty
            ? item.keyPoints
            : item.content
                .split('\n')
                .where((l) => l.trim().isNotEmpty)
                .take(4)
                .toList();
        out = 'Key information extracted:\n\n${pts.map((p) => '• ${p.trim()}').join('\n')}';
        break;
      default:
        out = AiService.instance.summarize(item);
    }
    if (!mounted) return;
    setState(() {
      _aiResult = out;
      _busy = false;
    });
  }

  String _autoSummary(LifeItem i) {
    final first = i.content
        .split('\n')
        .where((l) => l.trim().isNotEmpty)
        .take(3)
        .join('. ');
    return first;
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final state = AppScope.of(context);
    final c = ItemTypeBadge.color(item.type);
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
          children: [
            Row(
              children: [
                _IconBtnWrap(
                  icon: Icons.arrow_back_rounded,
                  onTap: () => Navigator.pop(context),
                ),
                Expanded(
                  child: Text(t(context, 'tDocument'),
                      textAlign: TextAlign.center,
                      style: AppText.sectionHeading),
                ),
                _IconBtnWrap(
                  icon: item.important
                      ? Icons.bookmark_rounded
                      : Icons.bookmark_border_rounded,
                  color: item.important ? AppColors.accentSoft : null,
                  onTap: () => state.toggleImportant(item),
                ),
                const SizedBox(width: 8),
                _IconBtnWrap(
                  icon: Icons.delete_outline_rounded,
                  onTap: () {
                    state.deleteItem(item.id);
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
            const SizedBox(height: 18),
            Container(
              height: 190,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [c.withOpacity(0.28), AppColors.surfaceAlt],
                ),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: AppColors.borderSoft),
              ),
              child: item.imagePath != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(21),
                      child: Image.file(File(item.imagePath!),
                          cacheWidth: 720,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _previewIcon(item, c)),
                    )
                  : _previewIcon(item, c),
            ),
            const SizedBox(height: 18),
            Text(item.title, style: AppText.pageTitle.copyWith(fontSize: 23)),
            const SizedBox(height: 4),
            Text(
                '${itemTypeLabel(context, item.type)} · ${item.category} · ${t(context, 'added')} ${Fmt.relative(item.createdAt)}',
                style: AppText.caption),
            const SizedBox(height: 16),

            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.auto_awesome,
                          color: AppColors.accentSoft, size: 18),
                      const SizedBox(width: 8),
                      Text(t(context, 'aiSummary'), style: AppText.cardTitle),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(item.aiSummary ?? _autoSummary(item),
                      style: AppText.body),
                  if (item.keyPoints.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    ...item.keyPoints.map(
                      (p) => Padding(
                        padding: const EdgeInsets.only(bottom: 5),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('•  ',
                                style: TextStyle(color: AppColors.accentSoft)),
                            Expanded(
                                child: Text(p, style: AppText.bodyStrong)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 14),

            SectionHeader(t(context, 'categories')),
            AppCard(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              onTap: () => _chooseCategory(context, item),
              child: Row(
                children: [
                  Icon(ItemTypeBadge.icon(item.type),
                      color: ItemTypeBadge.color(item.type), size: 22),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.category,
                            style: AppText.cardTitle,
                            overflow: TextOverflow.ellipsis),
                        Text(t(context, 'saveToLibrary'),
                            style: AppText.caption.copyWith(fontSize: 11.5)),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded,
                      color: AppColors.textFaint),
                ],
              ),
            ),
            const SizedBox(height: 14),

            Row(
              children: [
                _aiAction(t(context, 'summarizeA')),
                const SizedBox(width: 10),
                _aiAction(t(context, 'explainA')),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _aiAction(t(context, 'extractA')),
                const SizedBox(width: 10),
                _aiAction(t(context, 'askAI')),
              ],
            ),

            if (_busy) ...[
              const SizedBox(height: 18),
              Row(
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                        color: AppColors.accent, strokeWidth: 2),
                  ),
                  const SizedBox(width: 10),
                  Text('AI is thinking...',
                      style: AppText.caption.copyWith(
                          color: AppColors.accentSoft)),
                ],
              ),
            ],

            if (_aiResult != null) ...[
              const SizedBox(height: 16),
              AppCard(
                color: AppColors.surfaceAlt,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.auto_awesome,
                            color: AppColors.accentSoft, size: 18),
                        const SizedBox(width: 8),
                        Text(t(context, 'aiAnalysis'), style: AppText.cardTitle),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(_aiResult!, style: AppText.body),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 16),

            SectionHeader(t(context, 'content')),
            AppCard(
              child: Text(item.content, style: AppText.body),
            ),

            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: PrimaryButton(
                    label: t(context, 'createTask'),
                    icon: Icons.check_circle_outline_rounded,
                    onTap: () {
                      if (_taskAdded) return;
                      _taskAdded = true;
                      state.addTask(item.title.toLowerCase().contains('bill')
                          ? 'Pay ${item.title}'
                          : 'Follow up: ${item.title}');
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text('Task added: ${item.title}')));
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: PrimaryButton(
                    label: t(context, 'remindMe'),
                    icon: Icons.alarm_rounded,
                    gradient: false,
                    onTap: () => Navigator.pushNamed(context, '/reminder-new',
                        arguments: item.title.toLowerCase().contains('bill')
                            ? 'Pay ${item.title}'
                            : 'Follow up: ${item.title}'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _chooseCategory(
      BuildContext context, LifeItem item) async {
    final state = AppScope.of(context);
    await showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(t(context, 'categories'),
                    style: AppText.sectionHeading),
              ),
              const SizedBox(height: 6),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    ...ItemType.values.map((type) {
                      final isCurrent =
                          identical(item.type, type) && item.category == type.label;
                      return ListTile(
                        dense: true,
                        leading: Icon(ItemTypeBadge.icon(type),
                            color: ItemTypeBadge.color(type), size: 21),
                        title: Text(itemTypePlural(context, type),
                            style: AppText.bodyStrong),
                        trailing: isCurrent
                            ? Icon(Icons.check_rounded,
                                color: AppColors.accentSoft, size: 20)
                            : null,
                        onTap: () {
                          item.type = type;
                          item.category = type.label;
                          state.updateItem(item);
                          Navigator.pop(ctx);
                        },
                      );
                    }),
                    ...state.customCategories.map((name) {
                      final isCurrent = item.category == name;
                      return ListTile(
                        dense: true,
                        leading: Icon(Icons.folder_special_outlined,
                            color: AppColors.accentSoft, size: 21),
                        title: Text(name, style: AppText.bodyStrong),
                        trailing: isCurrent
                            ? Icon(Icons.check_rounded,
                                color: AppColors.accentSoft, size: 20)
                            : null,
                        onTap: () {
                          item.category = name;
                          state.updateItem(item);
                          Navigator.pop(ctx);
                        },
                      );
                    }),
                    ListTile(
                      dense: true,
                      leading: Icon(Icons.add_circle_outline_rounded,
                          color: AppColors.accentSoft, size: 21),
                      title: Text(t(context, 'newCategory'),
                          style: AppText.bodyStrong),
                      onTap: () async {
                        Navigator.pop(ctx);
                        final ctrl = TextEditingController();
                        final name = await showDialog<String>(
                          context: context,
                          builder: (dlgCtx) => AlertDialog(
                            backgroundColor: AppColors.surface,
                            title: Text(t(context, 'newCategory'),
                                style: AppText.sectionHeading),
                            content: TextField(
                              controller: ctrl,
                              autofocus: true,
                              style: AppText.bodyStrong,
                              decoration: const InputDecoration(
                                  hintText: 'Travel, Work, Ideas...'),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(dlgCtx),
                                child: Text(t(context, 'cancel')),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(
                                    dlgCtx, ctrl.text.trim()),
                                child: Text(t(context, 'save')),
                              ),
                            ],
                          ),
                        );
                        if (name != null && name.isNotEmpty) {
                          state.addCustomCategory(name);
                          item.category = name;
                          state.updateItem(item);
                        }
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(t(context, 'saveToLibrary'))));
    }
  }

  Widget _previewIcon(LifeItem item, Color c) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(ItemTypeBadge.icon(item.type), color: c, size: 52),
          const SizedBox(height: 10),
          Text('DOCUMENT PREVIEW',
              style: AppText.label.copyWith(
                  color: AppColors.textFaint, letterSpacing: 1.4,
                  fontSize: 11)),
        ],
      ),
    );
  }

  Widget _aiAction(String label) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _busy ? null : () => _run(label),
          borderRadius: BorderRadius.circular(14),
          child: Ink(
            padding: const EdgeInsets.symmetric(vertical: 13),
            decoration: BoxDecoration(
              color: AppColors.surfaceAlt,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.auto_awesome,
                      size: 15, color: AppColors.accentSoft),
                  const SizedBox(width: 7),
                  Text(label,
                      style: AppText.label.copyWith(
                          color: AppColors.textPrimary)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _IconBtnWrap extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final Color? color;
  const _IconBtnWrap({required this.icon, this.onTap, this.color});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.borderSoft),
          color: AppColors.surface.withOpacity(0.5),
        ),
        child: Icon(icon, size: 22, color: color ?? AppColors.textSecondary),
      ),
    );
  }
}

class CategoryScreen extends StatelessWidget {
  final dynamic filter; // ItemType or '__custom:<name>'
  const CategoryScreen({super.key, required this.filter});

  @override
  Widget build(BuildContext context) {
    final bool isCustom =
        filter is String && filter.toString().startsWith('__custom:');
    final String customName =
        isCustom ? filter.toString().substring(9) : '';
    final title = isCustom
        ? customName
        : itemTypePlural(context, filter as ItemType);
    return StateRefresher(
      builder: (context, state) {
        final list = isCustom
            ? state.items.where((i) => i.category == customName).toList()
            : state.itemsOfType(filter);
        list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return Scaffold(
          body: SafeArea(
            bottom: false,
            child: Stack(
              children: [
                ListView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 110),
                  children: [
                    TopBar(
                      title: title,
                      showProfile: false,
                      trailing: GestureDetector(
                        onTap: () => _addMediaSheet(
                            context, state,
                            type: isCustom ? ItemType.document : filter,
                            categoryName:
                                isCustom ? customName : null),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppColors.borderSoft),
                            color: AppColors.surface.withOpacity(0.5),
                          ),
                          child: Icon(Icons.add_rounded,
                              size: 22, color: AppColors.textSecondary),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (list.isEmpty)
                      AppCard(
                        child: Column(
                          children: [
                            const SizedBox(height: 8),
                            Icon(Icons.inbox_outlined,
                                size: 40, color: AppColors.textFaint),
                            const SizedBox(height: 12),
                            Text(t(context, 'noResults'),
                                style: AppText.cardTitle),
                            const SizedBox(height: 6),
                            Text(t(context, 'noActivityHint'),
                                style: AppText.body,
                                textAlign: TextAlign.center),
                            const SizedBox(height: 8),
                          ],
                        ),
                      )
                    else
                      ...list.map((i) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: ItemTile(
                              item: i,
                              onTap: () => openItem(context, i),
                            ),
                          )),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _addMediaSheet(BuildContext context, AppState state,
      {required ItemType type, String? categoryName}) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 14),
            Text(t(context, 'uploadT'), style: AppText.sectionHeading),
            const SizedBox(height: 8),
            ListTile(
              leading: Icon(Icons.camera_alt_rounded,
                  color: AppColors.accentSoft),
              title: Text(t(context, 'scanTitle'),
                  style: AppText.bodyStrong),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: Icon(Icons.photo_library_rounded,
                  color: AppColors.accentSoft),
              title: Text(t(context, 'chooseFromGallery'),
                  style: AppText.bodyStrong),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
    if (source == null || !context.mounted) return;

    final picker = ImagePicker();
    XFile? x;
    try {
      x = await picker.pickImage(source: source);
    } catch (_) {
      x = null;
    }
    if (x == null || !context.mounted) return;

    final persisted = await state.persistImage(x.path);

    final defaultCategory =
        categoryName ?? type.label;
    final analysis = await AiService.instance.analyzeImageSmart(
            x.path, x.name, 'add to $defaultCategory', state) ??
        await AiService.instance.provider.analyzeImage(x.name,
            hint: defaultCategory);

    final item = LifeItem(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      type: type,
      title: analysis.title,
      category: analysis.category,
      content: analysis.extractedText,
      keyPoints: analysis.keyInfo,
      imagePath: persisted,
      createdAt: DateTime.now(),
    );
    item.category = defaultCategory;
    state.addItem(item);
    if (!context.mounted) return;
    Navigator.pushNamed(context, '/document', arguments: item.id);
  }
}
