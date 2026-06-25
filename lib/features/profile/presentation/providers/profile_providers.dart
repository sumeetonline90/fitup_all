import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/error/failures.dart';
import '../../../../services/subscription_service.dart';
import '../../../auth/domain/entities/fitup_user.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../domain/entities/profile_enums.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/repositories/profile_repository.dart';

/// Registered [ProfileRepository].
final Provider<ProfileRepository> profileRepositoryProvider =
    Provider<ProfileRepository>((Ref ref) => getIt<ProfileRepository>());

/// Live profile from Firestore — show [AsyncValue.isLoading] with prior data in UI.
final StreamProvider<UserProfile> userProfileProvider =
    StreamProvider<UserProfile>((Ref ref) {
  final AsyncValue<FitupUser?> auth = ref.watch(authStateProvider);
  final FitupUser? u = auth.value;
  if (u == null) {
    return Stream<UserProfile>.value(
      UserProfile(
        userId: '',
        email: '',
        updatedAt: DateTime.now(),
      ),
    );
  }
  return ref.watch(profileRepositoryProvider).watchProfile(u.id);
});

/// Subscription tier from [SubscriptionService] (RevenueCat stub in Phase 8).
final StreamProvider<SubscriptionTier> subscriptionTierProvider =
    StreamProvider<SubscriptionTier>((Ref ref) {
  final FitupUser? u = ref.watch(authStateProvider).value;
  if (u == null) {
    return Stream<SubscriptionTier>.value(SubscriptionTier.free);
  }
  return getIt<SubscriptionService>().watchTier(u.id);
});

final AsyncNotifierProvider<EditProfileNotifier, void> editProfileNotifierProvider =
    AsyncNotifierProvider<EditProfileNotifier, void>(EditProfileNotifier.new);

/// Persists profile updates from [EditProfileScreen].
class EditProfileNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> updateProfile(UserProfile profile) async {
    state = const AsyncLoading();
    final Either<Failure, Unit> result =
        await ref.read(profileRepositoryProvider).updateProfile(profile);
    result.fold(
      (Failure f) {
        state = AsyncError<void>(f, StackTrace.current);
      },
      (_) {
        state = const AsyncData<void>(null);
      },
    );
  }
}
