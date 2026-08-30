import 'package:flutter/material.dart';
import '../../core/fmt.dart';
import '../../core/l10n.dart';
import '../../core/theme.dart';
import '../../data/models.dart';
import '../../data/app_state.dart';
import '../../data/scope.dart';
import '../../widgets/common.dart';
import '../library/item_detail.dart';

class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  final Set<String> _selected = {};
  bool _selectMode = false;

  void _toggleSelect(String id) {
    setState(() {
      if (_selected.contains(id)) {
        _selected.remove(id);
        if (_selected.isEmpty) _selectMode = false;
      } else {
        _selected.add(id);
      }
    });
  }

  void _confirmDelete(BuildContext context, AppState state) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(t(context, 'discard'), style: AppText.sectionHeading),
        content: Text('${_selected.length} note(s)',
            style: AppText.body),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(t(context, 'cancel')),
          ),
          TextButton(
            onPressed: () {
              for (final id in _selected.toList()) {
                state.deleteItem(id);
              }
              setState(() {
                _selected.clear();
                _selectMode = false;
              });
              Navigator.pop(ctx);
            },
            child: Text(t(context, 'discard'),
                style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StateRefresher(
      builder: (context, state) {
        final notes = state.itemsOfType(ItemType.note);
        return Scaffold(
          body: SafeArea(
            bottom: false,
            child: Stack(
              children: [
                ListView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 110),
                  children: [
                    _selectMode
                        ? Row(
                            children: [
                              GestureDetector(
                                onTap: () => setState(() {
                                  _selectMode = false;
                                  _selected.clear();
                                }),
                                child: Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                        color: AppColors.borderSoft),
                                    color:
                                        AppColors.surface.withOpacity(0.5),
                                  ),
                                  child: Icon(Icons.close_rounded,
                                      size: 22,
                                      color: AppColors.textSecondary),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  '${_selected.length}',
                                  textAlign: TextAlign.center,
                                  style: AppText.sectionHeading,
                                ),
                              ),
                              GestureDetector(
                                onTap: _selected.isEmpty
                                    ? null
                                    : () => _confirmDelete(context, state),
                                child: Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                        color: _selected.isEmpty
                                            ? AppColors.borderSoft
                                            : AppColors.danger
                                                .withOpacity(0.5)),
                                    color:
                                        AppColors.surface.withOpacity(0.5),
                                  ),
                                  child: Icon(Icons.delete_outline_rounded,
                                      size: 22,
                                      color: _selected.isEmpty
                                          ? AppColors.textFaint
                                          : AppColors.danger),
                                ),
                              ),
                            ],
                          )
                        : TopBar(
                            title: t(context, 'notesL'),
                            showProfile: false,
                          ),
                    const SizedBox(height: 10),
                    if (!_selectMode)
                      GestureDetector(
                        onTap: () => Navigator.pushNamed(context, '/search'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 15),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius:
                                BorderRadius.circular(AppRadius.field),
                            border: Border.all(color: AppColors.borderSoft),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.search_rounded,
                                  color: AppColors.textFaint, size: 22),
                              const SizedBox(width: 10),
                              Text(t(context, 'searchNotes'),
                                  style: AppText.body),
                            ],
                          ),
                        ),
                      ),
                    const SizedBox(height: 16),
                    if (notes.isEmpty)
                      AppCard(
                        child: Text(t(context, 'noActivityYet'),
                            style: AppText.body),
                      )
                    else
                      ...notes.map((n) {
                        final isSelected = _selected.contains(n.id);
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: AppCard(
                            onTap: () {
                              if (_selectMode) {
                                _toggleSelect(n.id);
                              } else {
                                openItem(context, n);
                              }
                            },
                            onLongPress: () {
                              if (!_selectMode) {
                                setState(() {
                                  _selectMode = true;
                                  _selected.add(n.id);
                                });
                              }
                            },
                            color: isSelected
                                ? AppColors.accentDim
                                : AppColors.surface,
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (_selectMode) ...[
                                  Icon(
                                    isSelected
                                        ? Icons.check_circle_rounded
                                        : Icons.circle_outlined,
                                    color: isSelected
                                        ? AppColors.accentSoft
                                        : AppColors.textFaint,
                                    size: 22,
                                  ),
                                  const SizedBox(width: 12),
                                ],
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(n.title, style: AppText.cardTitle),
                                      const SizedBox(height: 8),
                                      Text(
                                        n.content,
                                        style: AppText.body,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 10),
                                      Text(Fmt.relative(n.createdAt),
                                          style: AppText.caption.copyWith(
                                              color: AppColors.textFaint)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                  ],
                ),
                // FAB (hidden during selection)
                if (!_selectMode)
                  Positioned(
                    right: 20,
                    bottom: 24,
                    child: GestureDetector(
                      onTap: () =>
                          Navigator.pushNamed(context, '/note-edit'),
                      child: Container(
                        width: 58,
                        height: 58,
                        decoration: BoxDecoration(
                          gradient: AppColors.fabGradient,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.add_rounded,
                            color: Colors.white, size: 30),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class NoteEditScreen extends StatefulWidget {
  final String? noteId;
  const NoteEditScreen({super.key, this.noteId});

  @override
  State<NoteEditScreen> createState() => _NoteEditScreenState();
}

class _NoteEditScreenState extends State<NoteEditScreen> {
  final _title = TextEditingController();
  final _body = TextEditingController();
  bool _loaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loaded) return;
    _loaded = true;
    if (widget.noteId != null) {
      final state = AppScope.of(context);
      for (final i in state.items) {
        if (i.id == widget.noteId) {
          _title.text = i.title;
          _body.text = i.content;
        }
      }
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    super.dispose();
  }

  void _save({bool pop = true}) {
    final state = AppScope.of(context);
    if (widget.noteId == null) {
      // Don't create empty notes when backing out of a new editor.
      if (_title.text.trim().isEmpty && _body.text.trim().isEmpty) {
        if (pop && mounted) Navigator.pop(context);
        return;
      }
      final n = state.createNote(_title.text, _body.text);
      if (pop && mounted) {
        Navigator.pop(context, n.id);
      }
    } else {
      LifeItem? found;
      for (final i in state.items) {
        if (i.id == widget.noteId) {
          i.title = _title.text.isEmpty ? 'Untitled note' : _title.text;
          i.content = _body.text;
          found = i;
        }
      }
      state.updateItem(found ?? state.items.first);
      if (pop && mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isNew = widget.noteId == null;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _save();
      },
      child: Scaffold(
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
                child: SizedBox(
                  height: 56,
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => _save(),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            border:
                                Border.all(color: AppColors.borderSoft),
                            color: AppColors.surface.withOpacity(0.5),
                          ),
                          child: Icon(Icons.arrow_back_rounded,
                              size: 22, color: AppColors.textSecondary),
                        ),
                      ),
                      Expanded(
                        child: Text(isNew ? t(context, 'newNote') : t(context, 'editNote'),
                            textAlign: TextAlign.center,
                            style: AppText.sectionHeading),
                      ),
                      GestureDetector(
                        onTap: () => _save(),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 11),
                          decoration: BoxDecoration(
                            gradient: AppColors.fabGradient,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Text(t(context, 'save'),
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                  fontFamily: AppText.family)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 40),
                  children: [
                    TextField(
                      controller: _title,
                      style: AppText.pageTitle.copyWith(fontSize: 22),
                      decoration: const InputDecoration(
                        hintText: 'Title',
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        filled: false,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _body,
                      maxLines: 14,
                      style: AppText.body.copyWith(
                          color: AppColors.textPrimary, fontSize: 15),
                      decoration: InputDecoration(
                        hintText: t(context, 'startWriting'),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        filled: false,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
