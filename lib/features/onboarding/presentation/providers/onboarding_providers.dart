import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/fitup_database.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/error/failures.dart';
import '../../../../services/analytics_service.dart';
import '../../../auth/domain/entities/fitup_user.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../profile/domain/entities/emergency_contact.dart';
import '../../../profile/domain/entities/profile_enums.dart';
import '../../../profile/domain/entities/user_profile.dart';
import '../../../profile/domain/repositories/profile_repository.dart';
import '../../../profile/presentation/providers/profile_providers.dart';
import '../../data/onboarding_draft_repository.dart';
import '../../domain/onboarding_state.dart';

final Provider<OnboardingDraftRepository> onboardingDraftRepositoryProvider =
    Provider<OnboardingDraftRepository>((Ref ref) {
  return OnboardingDraftRepository(kIsWeb ? null : getIt<FitupDatabase>());
});

final AsyncNotifierProvider<OnboardingNotifier, OnboardingState>
    onboardingNotifierProvider =
    AsyncNotifierProvider<OnboardingNotifier, OnboardingState>(
  OnboardingNotifier.new,
);

class OnboardingNotifier extends AsyncNotifier<OnboardingState> {
  OnboardingDraftRepository get _drafts =>
      ref.read(onboardingDraftRepositoryProvider);

  @override
  Future<OnboardingState> build() async {
    final FitupUser? user = ref.watch(authStateProvider).value;
    if (user == null) {
      return const OnboardingState();
    }
    final Either<Failure, OnboardingState?> res =
        await _drafts.loadDraft(user.id);
    return res.fold(
      (_) => const OnboardingState(),
      (OnboardingState? s) => s ?? const OnboardingState(),
    );
  }

  Future<void> _persist(OnboardingState next) async {
    state = AsyncData<OnboardingState>(next);
    final FitupUser? user = ref.read(authStateProvider).value;
    if (user == null) {
      return;
    }
    await _drafts.saveDraft(user.id, next);
  }

  void setStep(int step) {
    final OnboardingState s = state.requireValue;
    unawaited(_persist(s.copyWith(currentStep: step.clamp(0, 4))));
  }

  void nextStep() => setStep(state.requireValue.currentStep + 1);

  void prevStep() => setStep(state.requireValue.currentStep - 1);

  void toggleGoal(HealthGoal g) {
    final OnboardingState s = state.requireValue;
    final Set<HealthGoal> next = Set<HealthGoal>.from(s.goals);
    if (next.contains(g)) {
      if (next.length > 1) {
        next.remove(g);
      }
    } else {
      next.add(g);
    }
    unawaited(_persist(s.copyWith(goals: next)));
  }

  void setBodyMetrics({
    ProfileGender? gender,
    DateTime? dateOfBirth,
    double? heightCm,
    double? weightKg,
    double? targetWeightKg,
    bool? useMetricUnits,
  }) {
    final OnboardingState s = state.requireValue;
    unawaited(
      _persist(
        s.copyWith(
          gender: gender ?? s.gender,
          dateOfBirth: dateOfBirth ?? s.dateOfBirth,
          heightCm: heightCm ?? s.heightCm,
          weightKg: weightKg ?? s.weightKg,
          targetWeightKg: targetWeightKg ?? s.targetWeightKg,
          useMetricUnits: useMetricUnits ?? s.useMetricUnits,
        ),
      ),
    );
  }

  void setDietPrefs({
    DietType? dietType,
    List<String>? cuisines,
    List<String>? allergies,
  }) {
    final OnboardingState s = state.requireValue;
    unawaited(
      _persist(
        s.copyWith(
          dietType: dietType ?? s.dietType,
          cuisines: cuisines ?? s.cuisines,
          allergies: allergies ?? s.allergies,
        ),
      ),
    );
  }

  void setFitness(FitnessLevel level, ActivityLevel activity) {
    unawaited(
      _persist(
        state.requireValue.copyWith(
          fitnessLevel: level,
          activityLevel: activity,
        ),
      ),
    );
  }

  void setHealthConditions({
    List<String>? conditions,
    String? medicationsNote,
    List<EmergencyContact>? contacts,
  }) {
    final OnboardingState s = state.requireValue;
    unawaited(
      _persist(
        s.copyWith(
          healthConditions: conditions ?? s.healthConditions,
          medicationsNote: medicationsNote ?? s.medicationsNote,
          emergencyContacts: contacts ?? s.emergencyContacts,
        ),
      ),
    );
  }

  Future<bool> complete() async {
    final FitupUser? user = ref.read(authStateProvider).value;
    if (user == null) {
      return false;
    }
    final UserProfile p = state.requireValue.toUserProfile(
      userId: user.id,
      email: user.email,
      displayName: user.displayName,
      photoUrl: user.photoUrl,
      isOnboarded: true,
    );
    final ProfileRepository repo = ref.read(profileRepositoryProvider);
    final Either<Failure, Unit> updated = await repo.updateProfile(p);
    if (updated.isLeft()) {
      return false;
    }
    final Either<Failure, Unit> done = await repo.completeOnboarding(user.id);
    if (done.isRight()) {
      await _drafts.clearDraft(user.id);
      if (getIt.isRegistered<AnalyticsService>()) {
        unawaited(
          getIt<AnalyticsService>().logEvent(AnalyticsEvents.onboardingComplete),
        );
      }
    }
    return done.isRight();
  }

  Future<bool> skip() async {
    final FitupUser? user = ref.read(authStateProvider).value;
    if (user == null) {
      return false;
    }
    final UserProfile p = state.requireValue.toUserProfile(
      userId: user.id,
      email: user.email,
      displayName: user.displayName,
      photoUrl: user.photoUrl,
      isOnboarded: true,
    );
    final ProfileRepository repo = ref.read(profileRepositoryProvider);
    final Either<Failure, Unit> updated = await repo.updateProfile(p);
    if (updated.isLeft()) {
      return false;
    }
    final Either<Failure, Unit> done = await repo.completeOnboarding(user.id);
    if (done.isRight()) {
      await _drafts.clearDraft(user.id);
      if (getIt.isRegistered<AnalyticsService>()) {
        unawaited(
          getIt<AnalyticsService>().logEvent(AnalyticsEvents.onboardingComplete),
        );
      }
    }
    return done.isRight();
  }
}
