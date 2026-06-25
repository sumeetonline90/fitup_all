import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../layout/app_breakpoints.dart';
import 'sidebar_nav.dart';
import 'web_top_bar.dart';

/// Responsive shell: bottom nav on narrow viewports; sidebar + top bar on tablet/desktop.
class AppShell extends ConsumerStatefulWidget {
  const AppShell({
    super.key,
    required this.navigationShell,
    required this.navEntries,
    required this.moduleLabelForIndex,
    required this.communityBadgeCount,
  });

  final StatefulNavigationShell navigationShell;
  final List<SidebarNavEntry> navEntries;
  final String Function(int index) moduleLabelForIndex;
  final int communityBadgeCount;

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  late final ValueNotifier<bool> _collapsed;
  bool _inited = false;

  @override
  void initState() {
    super.initState();
    _collapsed = ValueNotifier<bool>(true);
  }

  @override
  void dispose() {
    _collapsed.dispose();
    super.dispose();
  }

  void _ensureInitialCollapse(double width) {
    if (_inited) {
      return;
    }
    _inited = true;
    _collapsed.value = width < kTabletBreak;
  }

  void _showSearchStub(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceContainer,
        title: Text(
          'Search',
          style: Theme.of(ctx).textTheme.titleLarge,
        ),
        content: TextField(
          autofocus: true,
          style: Theme.of(ctx).textTheme.bodyLarge,
          decoration: const InputDecoration(
            labelText: 'Search Fitup',
            hintText: 'Try activities, meals, workouts…',
            border: OutlineInputBorder(),
          ),
          onSubmitted: (_) => Navigator.of(ctx).pop(),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.sizeOf(context).width;
    _ensureInitialCollapse(width);
    final bool useWideShell = width >= kMobileBreak;

    return ListenableBuilder(
      listenable: _collapsed,
      builder: (BuildContext context, _) {
        final bool collapsed = _collapsed.value;
        final double sidebarW = collapsed
            ? SidebarNav.collapsedWidth
            : SidebarNav.expandedWidth;

        if (!useWideShell) {
          return _MobileShell(
            navigationShell: widget.navigationShell,
            navEntries: widget.navEntries,
            communityBadgeCount: widget.communityBadgeCount,
          );
        }

        return Scaffold(
          backgroundColor: AppColors.background,
          body: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              SidebarNav(
                width: sidebarW,
                collapsed: collapsed,
                onToggleCollapsed: () => _collapsed.value = !_collapsed.value,
                currentIndex: widget.navigationShell.currentIndex,
                onDestinationSelected: (int index) {
                  widget.navigationShell.goBranch(
                    index,
                    initialLocation:
                        index == widget.navigationShell.currentIndex,
                  );
                },
                entries: widget.navEntries,
                communityBadgeCount: widget.communityBadgeCount,
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    WebTopBar(
                      moduleLabel: widget.moduleLabelForIndex(
                        widget.navigationShell.currentIndex,
                      ),
                      onSearchTap: () => _showSearchStub(context),
                    ),
                    Expanded(child: widget.navigationShell),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _MobileShell extends ConsumerWidget {
  const _MobileShell({
    required this.navigationShell,
    required this.navEntries,
    required this.communityBadgeCount,
  });

  final StatefulNavigationShell navigationShell;
  final List<SidebarNavEntry> navEntries;
  final int communityBadgeCount;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: navigationShell,
      bottomNavigationBar: _MobileBottomNav(
        navigationShell: navigationShell,
        navEntries: navEntries,
        communityBadgeCount: communityBadgeCount,
      ),
    );
  }
}

class _MobileBottomNav extends StatelessWidget {
  const _MobileBottomNav({
    required this.navigationShell,
    required this.navEntries,
    required this.communityBadgeCount,
  });

  final StatefulNavigationShell navigationShell;
  final List<SidebarNavEntry> navEntries;
  final int communityBadgeCount;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.outlineVariant)),
      ),
      child: NavigationBar(
        height: 64,
        backgroundColor: AppColors.background,
        indicatorColor: Colors.transparent,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysHide,
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (int index) {
          navigationShell.goBranch(
            index,
            initialLocation: index == navigationShell.currentIndex,
          );
        },
        destinations: <NavigationDestination>[
          for (int i = 0; i < navEntries.length; i++)
            NavigationDestination(
              icon: _NavIcon(
                outlined: navEntries[i].iconOutlined,
                filled: navEntries[i].iconFilled,
                selected: false,
                showDot: i == navEntries.length - 1 && communityBadgeCount > 0,
              ),
              selectedIcon: _NavIcon(
                outlined: navEntries[i].iconOutlined,
                filled: navEntries[i].iconFilled,
                selected: true,
                showDot: i == navEntries.length - 1 && communityBadgeCount > 0,
              ),
              label: navEntries[i].semanticLabel,
            ),
        ],
      ),
    );
  }
}

class _NavIcon extends StatelessWidget {
  const _NavIcon({
    required this.outlined,
    required this.filled,
    required this.selected,
    required this.showDot,
  });

  final IconData outlined;
  final IconData filled;
  final bool selected;
  final bool showDot;

  @override
  Widget build(BuildContext context) {
    final IconData icon = selected ? filled : outlined;
    final Color color = selected
        ? AppColors.secondary
        : AppColors.onSurfaceVariant;
    return Stack(
      clipBehavior: Clip.none,
      children: <Widget>[
        Icon(icon, color: color),
        if (showDot)
          Positioned(
            right: -2,
            top: -2,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.secondary,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.background, width: 1.5),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: AppColors.secondary.withValues(alpha: 0.45),
                    blurRadius: 6,
                  ),
                ],
              ),
              child: const SizedBox.square(dimension: 8),
            ),
          ),
      ],
    );
  }
}
