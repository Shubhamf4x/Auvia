import 'package:flutter/material.dart';

import '../core/l10n.dart';
import '../core/theme.dart';
import '../data/scope.dart';
import 'common.dart';

/// Preset AI profiles shown in the UI. Real model IDs stay internal.
const List<({String id, String label, String desc})> freeModels = [
  (
    id: 'nvidia/nemotron-3-ultra-550b-a55b:free',
    label: 'Best quality',
    desc: 'Smartest responses',
  ),
  (
    id: 'minimax/minimax-m3:free',
    label: 'Fastest',
    desc: 'Quick replies · reads images',
  ),
  (
    id: 'nvidia/nemotron-3-super-120b-a12b:free',
    label: 'Balanced',
    desc: 'Speed and quality',
  ),
  (
    id: 'minimax/minimax-m2.7:free',
    label: 'Lightweight',
    desc: 'Simple and steady',
  ),
];

/// Bottom sheet to connect the app to AI (free, key stays on device).
Future<void> showAiSettingsSheet(BuildContext context) {
  final state = AppScope.of(context);
  String selected = state.aiModel;

  return showModalBottomSheet(
    context: context,
    backgroundColor: AppColors.surface,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setSheet) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(t(context, 'aiConnectionL'),
                        style: AppText.sectionHeading),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: state.apiKey.isEmpty
                          ? AppColors.surfaceAlt
                          : AppColors.success.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: state.apiKey.isEmpty
                              ? AppColors.border
                              : AppColors.success.withOpacity(0.4)),
                    ),
                    child: Text(
                      state.apiKey.isEmpty
                          ? t(context, 'onDevice')
                          : t(context, 'connected'),
                      style: AppText.caption.copyWith(
                          fontSize: 11,
                          color: state.apiKey.isEmpty
                              ? AppColors.textSecondary
                              : AppColors.success),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              Text(t(context, 'models'), style: AppText.label),
              const SizedBox(height: 8),
              ...freeModels.map((m) {
                final isSel = selected == m.id;
                return GestureDetector(
                  onTap: () => setSheet(() => selected = m.id),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 11),
                    decoration: BoxDecoration(
                      color:
                          isSel ? AppColors.accentDim : AppColors.surfaceAlt,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: isSel
                              ? AppColors.accent
                              : AppColors.borderSoft,
                          width: isSel ? 1.4 : 1),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isSel
                              ? Icons.radio_button_checked
                              : Icons.radio_button_off,
                          size: 18,
                          color: isSel
                              ? AppColors.accentSoft
                              : AppColors.textFaint,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(m.label, style: AppText.cardTitle),
                              Text(m.desc,
                                  style: AppText.caption.copyWith(
                                      fontSize: 11.5)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
              const SizedBox(height: 18),
              PrimaryButton(
                label: t(context, 'save'),
                icon: Icons.auto_awesome,
                onTap: () {
                  state.setAiConfig(model: selected);
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(t(context, 'save')),
                  ));
                },
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
