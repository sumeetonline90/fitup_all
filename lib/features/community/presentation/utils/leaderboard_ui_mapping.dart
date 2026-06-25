import '../../../auth/domain/entities/fitup_user.dart';
import '../../domain/entities/leaderboard_models.dart';

/// Maps pre-computed leaderboard entries (ADR-023) to UI rows — no client aggregation.
LeaderboardRow leaderboardEntryToRow(int rank, MapEntry<String, int> e) {
  final String uid = e.key;
  final String short =
      uid.length > 10 ? '${uid.substring(0, 10)}…' : uid;
  final String initials = uid.isEmpty
      ? '?'
      : uid.length >= 2
          ? uid.substring(0, 2).toUpperCase()
          : uid.substring(0, 1).toUpperCase();
  return LeaderboardRow(
    rank: rank,
    displayName: short,
    handle: '@${short.replaceAll(RegExp(r'\s'), '')}',
    metricValue: e.value,
    avatarInitials: initials.length > 2 ? initials.substring(0, 2) : initials,
    trend: 0,
  );
}

/// Top three entries for podium (second / first / third ordering is handled by the widget).
LeaderboardPodium? leaderboardPodiumFromEntries(List<MapEntry<String, int>> entries) {
  if (entries.length < 3) {
    return null;
  }
  return LeaderboardPodium(
    first: leaderboardEntryToRow(1, entries[0]),
    second: leaderboardEntryToRow(2, entries[1]),
    third: leaderboardEntryToRow(3, entries[2]),
  );
}

String initialsForUser(FitupUser u) {
  final String? n = u.displayName?.trim();
  if (n != null && n.isNotEmpty) {
    final List<String> parts = n.split(RegExp(r'\s+'));
    if (parts.length >= 2 && parts[0].isNotEmpty && parts[1].isNotEmpty) {
      return (parts[0][0] + parts[1][0]).toUpperCase();
    }
    return n.length >= 2 ? n.substring(0, 2).toUpperCase() : n[0].toUpperCase();
  }
  final String e = u.email;
  return e.isNotEmpty ? e.substring(0, 1).toUpperCase() : '?';
}

LeaderboardRow yourLeaderboardRow({
  required FitupUser me,
  required List<MapEntry<String, int>> entries,
}) {
  final int idx = entries.indexWhere((MapEntry<String, int> e) => e.key == me.id);
  if (idx < 0) {
    return LeaderboardRow(
      rank: 0,
      displayName: me.displayName ?? me.email.split('@').first,
      handle: '@${me.email.split('@').first}',
      metricValue: 0,
      avatarInitials: initialsForUser(me),
      trend: 0,
    );
  }
  final MapEntry<String, int> e = entries[idx];
  return LeaderboardRow(
    rank: idx + 1,
    displayName: me.displayName ?? me.email.split('@').first,
    handle: '@${e.key.length > 8 ? e.key.substring(0, 8) : e.key}',
    metricValue: e.value,
    avatarInitials: initialsForUser(me),
    trend: 0,
  );
}

/// Steps / score gap to reach rank 3 (0 if already in top 3 or no data).
int gapToThirdPlace(List<MapEntry<String, int>> entries, FitupUser? me) {
  if (me == null || entries.length < 3) {
    return 0;
  }
  final int idx = entries.indexWhere((MapEntry<String, int> e) => e.key == me.id);
  if (idx < 0 || idx < 3) {
    return 0;
  }
  final int thirdScore = entries[2].value;
  final int yours = entries[idx].value;
  final int gap = thirdScore - yours;
  return gap > 0 ? gap : 0;
}
