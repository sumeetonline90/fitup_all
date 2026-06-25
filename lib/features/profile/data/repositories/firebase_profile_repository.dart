import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:drift/drift.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../../../../core/database/fitup_database.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/sync/sync_status_emitter.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/repositories/profile_repository.dart';
import '../models/user_profile_model.dart';
import '../../../../services/logger_service.dart';

Failure _profileMap(Object e) {
  if (e is FirebaseException) {
    return ProfileFailure(e.message ?? e.code);
  }
  if (e is ProfileFailure) {
    return e;
  }
  return ProfileFailure(e.toString());
}

/// Firestore + Storage + optional Drift cache (`users/{uid}`).
class FirebaseProfileRepository implements ProfileRepository {
  FirebaseProfileRepository(
    this._firestore,
    this._storage, {
    FitupDatabase? database,
    SyncStatusEmitter? syncEmitter,
    void Function(String userId)? onProfileRemoteFailed,
  })  : _db = database,
        _syncEmitter = syncEmitter,
        _onProfileRemoteFailed = onProfileRemoteFailed;

  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;
  final FitupDatabase? _db;
  final SyncStatusEmitter? _syncEmitter;
  final void Function(String userId)? _onProfileRemoteFailed;

  static const String _users = 'users';

  DocumentReference<Map<String, dynamic>> _ref(String userId) =>
      _firestore.collection(_users).doc(userId);

  Future<void> _writeCache(UserProfile p, {required bool synced}) async {
    final FitupDatabase? db = _db;
    if (db == null) {
      return;
    }
    await db.into(db.userProfileCache).insertOnConflictUpdate(
          UserProfileCacheCompanion.insert(
            userId: p.userId,
            payloadJson: UserProfileModel.toCacheJson(p),
            synced: Value<bool>(synced),
            updatedAt: p.updatedAt ?? DateTime.now(),
          ),
        );
  }

  Future<UserProfileCacheRow?> _readCacheRow(String userId) async {
    final FitupDatabase? db = _db;
    if (db == null) {
      return null;
    }
    try {
      return await (db.select(db.userProfileCache)
            ..where((UserProfileCache tbl) => tbl.userId.equals(userId)))
          .getSingleOrNull();
    } catch (_) {
      return null;
    }
  }

  Future<UserProfile?> _readCache(String userId) async {
    final UserProfileCacheRow? row = await _readCacheRow(userId);
    if (row == null) {
      return null;
    }
    return UserProfileModel.fromCacheJson(row.payloadJson);
  }

  @override
  Future<Either<Failure, UserProfile>> getProfile(String userId) async {
    try {
      final UserProfile? cached = await _readCache(userId);
      if (cached != null) {
        return Right<Failure, UserProfile>(cached);
      }
      final DocumentSnapshot<Map<String, dynamic>> doc =
          await _ref(userId).get();
      if (!doc.exists) {
        final UserProfile shell = UserProfile(
          userId: userId,
          email: '',
          updatedAt: DateTime.now(),
        );
        await _writeCache(shell, synced: false);
        return Right<Failure, UserProfile>(shell);
      }
      final UserProfile p = UserProfileModel.fromFirestore(doc);
      await _writeCache(p, synced: true);
      return Right<Failure, UserProfile>(p);
    } catch (e, st) {
      LoggerService.e('getProfile', e, st);
      return Left<Failure, UserProfile>(_profileMap(e));
    }
  }

  @override
  Stream<UserProfile> watchProfile(String userId) {
    return _ref(userId).snapshots().asyncMap(
      (DocumentSnapshot<Map<String, dynamic>> doc) async {
        if (!doc.exists) {
          final UserProfile shell = UserProfile(
            userId: userId,
            email: '',
            updatedAt: DateTime.now(),
          );
          await _writeCache(shell, synced: false);
          return shell;
        }
        final UserProfile p = UserProfileModel.fromFirestore(doc);
        await _writeCache(p, synced: true);
        return p;
      },
    );
  }

  @override
  Future<Either<Failure, Unit>> updateProfile(UserProfile profile) async {
    try {
      await _writeCache(profile, synced: true);
    } catch (e, st) {
      LoggerService.e('updateProfile cache', e, st);
      return Left<Failure, Unit>(_profileMap(e));
    }
    try {
      await _ref(profile.userId).set(
        UserProfileModel.toFirestore(profile),
        SetOptions(merge: true),
      );
      await _writeCache(profile, synced: true);
      return const Right<Failure, Unit>(unit);
    } catch (e, st) {
      LoggerService.w('updateProfile remote', e, st);
      try {
        await _writeCache(profile, synced: false);
      } catch (_) {}
      _syncEmitter?.emitProfilePendingLocalSync();
      _onProfileRemoteFailed?.call(profile.userId);
      return const Right<Failure, Unit>(unit);
    }
  }

  @override
  Future<Either<Failure, Unit>> flushPendingProfileToRemote(String userId) async {
    final UserProfileCacheRow? row = await _readCacheRow(userId);
    if (row == null || row.synced) {
      return const Right<Failure, Unit>(unit);
    }
    final UserProfile profile = UserProfileModel.fromCacheJson(row.payloadJson);
    try {
      await _ref(userId).set(
        UserProfileModel.toFirestore(profile),
        SetOptions(merge: true),
      );
      await _writeCache(profile, synced: true);
      return const Right<Failure, Unit>(unit);
    } catch (e, st) {
      LoggerService.w('flushPendingProfileToRemote', e, st);
      return Left<Failure, Unit>(_profileMap(e));
    }
  }

  @override
  Future<Either<Failure, void>> saveProfile(UserProfile profile) async {
    final Either<Failure, Unit> r = await updateProfile(profile);
    return r.fold(Left<Failure, void>.new, (_) => const Right<Failure, void>(null));
  }

  @override
  Future<Either<Failure, Unit>> completeOnboarding(String userId) async {
    try {
      await _ref(userId).set(
        <String, dynamic>{
          'isOnboarded': true,
          'onboardingComplete': true,
          'onboardingCompletedAt': FieldValue.serverTimestamp(),
          'profileUpdatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
      final DocumentSnapshot<Map<String, dynamic>> doc = await _ref(userId).get();
      if (doc.exists) {
        final UserProfile p = UserProfileModel.fromFirestore(doc);
        await _writeCache(p, synced: true);
      }
      return const Right<Failure, Unit>(unit);
    } catch (e, st) {
      LoggerService.e('completeOnboarding', e, st);
      return Left<Failure, Unit>(_profileMap(e));
    }
  }

  @override
  Future<Either<Failure, String>> uploadAvatar(
    String userId,
    Uint8List bytes,
    String mimeType,
  ) async {
    try {
      final String ext = mimeType.contains('png') ? 'png' : 'jpg';
      final Reference ref =
          _storage.ref().child('users').child(userId).child('avatar.$ext');
      await ref.putData(bytes, SettableMetadata(contentType: mimeType));
      final String url = await ref.getDownloadURL();
      await _ref(userId).set(
        <String, dynamic>{'photoUrl': url},
        SetOptions(merge: true),
      );
      return Right(url);
    } catch (e, st) {
      LoggerService.e('uploadAvatar', e, st);
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, String>> uploadProgressPhoto(
    String userId,
    String slot,
    Uint8List bytes,
    String mimeType,
  ) async {
    try {
      final String ext = mimeType.contains('png') ? 'png' : 'jpg';
      final String ts = DateTime.now().millisecondsSinceEpoch.toString();
      final Reference ref = _storage
          .ref()
          .child('users')
          .child(userId)
          .child('progress')
          .child('${slot}_$ts.$ext');
      await ref.putData(bytes, SettableMetadata(contentType: mimeType));
      final String url = await ref.getDownloadURL();
      final DocumentSnapshot<Map<String, dynamic>> snap = await _ref(userId).get();
      final Map<String, dynamic> urls = Map<String, dynamic>.from(
        (snap.data()?['progressPhotoUrls'] as Map<String, dynamic>?) ??
            <String, dynamic>{},
      );
      urls[slot] = url;
      await _ref(userId).set(
        <String, dynamic>{'progressPhotoUrls': urls},
        SetOptions(merge: true),
      );
      return Right(url);
    } catch (e, st) {
      LoggerService.e('uploadProgressPhoto', e, st);
      return Left(ServerFailure(e.toString()));
    }
  }
}
