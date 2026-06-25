import 'dart:async';

import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/challenge.dart';
import '../entities/community_event.dart';
import '../entities/feed_post.dart';
import '../entities/report_reason.dart';

abstract interface class CommunityRepository {
  /// Tab badge: unseen feed + invite counters on user doc (server-maintained).
  Stream<int> watchUnreadNotificationCount(String userId);

  Future<Either<Failure, List<CommunityEvent>>> getUpcomingEvents({int limit = 20});
  Future<Either<Failure, List<CommunityEvent>>> getPublicEvents({int limit = 20});
  Future<Either<Failure, List<CommunityEvent>>> getJoinedEvents(String userId);
  Future<Either<Failure, CommunityEvent>> searchEventByCode(String code);

  Future<Either<Failure, CommunityEvent>> getEvent(String eventId);

  Future<Either<Failure, CommunityEvent>> createEvent(CommunityEvent event);

  Future<Either<Failure, Unit>> joinEvent(String userId, String eventId);

  Future<Either<Failure, Unit>> completeEvent(String userId, String eventId);

  /// Deletes a community event created by [userId].
  ///
  /// UI is responsible for checking organizer ownership; repository still
  /// validates organizerId from Firestore for safety.
  Future<Either<Failure, Unit>> deleteEvent(String userId, String eventId);

  /// Extends an event created by [userId] up to [newEndsAt].
  ///
  /// Repository validates organizer ownership; the extension keeps the event
  /// type/targets intact and updates `endsAt` (+ `status` best-effort).
  Future<Either<Failure, Unit>> extendEvent(
    String userId,
    String eventId,
    DateTime newEndsAt,
  );

  Future<Either<Failure, List<Challenge>>> getActiveChallenges(String userId);

  Future<Either<Failure, Challenge>> createChallenge(Challenge challenge);

  Future<Either<Failure, Unit>> joinChallenge(String userId, String challengeId);

  Future<Either<Failure, List<MapEntry<String, int>>>> getLeaderboard({
    required String metric,
    required String period,
    int limit = 50,
  });
  Future<Either<Failure, List<MapEntry<String, int>>>> getEventLeaderboard(
    String eventId, {
    int limit = 50,
  });

  /// Inbox feed; [cursorPostId] is the last post id from the previous page.
  Future<Either<Failure, List<FeedPost>>> getFeed(
    String userId, {
    int limit = 20,
    String? cursorPostId,
  });

  Future<Either<Failure, Unit>> likePost(String userId, String postId);

  Future<Either<Failure, Unit>> publishAchievementPost(String userId, FeedPost post);
  Future<Either<Failure, Unit>> publishActivityPost(String userId, FeedPost post);

  Future<Either<Failure, Unit>> followUser(String followerId, String targetId);

  Future<Either<Failure, Unit>> unfollowUser(String followerId, String targetId);

  Future<Either<Failure, List<String>>> getFollowing(String userId);
  Future<Either<Failure, List<String>>> getFollowers(String userId);

  Future<Either<Failure, Unit>> reportUser(
    String reporterId,
    String reportedUserId,
    ReportReason reason,
  );

  Future<Either<Failure, Unit>> blockUser(String blockerId, String blockedUserId);

  Future<Either<Failure, List<String>>> getBlockedUserIds(String userId);
}
