import 'package:fitup/features/mental_wellbeing/domain/entities/breathing_pattern.dart';
import 'package:fitup/features/mental_wellbeing/presentation/screens/breathing_session_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('BreathingSessionScreen shows phase label Inhale at session start',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: BreathingSessionScreen(pattern: BreathingPattern.box478),
        ),
      ),
    );
    expect(find.text('Inhale'), findsOneWidget);
  });
}
