enum AchievementCategory { all, activity, workout, diet, streaks, social }

class AchievementItem {
  const AchievementItem({
    required this.id,
    required this.name,
    required this.iconCodePoint,
    required this.category,
    required this.unlocked,
    this.unlockDate,
    this.progressNumerator,
    this.progressDenominator,
    this.isNew = false,
    this.fcReward = 0,
  });

  final String id;
  final String name;
  final int iconCodePoint;
  final AchievementCategory category;
  final bool unlocked;
  final DateTime? unlockDate;
  final int? progressNumerator;
  final int? progressDenominator;
  final bool isNew;
  final int fcReward;
}
