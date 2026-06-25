import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/fitup_user.dart';

/// Auth abstraction — Firebase implementation in `data/`.
abstract class AuthRepository {
  Future<Either<Failure, FitupUser>> signInWithGoogle();

  Future<Either<Failure, FitupUser>> signInWithEmail(
    String email,
    String password,
  );

  Future<Either<Failure, FitupUser>> registerWithEmail(
    String email,
    String password, {
    String? displayName,
  });

  Future<Either<Failure, void>> signOut();

  /// Deletes the Firebase Auth account (may require recent login on backend).
  Future<Either<Failure, void>> deleteAccount();

  Stream<FitupUser?> get authStateChanges;

  FitupUser? get currentUser;
}
