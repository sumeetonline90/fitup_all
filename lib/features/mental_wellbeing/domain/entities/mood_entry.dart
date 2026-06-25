import 'mood_level.dart';

class MoodEntry {
  const MoodEntry({
    required this.id,
    required this.userId,
    required this.mood,
    required this.recordedAt,
    this.journal,
    this.tags = const <String>[],
  });

  final String id;
  final String userId;
  final MoodLevel mood;
  final String? journal;
  final DateTime recordedAt;
  final List<String> tags;
}
