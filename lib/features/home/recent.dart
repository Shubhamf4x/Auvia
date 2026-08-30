import 'package:flutter/material.dart';
import '../../core/l10n.dart';
import '../../core/theme.dart';
import '../../data/scope.dart';
import '../../widgets/common.dart';
import '../library/item_detail.dart';

class RecentScreen extends StatelessWidget {
  const RecentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return StateRefresher(
      builder: (context, state) {
        final items = state.recentItems;
        return Scaffold(
          body: SafeArea(
            bottom: false,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
              children: [
                TopBar(title: t(context, 'recentActivity'), showProfile: false),
                const SizedBox(height: 10),
                if (items.isEmpty)
                  AppCard(
                    child: Column(
                      children: [
                        Icon(Icons.auto_awesome_outlined,
                            size: 36, color: AppColors.textFaint),
                        const SizedBox(height: 12),
                        Text(t(context, 'noActivityYet'),
                            style: AppText.cardTitle),
                        const SizedBox(height: 6),
                        Text(t(context, 'noActivityHint'),
                            style: AppText.body,
                            textAlign: TextAlign.center),
                      ],
                    ),
                  )
                else
                  ...items.map((i) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: ItemTile(
                          item: i,
                          onTap: () => openItem(context, i),
                        ),
                      )),
              ],
            ),
          ),
        );
      },
    );
  }
}
