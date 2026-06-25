enum PostType { achievement, milestone, eventResult, manualPost }

class FeedPost {
  const FeedPost({
    required this.id,
    required this.authorId,
    required this.authorName,
    required this.type,
    required this.content,
    this.metadata,
    required this.likerIds,
    required this.commentCount,
    required this.createdAt,
  });

  final String id;
  final String authorId;
  final String authorName;
  final PostType type;
  final String content;
  final Map<String, dynamic>? metadata;
  final List<String> likerIds;
  final int commentCount;
  final DateTime createdAt;

  /// Legacy community UI text (single body field).
  String? get body => content.isEmpty ? null : content;

  String? get achievementTitle => type == PostType.achievement ? content : null;

  String? get milestoneTitle => type == PostType.milestone ? content : null;

  /// Optional social UI fields (demo + legacy layouts) via [metadata].
  String get handle =>
      (metadata?['handle'] as String?) ?? '@${authorName.toLowerCase()}';

  int get followerCount => (metadata?['followerCount'] as num?)?.toInt() ?? 0;

  DateTime get postedAt => createdAt;

  int get likeCount => likerIds.length;

  bool get isLiked => metadata?['isLiked'] as bool? ?? false;

  /// True if [userId] is in [likerIds] (canonical; preferred over [isLiked]).
  bool isLikedByUser(String? userId) =>
      userId != null && likerIds.contains(userId);

  String? get prLabel => metadata?['prLabel'] as String?;

  String? get moduleStatsLine => metadata?['moduleStatsLine'] as String?;

  int? get streakDays => (metadata?['streakDays'] as num?)?.toInt();
}

/// Horizontal story ring (UI demo).
class FeedStory {
  const FeedStory({
    required this.id,
    required this.initials,
    required this.seen,
  });

  final String id;
  final String initials;
  final bool seen;
}
