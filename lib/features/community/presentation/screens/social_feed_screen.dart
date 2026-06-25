import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/fitup_logo.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../../auth/domain/entities/fitup_user.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../domain/entities/feed_post.dart';
import '../../domain/entities/report_reason.dart';
import '../providers/community_mock_data.dart';
import '../providers/community_providers.dart';
import '../widgets/community_report_sheet.dart';

class SocialFeedScreen extends ConsumerStatefulWidget {
  const SocialFeedScreen({super.key});

  @override
  ConsumerState<SocialFeedScreen> createState() => _SocialFeedScreenState();
}

class _SocialFeedScreenState extends ConsumerState<SocialFeedScreen> {
  bool _showFab = true;
  final ScrollController _scroll = ScrollController();
  bool _loadMoreScheduled = false;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
  }

  void _onScroll() {
    if (!_scroll.hasClients) {
      return;
    }
    final double max = _scroll.position.maxScrollExtent;
    if (max <= 0) {
      return;
    }
    if (_scroll.position.pixels >= max - 320 && !_loadMoreScheduled) {
      _loadMoreScheduled = true;
      ref.read(socialFeedProvider.notifier).loadMore().whenComplete(() {
        if (mounted) {
          _loadMoreScheduled = false;
        }
      });
    }
  }

  @override
  void dispose() {
    _scroll.removeListener(_onScroll);
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _onRefresh() async {
    ref.invalidate(socialFeedProvider);
    await ref.read(socialFeedProvider.future);
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<List<FeedPost>> feed = ref.watch(socialFeedProvider);
    final List<FeedStory> stories = mockStories;
    final FitupUser? me = switch (ref.watch(authStateProvider)) {
      AsyncData<FitupUser?>(:final value) => value,
      _ => null,
    };

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceContainer,
        title: Row(
          children: <Widget>[
            const FitupLogo(size: 28),
            const SizedBox(width: 10),
            Text(
              'Feed',
              style: AppTextStyles.headlineMedium.copyWith(fontSize: 18),
            ),
          ],
        ),
        actions: <Widget>[
          IconButton(icon: const Icon(Icons.search), onPressed: () {}),
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {},
          ),
        ],
      ),
      floatingActionButton: _showFab
          ? FloatingActionButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Compose — coming soon')),
                );
              },
              backgroundColor: AppColors.secondary,
              child: const Icon(Icons.edit, color: AppColors.background),
            )
          : null,
      body: NotificationListener<ScrollNotification>(
        onNotification: (ScrollNotification n) {
          if (n.metrics.pixels > 48 && _showFab) {
            setState(() => _showFab = false);
          } else if (n.metrics.pixels <= 24 && !_showFab) {
            setState(() => _showFab = true);
          }
          return false;
        },
        child: feed.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (Object e, StackTrace _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    e is Failure ? e.message ?? 'Error' : 'Could not load feed',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () => ref.invalidate(socialFeedProvider),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
          data: (List<FeedPost> posts) => RefreshIndicator(
            color: AppColors.secondary,
            onRefresh: _onRefresh,
            child: CustomScrollView(
              controller: _scroll,
              slivers: <Widget>[
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 96,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      children: <Widget>[
                        Column(
                          children: <Widget>[
                            Container(
                              width: 64,
                              height: 64,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppColors.secondary,
                                  width: 2,
                                ),
                              ),
                              child: const Icon(
                                Icons.add,
                                color: AppColors.secondary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text('Your story', style: AppTextStyles.bodySmall),
                          ],
                        ),
                        const SizedBox(width: 12),
                        ...stories.map((FeedStory s) => _StoryAvatar(story: s)),
                      ],
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Container(
                    height: 12,
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainer.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                SliverList(
                  delegate: SliverChildBuilderDelegate((
                    BuildContext context,
                    int i,
                  ) {
                    final FeedPost p = posts[i];
                    return _FeedPostCard(
                      post: p,
                      currentUserId: me?.id,
                      onLike: () async {
                        if (me == null) {
                          return;
                        }
                        final result = await ref
                            .read(communityRepositoryProvider)
                            .likePost(me.id, p.id);
                        result.fold((Failure f) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(f.message ?? 'Like failed')),
                          );
                        }, (_) => ref.invalidate(socialFeedProvider));
                      },
                      onReport: () {
                        if (me == null) {
                          return;
                        }
                        showModalBottomSheet<void>(
                          context: context,
                          backgroundColor: AppColors.surfaceContainer,
                          builder: (BuildContext ctx) => CommunityReportSheet(
                            onSubmit: (ReportReason reason) async {
                              final r = await ref
                                  .read(communityRepositoryProvider)
                                  .reportUser(me.id, p.authorId, reason);
                              r.fold(
                                (Failure f) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        f.message ?? 'Report failed',
                                      ),
                                    ),
                                  );
                                },
                                (_) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Report sent'),
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                        );
                      },
                      onBlock: () async {
                        if (me == null) {
                          return;
                        }
                        final bool? ok = await showDialog<bool>(
                          context: context,
                          builder: (BuildContext ctx) => AlertDialog(
                            title: const Text('Block user?'),
                            content: const Text(
                              'You won’t see their posts in your feed. You can change this later in settings.',
                            ),
                            actions: <Widget>[
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, false),
                                child: const Text('Cancel'),
                              ),
                              FilledButton(
                                onPressed: () => Navigator.pop(ctx, true),
                                child: const Text('Block'),
                              ),
                            ],
                          ),
                        );
                        if (ok != true || !context.mounted) {
                          return;
                        }
                        final r = await ref
                            .read(communityRepositoryProvider)
                            .blockUser(me.id, p.authorId);
                        r.fold(
                          (Failure f) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(f.message ?? 'Block failed'),
                              ),
                            );
                          },
                          (_) {
                            ref.invalidate(socialFeedProvider);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('User blocked')),
                            );
                          },
                        );
                      },
                    );
                  }, childCount: posts.length),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 88)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StoryAvatar extends StatelessWidget {
  const _StoryAvatar({required this.story});

  final FeedStory story;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: Column(
        children: <Widget>[
          Container(
            width: 64,
            height: 64,
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: story.seen
                  ? null
                  : const LinearGradient(
                      colors: <Color>[AppColors.secondary, AppColors.primary],
                    ),
              color: story.seen ? AppColors.surfaceContainerHigh : null,
            ),
            child: Container(
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.surfaceContainer,
              ),
              alignment: Alignment.center,
              child: Text(story.initials, style: AppTextStyles.labelLarge),
            ),
          ),
        ],
      ),
    );
  }
}

class _FeedPostCard extends StatelessWidget {
  const _FeedPostCard({
    required this.post,
    required this.currentUserId,
    required this.onLike,
    required this.onReport,
    required this.onBlock,
  });

  final FeedPost post;
  final String? currentUserId;
  final VoidCallback onLike;
  final VoidCallback onReport;
  final VoidCallback onBlock;

  @override
  Widget build(BuildContext context) {
    final bool liked = post.isLikedByUser(currentUserId);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              CircleAvatar(
                backgroundColor: AppColors.surfaceContainerHighest,
                child: Text(
                  post.authorName.isNotEmpty ? post.authorName[0] : '?',
                  style: AppTextStyles.labelSmall,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(post.authorName, style: AppTextStyles.labelLarge),
                    Text(
                      '${post.handle} · ${post.followerCount} followers · '
                      '${DateFormat.jm().format(post.postedAt)}',
                      style: AppTextStyles.bodySmall,
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (String v) {
                  if (v == 'report') {
                    onReport();
                  } else if (v == 'block') {
                    onBlock();
                  }
                },
                itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                  const PopupMenuItem<String>(
                    value: 'report',
                    child: Text('Report'),
                  ),
                  const PopupMenuItem<String>(
                    value: 'block',
                    child: Text('Block'),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (post.type == PostType.achievement)
            GlassCard(
              glowColor: AppColors.primary,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      const Icon(Icons.emoji_events, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          post.achievementTitle ?? 'Achievement',
                          style: AppTextStyles.headlineMedium.copyWith(
                            fontSize: 18,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (post.prLabel != null)
                    Text('PR ${post.prLabel}', style: AppTextStyles.labelLarge),
                  if (post.moduleStatsLine != null)
                    Text(post.moduleStatsLine!, style: AppTextStyles.bodySmall),
                ],
              ),
            )
          else if (post.type == PostType.milestone)
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    post.milestoneTitle ?? 'Milestone',
                    style: AppTextStyles.headlineMedium.copyWith(fontSize: 18),
                  ),
                  if (post.streakDays != null)
                    Text(
                      '${post.streakDays} day streak',
                      style: AppTextStyles.bodyMedium,
                    ),
                ],
              ),
            )
          else
            Text(post.body ?? '', style: AppTextStyles.bodyLarge),
          const SizedBox(height: 10),
          Row(
            children: <Widget>[
              InkWell(
                onTap: onLike,
                child: Icon(
                  liked ? Icons.favorite : Icons.favorite_border,
                  color: liked
                      ? AppColors.tertiary
                      : AppColors.onSurfaceVariant,
                  size: 22,
                ),
              ),
              const SizedBox(width: 6),
              Text('${post.likeCount}', style: AppTextStyles.bodySmall),
              const SizedBox(width: 20),
              const Icon(Icons.chat_bubble_outline, size: 20),
              const SizedBox(width: 6),
              Text('${post.commentCount}', style: AppTextStyles.bodySmall),
              const Spacer(),
              const Icon(Icons.share_outlined, size: 20),
            ],
          ),
        ],
      ),
    );
  }
}
