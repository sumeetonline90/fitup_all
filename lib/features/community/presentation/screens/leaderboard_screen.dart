import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../../auth/domain/entities/fitup_user.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../domain/entities/leaderboard_models.dart';
import '../providers/community_providers.dart';
import '../utils/leaderboard_ui_mapping.dart';

class LeaderboardScreen extends ConsumerStatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  ConsumerState<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends ConsumerState<LeaderboardScreen> {
  LeaderboardPeriod _period = LeaderboardPeriod.week;
  LeaderboardMetric _metric = LeaderboardMetric.steps;

  @override
  Widget build(BuildContext context) {
    final LeaderboardQuery q = (
      period: _period,
      metric: _metric,
    );
    final AsyncValue<List<MapEntry<String, int>>> asyncEntries =
        ref.watch(leaderboardEntriesProvider(q));
    final AsyncValue<FitupUser?> auth = ref.watch(authStateProvider);
    final FitupUser? me = switch (auth) {
      AsyncData<FitupUser?>(:final value) => value,
      _ => null,
    };

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceContainer,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Leaderboard',
          style: AppTextStyles.headlineMedium.copyWith(fontSize: 18),
        ),
      ),
      body: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: LeaderboardPeriod.values.map((LeaderboardPeriod p) {
                final bool sel = _period == p;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: ChoiceChip(
                      label: Text(
                        switch (p) {
                          LeaderboardPeriod.week => 'This Week',
                          LeaderboardPeriod.month => 'This Month',
                          LeaderboardPeriod.allTime => 'All Time',
                        },
                        style: AppTextStyles.labelSmall,
                      ),
                      selected: sel,
                      onSelected: (_) => setState(() => _period = p),
                      selectedColor: AppColors.secondary.withValues(alpha: 0.3),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: LeaderboardMetric.values.map((LeaderboardMetric m) {
                final bool sel = _metric == m;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(
                      switch (m) {
                        LeaderboardMetric.steps => 'Steps',
                        LeaderboardMetric.workouts => 'Workouts',
                        LeaderboardMetric.fitcoins => 'Fitcoins',
                        LeaderboardMetric.challenges => 'Challenges',
                      },
                      style: AppTextStyles.labelSmall,
                    ),
                    selected: sel,
                    onSelected: (_) => setState(() => _metric = m),
                    selectedColor: AppColors.secondary.withValues(alpha: 0.25),
                  ),
                );
              }).toList(),
            ),
          ),
          Expanded(
            child: asyncEntries.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (Object e, StackTrace _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text(
                        e is Failure
                            ? (e.message ?? 'Could not load leaderboard')
                            : 'Error',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: () =>
                            ref.invalidate(leaderboardEntriesProvider(q)),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ),
              data: (List<MapEntry<String, int>> entries) {
                final LeaderboardPodium? podium =
                    leaderboardPodiumFromEntries(entries);
                final List<LeaderboardRow> rest = <LeaderboardRow>[];
                for (int i = 3; i < entries.length; i++) {
                  final MapEntry<String, int> e = entries[i];
                  if (me != null && e.key == me.id) {
                    continue;
                  }
                  rest.add(leaderboardEntryToRow(i + 1, e));
                }
                final LeaderboardRow you = me != null
                    ? yourLeaderboardRow(me: me, entries: entries)
                    : const LeaderboardRow(
                        rank: 0,
                        displayName: 'Sign in',
                        handle: '',
                        metricValue: 0,
                        avatarInitials: '?',
                      );
                final int gap = gapToThirdPlace(entries, me);

                return ListView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                  children: <Widget>[
                    if (podium != null)
                      GlassCard(
                        child: SizedBox(
                          height: 200,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: <Widget>[
                              _podiumBar(
                                context,
                                rank: 2,
                                row: podium.second,
                                height: 120,
                                color: AppColors.secondary,
                                icon: null,
                              ),
                              _podiumBar(
                                context,
                                rank: 1,
                                row: podium.first,
                                height: 160,
                                color: AppColors.primary,
                                icon: Icons.emoji_events,
                              ),
                              _podiumBar(
                                context,
                                rank: 3,
                                row: podium.third,
                                height: 96,
                                color: AppColors.tertiary,
                                icon: null,
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      GlassCard(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            entries.isEmpty
                                ? 'No rankings yet for this period.'
                                : 'Not enough players for a podium yet.',
                            style: AppTextStyles.bodyMedium,
                          ),
                        ),
                      ),
                    const SizedBox(height: 16),
                    ...rest.map((LeaderboardRow r) => _rankRow(r)),
                    const SizedBox(height: 12),
                    Text(
                      'You',
                      style: AppTextStyles.labelSmall,
                    ),
                    const SizedBox(height: 6),
                    _rankRow(
                      you,
                      highlight: true,
                      footer: me != null && gap > 0 && you.rank > 3
                          ? '$gap more to reach #3'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    GlassCard(
                      child: Text(
                        'Reach your goals to climb the board — rewards update from the server (ADR-023).',
                        style: AppTextStyles.bodyMedium,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _podiumBar(
    BuildContext context, {
    required int rank,
    required LeaderboardRow row,
    required double height,
    required Color color,
    IconData? icon,
  }) {
    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: <Widget>[
          CircleAvatar(
            radius: 22,
            backgroundColor: color.withValues(alpha: 0.25),
            child: Text(row.avatarInitials, style: AppTextStyles.labelLarge),
          ),
          const SizedBox(height: 6),
          Text(
            row.displayName,
            style: AppTextStyles.bodySmall,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            '${row.metricValue}',
            style: AppTextStyles.labelLarge,
          ),
          const SizedBox(height: 6),
          Container(
            height: height,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: <Color>[
                  color.withValues(alpha: 0.45),
                  color.withValues(alpha: 0.12),
                ],
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              border: Border.all(color: color.withValues(alpha: 0.5)),
              boxShadow: rank == 1
                  ? <BoxShadow>[
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.35),
                        blurRadius: 18,
                      ),
                    ]
                  : null,
            ),
            child: Center(
              child: icon != null
                  ? Icon(icon, color: AppColors.primary, size: 32)
                  : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _rankRow(
    LeaderboardRow r, {
    bool highlight = false,
    String? footer,
  }) {
    IconData trendIcon = Icons.remove;
    Color trendColor = AppColors.onSurfaceVariant;
    if (r.trend > 0) {
      trendIcon = Icons.arrow_upward;
      trendColor = AppColors.primaryContainer;
    } else if (r.trend < 0) {
      trendIcon = Icons.arrow_downward;
      trendColor = AppColors.tertiary;
    }
    final String rankLabel = r.rank == 0 ? '—' : '${r.rank}';
    final Widget card = GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: <Widget>[
          SizedBox(
            width: 28,
            child: Text(rankLabel, style: AppTextStyles.labelLarge),
          ),
          CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.surfaceContainerHighest,
            child: Text(
              r.avatarInitials,
              style: AppTextStyles.labelSmall,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(r.displayName, style: AppTextStyles.bodyLarge),
                Text(r.handle, style: AppTextStyles.bodySmall),
              ],
            ),
          ),
          Text(
            '${r.metricValue}',
            style: AppTextStyles.labelLarge,
          ),
          Icon(trendIcon, color: trendColor, size: 18),
        ],
      ),
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          DecoratedBox(
            decoration: highlight
                ? BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.secondary, width: 2),
                  )
                : const BoxDecoration(),
            child: card,
          ),
          if (highlight && footer != null) ...<Widget>[
            const SizedBox(height: 6),
            Text(footer, style: AppTextStyles.bodySmall),
          ],
        ],
      ),
    );
  }
}
