/// Spendable balance + lifetime totals for a user.
class FitcoinWallet {
  const FitcoinWallet({
    required this.userId,
    required this.balance,
    required this.totalEarned,
    required this.totalSpent,
    required this.updatedAt,
  });

  final String userId;
  final int balance;
  final int totalEarned;
  final int totalSpent;
  final DateTime updatedAt;

  /// Community hub extras (aggregate later from transactions).
  int get earnedToday => 0;

  int get earnedThisWeek => 0;

  int get earnedAllTime => totalEarned;

  /// Display-only INR hint (not a cash balance).
  double get approximateInrValue => balance * 0.10;
}
