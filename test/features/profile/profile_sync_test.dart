import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:fitup/core/database/fitup_database.dart';
import 'package:fitup/core/error/failures.dart';
import 'package:fitup/core/sync/sync_status_emitter.dart';
import 'package:fitup/features/profile/data/models/user_profile_model.dart';
import 'package:fitup/features/profile/data/repositories/firebase_profile_repository.dart';
import 'package:fitup/features/profile/domain/entities/user_profile.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockStorage extends Mock implements FirebaseStorage {}

void main() {
  late FakeFirebaseFirestore fs;
  late FitupDatabase db;
  late FirebaseProfileRepository repo;

  setUp(() {
    fs = FakeFirebaseFirestore();
    db = FitupDatabase(NativeDatabase.memory());
    repo = FirebaseProfileRepository(
      fs,
      _MockStorage(),
      database: db,
      syncEmitter: SyncStatusEmitter(),
      onProfileRemoteFailed: (_) {},
    );
  });

  tearDown(() async {
    await db.close();
  });

  test('flushPendingProfileToRemote writes Firestore when Drift synced is false', () async {
    final UserProfile p = UserProfile(
      userId: 'u1',
      email: 'a@b.com',
      updatedAt: DateTime.utc(2026, 1, 1),
    );
    await db.into(db.userProfileCache).insertOnConflictUpdate(
          UserProfileCacheCompanion.insert(
            userId: p.userId,
            payloadJson: UserProfileModel.toCacheJson(p),
            synced: const Value<bool>(false),
            updatedAt: p.updatedAt ?? DateTime.now(),
          ),
        );
    final Either<Failure, Unit> r = await repo.flushPendingProfileToRemote('u1');
    expect(r.isRight(), isTrue);
    final DocumentSnapshot<Map<String, dynamic>> doc =
        await fs.collection('users').doc('u1').get();
    expect(doc.exists, isTrue);
  });
}
