import 'dart:typed_data';

import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/user_profile.dart';

/// User profile persistence (Firestore + Storage + Drift) — UI uses providers only.
abstract class ProfileRepository {
  Future<Either<Failure, UserProfile>> getProfile(String userId);

  Stream<UserProfile> watchProfile(String userId);

  /// Offline-first: Drift optimistic [synced]=true, then Firestore; remote failure
  /// marks cache [synced]=false, emits sync status, enqueues retry — still [Right].
  Future<Either<Failure, Unit>> updateProfile(UserProfile profile);

  /// Push cached profile to Firestore when online (used by [SyncService]).
  Future<Either<Failure, Unit>> flushPendingProfileToRemote(String userId);

  /// Legacy alias for [updateProfile].
  Future<Either<Failure, void>> saveProfile(UserProfile profile);

  Future<Either<Failure, Unit>> completeOnboarding(String userId);

  Future<Either<Failure, String>> uploadAvatar(
    String userId,
    Uint8List bytes,
    String mimeType,
  );

  Future<Either<Failure, String>> uploadProgressPhoto(
    String userId,
    String slot,
    Uint8List bytes,
    String mimeType,
  );
}
