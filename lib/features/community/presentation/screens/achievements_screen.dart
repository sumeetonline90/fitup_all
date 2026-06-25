import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../../fitcoins/domain/entities/fitcoin_wallet.dart';
import '../../domain/entities/achievement_item.dart';
import '../providers/community_providers.dart';
import '../widgets/achievement_material_icon.dart';

class AchievementsScreen extends ConsumerStatefulWidget {
  const AchievementsScreen({super.key});

  @override
  ConsumerState<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends ConsumerState<AchievementsScreen> {
  AchievementCategory _filter = AchievementCategory.all;

  @override
  Widget build(BuildContext context) {
    final List<AchievementItem> all = ref.watch(achievementsCatalogProvider);
    final AsyncValue<FitcoinWallet> wallet =
        ref.watch(fitcoinWalletStreamProvider);
    final List<AchievementItem> filtered = _filter == AchievementCategory.all
        ? all
        : all.where((AchievementItem a) => a.category == _filter).toList();
    final List<AchievementItem> unlocked =
        filtered.where((AchievementItem a) => a.unlocked).toList();
    final List<AchievementItem> progress = filtered
        .where(
          (AchievementItem a) =>
              !a.unlocked &&
              a.progressNumerator != null &&
              a.progressDenominator != null,
        )
        .toList();
    final List<AchievementItem> locked =
        filtered.where((AchievementItem a) => !a.unlocked && a.progressNumerator == null).toList();

    final int total = all.length;
    final int unlockedCount = all.where((AchievementItem a) => a.unlocked).length;
    final int close = all
        .where(
          (AchievementItem a) =>
              !a.unlocked &&
              a.progressDenominator != null &&
              a.progressNumerator != null &&
              a.progressDenominator! - a.progressNumerator! <= 2,
        )
        .length;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceContainer,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Achievements',
          style: AppTextStyles.headlineMedium.copyWith(fontSize: 18),
        ),
        actions: <Widget>[
          wallet.when(
            data: (dynamic w) => Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: AppColors.glassBorder),
                  ),
                  child: Text(
                    '${NumberFormat.decimalPattern().format(w.balance)} FC',
                    style: AppTextStyles.labelLarge.copyWith(color: AppColors.primary),
                  ),
                ),
              ),
            ),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        children: <Widget>[
          GlassCard(
            child: Row(
              children: <Widget>[
                SizedBox(
                  width: 100,
                  height: 100,
                  child: CustomPaint(
                    painter: _RingPainter(
                      progress: total == 0 ? 0 : unlockedCount / total,
                    ),
                    child: Center(
                      child: Text(
                        '$unlockedCount/$total',
                        style: AppTextStyles.headlineMedium,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        '$unlockedCount badges unlocked of $total',
                        style: AppTextStyles.bodyLarge,
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: LinearProgressIndicator(
                          value: total == 0 ? 0 : unlockedCount / total,
                          minHeight: 8,
                          backgroundColor: AppColors.surfaceContainerHighest,
                          color: AppColors.secondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '$close badges close to unlock',
                        style: AppTextStyles.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: AchievementCategory.values.map((AchievementCategory c) {
              final bool sel = _filter == c;
              return FilterChip(
                label: Text(
                  switch (c) {
                    AchievementCategory.all => 'All',
                    AchievementCategory.activity => 'Activity',
                    AchievementCategory.workout => 'Workout',
                    AchievementCategory.diet => 'Diet',
                    AchievementCategory.streaks => 'Streaks',
                    AchievementCategory.social => 'Social',
                  },
                  style: AppTextStyles.labelSmall,
                ),
                selected: sel,
                onSelected: (_) => setState(() => _filter = c),
                selectedColor: AppColors.secondary.withValues(alpha: 0.25),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          Text(
            'Recently Unlocked',
            style: AppTextStyles.headlineMedium.copyWith(fontSize: 18),
          ),
          const SizedBox(height: 10),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 3,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 0.85,
            children: unlocked
                .map(
                  (AchievementItem a) => _BadgeTile(
                    item: a,
                    locked: false,
                    pulse: a.isNew,
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 20),
          Text(
            'In Progress',
            style: AppTextStyles.headlineMedium.copyWith(fontSize: 18),
          ),
          const SizedBox(height: 10),
          ...progress.map(
            (AchievementItem a) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Icon(achievementIconDataForCodePoint(a.iconCodePoint)),
                        const SizedBox(width: 8),
                        Expanded(child: Text(a.name, style: AppTextStyles.labelLarge)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: a.progressDenominator == null || a.progressDenominator == 0
                          ? 0
                          : (a.progressNumerator ?? 0) / a.progressDenominator!,
                      backgroundColor: AppColors.surfaceContainerHighest,
                      color: AppColors.primaryContainer,
                    ),
                    Text(
                      '${a.progressDenominator! - (a.progressNumerator ?? 0)} to go',
                      style: AppTextStyles.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Locked',
            style: AppTextStyles.headlineMedium.copyWith(fontSize: 18),
          ),
          const SizedBox(height: 10),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 4,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 0.75,
            children: locked
                .map(
                  (AchievementItem a) => Opacity(
                    opacity: 0.45,
                    child: Stack(
                      fit: StackFit.expand,
                      children: <Widget>[
                        _BadgeTile(item: a, locked: true, pulse: false),
                        const Center(
                          child: Icon(Icons.lock, color: AppColors.onSurface),
                        ),
                      ],
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final Offset c = Offset(size.width / 2, size.height / 2);
    final double r = size.shortestSide / 2 - 6;
    final Paint bg = Paint()
      ..color = AppColors.surfaceContainerHighest
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10;
    final Paint fg = Paint()
      ..color = AppColors.secondary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(c, r, bg);
    final double sweep = 2 * math.pi * progress.clamp(0.0, 1.0);
    canvas.drawArc(
      Rect.fromCircle(center: c, radius: r),
      -math.pi / 2,
      sweep,
      false,
      fg,
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

class _BadgeTile extends StatefulWidget {
  const _BadgeTile({
    required this.item,
    required this.locked,
    required this.pulse,
  });

  final AchievementItem item;
  final bool locked;
  final bool pulse;

  @override
  State<_BadgeTile> createState() => _BadgeTileState();
}

class _BadgeTileState extends State<_BadgeTile>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    if (widget.pulse) {
      _pulse.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (BuildContext context, Widget? child) {
        final double g = widget.pulse ? 0.15 + 0.15 * _pulse.value : 0.0;
        return GlassCard(
          padding: const EdgeInsets.all(8),
          glowColor: widget.pulse ? AppColors.primary : null,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Icon(
                achievementIconDataForCodePoint(widget.item.iconCodePoint),
                size: 28 + g * 8,
                color: widget.locked
                    ? AppColors.onSurfaceVariant
                    : AppColors.primary,
              ),
              const SizedBox(height: 4),
              Text(
                widget.item.name,
                style: AppTextStyles.bodySmall,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (widget.item.unlockDate != null)
                Text(
                  DateFormat.MMMd().format(widget.item.unlockDate!),
                  style: AppTextStyles.bodySmall.copyWith(fontSize: 10),
                ),
            ],
          ),
        );
      },
    );
  }
}
