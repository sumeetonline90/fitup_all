import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../domain/entities/community_event.dart';
import '../providers/community_providers.dart';
import '../utils/leaderboard_ui_mapping.dart';

/// Per-event progress leaderboard (server-updated entries).
class EventLeaderboardScreen extends ConsumerWidget {
  const EventLeaderboardScreen({super.key, required this.eventId});

  final String eventId;

  static Color _glowForRank(int rank) {
    return switch (rank) {
      1 => AppColors.primaryContainer,
      2 => AppColors.secondary,
      3 => AppColors.tertiary,
      _ => AppColors.outlineVariant,
    };
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<MapEntry<String, int>>> entries = ref.watch(
      eventLeaderboardProvider(eventId),
    );
    final AsyncValue<CommunityEvent> eventAsync = ref.watch(
      eventByIdProvider(eventId),
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceContainer,
        foregroundColor: AppColors.onSurface,
        elevation: 0,
        title: const Text('Leaderboard'),
      ),
      body: entries.when(
        data: (List<MapEntry<String, int>> list) => ListView(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
          children: <Widget>[
            _HeaderCard(eventAsync: eventAsync),
            const SizedBox(height: 16),
            if (list.isEmpty)
              GlassCard(
                glowColor: AppColors.secondary,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 28,
                    horizontal: 12,
                  ),
                  child: Column(
                    children: <Widget>[
                      const Icon(
                        Icons.emoji_events_outlined,
                        size: 40,
                        color: AppColors.onSurfaceVariant,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'No scores yet',
                        style: AppTextStyles.headlineMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Progress will appear here as participants log activity.',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              )
            else
              ...list.asMap().entries.map((
                MapEntry<int, MapEntry<String, int>> e,
              ) {
                final int rank = e.key + 1;
                final MapEntry<String, int> raw = e.value;
                final row = leaderboardEntryToRow(rank, raw);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: GlassCard(
                    glowColor: _glowForRank(rank),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      leading: CircleAvatar(
                        backgroundColor: rank <= 3
                            ? _glowForRank(rank).withValues(alpha: 0.35)
                            : AppColors.surfaceContainerHighest,
                        foregroundColor: AppColors.onSurface,
                        child: Text(
                          row.avatarInitials,
                          style: AppTextStyles.labelLarge,
                        ),
                      ),
                      title: Text(
                        row.displayName,
                        style: AppTextStyles.labelLarge,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        'Updated hourly',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                      trailing: Text(
                        '${row.metricValue}',
                        style: AppTextStyles.headlineMedium.copyWith(
                          color: AppColors.onSurface,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                );
              }),
          ],
        ),
        loading: () => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const CircularProgressIndicator(
                color: AppColors.primaryContainer,
              ),
              const SizedBox(height: 16),
              Text(
                'Loading rankings…',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        error: (Object _, StackTrace __) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: GlassCard(
              glowColor: AppColors.error,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    const Icon(
                      Icons.error_outline,
                      color: AppColors.error,
                      size: 36,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Unable to load leaderboard',
                      style: AppTextStyles.headlineMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Check your connection and try again.',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({required this.eventAsync});

  final AsyncValue<CommunityEvent> eventAsync;

  @override
  Widget build(BuildContext context) {
    final String title = eventAsync.when(
      data: (CommunityEvent e) => e.title,
      loading: () => 'Loading event…',
      error: (Object _, StackTrace __) => 'Event',
    );
    return GlassCard(
      glowColor: AppColors.secondary,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              title,
              style: AppTextStyles.headlineMedium.copyWith(
                color: AppColors.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Live rankings for this event. Scores update on the server '
              'about once per hour.',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
