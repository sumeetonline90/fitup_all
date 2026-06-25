import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../features/profile/domain/entities/profile_enums.dart';
import '../../features/profile/domain/entities/user_profile.dart';
import '../../features/profile/presentation/providers/profile_providers.dart';

/// Left rail for tablet/desktop — collapsed (72px) or expanded (240px).
class SidebarNav extends ConsumerWidget {
  const SidebarNav({
    super.key,
    required this.width,
    required this.collapsed,
    required this.onToggleCollapsed,
    required this.currentIndex,
    required this.onDestinationSelected,
    required this.entries,
    required this.communityBadgeCount,
  });

  final double width;
  final bool collapsed;
  final VoidCallback onToggleCollapsed;
  final int currentIndex;
  final ValueChanged<int> onDestinationSelected;
  final List<SidebarNavEntry> entries;
  final int communityBadgeCount;

  static const double collapsedWidth = 72;
  static const double expandedWidth = 240;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<UserProfile> profileAsync = ref.watch(userProfileProvider);
    final AsyncValue<SubscriptionTier> tierAsync =
        ref.watch(subscriptionTierProvider);
    final String? displayName = profileAsync.value?.displayName;
    final String initial = (displayName != null && displayName.isNotEmpty)
        ? displayName.substring(0, 1).toUpperCase()
        : '?';
    final SubscriptionTier tier = tierAsync.value ?? SubscriptionTier.free;

    final List<Widget> navChildren = <Widget>[];
    String? lastHeader;
    for (int i = 0; i < entries.length; i++) {
      final SidebarNavEntry e = entries[i];
      final String? h = e.sectionLabel;
      if (h != null && h != lastHeader) {
        lastHeader = h;
        if (!collapsed) {
          navChildren.add(
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 12, 8, 4),
              child: Text(
                h,
                style: AppTextStyles.labelSmall.copyWith(
                  letterSpacing: 1.2,
                  color: AppColors.outlineVariant,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          );
        }
      }
      final bool showBadge =
          i == entries.length - 1 && communityBadgeCount > 0;
      navChildren.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 2),
          child: _NavTile(
            collapsed: collapsed,
            selected: currentIndex == i,
            entry: e,
            badgeCount: showBadge ? communityBadgeCount : 0,
            onTap: () => onDestinationSelected(i),
          ),
        ),
      );
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOutCubic,
      width: width,
      decoration: BoxDecoration(
        color: AppColors.background.withValues(alpha: 0.95),
        border: const Border(
          right: BorderSide(color: AppColors.outlineVariant, width: 0.5),
        ),
      ),
      child: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 16, 12, 8),
            child: Row(
              children: <Widget>[
                if (!collapsed) ...<Widget>[
                  ShaderMask(
                    shaderCallback: (Rect b) =>
                        AppColors.secondaryToPrimaryGradient.createShader(b),
                    child: const Icon(
                      Icons.favorite_rounded,
                      size: 28,
                      color: AppColors.onBackground,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ShaderMask(
                      shaderCallback: (Rect b) =>
                          AppColors.secondaryToPrimaryGradient.createShader(b),
                      child: Text(
                        'fitup',
                        style: AppTextStyles.headlineMedium.copyWith(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: AppColors.onBackground,
                        ),
                      ),
                    ),
                  ),
                ] else ...<Widget>[
                  Expanded(
                    child: Tooltip(
                      message: 'fitup',
                      child: ShaderMask(
                        shaderCallback: (Rect b) =>
                            AppColors.secondaryToPrimaryGradient.createShader(b),
                        child: const Icon(
                          Icons.favorite_rounded,
                          size: 28,
                          color: AppColors.onBackground,
                        ),
                      ),
                    ),
                  ),
                ],
                Tooltip(
                  message: collapsed ? 'Expand sidebar' : 'Collapse sidebar',
                  child: Material(
                    color: AppColors.surfaceContainer.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(10),
                    child: InkWell(
                      onTap: onToggleCollapsed,
                      borderRadius: BorderRadius.circular(10),
                      child: const SizedBox(
                        width: 40,
                        height: 48,
                        child: Icon(
                          Icons.menu_rounded,
                          color: AppColors.onSurfaceVariant,
                          size: 22,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              children: navChildren,
            ),
          ),
          const Divider(height: 1, color: AppColors.outlineVariant),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => context.push('/profile'),
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Row(
                    children: <Widget>[
                      Tooltip(
                        message: 'Profile',
                        child: Container(
                          width: 36,
                          height: 36,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: AppColors.secondaryToPrimaryGradient,
                            boxShadow: <BoxShadow>[
                              BoxShadow(
                                color: AppColors.primaryContainer
                                    .withValues(alpha: 0.35),
                                blurRadius: 12,
                              ),
                            ],
                          ),
                          child: Text(
                            initial,
                            style: AppTextStyles.labelLarge.copyWith(
                              color: AppColors.background,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                      if (!collapsed) ...<Widget>[
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                displayName ?? 'Profile',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTextStyles.bodySmall.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primary,
                                ),
                              ),
                              Text(
                                tier.name.toUpperCase(),
                                style: AppTextStyles.labelSmall.copyWith(
                                  color: AppColors.onSurfaceVariant,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      Tooltip(
                        message: 'Settings',
                        child: IconButton(
                          icon: const Icon(Icons.settings_outlined),
                          color: AppColors.onSurfaceVariant,
                          onPressed: () => context.push('/settings'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// One row in [SidebarNav].
class SidebarNavEntry {
  const SidebarNavEntry({
    required this.path,
    required this.iconOutlined,
    required this.iconFilled,
    required this.label,
    required this.semanticLabel,
    this.sectionLabel,
  });

  final String path;
  final IconData iconOutlined;
  final IconData iconFilled;
  final String label;
  final String semanticLabel;

  /// Shown once per section (e.g. "Main", "Community").
  final String? sectionLabel;
}

class _NavTile extends StatelessWidget {
  const _NavTile({
    required this.collapsed,
    required this.selected,
    required this.entry,
    required this.onTap,
    required this.badgeCount,
  });

  final bool collapsed;
  final bool selected;
  final SidebarNavEntry entry;
  final VoidCallback onTap;
  final int badgeCount;

  @override
  Widget build(BuildContext context) {
    final Color iconColor =
        selected ? AppColors.primaryContainer : AppColors.onSurfaceVariant;
    final Color labelColor =
        selected ? AppColors.primaryContainer : AppColors.onSurfaceVariant;

    final Widget row = Material(
      color: selected
          ? AppColors.primaryContainer.withValues(alpha: 0.12)
          : Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          child: Row(
            children: <Widget>[
              Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: selected
                      ? AppColors.primaryContainer.withValues(alpha: 0.15)
                      : Colors.transparent,
                ),
                child: Icon(
                  selected ? entry.iconFilled : entry.iconOutlined,
                  size: 22,
                  color: iconColor,
                ),
              ),
              if (!collapsed) ...<Widget>[
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    entry.label,
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                      color: labelColor,
                    ),
                  ),
                ),
                if (badgeCount > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.tertiary,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      badgeCount > 9 ? '9+' : '$badgeCount',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.background,
                        fontWeight: FontWeight.w800,
                        fontSize: 10,
                      ),
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );

    final Widget inner =
        collapsed ? Tooltip(message: entry.label, child: row) : row;

    return Semantics(
      selected: selected,
      label: entry.semanticLabel,
      button: true,
      child: inner,
    );
  }
}
