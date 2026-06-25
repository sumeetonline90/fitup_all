/// Ledger entry for Fitcoins (earn / redeem / expire / bonus).
enum TransactionType { earned, redeemed, expired, bonus }

/// Why coins were earned (null for redeem/expired paths).
enum EarnSource {
  dailyStepGoal,
  workoutCompleted,
  allMealsLogged,
  weeklyStreakBonus,
  dailyLogin,
  /// One award when daily water total meets profile goal (idempotent per day).
  waterGoalMet,
  /// Milestone days (3/7/14/30) for consecutive calendar-day logins.
  loginStreakMilestone,
  labScanUploaded,
  eventJoined,
  eventCompleted,
  challengeWon,
  referralSuccess,
  manualBonus,
}

/// Single wallet movement (amount is always positive; [type] implies direction).
class FitcoinTransaction {
  const FitcoinTransaction({
    required this.id,
    required this.userId,
    required this.type,
    this.source,
    required this.amount,
    required this.description,
    required this.createdAt,
    this.synced = false,
  });

  final String id;
  final String userId;
  final TransactionType type;
  final EarnSource? source;
  final int amount;
  final String description;
  final DateTime createdAt;
  final bool synced;

  /// Drives [AchievementCelebrationNotifier] — whitelisted sources only,
  /// each shown at most once per transaction id (persisted on device).
  bool get triggersAchievementCelebration {
    if (type != TransactionType.earned) {
      return false;
    }
    if (source == null) {
      return false;
    }
    return _celebrationSources.contains(source);
  }

  static const Set<EarnSource> _celebrationSources = <EarnSource>{
    EarnSource.dailyStepGoal,
  };
}

/// Wallet history row direction (legacy UI).
enum FitcoinTransactionKind { earn, spend }

extension FitcoinTransactionLegacyUi on FitcoinTransaction {
  /// Stable key for popup dedupe (source + day), independent of tx id.
  String get celebrationDedupeKey {
    final EarnSource? s = source;
    if (s == null) {
      return id;
    }
    final DateTime d = DateTime(createdAt.year, createdAt.month, createdAt.day);
    final String day =
        '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
    return '${s.name}_$day';
  }

  FitcoinTransactionKind get kind =>
      type == TransactionType.redeemed
          ? FitcoinTransactionKind.spend
          : FitcoinTransactionKind.earn;

  DateTime get occurredAt => createdAt;
}
