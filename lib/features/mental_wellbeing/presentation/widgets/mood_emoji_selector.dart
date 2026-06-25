import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/mood_level.dart';

/// Five emoji buttons mapped to [MoodLevel].
class MoodEmojiSelector extends StatelessWidget {
  const MoodEmojiSelector({super.key, required this.onMoodSelected});

  final ValueChanged<MoodLevel> onMoodSelected;

  static const List<({String emoji, MoodLevel level})> _items =
      <({String emoji, MoodLevel level})>[
        (emoji: '😫', level: MoodLevel.veryBad),
        (emoji: '😕', level: MoodLevel.bad),
        (emoji: '😐', level: MoodLevel.neutral),
        (emoji: '🙂', level: MoodLevel.good),
        (emoji: '😄', level: MoodLevel.veryGood),
      ];

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: _items.map((({String emoji, MoodLevel level}) e) {
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Material(
              color: AppColors.surfaceContainer.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => onMoodSelected(e.level),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Center(
                    child: Text(e.emoji, style: const TextStyle(fontSize: 28)),
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
