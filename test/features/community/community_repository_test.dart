import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:fitup/core/error/failures.dart';
import 'package:fitup/features/community/data/repositories/firebase_community_repository.dart';
import 'package:fitup/features/community/domain/entities/community_event.dart';
import 'package:fitup/features/community/domain/entities/feed_post.dart';
import 'package:fitup/features/community/domain/entities/report_reason.dart';
import 'package:fitup/features/fitcoins/domain/services/fitcoin_award_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockAward extends Mock implements FitcoinAwardService {}

void main() {
  late FakeFirebaseFirestore fs;
  late FirebaseCommunityRepository repo;

  CommunityEvent sampleEvent(String id, {List<String>? participants}) {
    final DateTime start = DateTime.utc(2026, 4, 1, 10);
    return CommunityEvent(
      id: id,
      organizerId: 'org',
      organizerName: 'Organiser',
      title: 'Run',
      description: 'About the run',
      type: EventType.run,
      status: EventStatus.upcoming,
      startsAt: start,
      endsAt: start.add(const Duration(hours: 2)),
      eventCode: 'EVT123',
      visibility: EventVisibility.public,
      locationName: 'Park',
      distanceKm: 5,
      targetSteps: null,
      targetDistanceKm: null,
      maxParticipants: 0,
      participantIds: participants ?? <String>[],
      fitcoinsReward: 100,
      createdAt: DateTime.utc(2026, 3, 1),
    );
  }

  setUp(() {
    fs = FakeFirebaseFirestore();
    repo = FirebaseCommunityRepository(fs);
  });

  test('getUpcomingEvents returns empty when collection empty', () async {
    final Either<Failure, List<CommunityEvent>> r = await repo.getUpcomingEvents();
    expect(r.isRight(), isTrue);
    r.fold(
      (_) => fail('unexpected'),
      (List<CommunityEvent> list) => expect(list, isEmpty),
    );
  });

  test('getUpcomingEvents returns upcoming events', () async {
    final CommunityEvent e = sampleEvent('ev1');
    await repo.createEvent(e);
    final Either<Failure, List<CommunityEvent>> r =
        await repo.getUpcomingEvents(limit: 10);
    expect(r.isRight(), isTrue);
    r.fold(
      (_) => fail('unexpected'),
      (List<CommunityEvent> list) {
        expect(list.length, 1);
        expect(list.single.id, 'ev1');
      },
    );
  });

  test('joinEvent adds participant; duplicate join is idempotent', () async {
    await repo.createEvent(sampleEvent('ev2'));
    final Either<Failure, Unit> a = await repo.joinEvent('u1', 'ev2');
    final Either<Failure, Unit> b = await repo.joinEvent('u1', 'ev2');
    expect(a.isRight(), isTrue);
    expect(b.isRight(), isTrue);

    final Either<Failure, CommunityEvent> ev = await repo.getEvent('ev2');
    ev.fold(
      (_) => fail('unexpected'),
      (CommunityEvent e) {
        expect(e.participantIds, contains('u1'));
        expect(e.participantIds.where((String x) => x == 'u1').length, 1);
      },
    );
  });

  test('completeEvent invokes FitcoinAwardService.onEventCompleted', () async {
    final _MockAward award = _MockAward();
    when(() => award.onEventCompleted(any(), any())).thenAnswer((_) async {});
    final FirebaseCommunityRepository r =
        FirebaseCommunityRepository(fs, fitcoinAwardService: award);
    await r.createEvent(sampleEvent('ev3'));
    await r.completeEvent('userZ', 'ev3');
    verify(() => award.onEventCompleted('userZ', 'ev3')).called(1);
  });

  test('deleteEvent removes organizer event and leaderboard', () async {
    const String eventId = 'evDel';
    await repo.createEvent(sampleEvent(eventId));

    await fs
        .collection('community_events')
        .doc(eventId)
        .collection('leaderboard')
        .doc('latest')
        .set(<String, dynamic>{
      'entries': <Map<String, dynamic>>[],
    });

    final Either<Failure, Unit> r = await repo.deleteEvent('org', eventId);
    expect(r.isRight(), isTrue);

    final DocumentSnapshot<Map<String, dynamic>> evSnap =
        await fs.collection('community_events').doc(eventId).get();
    expect(evSnap.exists, isFalse);

    final DocumentSnapshot<Map<String, dynamic>> lbSnap = await fs
        .collection('community_events')
        .doc(eventId)
        .collection('leaderboard')
        .doc('latest')
        .get();
    expect(lbSnap.exists, isFalse);
  });

  test('extendEvent updates endsAt and status (organizer only)', () async {
    const String eventId = 'evExt';

    final DateTime now = DateTime.now();
    final DateTime start = now.subtract(const Duration(days: 2));
    final DateTime end = now.subtract(const Duration(days: 1));

    await repo.createEvent(
      CommunityEvent(
        id: eventId,
        organizerId: 'org',
        organizerName: 'Organiser',
        title: 'Run',
        description: 'About the run',
        type: EventType.run,
        status: EventStatus.upcoming,
        startsAt: start,
        endsAt: end,
        eventCode: 'EVT123',
        visibility: EventVisibility.public,
        locationName: 'Park',
        location: null,
        distanceKm: 5,
        targetSteps: null,
        targetDistanceKm: null,
        maxParticipants: 0,
        participantIds: <String>[],
        fitcoinsReward: 100,
        createdAt: now,
      ),
    );

    final DateTime newEndsAt = now.add(const Duration(days: 2));
    final Either<Failure, Unit> r = await repo.extendEvent('org', eventId, newEndsAt);
    expect(r.isRight(), isTrue);

    final DocumentSnapshot<Map<String, dynamic>> evSnap =
        await fs.collection('community_events').doc(eventId).get();
    final Map<String, dynamic>? m = evSnap.data();
    expect(m, isNotNull);

    expect((m?['endsAt'] as Timestamp).toDate().isAfter(end), isTrue);
    expect(m?['status'], EventStatus.live.name);

    final Either<Failure, Unit> r2 =
        await repo.extendEvent('someoneElse', eventId, newEndsAt);
    expect(r2.isLeft(), isTrue);
  });

  test('getLeaderboard returns sorted entries by score desc', () async {
    await fs.collection('leaderboard').doc('steps_week').set(<String, dynamic>{
      'entries': <Map<String, Object>>[
        <String, Object>{'userId': 'a', 'score': 10},
        <String, Object>{'userId': 'b', 'score': 99},
        <String, Object>{'userId': 'c', 'score': 50},
      ],
    });
    final Either<Failure, List<MapEntry<String, int>>> res =
        await repo.getLeaderboard(metric: 'steps', period: 'week');
    res.fold(
      (_) => fail('unexpected'),
      (List<MapEntry<String, int>> list) {
        expect(list.map((MapEntry<String, int> e) => e.key).toList(),
            <String>['b', 'c', 'a']);
      },
    );
  });

  test('publishAchievementPost fans out to followers (<=3)', () async {
    final FirebaseCommunityRepository r = FirebaseCommunityRepository(fs);
    for (final String fid in <String>['f1', 'f2', 'f3']) {
      await fs
          .collection('users')
          .doc('author')
          .collection('followers')
          .doc(fid)
          .set(<String, dynamic>{'createdAt': Timestamp.now()});
    }
    final FeedPost post = FeedPost(
      id: 'post1',
      authorId: 'author',
      authorName: 'Author',
      type: PostType.achievement,
      content: 'PR',
      likerIds: <String>[],
      commentCount: 0,
      createdAt: DateTime.utc(2026, 3, 22),
    );
    final Either<Failure, Unit> pub =
        await r.publishAchievementPost('author', post);
    expect(pub.isRight(), isTrue);

    for (final String fid in <String>['f1', 'f2', 'f3']) {
      final DocumentSnapshot<Map<String, dynamic>> d = await fs
          .collection('users')
          .doc(fid)
          .collection('feed_inbox')
          .doc('post1')
          .get();
      expect(d.exists, isTrue);
      expect(d.data()?['content'], 'PR');
    }
    final DocumentSnapshot<Map<String, dynamic>> selfDoc = await fs
        .collection('users')
        .doc('author')
        .collection('feed_inbox')
        .doc('post1')
        .get();
    expect(selfDoc.exists, isTrue);
  });

  test('watchUnreadNotificationCount sums feed and invite counters', () async {
    await fs.collection('users').doc('u1').set(<String, dynamic>{
      'communityUnseenFeedCount': 2,
      'communityUnseenInviteCount': 3,
    });
    final int n = await repo.watchUnreadNotificationCount('u1').first;
    expect(n, 5);
  });

  test('reportUser writes reports collection', () async {
    final Either<Failure, Unit> r = await repo.reportUser(
      'reporter',
      'bad_actor',
      ReportReason.harassment,
    );
    expect(r.isRight(), isTrue);
    final QuerySnapshot<Map<String, dynamic>> q =
        await fs.collection('reports').get();
    expect(q.docs.length, 1);
    expect(q.docs.single.data()['reason'], 'harassment');
  });

  test('blockUser and getBlockedUserIds', () async {
    final Either<Failure, Unit> r =
        await repo.blockUser('blocker', 'blocked_uid');
    expect(r.isRight(), isTrue);
    final Either<Failure, List<String>> ids = await repo.getBlockedUserIds('blocker');
    ids.fold(
      (_) => fail('unexpected'),
      (List<String> list) {
        expect(list, contains('blocked_uid'));
      },
    );
  });

  test('getFeed excludes posts from blocked authors', () async {
    await fs.collection('users').doc('viewer').collection('blocked_users').doc('bad').set(
          <String, dynamic>{'blockedUserId': 'bad'},
        );
    await fs.collection('users').doc('viewer').collection('feed_inbox').doc('p1').set(
          <String, dynamic>{
            'authorId': 'bad',
            'authorName': 'Bad',
            'type': PostType.manualPost.name,
            'content': 'spam',
            'metadata': <String, dynamic>{},
            'likerIds': <String>[],
            'commentCount': 0,
            'createdAt': Timestamp.fromDate(DateTime.utc(2026, 3, 20)),
          },
        );
    await fs.collection('users').doc('viewer').collection('feed_inbox').doc('p2').set(
          <String, dynamic>{
            'authorId': 'good',
            'authorName': 'Good',
            'type': PostType.manualPost.name,
            'content': 'hi',
            'metadata': <String, dynamic>{},
            'likerIds': <String>[],
            'commentCount': 0,
            'createdAt': Timestamp.fromDate(DateTime.utc(2026, 3, 21)),
          },
        );
    final Either<Failure, List<FeedPost>> res = await repo.getFeed('viewer');
    res.fold(
      (_) => fail('unexpected'),
      (List<FeedPost> list) {
        expect(list.length, 1);
        expect(list.single.authorId, 'good');
      },
    );
  });
}
