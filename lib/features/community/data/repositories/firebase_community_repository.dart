import 'dart:convert';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:fitup/core/database/fitup_database.dart';
import 'package:fitup/core/error/failures.dart';
import 'package:fitup/features/community/domain/entities/challenge.dart';
import 'package:fitup/features/community/domain/entities/community_event.dart';
import 'package:fitup/features/community/domain/entities/community_geo_point.dart';
import 'package:fitup/features/community/domain/entities/feed_post.dart';
import 'package:fitup/features/community/domain/entities/report_reason.dart';
import 'package:fitup/features/community/domain/repositories/community_repository.dart';
import 'package:fitup/features/fitcoins/domain/services/fitcoin_award_service.dart';
import 'package:fitup/services/logger_service.dart';

Failure _map(Object e) {
  if (e is FirebaseException) {
    return ServerFailure(e.message ?? e.code);
  }
  return ServerFailure(e.toString());
}

Failure _communityMap(Object e) {
  if (e is FirebaseException) {
    return CommunityFailure(e.message ?? e.code);
  }
  return CommunityFailure(e.toString());
}

/// Firestore-backed community + optional Drift cache + [FitcoinAwardService] on event complete.
class FirebaseCommunityRepository implements CommunityRepository {
  FirebaseCommunityRepository(
    this._firestore, {
    FitupDatabase? database,
    FitcoinAwardService? fitcoinAwardService,
  })  : _db = database,
        _award = fitcoinAwardService;

  final FirebaseFirestore _firestore;
  final FitupDatabase? _db;
  final FitcoinAwardService? _award;

  CollectionReference<Map<String, dynamic>> get _events =>
      _firestore.collection('community_events');

  CollectionReference<Map<String, dynamic>> get _challenges =>
      _firestore.collection('community_challenges');

  CollectionReference<Map<String, dynamic>> _followingCol(String uid) =>
      _firestore.collection('users').doc(uid).collection('following');

  CollectionReference<Map<String, dynamic>> _followersCol(String uid) =>
      _firestore.collection('users').doc(uid).collection('followers');

  CollectionReference<Map<String, dynamic>> _feedInbox(String uid) =>
      _firestore.collection('users').doc(uid).collection('feed_inbox');

  CollectionReference<Map<String, dynamic>> get _reports =>
      _firestore.collection('reports');

  CollectionReference<Map<String, dynamic>> _blockedUsers(String blockerId) =>
      _firestore.collection('users').doc(blockerId).collection('blocked_users');

  String _newCode(int len) {
    const String chars = 'ABCDEFGHJKMNPQRSTUVWXYZ23456789';
    final Random r = Random();
    return List<String>.generate(
      len,
      (_) => chars[r.nextInt(chars.length)],
    ).join();
  }

  Future<String> _generateUniqueEventCode() async {
    for (int i = 0; i < 8; i++) {
      final String code = _newCode(6);
      final QuerySnapshot<Map<String, dynamic>> q =
          await _events.where('eventCode', isEqualTo: code).limit(1).get();
      if (q.docs.isEmpty) {
        return code;
      }
    }
    return _newCode(8);
  }

  @override
  Stream<int> watchUnreadNotificationCount(String userId) {
    return _firestore.collection('users').doc(userId).snapshots().map(
      (DocumentSnapshot<Map<String, dynamic>> d) {
        final Map<String, dynamic>? m = d.data();
        final int feed =
            (m?['communityUnseenFeedCount'] as num?)?.toInt() ?? 0;
        final int inv =
            (m?['communityUnseenInviteCount'] as num?)?.toInt() ?? 0;
        return feed + inv;
      },
    );
  }

  CommunityEvent _eventFromDoc(DocumentSnapshot<Map<String, dynamic>> d) {
    final Map<String, dynamic> m = d.data() ?? <String, dynamic>{};
    final GeoPoint? gp = m['location'] as GeoPoint?;
    return CommunityEvent(
      id: d.id,
      organizerId: m['organizerId'] as String? ?? '',
      organizerName: m['organizerName'] as String? ?? '',
      title: m['title'] as String? ?? '',
      description: m['description'] as String? ?? '',
      type: EventType.values.firstWhere(
        (EventType e) => e.name == (m['type'] as String? ?? 'custom'),
        orElse: () => EventType.custom,
      ),
      status: EventStatus.values.firstWhere(
        (EventStatus e) => e.name == (m['status'] as String? ?? 'upcoming'),
        orElse: () => EventStatus.upcoming,
      ),
      startsAt: (m['startsAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      endsAt: (m['endsAt'] as Timestamp?)?.toDate() ??
          ((m['startsAt'] as Timestamp?)?.toDate() ??
              DateTime.now().add(const Duration(days: 1))),
      eventCode: (m['eventCode'] as String?) ?? '',
      visibility: EventVisibility.values.firstWhere(
        (EventVisibility e) => e.name == (m['visibility'] as String? ?? 'public'),
        orElse: () => EventVisibility.public,
      ),
      location: gp != null
          ? CommunityGeoPoint(latitude: gp.latitude, longitude: gp.longitude)
          : null,
      locationName: m['locationName'] as String?,
      distanceKm: (m['distanceKm'] as num?)?.toDouble(),
      targetSteps: (m['targetSteps'] as num?)?.toInt(),
      targetDistanceKm: (m['targetDistanceKm'] as num?)?.toDouble(),
      maxParticipants: (m['maxParticipants'] as num?)?.toInt() ?? 0,
      participantIds: (m['participantIds'] as List<dynamic>?)
              ?.map((dynamic e) => e.toString())
              .toList() ??
          const <String>[],
      fitcoinsReward: (m['fitcoinsReward'] as num?)?.toInt() ?? 0,
      createdAt: (m['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> _eventToMap(CommunityEvent e) {
    return <String, dynamic>{
      'organizerId': e.organizerId,
      'organizerName': e.organizerName,
      'title': e.title,
      'description': e.description,
      'type': e.type.name,
      'status': e.status.name,
      'startsAt': Timestamp.fromDate(e.startsAt),
      'endsAt': Timestamp.fromDate(e.endsAt),
      'eventCode': e.eventCode,
      'visibility': e.visibility.name,
      'location': e.location != null
          ? GeoPoint(e.location!.latitude, e.location!.longitude)
          : null,
      'locationName': e.locationName,
      'distanceKm': e.distanceKm,
      'targetSteps': e.targetSteps,
      'targetDistanceKm': e.targetDistanceKm,
      'maxParticipants': e.maxParticipants,
      'participantIds': e.participantIds,
      'fitcoinsReward': e.fitcoinsReward,
      'createdAt': Timestamp.fromDate(e.createdAt),
    };
  }

  Challenge _challengeFromDoc(DocumentSnapshot<Map<String, dynamic>> d) {
    final Map<String, dynamic> m = d.data() ?? <String, dynamic>{};
    final Map<String, int> scores = <String, int>{};
    final Object? rawScores = m['scores'];
    if (rawScores is Map<dynamic, dynamic>) {
      for (final MapEntry<dynamic, dynamic> e in rawScores.entries) {
        scores[e.key.toString()] = (e.value as num).toInt();
      }
    }
    return Challenge(
      id: d.id,
      challengeCode: m['challengeCode'] as String? ?? '',
      creatorId: m['creatorId'] as String? ?? '',
      type: ChallengeType.values.firstWhere(
        (ChallengeType e) => e.name == (m['challengeType'] as String? ?? 'group'),
        orElse: () => ChallengeType.group,
      ),
      metric: ChallengeMetric.values.firstWhere(
        (ChallengeMetric e) => e.name == (m['metric'] as String? ?? 'steps'),
        orElse: () => ChallengeMetric.steps,
      ),
      status: ChallengeStatus.values.firstWhere(
        (ChallengeStatus e) => e.name == (m['status'] as String? ?? 'active'),
        orElse: () => ChallengeStatus.active,
      ),
      title: m['title'] as String? ?? '',
      targetValue: (m['targetValue'] as num?)?.toInt() ?? 0,
      startsAt: (m['startsAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      endsAt: (m['endsAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      participantIds: (m['participantIds'] as List<dynamic>?)
              ?.map((dynamic e) => e.toString())
              .toList() ??
          const <String>[],
      scores: scores,
      winnerId: m['winnerId'] as String?,
      fitcoinsReward: (m['fitcoinsReward'] as num?)?.toInt() ?? 0,
      createdAt: (m['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  FeedPost _postFromDoc(String userId, DocumentSnapshot<Map<String, dynamic>> d) {
    final Map<String, dynamic> m = d.data() ?? <String, dynamic>{};
    return FeedPost(
      id: d.id,
      authorId: m['authorId'] as String? ?? userId,
      authorName: m['authorName'] as String? ?? '',
      type: PostType.values.firstWhere(
        (PostType e) => e.name == (m['type'] as String? ?? 'manualPost'),
        orElse: () => PostType.manualPost,
      ),
      content: m['content'] as String? ?? '',
      metadata: (m['metadata'] as Map?)?.cast<String, dynamic>(),
      likerIds: (m['likerIds'] as List<dynamic>?)
              ?.map((dynamic e) => e.toString())
              .toList() ??
          const <String>[],
      commentCount: (m['commentCount'] as num?)?.toInt() ?? 0,
      createdAt: (m['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Future<void> _cacheEvent(CommunityEvent e) async {
    final FitupDatabase? db = _db;
    if (db == null) {
      return;
    }
    // Use a JSON-safe snapshot for the Drift cache (no Firestore-only types).
    final Map<String, dynamic> cache = <String, dynamic>{
      'id': e.id,
      'organizerId': e.organizerId,
      'organizerName': e.organizerName,
      'title': e.title,
      'description': e.description,
      'type': e.type.name,
      'status': e.status.name,
      'startsAt': e.startsAt.toIso8601String(),
      'endsAt': e.endsAt.toIso8601String(),
      'eventCode': e.eventCode,
      'visibility': e.visibility.name,
      'locationLat': e.location?.latitude,
      'locationLng': e.location?.longitude,
      'locationName': e.locationName,
      'distanceKm': e.distanceKm,
      'targetSteps': e.targetSteps,
      'targetDistanceKm': e.targetDistanceKm,
      'maxParticipants': e.maxParticipants,
      'participantIds': e.participantIds,
      'fitcoinsReward': e.fitcoinsReward,
      'createdAt': e.createdAt.toIso8601String(),
    };
    await db.into(db.communityEventsCache).insertOnConflictUpdate(
          CommunityEventsCacheCompanion.insert(
            id: e.id,
            payloadJson: jsonEncode(cache),
            cachedAt: DateTime.now(),
          ),
        );
  }

  @override
  Future<Either<Failure, List<CommunityEvent>>> getUpcomingEvents({
    int limit = 20,
  }) async {
    return getPublicEvents(limit: limit);
  }

  @override
  Future<Either<Failure, List<CommunityEvent>>> getPublicEvents({
    int limit = 20,
  }) async {
    try {
      final QuerySnapshot<Map<String, dynamic>> snap =
          await _events.orderBy('startsAt').limit(limit * 2).get();
      final List<CommunityEvent> list = snap.docs
          .map(_eventFromDoc)
          .where(
            (CommunityEvent e) =>
                (e.status == EventStatus.upcoming || e.status == EventStatus.live) &&
                e.visibility == EventVisibility.public,
          )
          .take(limit)
          .toList();
      for (final CommunityEvent e in list) {
        await _cacheEvent(e);
      }
      return Right<Failure, List<CommunityEvent>>(list);
    } catch (e, st) {
      LoggerService.e('getPublicEvents', e, st);
      return Left<Failure, List<CommunityEvent>>(_map(e));
    }
  }

  @override
  Future<Either<Failure, List<CommunityEvent>>> getJoinedEvents(
    String userId,
  ) async {
    try {
      // No orderBy here — arrayContains + orderBy needs a composite index and
      // can fail or hang in poor network conditions. Sort client-side instead.
      final QuerySnapshot<Map<String, dynamic>> snap = await _events
          .where('participantIds', arrayContains: userId)
          .limit(50)
          .get();
      final List<CommunityEvent> list = snap.docs
          .map(_eventFromDoc)
          .where(
            (CommunityEvent e) =>
                e.status == EventStatus.upcoming || e.status == EventStatus.live,
          )
          .toList()
        ..sort(
          (CommunityEvent a, CommunityEvent b) =>
              a.startsAt.compareTo(b.startsAt),
        );
      if (list.length > 30) {
        return Right<Failure, List<CommunityEvent>>(list.take(30).toList());
      }
      return Right<Failure, List<CommunityEvent>>(list);
    } catch (e, st) {
      LoggerService.e('getJoinedEvents', e, st);
      return Left<Failure, List<CommunityEvent>>(_map(e));
    }
  }

  @override
  Future<Either<Failure, CommunityEvent>> searchEventByCode(String code) async {
    try {
      final String normalized = code.trim().toUpperCase();
      final QuerySnapshot<Map<String, dynamic>> snap = await _events
          .where('eventCode', isEqualTo: normalized)
          .limit(1)
          .get();
      if (snap.docs.isEmpty) {
        return Left<Failure, CommunityEvent>(ServerFailure('Event not found'));
      }
      final CommunityEvent event = _eventFromDoc(snap.docs.first);
      return Right<Failure, CommunityEvent>(event);
    } catch (e, st) {
      LoggerService.e('searchEventByCode', e, st);
      return Left<Failure, CommunityEvent>(_map(e));
    }
  }

  @override
  Future<Either<Failure, CommunityEvent>> getEvent(String eventId) async {
    try {
      final DocumentSnapshot<Map<String, dynamic>> d =
          await _events.doc(eventId).get();
      if (!d.exists) {
        return Left<Failure, CommunityEvent>(ServerFailure('Event not found'));
      }
      final CommunityEvent e = _eventFromDoc(d);
      await _cacheEvent(e);
      return Right<Failure, CommunityEvent>(e);
    } catch (e, st) {
      LoggerService.e('getEvent', e, st);
      return Left<Failure, CommunityEvent>(_map(e));
    }
  }

  @override
  Future<Either<Failure, CommunityEvent>> createEvent(CommunityEvent event) async {
    try {
      final String code = event.eventCode.isEmpty
          ? await _generateUniqueEventCode()
          : event.eventCode.toUpperCase();
      final CommunityEvent toSave = CommunityEvent(
        id: event.id,
        organizerId: event.organizerId,
        organizerName: event.organizerName,
        title: event.title,
        description: event.description,
        type: event.type,
        status: event.status,
        startsAt: event.startsAt,
        endsAt: event.endsAt,
        eventCode: code,
        visibility: event.visibility,
        location: event.location,
        locationName: event.locationName,
        distanceKm: event.distanceKm,
        targetSteps: event.targetSteps,
        targetDistanceKm: event.targetDistanceKm,
        maxParticipants: event.maxParticipants,
        participantIds: event.participantIds,
        fitcoinsReward: event.fitcoinsReward,
        createdAt: event.createdAt,
      );
      await _events.doc(toSave.id).set(_eventToMap(toSave));
      await _cacheEvent(toSave);
      return Right<Failure, CommunityEvent>(toSave);
    } catch (e, st) {
      LoggerService.e('createEvent', e, st);
      return Left<Failure, CommunityEvent>(_map(e));
    }
  }

  @override
  Future<Either<Failure, Unit>> joinEvent(String userId, String eventId) async {
    try {
      await _events.doc(eventId).update(<String, dynamic>{
        'participantIds': FieldValue.arrayUnion(<String>[userId]),
      });
      final FitcoinAwardService? a = _award;
      if (a != null) {
        await a.onEventJoined(userId, eventId);
      }
      return const Right<Failure, Unit>(unit);
    } catch (e, st) {
      LoggerService.e('joinEvent', e, st);
      return Left<Failure, Unit>(_map(e));
    }
  }

  @override
  Future<Either<Failure, Unit>> completeEvent(String userId, String eventId) async {
    try {
      await _events.doc(eventId).update(<String, dynamic>{
        'status': EventStatus.completed.name,
      });
      final FitcoinAwardService? a = _award;
      if (a != null) {
        await a.onEventCompleted(userId, eventId);
      }
      return const Right<Failure, Unit>(unit);
    } catch (e, st) {
      LoggerService.e('completeEvent', e, st);
      return Left<Failure, Unit>(_map(e));
    }
  }

  @override
  Future<Either<Failure, Unit>> deleteEvent(
    String userId,
    String eventId,
  ) async {
    try {
      final DocumentSnapshot<Map<String, dynamic>> d =
          await _events.doc(eventId).get();
      if (!d.exists) {
        return Left<Failure, Unit>(CommunityFailure('Event not found'));
      }
      final Map<String, dynamic> m = d.data() ?? <String, dynamic>{};
      final String organizerId = (m['organizerId'] as String?) ?? '';
      if (organizerId != userId) {
        return Left<Failure, Unit>(
          const CommunityFailure('Only the organizer can delete this event'),
        );
      }

      // Delete event + known subdocs (leaderboard).
      final CollectionReference<Map<String, dynamic>> lbCol =
          _events.doc(eventId).collection('leaderboard');
      final QuerySnapshot<Map<String, dynamic>> lbSnap = await lbCol.get();
      for (final QueryDocumentSnapshot<Map<String, dynamic>> row in
          lbSnap.docs) {
        await row.reference.delete();
      }

      await _events.doc(eventId).delete();

      // Best-effort local cache removal (offline).
      final FitupDatabase? db = _db;
      if (db != null) {
        await (db.delete(db.communityEventsCache)
              ..where(($CommunityEventsCacheTable t) => t.id.equals(eventId)))
            .go();
      }

      return const Right<Failure, Unit>(unit);
    } catch (e, st) {
      LoggerService.e('deleteEvent', e, st);
      return Left<Failure, Unit>(_communityMap(e));
    }
  }

  @override
  Future<Either<Failure, Unit>> extendEvent(
    String userId,
    String eventId,
    DateTime newEndsAt,
  ) async {
    try {
      final DocumentSnapshot<Map<String, dynamic>> d =
          await _events.doc(eventId).get();
      if (!d.exists) {
        return Left<Failure, Unit>(CommunityFailure('Event not found'));
      }

      final CommunityEvent current = _eventFromDoc(d);
      if (current.organizerId != userId) {
        return Left<Failure, Unit>(
          const CommunityFailure('Only the organizer can extend this event'),
        );
      }
      if (current.status == EventStatus.completed ||
          current.status == EventStatus.cancelled) {
        return Left<Failure, Unit>(
          const CommunityFailure('Completed/cancelled events cannot be extended'),
        );
      }

      final DateTime now = DateTime.now();
      final EventStatus nextStatus = now.isBefore(current.startsAt)
          ? EventStatus.upcoming
          : newEndsAt.isAfter(now)
              ? EventStatus.live
              : EventStatus.completed;

      await _events.doc(eventId).update(<String, dynamic>{
        'endsAt': Timestamp.fromDate(newEndsAt),
        'status': nextStatus.name,
      });

      // Refresh + cache the updated event for offline consistency.
      final DocumentSnapshot<Map<String, dynamic>> updated =
          await _events.doc(eventId).get();
      if (updated.exists) {
        final CommunityEvent e = _eventFromDoc(updated);
        await _cacheEvent(e);
      }

      return const Right<Failure, Unit>(unit);
    } catch (e, st) {
      LoggerService.e('extendEvent', e, st);
      return Left<Failure, Unit>(_communityMap(e));
    }
  }

  @override
  Future<Either<Failure, List<Challenge>>> getActiveChallenges(String userId) async {
    try {
      final QuerySnapshot<Map<String, dynamic>> snap = await _challenges
          .where('participantIds', arrayContains: userId)
          .where('status', isEqualTo: ChallengeStatus.active.name)
          .limit(20)
          .get();
      return Right<Failure, List<Challenge>>(
        snap.docs.map(_challengeFromDoc).toList(),
      );
    } catch (e, st) {
      LoggerService.e('getActiveChallenges', e, st);
      return Left<Failure, List<Challenge>>(_map(e));
    }
  }

  @override
  Future<Either<Failure, Challenge>> createChallenge(Challenge challenge) async {
    try {
      await _challenges.doc(challenge.id).set(<String, dynamic>{
        'creatorId': challenge.creatorId,
        'challengeType': challenge.type.name,
        'challengeCode': challenge.challengeCode,
        'metric': challenge.metric.name,
        'status': challenge.status.name,
        'title': challenge.title,
        'targetValue': challenge.targetValue,
        'startsAt': Timestamp.fromDate(challenge.startsAt),
        'endsAt': Timestamp.fromDate(challenge.endsAt),
        'participantIds': challenge.participantIds,
        'scores': challenge.scores,
        'winnerId': challenge.winnerId,
        'fitcoinsReward': challenge.fitcoinsReward,
        'createdAt': Timestamp.fromDate(challenge.createdAt),
      });
      return Right<Failure, Challenge>(challenge);
    } catch (e, st) {
      LoggerService.e('createChallenge', e, st);
      return Left<Failure, Challenge>(_map(e));
    }
  }

  @override
  Future<Either<Failure, Unit>> joinChallenge(String userId, String challengeId) async {
    try {
      await _challenges.doc(challengeId).update(<String, dynamic>{
        'participantIds': FieldValue.arrayUnion(<String>[userId]),
      });
      return const Right<Failure, Unit>(unit);
    } catch (e, st) {
      LoggerService.e('joinChallenge', e, st);
      return Left<Failure, Unit>(_map(e));
    }
  }

  @override
  Future<Either<Failure, List<MapEntry<String, int>>>> getLeaderboard({
    required String metric,
    required String period,
    int limit = 50,
  }) async {
    try {
      final DocumentSnapshot<Map<String, dynamic>> doc = await _firestore
          .collection('leaderboard')
          .doc('${metric}_$period')
          .get();
      final List<dynamic>? raw =
          doc.data()?['entries'] as List<dynamic>?;
      if (raw == null) {
        return const Right<Failure, List<MapEntry<String, int>>>(<MapEntry<String, int>>[]);
      }
      final List<MapEntry<String, int>> out = <MapEntry<String, int>>[];
      for (final Object item in raw) {
        if (item is Map<String, dynamic>) {
          out.add(
            MapEntry<String, int>(
              item['userId'] as String? ?? '',
              (item['score'] as num?)?.toInt() ?? 0,
            ),
          );
        }
      }
      out.sort((MapEntry<String, int> a, MapEntry<String, int> b) =>
          b.value.compareTo(a.value));
      if (out.length > limit) {
        return Right<Failure, List<MapEntry<String, int>>>(out.sublist(0, limit));
      }
      return Right<Failure, List<MapEntry<String, int>>>(out);
    } catch (e, st) {
      LoggerService.e('getLeaderboard', e, st);
      return Left<Failure, List<MapEntry<String, int>>>(_map(e));
    }
  }

  @override
  Future<Either<Failure, List<MapEntry<String, int>>>> getEventLeaderboard(
    String eventId, {
    int limit = 50,
  }) async {
    try {
      final DocumentSnapshot<Map<String, dynamic>> doc = await _events
          .doc(eventId)
          .collection('leaderboard')
          .doc('latest')
          .get();
      final List<dynamic>? raw = doc.data()?['entries'] as List<dynamic>?;
      if (raw == null) {
        return const Right<Failure, List<MapEntry<String, int>>>(<MapEntry<String, int>>[]);
      }
      final List<MapEntry<String, int>> out = <MapEntry<String, int>>[];
      for (final Object item in raw) {
        if (item is Map<String, dynamic>) {
          out.add(
            MapEntry<String, int>(
              item['userId'] as String? ?? '',
              (item['score'] as num?)?.toInt() ?? 0,
            ),
          );
        }
      }
      out.sort((MapEntry<String, int> a, MapEntry<String, int> b) =>
          b.value.compareTo(a.value));
      return Right<Failure, List<MapEntry<String, int>>>(
        out.length > limit ? out.sublist(0, limit) : out,
      );
    } catch (e, st) {
      LoggerService.e('getEventLeaderboard', e, st);
      return Left<Failure, List<MapEntry<String, int>>>(_map(e));
    }
  }

  @override
  Future<Either<Failure, List<FeedPost>>> getFeed(
    String userId, {
    int limit = 20,
    String? cursorPostId,
  }) async {
    try {
      final Either<Failure, List<String>> blockedRes =
          await getBlockedUserIds(userId);
      final Set<String> blocked = blockedRes.fold(
        (_) => <String>{},
        (List<String> ids) => ids.toSet(),
      );
      Query<Map<String, dynamic>> q = _feedInbox(userId)
          .orderBy('createdAt', descending: true)
          .limit(limit);
      if (cursorPostId != null) {
        final DocumentSnapshot<Map<String, dynamic>> cur =
            await _feedInbox(userId).doc(cursorPostId).get();
        if (cur.exists) {
          q = q.startAfterDocument(cur);
        }
      }
      final QuerySnapshot<Map<String, dynamic>> snap = await q.get();
      final List<FeedPost> posts = snap.docs
          .map(
            (QueryDocumentSnapshot<Map<String, dynamic>> d) =>
                _postFromDoc(userId, d),
          )
          .where((FeedPost p) => !blocked.contains(p.authorId))
          .toList();
      return Right<Failure, List<FeedPost>>(posts);
    } catch (e, st) {
      LoggerService.e('getFeed', e, st);
      return Left<Failure, List<FeedPost>>(_map(e));
    }
  }

  @override
  Future<Either<Failure, Unit>> likePost(String userId, String postId) async {
    try {
      await _feedInbox(userId).doc(postId).update(<String, dynamic>{
        'likerIds': FieldValue.arrayUnion(<String>[userId]),
      });
      return const Right<Failure, Unit>(unit);
    } catch (e, st) {
      LoggerService.e('likePost', e, st);
      return Left<Failure, Unit>(_map(e));
    }
  }

  @override
  Future<Either<Failure, Unit>> publishAchievementPost(
    String userId,
    FeedPost post,
  ) async {
    try {
      final Map<String, dynamic> data = <String, dynamic>{
        'authorId': post.authorId,
        'authorName': post.authorName,
        'type': post.type.name,
        'content': post.content,
        'metadata': post.metadata,
        'likerIds': post.likerIds,
        'commentCount': post.commentCount,
        'createdAt': Timestamp.fromDate(post.createdAt),
      };

      final QuerySnapshot<Map<String, dynamic>> followers =
          await _followersCol(userId).limit(500).get();
      final WriteBatch batch = _firestore.batch();
      for (final QueryDocumentSnapshot<Map<String, dynamic>> d in followers.docs) {
        final DocumentReference<Map<String, dynamic>> inbox =
            _feedInbox(d.id).doc(post.id);
        batch.set(inbox, data);
      }
      batch.set(_feedInbox(userId).doc(post.id), data);
      await batch.commit();
      return const Right<Failure, Unit>(unit);
    } catch (e, st) {
      LoggerService.e('publishAchievementPost', e, st);
      return Left<Failure, Unit>(_map(e));
    }
  }

  @override
  Future<Either<Failure, Unit>> publishActivityPost(
    String userId,
    FeedPost post,
  ) {
    return publishAchievementPost(userId, post);
  }

  @override
  Future<Either<Failure, Unit>> followUser(String followerId, String targetId) async {
    try {
      final WriteBatch b = _firestore.batch();
      b.set(
        _followingCol(followerId).doc(targetId),
        <String, dynamic>{'createdAt': FieldValue.serverTimestamp()},
      );
      b.set(
        _followersCol(targetId).doc(followerId),
        <String, dynamic>{'createdAt': FieldValue.serverTimestamp()},
      );
      await b.commit();
      return const Right<Failure, Unit>(unit);
    } catch (e, st) {
      LoggerService.e('followUser', e, st);
      return Left<Failure, Unit>(_map(e));
    }
  }

  @override
  Future<Either<Failure, Unit>> unfollowUser(String followerId, String targetId) async {
    try {
      final WriteBatch b = _firestore.batch();
      b.delete(_followingCol(followerId).doc(targetId));
      b.delete(_followersCol(targetId).doc(followerId));
      await b.commit();
      return const Right<Failure, Unit>(unit);
    } catch (e, st) {
      LoggerService.e('unfollowUser', e, st);
      return Left<Failure, Unit>(_map(e));
    }
  }

  @override
  Future<Either<Failure, List<String>>> getFollowing(String userId) async {
    try {
      final QuerySnapshot<Map<String, dynamic>> snap =
          await _followingCol(userId).get();
      return Right<Failure, List<String>>(
        snap.docs.map((QueryDocumentSnapshot<Map<String, dynamic>> d) => d.id).toList(),
      );
    } catch (e, st) {
      LoggerService.e('getFollowing', e, st);
      return Left<Failure, List<String>>(_map(e));
    }
  }

  @override
  Future<Either<Failure, List<String>>> getFollowers(String userId) async {
    try {
      final QuerySnapshot<Map<String, dynamic>> snap =
          await _followersCol(userId).get();
      return Right<Failure, List<String>>(
        snap.docs.map((QueryDocumentSnapshot<Map<String, dynamic>> d) => d.id).toList(),
      );
    } catch (e, st) {
      LoggerService.e('getFollowers', e, st);
      return Left<Failure, List<String>>(_map(e));
    }
  }

  @override
  Future<Either<Failure, Unit>> reportUser(
    String reporterId,
    String reportedUserId,
    ReportReason reason,
  ) async {
    try {
      final DocumentReference<Map<String, dynamic>> doc = _reports.doc();
      await doc.set(<String, dynamic>{
        'reporterId': reporterId,
        'reportedUserId': reportedUserId,
        'reason': reason.name,
        'createdAt': FieldValue.serverTimestamp(),
      });
      return const Right<Failure, Unit>(unit);
    } catch (e, st) {
      LoggerService.e('reportUser', e, st);
      return Left<Failure, Unit>(_communityMap(e));
    }
  }

  @override
  Future<Either<Failure, Unit>> blockUser(
    String blockerId,
    String blockedUserId,
  ) async {
    try {
      await _blockedUsers(blockerId).doc(blockedUserId).set(<String, dynamic>{
        'blockedUserId': blockedUserId,
        'createdAt': FieldValue.serverTimestamp(),
      });
      return const Right<Failure, Unit>(unit);
    } catch (e, st) {
      LoggerService.e('blockUser', e, st);
      return Left<Failure, Unit>(_communityMap(e));
    }
  }

  @override
  Future<Either<Failure, List<String>>> getBlockedUserIds(String userId) async {
    try {
      final QuerySnapshot<Map<String, dynamic>> snap =
          await _blockedUsers(userId).get();
      return Right<Failure, List<String>>(
        snap.docs
            .map((QueryDocumentSnapshot<Map<String, dynamic>> d) => d.id)
            .toList(),
      );
    } catch (e, st) {
      LoggerService.e('getBlockedUserIds', e, st);
      return Left<Failure, List<String>>(_communityMap(e));
    }
  }
}
