import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/error/failures.dart';
import '../../../../services/analytics_service.dart';
import '../../../../services/notification_service.dart';
import '../../../../services/subscription_service.dart';
import '../../../fitcoins/domain/services/fitcoin_award_service.dart';
import '../../domain/entities/fitup_user.dart';
import '../../domain/repositories/auth_repository.dart';

/// Global [AuthRepository] from get_it.
final authRepositoryProvider = Provider<AuthRepository>(
  (Ref ref) => getIt<AuthRepository>(),
);

/// Emits signed-in [FitupUser] or null.
final authStateProvider = StreamProvider<FitupUser?>((Ref ref) {
  return ref.watch(authRepositoryProvider).authStateChanges;
});

/// Auth actions (sign-in / register / sign-out).
final authNotifierProvider =
    AsyncNotifierProvider<AuthNotifier, void>(AuthNotifier.new);

class AuthNotifier extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() async {}

  Future<void> signInWithGoogle() async {
    state = const AsyncLoading();
    final Either<Failure, FitupUser> result =
        await ref.read(authRepositoryProvider).signInWithGoogle();
    result.fold(
      (Failure f) {
        state = AsyncError(
          Exception(f.message ?? 'Authentication failed'),
          StackTrace.current,
        );
      },
      (FitupUser user) {
        unawaited(getIt<FitcoinAwardService>().onDailyLogin(user.id));
        unawaited(getIt<SubscriptionService>().identifyUser(user.id));
        unawaited(getIt<AnalyticsService>().setUserId(user.id));
        state = const AsyncData(null);
      },
    );
  }

  Future<void> signInWithEmail(String email, String password) async {
    state = const AsyncLoading();
    final Either<Failure, FitupUser> result =
        await ref.read(authRepositoryProvider).signInWithEmail(email, password);
    result.fold(
      (Failure f) {
        state = AsyncError(
          Exception(f.message ?? 'Authentication failed'),
          StackTrace.current,
        );
      },
      (FitupUser user) {
        unawaited(getIt<FitcoinAwardService>().onDailyLogin(user.id));
        unawaited(getIt<SubscriptionService>().identifyUser(user.id));
        unawaited(getIt<AnalyticsService>().setUserId(user.id));
        state = const AsyncData(null);
      },
    );
  }

  Future<void> registerWithEmail(
    String email,
    String password, {
    String? displayName,
  }) async {
    state = const AsyncLoading();
    final Either<Failure, FitupUser> result =
        await ref.read(authRepositoryProvider).registerWithEmail(
              email,
              password,
              displayName: displayName,
            );
    result.fold(
      (Failure f) {
        state = AsyncError(
          Exception(f.message ?? 'Registration failed'),
          StackTrace.current,
        );
      },
      (FitupUser user) {
        unawaited(getIt<FitcoinAwardService>().onDailyLogin(user.id));
        unawaited(getIt<SubscriptionService>().identifyUser(user.id));
        unawaited(getIt<AnalyticsService>().setUserId(user.id));
        state = const AsyncData(null);
      },
    );
  }

  Future<void> signOut() async {
    state = const AsyncLoading();
    await getIt<NotificationService>().cancelAll();
    await getIt<SubscriptionService>().billingLogout();
    unawaited(getIt<AnalyticsService>().setUserId(null));
    final Either<Failure, void> result =
        await ref.read(authRepositoryProvider).signOut();
    result.fold(
      (Failure f) {
        state = AsyncError(
          Exception(f.message ?? 'Sign out failed'),
          StackTrace.current,
        );
      },
      (_) => state = const AsyncData(null),
    );
  }
}
