import 'package:fitup/features/mental_wellbeing/domain/entities/mood_level.dart';
import 'package:fitup/features/mental_wellbeing/presentation/widgets/mood_emoji_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('MoodEmojiSelector calls onMoodSelected with correct MoodLevel',
      (WidgetTester tester) async {
    MoodLevel? picked;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MoodEmojiSelector(
            onMoodSelected: (MoodLevel l) => picked = l,
          ),
        ),
      ),
    );
    await tester.tap(find.text('🙂'));
    expect(picked, MoodLevel.good);
  });
}
