import 'package:dartz/dartz.dart';

import '../core/error/failures.dart';
import '../features/profile/domain/entities/profile_enums.dart';
import '../features/profile/domain/repositories/profile_repository.dart';
import 'logger_service.dart';

/// In-app purchases (RevenueCat). Phase 9 will initialise [purchases_flutter].
abstract class SubscriptionService {
  Stream<SubscriptionTier> watchTier(String userId);

  Future<Either<Failure, Unit>> restorePurchases();

  Future<Either<Failure, Unit>> launchSubscriptionFlow();

  /// RevenueCat [Purchases.logIn] (no-op on web / stub).
  Future<void> identifyUser(String userId);

  /// RevenueCat [Purchases.logOut] (no-op on web / stub).
  Future<void> billingLogout();
}

/// Stub: uses [ProfileRepository] when provided (Firestore tier); else [pro] for tests.
class StubSubscriptionService implements SubscriptionService {
  StubSubscriptionService([this._profile]);

  final ProfileRepository? _profile;

  @override
  Stream<SubscriptionTier> watchTier(String userId) {
    final ProfileRepository? repo = _profile;
    if (repo == null || userId.isEmpty) {
      return Stream<SubscriptionTier>.value(SubscriptionTier.pro);
    }
    return repo.watchProfile(userId).map((p) => p.subscriptionTier);
  }

  @override
  Future<Either<Failure, Unit>> restorePurchases() async {
    return const Right<Failure, Unit>(unit);
  }

  @override
  Future<Either<Failure, Unit>> launchSubscriptionFlow() async {
    LoggerService.i('RevenueCat not configured — launchSubscriptionFlow no-op');
    return const Right<Failure, Unit>(unit);
  }

  @override
  Future<void> identifyUser(String userId) async {}

  @override
  Future<void> billingLogout() async {}
}
