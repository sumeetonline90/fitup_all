import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dartz/dartz.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/error/failures.dart';
import '../../../auth/domain/entities/fitup_user.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../fitcoins/domain/entities/fitcoin_transaction.dart';
import '../../../fitcoins/domain/entities/fitcoin_wallet.dart';
import '../../../fitcoins/domain/repositories/fitcoin_repository.dart';
import '../../domain/entities/achievement_item.dart';
import '../../domain/entities/challenge.dart';
import '../../domain/entities/community_challenge.dart';
import '../../domain/entities/community_event.dart';
import '../../domain/entities/feed_post.dart';
import '../../domain/entities/leaderboard_models.dart';
import '../../domain/repositories/community_repository.dart';
import 'community_mock_data.dart';

FitupUser? _user(AsyncValue<FitupUser?> auth) {
  return switch (auth) {
    AsyncData<FitupUser?>(:final value) => value,
    _ => null,
  };
}

/// DI — no Firebase in presentation (C1).
final Provider<CommunityRepository> communityRepositoryProvider =
    Provider<CommunityRepository>((Ref ref) => getIt<CommunityRepository>());

/// Live wallet from [FitcoinRepository] (Firestore + Drift mirror).
final StreamProvider<FitcoinWallet> fitcoinWalletStreamProvider =
    StreamProvider<FitcoinWallet>((Ref ref) {
      final AsyncValue<FitupUser?> auth = ref.watch(authStateProvider);
      final FitupUser? u = _user(auth);
      if (u == null) {
        return Stream<FitcoinWallet>.value(
          FitcoinWallet(
            userId: '',
            balance: 0,
            totalEarned: 0,
            totalSpent: 0,
            updatedAt: DateTime.now(),
          ),
        );
      }
      return getIt<FitcoinRepository>().watchWallet(u.id);
    });

/// Unseen feed + invites — from repository stream (C1).
final StreamProvider<int> communityTabBadgeProvider = StreamProvider<int>((
  Ref ref,
) {
  final AsyncValue<FitupUser?> auth = ref.watch(authStateProvider);
  final FitupUser? u = _user(auth);
  if (u == null) {
    return Stream<int>.value(0);
  }
  return ref
      .watch(communityRepositoryProvider)
      .watchUnreadNotificationCount(u.id);
});

/// Ledger lines; falls back to mock data when the stream is empty.
final StreamProvider<List<FitcoinTransaction>> fitcoinLedgerStreamProvider =
    StreamProvider<List<FitcoinTransaction>>((Ref ref) {
      final AsyncValue<FitupUser?> auth = ref.watch(authStateProvider);
      final FitupUser? u = _user(auth);
      if (u == null) {
        return Stream<List<FitcoinTransaction>>.value(<FitcoinTransaction>[]);
      }
      return getIt<FitcoinRepository>()
          .watchTransactions(u.id)
          .map(
            (List<FitcoinTransaction> list) =>
                list.isEmpty ? mockFitcoinTransactions() : list,
          );
    });

/// Payload shown in [AchievementUnlockOverlay].
class AchievementCelebrationPayload {
  const AchievementCelebrationPayload({
    required this.transactionId,
    required this.title,
    required this.fcAmount,
    required this.iconCodePoint,
  });

  final String transactionId;
  final String title;
  final int fcAmount;
  final int iconCodePoint;
}

final NotifierProvider<
  AchievementCelebrationNotifier,
  AchievementCelebrationPayload?
>
achievementCelebrationProvider =
    NotifierProvider<
      AchievementCelebrationNotifier,
      AchievementCelebrationPayload?
    >(AchievementCelebrationNotifier.new);

class AchievementCelebrationNotifier
    extends Notifier<AchievementCelebrationPayload?> {
  static const String _kSeenAchievementTxIds = 'fitup_seen_achievement_tx_ids';
  final Set<String> _seenIds = <String>{};
  bool _loadedSeen = false;

  @override
  AchievementCelebrationPayload? build() => null;

  Future<void> _ensureLoaded() async {
    if (_loadedSeen) return;
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final List<String> persisted =
        prefs.getStringList(_kSeenAchievementTxIds) ?? <String>[];
    _seenIds
      ..clear()
      ..addAll(persisted);
    _loadedSeen = true;
  }

  Future<void> _persistSeen() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_kSeenAchievementTxIds, _seenIds.toList());
  }

  void evaluateLedger(List<FitcoinTransaction> list) {
    _evaluateLedgerAsync(list);
  }

  Future<void> _evaluateLedgerAsync(List<FitcoinTransaction> list) async {
    await _ensureLoaded();
    for (final FitcoinTransaction t in list) {
      if (!t.triggersAchievementCelebration) {
        continue;
      }
      final String dedupeKey = t.celebrationDedupeKey;
      if (_seenIds.contains(dedupeKey)) {
        continue;
      }
      _seenIds.add(dedupeKey);
      await _persistSeen();
      state = AchievementCelebrationPayload(
        transactionId: t.id,
        title: t.description.isEmpty ? 'Achievement unlocked' : t.description,
        fcAmount: t.amount,
        iconCodePoint: Icons.emoji_events_rounded.codePoint,
      );
      return;
    }
  }

  void clear() => state = null;
}

// --- Upcoming events (repository) ---

final FutureProvider<List<CommunityEvent>> upcomingEventsProvider =
    FutureProvider<List<CommunityEvent>>((Ref ref) async {
      final result = await ref
          .read(communityRepositoryProvider)
          .getUpcomingEvents(limit: 20);
      return result.fold(
        (Object f) => throw f,
        (List<CommunityEvent> list) => list,
      );
    });

// --- Active challenges (repository → UI model) ---

CommunityChallenge _challengeToUi(Challenge c, String userId) {
  int yourScore = c.scores[userId] ?? 0;
  String opponentName = 'Opponent';
  int opponentScore = 0;
  for (final MapEntry<String, int> e in c.scores.entries) {
    if (e.key != userId) {
      opponentName = e.key.length > 8 ? e.key.substring(0, 8) : e.key;
      opponentScore = e.value;
      break;
    }
  }
  int rank = 1;
  final List<int> sorted = c.scores.values.toList()
    ..sort((int a, int b) => b.compareTo(a));
  if (sorted.isNotEmpty && yourScore < sorted.first) {
    rank = sorted.indexOf(yourScore) + 1;
  }
  return CommunityChallenge(
    id: c.id,
    title: c.title,
    metricLabel: c.metric.name,
    endsAt: c.endsAt,
    yourScore: yourScore,
    opponentScore: opponentScore,
    opponentName: opponentName,
    yourRank: rank,
  );
}

final FutureProvider<List<CommunityChallenge>> activeChallengesProvider =
    FutureProvider<List<CommunityChallenge>>((Ref ref) async {
      final FitupUser? u = _user(ref.watch(authStateProvider));
      if (u == null) {
        return <CommunityChallenge>[];
      }
      final result = await ref
          .read(communityRepositoryProvider)
          .getActiveChallenges(u.id);
      return result.fold(
        (Object f) => throw f,
        (List<Challenge> list) =>
            list.map((Challenge c) => _challengeToUi(c, u.id)).toList(),
      );
    });

// --- Event by id ---

final eventByIdProvider = FutureProvider.family<CommunityEvent, String>((
  Ref ref,
  String eventId,
) async {
  final result = await ref.read(communityRepositoryProvider).getEvent(eventId);
  return result.fold((Object f) => throw f, (CommunityEvent e) => e);
});

// --- Leaderboard (pre-computed docs, ADR-023) ---

String leaderboardPeriodApi(LeaderboardPeriod p) => switch (p) {
  LeaderboardPeriod.week => 'week',
  LeaderboardPeriod.month => 'month',
  LeaderboardPeriod.allTime => 'all_time',
};

String leaderboardMetricApi(LeaderboardMetric m) => switch (m) {
  LeaderboardMetric.steps => 'steps',
  LeaderboardMetric.workouts => 'workouts',
  LeaderboardMetric.fitcoins => 'fitcoins',
  LeaderboardMetric.challenges => 'challenges',
};

typedef LeaderboardQuery = ({
  LeaderboardPeriod period,
  LeaderboardMetric metric,
});

final leaderboardEntriesProvider =
    FutureProvider.family<List<MapEntry<String, int>>, LeaderboardQuery>((
      Ref ref,
      LeaderboardQuery q,
    ) async {
      final result = await ref
          .read(communityRepositoryProvider)
          .getLeaderboard(
            metric: leaderboardMetricApi(q.metric),
            period: leaderboardPeriodApi(q.period),
            limit: 50,
          );
      return result.fold(
        (Object f) => throw f,
        (List<MapEntry<String, int>> list) => list,
      );
    });

// --- Social feed ---

class SocialFeedNotifier extends AsyncNotifier<List<FeedPost>> {
  String? _cursor;

  @override
  Future<List<FeedPost>> build() async {
    _cursor = null;
    final FitupUser? u = _user(ref.watch(authStateProvider));
    if (u == null) {
      return <FeedPost>[];
    }
    final result = await ref
        .watch(communityRepositoryProvider)
        .getFeed(u.id, limit: 20);
    return result.fold((Object f) => throw f, (List<FeedPost> list) {
      _cursor = list.isEmpty ? null : list.last.id;
      return list;
    });
  }

  Future<void> loadMore() async {
    final List<FeedPost> cur = state.value ?? <FeedPost>[];
    final FitupUser? u = _user(ref.read(authStateProvider));
    if (u == null || _cursor == null) {
      return;
    }
    final result = await ref
        .read(communityRepositoryProvider)
        .getFeed(u.id, limit: 20, cursorPostId: _cursor);
    result.fold(
      (Failure f) {
        state = AsyncValue<List<FeedPost>>.error(f, StackTrace.current);
      },
      (List<FeedPost> more) {
        if (more.isEmpty) {
          _cursor = null;
          return;
        }
        _cursor = more.last.id;
        state = AsyncData<List<FeedPost>>(<FeedPost>[...cur, ...more]);
      },
    );
  }
}

final AsyncNotifierProvider<SocialFeedNotifier, List<FeedPost>>
socialFeedProvider = AsyncNotifierProvider<SocialFeedNotifier, List<FeedPost>>(
  SocialFeedNotifier.new,
);

/// Hub teaser: first posts from feed (C3).
final FutureProvider<List<FeedPost>> communityFeedTeaserProvider =
    FutureProvider<List<FeedPost>>((Ref ref) async {
      final AsyncValue<List<FeedPost>> feed = ref.watch(socialFeedProvider);
      return feed.when(
        data: (List<FeedPost> list) => list.take(2).toList(),
        loading: () => <FeedPost>[],
        error: (_, StackTrace __) => <FeedPost>[],
      );
    });

/// Leaderboard preview on hub — steps / week.
final FutureProvider<List<MapEntry<String, int>>> leaderboardPreviewProvider =
    FutureProvider<List<MapEntry<String, int>>>((Ref ref) async {
      final result = await ref
          .read(communityRepositoryProvider)
          .getLeaderboard(metric: 'steps', period: 'week', limit: 10);
      return result.fold(
        (Object f) => throw f,
        (List<MapEntry<String, int>> list) => list,
      );
    });

/// Achievements catalog — still mock until catalog API exists.
final Provider<List<AchievementItem>> achievementsCatalogProvider =
    Provider<List<AchievementItem>>((Ref ref) => mockAchievements());

// --- Create Event (publish public/private by code) ---

class CreateEventInput {
  const CreateEventInput({
    required this.title,
    required this.description,
    required this.type,
    required this.visibility,
    required this.startsAt,
    required this.endsAt,
    required this.maxParticipants,
    required this.fitcoinsReward,
    this.targetSteps,
    this.targetDistanceKm,
  });

  final String title;
  final String description;
  final EventType type;
  final EventVisibility visibility;
  final DateTime startsAt;
  final DateTime endsAt;
  final int maxParticipants;
  final int fitcoinsReward;
  final int? targetSteps;
  final double? targetDistanceKm;
}

class CreateEventNotifier extends AsyncNotifier<CommunityEvent?> {
  @override
  Future<CommunityEvent?> build() async => null;

  Future<void> create(CreateEventInput input) async {
    final FitupUser? u = _user(ref.read(authStateProvider));
    if (u == null) {
      state = AsyncError<CommunityEvent?>(
        const AuthFailure('Please sign in'),
        StackTrace.current,
      );
      return;
    }

    state = const AsyncLoading<CommunityEvent?>();

    final String id = DateTime.now().millisecondsSinceEpoch.toString();
    final CommunityEvent draft = CommunityEvent(
      id: id,
      organizerId: u.id,
      organizerName: u.displayName ?? u.email.split('@').first,
      title: input.title.trim(),
      description: input.description.trim(),
      type: input.type,
      status: EventStatus.upcoming,
      startsAt: input.startsAt,
      endsAt: input.endsAt,
      eventCode: '',
      visibility: input.visibility,
      location: null,
      locationName: null,
      distanceKm: null,
      targetSteps: input.targetSteps,
      targetDistanceKm: input.targetDistanceKm,
      maxParticipants: input.maxParticipants,
      participantIds: <String>[u.id],
      fitcoinsReward: input.fitcoinsReward,
      createdAt: DateTime.now(),
    );

    final Either<Failure, CommunityEvent> result = await ref
        .read(communityRepositoryProvider)
        .createEvent(draft);

    result.fold(
      (Failure f) => state = AsyncError<CommunityEvent?>(f, StackTrace.current),
      (CommunityEvent e) {
        ref.invalidate(upcomingEventsProvider);
        state = AsyncData<CommunityEvent?>(e);
      },
    );
  }
}

final AsyncNotifierProvider<CreateEventNotifier, CommunityEvent?>
createEventProvider =
    AsyncNotifierProvider<CreateEventNotifier, CommunityEvent?>(
      CreateEventNotifier.new,
    );

// --- Create Challenge (private 1v1 duels) ---

class CreateChallengeInput {
  const CreateChallengeInput({
    required this.opponentId,
    required this.metric,
    required this.startsAt,
    required this.endsAt,
    required this.targetValue,
  });

  final String opponentId;
  final ChallengeMetric metric;
  final DateTime startsAt;
  final DateTime endsAt;
  final int targetValue;
}

String _generateUniqueChallengeCode() {
  final int n = DateTime.now().millisecondsSinceEpoch % 1000000;
  return 'DUEL${n.toString().padLeft(6, '0')}';
}

class CreateChallengeNotifier extends AsyncNotifier<Challenge?> {
  @override
  Future<Challenge?> build() async => null;

  Future<void> create(CreateChallengeInput input) async {
    final FitupUser? u = _user(ref.read(authStateProvider));
    if (u == null) {
      state = AsyncError<Challenge?>(
        const AuthFailure('Please sign in'),
        StackTrace.current,
      );
      return;
    }
    final String opponentId = input.opponentId.trim();
    if (opponentId.isEmpty) {
      state = AsyncError<Challenge?>(
        const ValidationFailure('Opponent user id is required'),
        StackTrace.current,
      );
      return;
    }

    state = const AsyncLoading<Challenge?>();

    final String id = DateTime.now().millisecondsSinceEpoch.toString();
    final String creatorId = u.id;
    final Challenge draft = Challenge(
      id: id,
      challengeCode: _generateUniqueChallengeCode(),
      creatorId: creatorId,
      type: ChallengeType.oneVsOne,
      metric: input.metric,
      status: ChallengeStatus.active,
      title: 'Duel Challenge',
      targetValue: input.targetValue,
      startsAt: input.startsAt,
      endsAt: input.endsAt,
      participantIds: <String>[creatorId, opponentId],
      scores: <String, int>{creatorId: 0, opponentId: 0},
      winnerId: null,
      fitcoinsReward: 100,
      createdAt: DateTime.now(),
    );

    final Either<Failure, Challenge> result = await ref
        .read(communityRepositoryProvider)
        .createChallenge(draft);

    result.fold(
      (Failure f) => state = AsyncError<Challenge?>(f, StackTrace.current),
      (Challenge c) {
        ref.invalidate(activeChallengesProvider);
        state = AsyncData<Challenge?>(c);
      },
    );
  }
}

final AsyncNotifierProvider<CreateChallengeNotifier, Challenge?>
createChallengeProvider =
    AsyncNotifierProvider<CreateChallengeNotifier, Challenge?>(
      CreateChallengeNotifier.new,
    );

// --- Search event by exact code (public + private) ---

final eventSearchByCodeProvider = FutureProvider.family<CommunityEvent, String>(
  (Ref ref, String code) async {
    final String normalized = code.trim().toUpperCase();
    final Either<Failure, CommunityEvent> result = await ref
        .read(communityRepositoryProvider)
        .searchEventByCode(normalized);
    return result.fold((Failure f) => throw f, (CommunityEvent e) => e);
  },
);

// --- Per-event leaderboard (server-updated hourly) ---

final eventLeaderboardProvider =
    FutureProvider.family<List<MapEntry<String, int>>, String>((
      Ref ref,
      String eventId,
    ) async {
      final Either<Failure, List<MapEntry<String, int>>> result = await ref
          .read(communityRepositoryProvider)
          .getEventLeaderboard(eventId, limit: 100);
      return result.fold(
        (Failure f) => throw f,
        (List<MapEntry<String, int>> list) => list,
      );
    });
