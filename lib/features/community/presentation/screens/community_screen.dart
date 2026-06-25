import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../../../shared/widgets/module_top_header.dart';
import '../../../../shared/widgets/neon_outline_button.dart';
import '../../../fitcoins/domain/entities/fitcoin_wallet.dart';
import '../../domain/entities/community_challenge.dart';
import '../../domain/entities/community_event.dart';
import '../../domain/entities/feed_post.dart';
import '../providers/community_providers.dart';

/// Community hub — bottom tab root.
class CommunityScreen extends ConsumerWidget {
  const CommunityScreen({super.key});

  static String _fmtFc(int n) => NumberFormat.decimalPattern().format(n);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<FitcoinWallet> wallet = ref.watch(fitcoinWalletStreamProvider);
    final AsyncValue<List<CommunityEvent>> eventsAsync =
        ref.watch(upcomingEventsProvider);
    final AsyncValue<List<CommunityChallenge>> challengesAsync =
        ref.watch(activeChallengesProvider);
    final AsyncValue<List<FeedPost>> teaserAsync =
        ref.watch(communityFeedTeaserProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        top: true,
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
          children: <Widget>[
          const ModuleTopHeader(),
          const SizedBox(height: 8),
          NeonOutlineButton(
            label: 'Event AI',
            onPressed: () => context.push('/insights'),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: IconButton(
              onPressed: () {},
              icon: const Icon(Icons.notifications_outlined),
              color: AppColors.onSurfaceVariant,
            ),
          ),
          wallet.when(
            data: (FitcoinWallet w) => InkWell(
              onTap: () => context.push('/community/wallet'),
              borderRadius: BorderRadius.circular(16),
              child: GlassCard(
                glowColor: AppColors.secondary,
                child: Row(
                  children: <Widget>[
                    Image.asset(
                      'assets/images/fitcoins.png',
                      width: 48,
                      height: 48,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.monetization_on_outlined,
                        size: 40,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            '${_fmtFc(w.balance)} FC',
                            style: AppTextStyles.headlineLarge.copyWith(
                              fontSize: 28,
                            ),
                          ),
                          Text(
                            'Earned today: +${_fmtFc(w.earnedToday)} FC',
                            style: AppTextStyles.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: AppColors.onSurfaceVariant),
                  ],
                ),
              ),
            ),
            loading: () => const GlassCard(
              child: SizedBox(
                height: 72,
                child: Center(child: CircularProgressIndicator()),
              ),
            ),
            error: (_, __) => GlassCard(
              child: Text(
                'Wallet unavailable',
                style: AppTextStyles.bodyMedium,
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: <Widget>[
                _QuickChip(
                  label: 'Create Event',
                  onTap: () => context.push('/community/events/create'),
                ),
                _QuickChip(
                  label: 'Events',
                  onTap: () => context.push('/community/events'),
                ),
                _QuickChip(
                  label: 'Search Code',
                  onTap: () => context.push('/community/events/search'),
                ),
                _QuickChip(
                  label: 'Challenges',
                  onTap: () => context.push('/community/challenges/create'),
                ),
                _QuickChip(
                  label: 'Leaderboard',
                  onTap: () => context.push('/community/leaderboard'),
                ),
                _QuickChip(
                  label: 'Friends',
                  onTap: () => context.push('/community/feed'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _SectionHeader(
            title: 'Upcoming Events',
            actionLabel: 'View All',
            onAction: () => context.push('/community/events'),
          ),
          const SizedBox(height: 12),
          eventsAsync.when(
            data: (List<CommunityEvent> events) => SizedBox(
              height: 168,
              child: events.isEmpty
                  ? Center(
                      child: Text(
                        'No upcoming events yet',
                        style: AppTextStyles.bodyMedium,
                      ),
                    )
                  : ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: events.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 12),
                      itemBuilder: (BuildContext context, int i) {
                        return _EventCard(event: events[i]);
                      },
                    ),
            ),
            loading: () => const SizedBox(
              height: 168,
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (Object e, StackTrace _) => _RetrySection(
              message: e is Failure ? (e.message ?? 'Could not load events') : 'Error',
              onRetry: () => ref.invalidate(upcomingEventsProvider),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Text(
                'Active Challenges',
                style: AppTextStyles.headlineMedium.copyWith(fontSize: 18),
              ),
              TextButton(
                onPressed: () =>
                    context.push('/community/challenges/create'),
                child: Text(
                  'New Challenge',
                  style: AppTextStyles.labelLarge.copyWith(
                    color: AppColors.secondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          challengesAsync.when(
            data: (List<CommunityChallenge> challenges) {
              if (challenges.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    'No active challenges',
                    style: AppTextStyles.bodyMedium,
                  ),
                );
              }
              return Column(
                children: challenges
                    .map(
                      (CommunityChallenge c) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _ChallengeCard(challenge: c),
                      ),
                    )
                    .toList(),
              );
            },
            loading: () => const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (Object e, StackTrace _) => _RetrySection(
              message: e is Failure ? (e.message ?? 'Could not load challenges') : 'Error',
              onRetry: () => ref.invalidate(activeChallengesProvider),
            ),
          ),
          const SizedBox(height: 12),
          GlassCard(
            child: ExpansionTile(
              tilePadding: const EdgeInsets.symmetric(horizontal: 16),
              title: Text(
                'AI Plan Guide',
                style: AppTextStyles.labelLarge.copyWith(
                  color: AppColors.secondary,
                ),
              ),
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: Text(
                    'Holistic plan is generated first (with start/end dates), then each module plan can be amended. '
                    'Only one holistic plan stays active at a time. '
                    'Every day the app checks your adherence against active plan targets and may show supportive nudges. '
                    'This is not medical advice.',
                    style: AppTextStyles.bodySmall,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _SectionHeader(
            title: 'Feed',
            actionLabel: 'View Feed',
            onAction: () => context.push('/community/feed'),
          ),
          const SizedBox(height: 12),
          teaserAsync.when(
            data: (List<FeedPost> teasers) {
              if (teasers.isEmpty) {
                return GlassCard(
                  child: Text(
                    'No posts in your feed yet',
                    style: AppTextStyles.bodyMedium,
                  ),
                );
              }
              return Column(
                children: teasers
                    .map(
                      (FeedPost p) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: GlassCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                p.authorName,
                                style: AppTextStyles.labelLarge,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                p.body ??
                                    p.achievementTitle ??
                                    p.milestoneTitle ??
                                    'Update',
                                style: AppTextStyles.bodySmall,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                    .toList(),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => _RetrySection(
              message: 'Feed unavailable',
              onRetry: () => ref.invalidate(socialFeedProvider),
            ),
          ),
          ],
        ),
      ),
    );
  }
}

class _RetrySection extends StatelessWidget {
  const _RetrySection({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(message, style: AppTextStyles.bodyMedium),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: onRetry,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.actionLabel,
    required this.onAction,
  });

  final String title;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        Text(
          title,
          style: AppTextStyles.headlineMedium.copyWith(fontSize: 18),
        ),
        TextButton(
          onPressed: onAction,
          child: Text(
            actionLabel,
            style: AppTextStyles.labelLarge.copyWith(color: AppColors.secondary),
          ),
        ),
      ],
    );
  }
}

class _QuickChip extends StatelessWidget {
  const _QuickChip({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ActionChip(
        label: Text(label, style: AppTextStyles.labelSmall),
        onPressed: onTap,
        backgroundColor: AppColors.surfaceContainer.withValues(alpha: 0.65),
        side: BorderSide(color: AppColors.glassBorder),
      ),
    );
  }
}

class _EventCard extends StatelessWidget {
  const _EventCard({required this.event});

  final CommunityEvent event;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      child: InkWell(
        onTap: () => context.push('/community/events/${event.id}'),
        borderRadius: BorderRadius.circular(16),
        child: GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                event.title,
                style: AppTextStyles.labelLarge,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.secondary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  event.type.name,
                  style: AppTextStyles.labelSmall,
                ),
              ),
              const Spacer(),
              Text(
                DateFormat.MMMd().add_jm().format(event.startsAt),
                style: AppTextStyles.bodySmall,
              ),
              Text(
                '${event.participantCount} joined · ${event.distanceKm != null ? '${event.distanceKm}' : '—'} km · +${event.rewardFc} FC',
                style: AppTextStyles.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChallengeCard extends StatelessWidget {
  const _ChallengeCard({required this.challenge});

  final CommunityChallenge challenge;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(challenge.title, style: AppTextStyles.labelLarge),
          const SizedBox(height: 6),
          Text(
            challenge.metricLabel,
            style: AppTextStyles.bodySmall,
          ),
          Text(
            'Ends ${DateFormat.MMMd().format(challenge.endsAt)}',
            style: AppTextStyles.bodySmall,
          ),
          const SizedBox(height: 8),
          Text(
            'You ${challenge.yourScore} vs ${challenge.opponentName} ${challenge.opponentScore} · Rank #${challenge.yourRank}',
            style: AppTextStyles.bodyMedium,
          ),
        ],
      ),
    );
  }
}

// Intentionally no podium preview widget anymore (removed overflow section).
