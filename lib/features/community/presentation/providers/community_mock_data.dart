import 'package:flutter/material.dart';

import '../../domain/entities/achievement_item.dart';
import '../../domain/entities/community_challenge.dart';
import '../../domain/entities/community_event.dart';
import '../../domain/entities/feed_post.dart';
import '../../domain/entities/leaderboard_models.dart';
import '../../../fitcoins/domain/entities/fitcoin_transaction.dart';

/// Demo content when Firestore has no community rows yet.
final List<CommunityEvent> mockCommunityEvents = <CommunityEvent>[
  CommunityEvent(
    id: 'e1',
    organizerId: 'org1',
    organizerName: 'Fitup Crew',
    title: 'Neon Night 5K',
    description: 'Evening run along the coast with neon checkpoints.',
    type: EventType.run,
    status: EventStatus.upcoming,
    startsAt: DateTime.now().add(const Duration(days: 2, hours: 18)),
    endsAt: DateTime.now().add(const Duration(days: 3, hours: 6)),
    eventCode: 'N5K123',
    visibility: EventVisibility.public,
    locationName: 'Marine Drive, Mumbai',
    distanceKm: 5,
    maxParticipants: 0,
    participantIds: <String>['u_demo'],
    fitcoinsReward: 150,
    createdAt: DateTime.now().subtract(const Duration(days: 1)),
  ),
  CommunityEvent(
    id: 'e2',
    organizerId: 'org2',
    organizerName: 'Ride Club',
    title: 'Weekend Ride Club',
    description: 'Social cycle — all paces welcome.',
    type: EventType.cycle,
    status: EventStatus.upcoming,
    startsAt: DateTime.now().add(const Duration(days: 5, hours: 6)),
    endsAt: DateTime.now().add(const Duration(days: 6, hours: 2)),
    eventCode: 'RIDE88',
    visibility: EventVisibility.public,
    locationName: 'Bandra Reclamation',
    distanceKm: 32,
    maxParticipants: 0,
    participantIds: <String>[],
    fitcoinsReward: 220,
    createdAt: DateTime.now().subtract(const Duration(days: 2)),
  ),
  CommunityEvent(
    id: 'e3',
    organizerId: 'org3',
    organizerName: 'Recovery Co.',
    title: 'Recovery Walk & Stretch',
    description: 'Easy walk plus guided mobility.',
    type: EventType.walk,
    status: EventStatus.upcoming,
    startsAt: DateTime.now().add(const Duration(days: 1, hours: 7)),
    endsAt: DateTime.now().add(const Duration(days: 1, hours: 19)),
    eventCode: 'WALK77',
    visibility: EventVisibility.public,
    locationName: 'Joggers Park',
    distanceKm: 3.5,
    maxParticipants: 0,
    participantIds: <String>[],
    fitcoinsReward: 80,
    createdAt: DateTime.now().subtract(const Duration(days: 3)),
  ),
];

final List<CommunityChallenge> mockChallenges = <CommunityChallenge>[
  CommunityChallenge(
    id: 'c1',
    title: 'Steps Duel vs Priya',
    metricLabel: 'Steps',
    endsAt: DateTime.now().add(const Duration(days: 3)),
    yourScore: 8420,
    opponentScore: 9100,
    opponentName: 'Priya',
    yourRank: 2,
  ),
  CommunityChallenge(
    id: 'c2',
    title: 'Workout streak battle',
    metricLabel: 'Sessions',
    endsAt: DateTime.now().add(const Duration(days: 1)),
    yourScore: 4,
    opponentScore: 3,
    opponentName: 'Alex',
    yourRank: 1,
  ),
];

LeaderboardPodium mockPodiumFor(LeaderboardMetric m) {
  return LeaderboardPodium(
    first: LeaderboardRow(
      rank: 1,
      displayName: 'Aisha',
      handle: '@aisha_runs',
      metricValue: m == LeaderboardMetric.steps
          ? 124000
          : m == LeaderboardMetric.workouts
          ? 18
          : m == LeaderboardMetric.fitcoins
          ? 4200
          : 12,
      avatarInitials: 'AR',
      trend: 1,
    ),
    second: LeaderboardRow(
      rank: 2,
      displayName: 'Rahul',
      handle: '@rahul.fit',
      metricValue: m == LeaderboardMetric.steps
          ? 118200
          : m == LeaderboardMetric.workouts
          ? 16
          : m == LeaderboardMetric.fitcoins
          ? 3980
          : 11,
      avatarInitials: 'RF',
      trend: 0,
    ),
    third: LeaderboardRow(
      rank: 3,
      displayName: 'You',
      handle: '@you',
      metricValue: m == LeaderboardMetric.steps
          ? 112400
          : m == LeaderboardMetric.workouts
          ? 14
          : m == LeaderboardMetric.fitcoins
          ? 3650
          : 9,
      avatarInitials: 'ME',
      trend: 1,
    ),
  );
}

List<LeaderboardRow> mockLeaderboardRest(LeaderboardMetric m) {
  return <LeaderboardRow>[
    const LeaderboardRow(
      rank: 4,
      displayName: 'Sam',
      handle: '@sam_k',
      metricValue: 98000,
      avatarInitials: 'SK',
      trend: -1,
    ),
    const LeaderboardRow(
      rank: 5,
      displayName: 'Neha',
      handle: '@neha lifts',
      metricValue: 94500,
      avatarInitials: 'NL',
      trend: 1,
    ),
  ];
}

LeaderboardRow mockYourRow(LeaderboardMetric m) => LeaderboardRow(
  rank: 7,
  displayName: 'You',
  handle: '@fitup_you',
  metricValue: m == LeaderboardMetric.steps
      ? 88200
      : m == LeaderboardMetric.workouts
      ? 11
      : m == LeaderboardMetric.fitcoins
      ? 2450
      : 7,
  avatarInitials: 'YO',
  trend: 1,
);

final List<FeedStory> mockStories = <FeedStory>[
  const FeedStory(id: 's1', initials: 'YO', seen: false),
  const FeedStory(id: 's2', initials: 'AR', seen: false),
  const FeedStory(id: 's3', initials: 'RF', seen: true),
  const FeedStory(id: 's4', initials: 'SK', seen: true),
];

List<FeedPost> mockFeedPosts() => <FeedPost>[
  FeedPost(
    id: 'p1',
    authorId: 'aisha',
    authorName: 'Aisha',
    type: PostType.achievement,
    content: 'Half marathon PR',
    metadata: <String, dynamic>{
      'handle': '@aisha_runs',
      'followerCount': 1200,
      'prLabel': '1:58:20',
      'moduleStatsLine': 'Activity · 21.1 km · 142 bpm avg',
      'isLiked': false,
    },
    likerIds: <String>[],
    commentCount: 12,
    createdAt: DateTime.now().subtract(const Duration(hours: 2)),
  ),
  FeedPost(
    id: 'p2',
    authorId: 'rahul',
    authorName: 'Rahul',
    type: PostType.milestone,
    content: '30-day workout streak',
    metadata: <String, dynamic>{
      'handle': '@rahul.fit',
      'followerCount': 540,
      'streakDays': 30,
      'isLiked': true,
    },
    likerIds: <String>['me'],
    commentCount: 6,
    createdAt: DateTime.now().subtract(const Duration(hours: 5)),
  ),
  FeedPost(
    id: 'p3',
    authorId: 'fitup',
    authorName: 'Fitup Team',
    type: PostType.manualPost,
    content:
        'New community challenge drops tomorrow — double FC for early birds.',
    metadata: <String, dynamic>{
      'handle': '@fitup',
      'followerCount': 8900,
      'isLiked': false,
    },
    likerIds: <String>[],
    commentCount: 34,
    createdAt: DateTime.now().subtract(const Duration(days: 1)),
  ),
];

List<AchievementItem> mockAchievements() => <AchievementItem>[
  AchievementItem(
    id: 'a1',
    name: 'First 5K',
    iconCodePoint: Icons.directions_run_rounded.codePoint,
    category: AchievementCategory.activity,
    unlocked: true,
    unlockDate: DateTime.now().subtract(const Duration(days: 2)),
    fcReward: 50,
    isNew: true,
  ),
  AchievementItem(
    id: 'a2',
    name: 'Iron Week',
    iconCodePoint: Icons.fitness_center_rounded.codePoint,
    category: AchievementCategory.workout,
    unlocked: true,
    unlockDate: DateTime.now().subtract(const Duration(days: 20)),
    fcReward: 120,
  ),
  AchievementItem(
    id: 'a3',
    name: 'Protein Pro',
    iconCodePoint: Icons.restaurant_rounded.codePoint,
    category: AchievementCategory.diet,
    unlocked: false,
    progressNumerator: 4,
    progressDenominator: 7,
  ),
  AchievementItem(
    id: 'a4',
    name: 'Early Bird',
    iconCodePoint: Icons.wb_sunny_rounded.codePoint,
    category: AchievementCategory.streaks,
    unlocked: false,
    progressNumerator: 2,
    progressDenominator: 5,
  ),
  AchievementItem(
    id: 'a5',
    name: 'Social Spark',
    iconCodePoint: Icons.groups_rounded.codePoint,
    category: AchievementCategory.social,
    unlocked: false,
    progressNumerator: 1,
    progressDenominator: 3,
  ),
];

List<FitcoinTransaction> mockFitcoinTransactions() {
  final DateTime now = DateTime.now();
  return <FitcoinTransaction>[
    FitcoinTransaction(
      id: 'tx1',
      userId: 'demo',
      type: TransactionType.earned,
      source: EarnSource.workoutCompleted,
      amount: 85,
      description: 'Upper body session',
      createdAt: now.subtract(const Duration(hours: 3)),
    ),
    FitcoinTransaction(
      id: 'tx2',
      userId: 'demo',
      type: TransactionType.earned,
      source: EarnSource.allMealsLogged,
      amount: 15,
      description: 'Daily log bonus',
      createdAt: now.subtract(const Duration(hours: 8)),
    ),
    FitcoinTransaction(
      id: 'tx3',
      userId: 'demo',
      type: TransactionType.redeemed,
      amount: 200,
      description: 'Recovery pack (preview)',
      createdAt: now.subtract(const Duration(days: 2)),
    ),
  ];
}
