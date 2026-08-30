import 'package:flutter/material.dart';
import '../../core/l10n.dart';
import '../../core/theme.dart';
import '../../data/scope.dart';
import '../../widgets/common.dart';
import '../library/item_detail.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _ctrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StateRefresher(
      builder: (context, state) {
        final results = _query.trim().isEmpty
            ? const <dynamic>[]
            : state.searchItems(_query);

        final suggestions = [
          'electricity bill',
          'train ticket',
          'interview',
          'wi-fi',
        ];

        return Scaffold(
          body: SafeArea(
            bottom: false,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
              children: [
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.borderSoft),
                          color: AppColors.surface.withOpacity(0.5),
                        ),
                        child: Icon(Icons.arrow_back_rounded,
                            size: 22, color: AppColors.textSecondary),
                      ),
                    ),
                    Expanded(
                      child: Text(t(context, 'search'),
                          textAlign: TextAlign.center,
                          style: AppText.sectionHeading),
                    ),
                    const SizedBox(width: 46),
                  ],
                ),
                SizedBox(height: 16),
                TextField(
                  controller: _ctrl,
                  autofocus: true,
                  style: AppText.bodyStrong,
                  onChanged: (v) => setState(() => _query = v),
                  decoration: InputDecoration(
                    hintText: t(context, 'searchHint'),
                    prefixIcon: Icon(Icons.search_rounded,
                        color: AppColors.textFaint),
                  ),
                ),
                const SizedBox(height: 18),

                if (_query.trim().isEmpty) ...[
                  Text(t(context, 'trySearching'), style: AppText.label),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: suggestions
                        .map((s) => GestureDetector(
                              onTap: () {
                                _ctrl.text = s;
                                setState(() => _query = s);
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 9),
                                decoration: BoxDecoration(
                                  color: AppColors.surface,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                      color: AppColors.borderSoft),
                                ),
                                child: Text(s, style: AppText.label),
                              ),
                            ))
                        .toList(),
                  ),
                  const SizedBox(height: 20),
                  AppCard(
                    child: Row(
                      children: [
                        Icon(Icons.auto_awesome,
                            color: AppColors.accentSoft, size: 20),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Search covers screenshots, documents, notes, tasks, reminders and AI metadata.',
                            style: AppText.body,
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else if (results.isEmpty) ...[
                  const SizedBox(height: 8),
                  Text(t(context, 'results'), style: AppText.sectionHeading),
                  const SizedBox(height: 10),
                  AppCard(
                    child: Text(
                      '${t(context, 'noResults')} " $_query "',
                      style: AppText.body,
                    ),
                  ),
                ] else ...[
                  Text('${t(context, 'results')} · ${results.length}',
                      style: AppText.sectionHeading),
                  const SizedBox(height: 12),
                  ...results.map((r) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: ItemTile(
                          item: r,
                          onTap: () => openItem(context, r),
                        ),
                      )),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
