import 'dart:io';

import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../core/fmt.dart';
import '../data/models.dart';

class TopBar extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final VoidCallback? onMenu;
  final VoidCallback? onProfile;
  final List<Widget>? actions;
  final bool showProfile;
  final Widget? trailing;

  const TopBar({
    super.key,
    this.title,
    this.onMenu,
    this.onProfile,
    this.actions,
    this.showProfile = true,
    this.trailing,
  });

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
      child: SizedBox(
        height: 56,
        child: Row(
          children: [
            _IconBtn(
              icon: title == null ? Icons.menu_rounded : Icons.arrow_back_rounded,
              onTap: onMenu ?? () => Navigator.maybePop(context),
            ),
            Expanded(
              child: Text(
                title ?? '',
                textAlign: TextAlign.center,
                style: AppText.sectionHeading,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            trailing ??
                (showProfile
                    ? _IconBtn(
                        icon: Icons.account_circle_outlined,
                        onTap: onProfile ??
                            () => Navigator.pushNamed(context, '/profile'),
                      )
                    : const SizedBox(width: 46)),
          ],
        ),
      ),
    );
  }
}

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  const _IconBtn({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.borderSoft),
            color: AppColors.surface.withOpacity(0.5),
          ),
          child: Icon(icon, size: 22, color: AppColors.textSecondary),
        ),
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  final String title;
  final String? action;
  final VoidCallback? onAction;

  const SectionHeader(this.title, {super.key, this.action, this.onAction});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: AppText.sectionHeading),
          if (action != null)
            GestureDetector(
              onTap: onAction,
              child: Text(action!,
                  style: AppText.label.copyWith(color: AppColors.accentSoft)),
            ),
        ],
      ),
    );
  }
}

class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? color;
  final Gradient? gradient;
  final Border? border;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const AppCard({
    super.key,
    required this.child,
    this.padding = AppPadding.card,
    this.color,
    this.gradient,
    this.border,
    this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: Ink(
          decoration: BoxDecoration(
            color: color ?? AppColors.surface,
            gradient: gradient,
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: border ?? Border.all(color: AppColors.borderSoft),
            ),
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final IconData? icon;
  final bool gradient;

  const PrimaryButton({
    super.key,
    required this.label,
    this.onTap,
    this.icon,
    this.gradient = true,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.button),
        child: Ink(
          height: 52,
          decoration: BoxDecoration(
            gradient: gradient ? AppColors.fabGradient : null,
            color: gradient ? null : AppColors.surfaceAlt,
            borderRadius: BorderRadius.circular(AppRadius.button),
            border: gradient
                ? null
                : Border.all(color: AppColors.border),
            boxShadow: gradient
                ? [
                    BoxShadow(
                      color: AppColors.accent.withOpacity(0.35),
                      blurRadius: 22,
                      offset: const Offset(0, 8),
                    )
                  ]
                : null,
          ),
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 20, color: gradient ? Colors.white : AppColors.textPrimary),
                  const SizedBox(width: 8),
                ],
                Text(
                  label,
                  style: gradient
                      ? AppText.button
                      : AppText.button.copyWith(color: AppColors.textPrimary),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ItemTypeBadge {
  static IconData icon(ItemType t) {
    switch (t) {
      case ItemType.screenshot:
        return Icons.crop_square_rounded;
      case ItemType.document:
        return Icons.description_outlined;
      case ItemType.note:
        return Icons.sticky_note_2_outlined;
      case ItemType.receipt:
        return Icons.receipt_long_outlined;
      case ItemType.ticket:
        return Icons.local_activity_outlined;
    }
  }

  static Color color(ItemType t) {
    switch (t) {
      case ItemType.screenshot:
        return const Color(0xFF60A5FA);
      case ItemType.document:
        return AppColors.accentSoft;
      case ItemType.note:
        return const Color(0xFF34D399);
      case ItemType.receipt:
        return const Color(0xFFFBBF24);
      case ItemType.ticket:
        return const Color(0xFFF472B6);
    }
  }
}

class ItemTile extends StatelessWidget {
  final LifeItem item;
  final VoidCallback? onTap;

  const ItemTile({super.key, required this.item, this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = ItemTypeBadge.color(item.type);
    return AppCard(
      padding: const EdgeInsets.all(12),
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: c.withOpacity(0.14),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: c.withOpacity(0.35)),
            ),
            child: item.imagePath != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(11),
                    child: Image.file(File(item.imagePath!),
                        cacheWidth: 160,
                        fit: BoxFit.cover, errorBuilder: (_, __, ___) =>
                            Icon(ItemTypeBadge.icon(item.type), color: c, size: 22)),
                  )
                : Icon(ItemTypeBadge.icon(item.type), color: c, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(item.title,
                          style: AppText.cardTitle,
                          overflow: TextOverflow.ellipsis),
                    ),
                    if (item.important)
                      Icon(Icons.bookmark_rounded,
                          size: 16, color: AppColors.accentSoft),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  '${item.type.label} · ${Fmt.relative(item.createdAt)}',
                  style: AppText.caption,
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Icon(Icons.chevron_right_rounded,
              color: AppColors.textFaint, size: 22),
        ],
      ),
    );
  }
}
