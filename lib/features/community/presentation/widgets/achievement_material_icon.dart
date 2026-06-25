import 'package:flutter/material.dart';

/// Maps persisted icon code points to const [IconData] so web release can tree-shake fonts.
IconData achievementIconDataForCodePoint(int codePoint) {
  if (codePoint == Icons.emoji_events_rounded.codePoint) {
    return Icons.emoji_events_rounded;
  }
  if (codePoint == Icons.directions_run_rounded.codePoint) {
    return Icons.directions_run_rounded;
  }
  if (codePoint == Icons.fitness_center_rounded.codePoint) {
    return Icons.fitness_center_rounded;
  }
  if (codePoint == Icons.restaurant_rounded.codePoint) {
    return Icons.restaurant_rounded;
  }
  if (codePoint == Icons.wb_sunny_rounded.codePoint) {
    return Icons.wb_sunny_rounded;
  }
  if (codePoint == Icons.groups_rounded.codePoint) {
    return Icons.groups_rounded;
  }
  return Icons.emoji_events_rounded;
}
