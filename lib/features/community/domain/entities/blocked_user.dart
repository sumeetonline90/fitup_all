class BlockedUser {
  const BlockedUser({
    required this.blockerId,
    required this.blockedUserId,
    required this.createdAt,
  });

  final String blockerId;
  final String blockedUserId;
  final DateTime createdAt;
}
