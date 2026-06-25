/// Base type for recoverable / domain errors (use with [Either] from `dartz`).
sealed class Failure implements Exception {
  const Failure([this.message]);

  /// Optional human-readable detail.
  final String? message;

  @override
  String toString() => message ?? '$runtimeType';
}

/// Remote server / Firestore / Functions errors.
final class ServerFailure extends Failure {
  const ServerFailure([super.message]);
}

/// Local cache (Hive / Drift) errors.
final class CacheFailure extends Failure {
  const CacheFailure([super.message]);
}

/// No connectivity or timeout.
final class NetworkFailure extends Failure {
  const NetworkFailure([super.message]);
}

/// Authentication / authorization failures.
final class AuthFailure extends Failure {
  const AuthFailure([super.message]);
}

/// Gemini or other AI provider failures.
final class AiFailure extends Failure {
  const AiFailure([super.message]);
}

/// Domain validation (bad input).
final class ValidationFailure extends Failure {
  const ValidationFailure([super.message]);
}

/// Fitcoin redeem / spend when balance is too low (typed UX — see ADR-021).
final class InsufficientBalanceFailure extends Failure {
  const InsufficientBalanceFailure({
    required this.currentBalance,
    required this.required,
  }) : super('Insufficient Fitcoin balance');

  final int currentBalance;
  final int required;
}

/// Community / social moderation and feed (see Phase 7.1).
final class CommunityFailure extends Failure {
  const CommunityFailure([super.message]);
}

/// OS permissions (health, location, notifications).
final class PermissionFailure extends Failure {
  const PermissionFailure([super.message]);
}

/// Unexpected / unclassified errors (catch-all).
final class UnexpectedFailure extends Failure {
  const UnexpectedFailure([super.message]);
}

/// Workout log persisted but Fitcoin balance update failed (user can retry sync).
final class FitcoinUpdateFailure extends Failure {
  const FitcoinUpdateFailure(
    super.message, {
    required this.savedWorkoutLogId,
  });

  final String savedWorkoutLogId;
}

/// Profile / settings persistence (Phase 8).
final class ProfileFailure extends Failure {
  const ProfileFailure([super.message]);
}

/// RevenueCat / in-app purchase errors (Phase 9).
final class SubscriptionFailure extends Failure {
  const SubscriptionFailure([super.message]);
}

/// Emergency SOS errors (SMS + optional call).
final class SosFailure extends Failure {
  const SosFailure([super.message]);

  const SosFailure.noContactConfigured()
      : super('Please update your emergency contact in Profile.');

  const SosFailure.invalidPhoneNumber(String raw)
      : super('Please update your emergency contact phone in Profile. (Got: $raw)');

  const SosFailure.launchFailed()
      : super('Could not trigger SOS. Please try again.');
}

/// URL launcher errors (HTTPS-only hardening for webview safety).
final class UrlFailure extends Failure {
  const UrlFailure([super.message]);
}
