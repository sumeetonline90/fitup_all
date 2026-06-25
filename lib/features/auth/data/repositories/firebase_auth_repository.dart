import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:firebase_auth/firebase_auth.dart'
    show
        FirebaseAuth,
        FirebaseAuthException,
        GoogleAuthProvider,
        OAuthCredential,
        User,
        UserCredential;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../../../core/error/failures.dart';
import '../../../../services/account_deletion_service.dart';
import '../../../../services/logger_service.dart';
import '../../domain/entities/fitup_user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../models/fitup_user_model.dart';

/// Firebase Auth + Firestore user profile at `users/{uid}`.
class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository(
    this._auth,
    this._firestore,
    this._googleSignIn,
    this._accountDeletion,
  );

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final GoogleSignIn _googleSignIn;
  final AccountDeletionService _accountDeletion;

  static const String _users = 'users';

  String _friendlyAuthMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'user-not-found':
        return 'No account found with that email.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'email-already-in-use':
        return 'An account already exists with this email.';
      case 'weak-password':
        return 'Password must be at least 6 characters.';
      case 'too-many-requests':
        return 'Too many attempts. Please wait a few minutes.';
      case 'network-request-failed':
        return 'No internet connection. Please check your network.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'invalid-credential':
        return 'Invalid credentials. Please check and try again.';
      default:
        return 'Something went wrong. Please try again.';
    }
  }

  @override
  FitupUser? get currentUser {
    final User? u = _auth.currentUser;
    if (u == null) {
      return null;
    }
    return FitupUser(
      id: u.uid,
      email: u.email ?? '',
      displayName: u.displayName,
      photoUrl: u.photoURL,
      isOnboarded: false,
      createdAt: u.metadata.creationTime ?? DateTime.now(),
    );
  }

  @override
  Stream<FitupUser?> get authStateChanges {
    return _auth.authStateChanges().asyncMap((User? user) async {
      if (user == null) {
        return null;
      }
      await _ensureUserDocument(user);
      final DocumentSnapshot<Map<String, dynamic>> doc =
          await _firestore.collection(_users).doc(user.uid).get();
      if (!doc.exists) {
        return _fromFirebaseUser(user);
      }
      return FitupUserModel.fromFirestore(doc);
    });
  }

  FitupUser _fromFirebaseUser(User user) {
    return FitupUser(
      id: user.uid,
      email: user.email ?? '',
      displayName: user.displayName,
      photoUrl: user.photoURL,
      isOnboarded: false,
      createdAt: user.metadata.creationTime ?? DateTime.now(),
    );
  }

  Future<void> _ensureUserDocument(User user) async {
    final DocumentReference<Map<String, dynamic>> ref =
        _firestore.collection(_users).doc(user.uid);
    final DocumentSnapshot<Map<String, dynamic>> snap = await ref.get();
    final FitupUserModel model = FitupUserModel(
      id: user.uid,
      email: user.email ?? '',
      displayName: user.displayName,
      photoUrl: user.photoURL,
      isOnboarded: false,
      createdAt: user.metadata.creationTime ?? DateTime.now(),
    );
    if (!snap.exists) {
      await ref.set(model.toFirestore());
    } else {
      await ref.set(
        <String, dynamic>{
          'email': model.email,
          'displayName': model.displayName,
          'photoUrl': model.photoUrl,
        },
        SetOptions(merge: true),
      );
    }
    await _updateLoginStreak(ref);
  }

  Future<void> _updateLoginStreak(
    DocumentReference<Map<String, dynamic>> ref,
  ) async {
    final DocumentSnapshot<Map<String, dynamic>> snap = await ref.get();
    final Map<String, dynamic> d = snap.data() ?? <String, dynamic>{};
    final DateTime now = DateTime.now();
    final DateTime today = DateTime(now.year, now.month, now.day);
    final Timestamp? lastTs = d['lastLoginDate'] as Timestamp?;
    final DateTime? last = lastTs?.toDate();
    final DateTime? lastDay = last == null
        ? null
        : DateTime(last.year, last.month, last.day);
    final int current = (d['currentStreakDays'] as num?)?.toInt() ?? 0;

    int nextStreak;
    if (lastDay == null) {
      nextStreak = 1;
    } else {
      final int dayDiff = today.difference(lastDay).inDays;
      if (dayDiff <= 0) {
        nextStreak = current > 0 ? current : 1;
      } else if (dayDiff == 1) {
        nextStreak = current + 1;
      } else {
        nextStreak = 1;
      }
    }

    await ref.set(
      <String, dynamic>{
        'currentStreakDays': nextStreak,
        'lastLoginDate': Timestamp.fromDate(today),
      },
      SetOptions(merge: true),
    );
  }

  @override
  Future<Either<Failure, FitupUser>> signInWithGoogle() async {
    try {
      if (kIsWeb) {
        // Web: use FirebaseAuth's popup flow (google_sign_in doesn't work reliably).
        final GoogleAuthProvider provider = GoogleAuthProvider();
        final UserCredential cred =
            await _auth.signInWithPopup(provider);
        final User? user = cred.user;
        if (user == null) {
          return const Left(AuthFailure('No user returned'));
        }
        await _ensureUserDocument(user);
        final DocumentSnapshot<Map<String, dynamic>> doc =
            await _firestore.collection(_users).doc(user.uid).get();
        if (doc.exists) {
          return Right(FitupUserModel.fromFirestore(doc));
        }
        return Right(_fromFirebaseUser(user));
      }

      // Mobile/desktop: keep the existing google_sign_in flow.
      final GoogleSignInAccount? googleUser =
          await _googleSignIn.signIn();
      if (googleUser == null) {
        return const Left(AuthFailure('Sign-in cancelled'));
      }
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      final UserCredential cred =
          await _auth.signInWithCredential(credential);
      final User? user = cred.user;
      if (user == null) {
        return const Left(AuthFailure('No user returned'));
      }
      await _ensureUserDocument(user);
      final DocumentSnapshot<Map<String, dynamic>> doc =
          await _firestore.collection(_users).doc(user.uid).get();
      if (doc.exists) {
        return Right(FitupUserModel.fromFirestore(doc));
      }
      return Right(_fromFirebaseUser(user));
    } on FirebaseAuthException catch (e, st) {
      LoggerService.e('signInWithGoogle auth', e, st);
      return Left(AuthFailure(_friendlyAuthMessage(e)));
    } catch (e, st) {
      LoggerService.e('signInWithGoogle', e, st);
      return const Left<Failure, FitupUser>(
        AuthFailure('Something went wrong. Please try again.'),
      );
    }
  }

  @override
  Future<Either<Failure, FitupUser>> signInWithEmail(
    String email,
    String password,
  ) async {
    try {
      final UserCredential cred = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final User? user = cred.user;
      if (user == null) {
        return const Left(AuthFailure('No user returned'));
      }
      await _ensureUserDocument(user);
      final DocumentSnapshot<Map<String, dynamic>> doc =
          await _firestore.collection(_users).doc(user.uid).get();
      if (doc.exists) {
        return Right(FitupUserModel.fromFirestore(doc));
      }
      return Right(_fromFirebaseUser(user));
    } on FirebaseAuthException catch (e, st) {
      LoggerService.e('signInWithEmail', e, st);
      return Left(AuthFailure(_friendlyAuthMessage(e)));
    } catch (e, st) {
      LoggerService.e('signInWithEmail', e, st);
      return const Left<Failure, FitupUser>(
        AuthFailure('Something went wrong. Please try again.'),
      );
    }
  }

  @override
  Future<Either<Failure, FitupUser>> registerWithEmail(
    String email,
    String password, {
    String? displayName,
  }) async {
    try {
      final UserCredential cred = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final User? user = cred.user;
      if (user == null) {
        return const Left(AuthFailure('No user returned'));
      }
      if (displayName != null && displayName.trim().isNotEmpty) {
        await user.updateDisplayName(displayName.trim());
        await user.reload();
      }
      final User? fresh = _auth.currentUser;
      await _ensureUserDocument(fresh ?? user);
      final DocumentSnapshot<Map<String, dynamic>> doc =
          await _firestore.collection(_users).doc(user.uid).get();
      if (doc.exists) {
        return Right(FitupUserModel.fromFirestore(doc));
      }
      return Right(_fromFirebaseUser(user));
    } on FirebaseAuthException catch (e, st) {
      LoggerService.e('registerWithEmail', e, st);
      return Left(AuthFailure(_friendlyAuthMessage(e)));
    } catch (e, st) {
      LoggerService.e('registerWithEmail', e, st);
      return const Left<Failure, FitupUser>(
        AuthFailure('Something went wrong. Please try again.'),
      );
    }
  }

  @override
  Future<Either<Failure, void>> signOut() async {
    try {
      await Future.wait(<Future<void>>[
        _auth.signOut(),
        _googleSignIn.signOut(),
      ]);
      return const Right(null);
    } catch (e, st) {
      LoggerService.e('signOut', e, st);
      return Left(AuthFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteAccount() async {
    try {
      final User? u = _auth.currentUser;
      if (u == null) {
        return const Left(AuthFailure('Not signed in'));
      }
      final String uid = u.uid;
      final Either<Failure, Unit> wiped = await _accountDeletion.deleteAllUserData(uid);
      if (wiped.isLeft()) {
        return wiped.fold(
          (Failure f) => Left<Failure, void>(f),
          (_) => throw StateError('unreachable'),
        );
      }
      try {
        await u.delete();
      } on FirebaseAuthException catch (e, st) {
        LoggerService.e('deleteAccount auth', e, st);
        if (e.code == 'requires-recent-login') {
          return const Left<Failure, void>(
            AuthFailure(
              'Please sign out and sign back in, then delete your account again.',
            ),
          );
        }
        return Left<Failure, void>(AuthFailure(e.message ?? e.code));
      }
      await Future.wait(<Future<void>>[
        _googleSignIn.signOut(),
      ]);
      return const Right(null);
    } catch (e, st) {
      LoggerService.e('deleteAccount', e, st);
      return Left(AuthFailure(e.toString()));
    }
  }
}
